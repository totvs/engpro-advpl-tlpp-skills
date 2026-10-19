@echo off
setlocal EnableDelayedExpansion
REM convert-encoding.bat — Convert AdvPL/TLPP sources from UTF-8 to CP1252
REM
REM Native on Windows (CMD + PowerShell inline via -Command).
REM No .ps1 execution policy required — runs in any Windows environment.
REM
REM Usage:
REM   convert-encoding.bat file1.prw file2.tlpp
REM   convert-encoding.bat /r src\
REM   convert-encoding.bat /dryrun /r src\

set "VERSION=1.1.0"
set "RECURSIVE=0"
set "DRYRUN=0"
set "CONVERTED=0"
set "SKIPPED=0"
set "ERRORS=0"
set "TOTAL=0"
set "FILE_COUNT=0"

REM Collect arguments
set "PATHS="
:parse_args
if "%~1"=="" goto :end_args
if /I "%~1"=="/r"        (set "RECURSIVE=1" & shift & goto :parse_args)
if /I "%~1"=="--recursive" (set "RECURSIVE=1" & shift & goto :parse_args)
if /I "%~1"=="/dryrun"    (set "DRYRUN=1" & shift & goto :parse_args)
if /I "%~1"=="--dry-run"  (set "DRYRUN=1" & shift & goto :parse_args)
if /I "%~1"=="/h"         goto :usage
if /I "%~1"=="--help"     goto :usage
if /I "%~1"=="/?"         goto :usage
if /I "%~1"=="/v"         (echo convert-encoding.bat v%VERSION% & exit /b 0)
if /I "%~1"=="--version"  (echo convert-encoding.bat v%VERSION% & exit /b 0)

set "FILE_COUNT=0"
:count_existing
if defined PATHS (
    for %%P in (!PATHS!) do set /a FILE_COUNT+=1
)
set /a FILE_COUNT+=1
set "PATHS=!PATHS! "%~1""
shift
goto :parse_args
:end_args

if not defined PATHS (
    echo Error: No files or directories specified. >&2
    goto :usage
)

REM Process each path
for %%A in (%PATHS%) do (
    if exist "%%~A\*" (
        REM It's a directory
        if "!RECURSIVE!"=="1" (
            call :process_dir "%%~A"
        ) else (
            echo SKIP ^(use /r to process directories^): %%~A
            set /a SKIPPED+=1
        )
    ) else if exist "%%~A" (
        REM It's a file
        call :convert_file "%%~A"
    ) else (
        echo SKIP ^(path not found^): %%~A
        set /a SKIPPED+=1
    )
)

REM Summary
echo.
echo --- Summary ---
if "!DRYRUN!"=="1" (
    echo Would convert: !CONVERTED! ^| Skipped: !SKIPPED! ^| Errors: !ERRORS! ^| Total: !TOTAL!
) else (
    echo Converted: !CONVERTED! ^| Skipped: !SKIPPED! ^| Errors: !ERRORS! ^| Total: !TOTAL!
)

if !ERRORS! GTR 0 (exit /b 1) else (exit /b 0)

REM =====================================================
REM Functions
REM =====================================================

:usage
echo convert-encoding.bat v%VERSION%
echo Convert AdvPL/TLPP source files from UTF-8 to CP1252 ^(Windows-1252^).
echo.
echo Usage:
echo     convert-encoding.bat [options] ^<files or directories...^>
echo.
echo Options:
echo     /r, --recursive     Recursively process directories
echo     /dryrun             Report what would be converted without modifying
echo     /h, --help          Show this help message
echo     /v, --version       Show version
echo.
echo Examples:
echo     convert-encoding.bat source.tlpp
echo     convert-encoding.bat /r src\
echo     convert-encoding.bat /dryrun /r src\
exit /b 0

:process_dir
REM Process directory recursively for AdvPL/TLPP files
for /R "%~1" %%F in (*.prw *.prg *.tlpp *.prx *.ch *.th) do (
    call :convert_file "%%F"
)
goto :eof

:convert_file
REM Convert a single file using PowerShell inline (no execution policy needed)
set /a TOTAL+=1
set "FILEPATH=%~1"

REM Check extension
set "EXT=%~x1"
set "VALID=0"
if /I "!EXT!"==".prw"  set "VALID=1"
if /I "!EXT!"==".prg"  set "VALID=1"
if /I "!EXT!"==".tlpp" set "VALID=1"
if /I "!EXT!"==".prx"  set "VALID=1"
if /I "!EXT!"==".ch"   set "VALID=1"
if /I "!EXT!"==".th"   set "VALID=1"
if "!VALID!"=="0" (
    echo SKIP ^(extension !EXT! not in target list^): !FILEPATH!
    set /a SKIPPED+=1
    goto :eof
)

REM Use PowerShell inline for encoding detection and conversion
REM This avoids execution policy issues — -Command runs without .ps1 restrictions
for /f "tokens=*" %%R in ('powershell -NoProfile -Command ^
    "$f='!FILEPATH!'; " ^
    "$bytes=[IO.File]::ReadAllBytes($f); " ^
    "if($bytes.Length -eq 0){Write-Output 'ascii';exit} " ^
    "$bom=($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF); " ^
    "if($bom){Write-Output 'utf-8-bom';exit} " ^
    "$hi=$false; foreach($b in $bytes){if($b -gt 127){$hi=$true;break}} " ^
    "if(-not $hi){Write-Output 'ascii';exit} " ^
    "$u=[Text.UTF8Encoding]::new($false,$true); " ^
    "try{$t=$u.GetString($bytes);if($t.Length -lt $bytes.Length){Write-Output 'utf-8'}else{Write-Output 'cp1252'}} " ^
    "catch{Write-Output 'cp1252'}" ^
') do set "ENCODING=%%R"

if "!ENCODING!"=="ascii" (
    echo SKIP ^(pure ASCII, compatible with CP1252^): !FILEPATH!
    set /a SKIPPED+=1
    goto :eof
)

if "!ENCODING!"=="cp1252" (
    echo SKIP ^(already CP1252 or non-UTF-8^): !FILEPATH!
    set /a SKIPPED+=1
    goto :eof
)

REM File is UTF-8 or UTF-8 with BOM — convert
set "BOMNOTE="
if "!ENCODING!"=="utf-8-bom" set "BOMNOTE= [BOM removed]"

if "!DRYRUN!"=="1" (
    echo WOULD CONVERT ^(UTF-8!BOMNOTE! -^> CP1252^): !FILEPATH!
    set /a CONVERTED+=1
    goto :eof
)

REM Convert using PowerShell inline (writes directly to the same file — no extra files)
powershell -NoProfile -Command ^
    "$f='!FILEPATH!'; " ^
    "$bytes=[IO.File]::ReadAllBytes($f); " ^
    "$bom=($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF); " ^
    "if($bom){$bytes=$bytes[3..($bytes.Length-1)]} " ^
    "$utf8=[Text.UTF8Encoding]::new($false,$false); " ^
    "$text=$utf8.GetString($bytes); " ^
    "$cp1252=[Text.Encoding]::GetEncoding(1252); " ^
    "$out=$cp1252.GetBytes($text); " ^
    "if($cp1252.GetString($out) -ne $text){Write-Host 'WARNING: characters without CP1252 mapping replaced by ?'} " ^
    "if($out.Length -eq 0 -and $bytes.Length -gt 0){Write-Error 'Conversion produced empty output';exit 1} " ^
    "[IO.File]::WriteAllBytes($f,$out)"

if !ERRORLEVEL! NEQ 0 (
    echo ERROR ^(conversion failed^): !FILEPATH!
    set /a ERRORS+=1
    goto :eof
)

REM Verify conversion — confirm file is no longer valid UTF-8
powershell -NoProfile -Command ^
    "$f='!FILEPATH!'; " ^
    "$bytes=[IO.File]::ReadAllBytes($f); " ^
    "$u=[Text.UTF8Encoding]::new($false,$true); " ^
    "$hi=$false; foreach($b in $bytes){if($b -gt 127){$hi=$true;break}} " ^
    "if(-not $hi){exit 0} " ^
    "try{$null=$u.GetString($bytes);Write-Error 'File is still UTF-8 after conversion';exit 1}catch{exit 0}"

if !ERRORLEVEL! NEQ 0 (
    echo ERROR ^(file still UTF-8 after conversion^): !FILEPATH!
    set /a ERRORS+=1
    goto :eof
)

echo CONVERTED ^(UTF-8!BOMNOTE! -^> CP1252^): !FILEPATH!
set /a CONVERTED+=1
goto :eof
