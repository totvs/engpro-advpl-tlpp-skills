#!/usr/bin/env bash
# convert-encoding.sh — Convert AdvPL/TLPP sources from UTF-8 to CP1252
#
# Native on Linux and macOS (uses iconv, which is pre-installed).
# Also works on Windows via Git Bash (ships with iconv).
#
# Usage:
#   ./convert-encoding.sh file1.prw file2.tlpp
#   ./convert-encoding.sh -r src/
#   ./convert-encoding.sh --dry-run -r src/

set -euo pipefail

readonly VERSION="1.1.0"
readonly DEFAULT_EXTENSIONS="prw prg tlpp prx ch th"
readonly UTF8_BOM=$'\xef\xbb\xbf'

# Counters
converted=0
skipped=0
errors=0
total=0

# Track temp files for cleanup on unexpected exit
_tmpfiles=()
cleanup_tmpfiles() {
    for f in "${_tmpfiles[@]}"; do
        rm -f "$f"
    done
}
trap cleanup_tmpfiles EXIT INT TERM HUP

# Options
recursive=false
dry_run=false
extensions="$DEFAULT_EXTENSIONS"

usage() {
    cat <<EOF
convert-encoding.sh v${VERSION}
Convert AdvPL/TLPP source files from UTF-8 to CP1252 (Windows-1252).

Usage:
    $(basename "$0") [options] <files or directories...>

Options:
    -r, --recursive     Recursively process directories
    --dry-run           Report what would be converted without modifying files
    -e, --extensions    Space-separated extensions (default: ${DEFAULT_EXTENSIONS})
    -h, --help          Show this help message
    -v, --version       Show version

Examples:
    $(basename "$0") source.tlpp
    $(basename "$0") -r src/
    $(basename "$0") --dry-run -r src/
EOF
}

# Check if iconv is available
check_dependencies() {
    if ! command -v iconv &>/dev/null; then
        echo "ERROR: 'iconv' not found. It should be pre-installed on Linux/macOS." >&2
        echo "  Linux (Debian/Ubuntu): sudo apt install libc-bin" >&2
        echo "  Linux (RHEL/Fedora):   sudo dnf install glibc-common" >&2
        echo "  macOS: pre-installed with Xcode Command Line Tools" >&2
        echo "  Windows: use convert-encoding.bat instead" >&2
        exit 1
    fi
}

# Convert UTF-8 on stdin to CP1252 on stdout. Characters with no CP1252
# mapping (emoji, arrows, CJK...) become '?' instead of aborting the file.
# GNU libiconv (macOS, Git Bash) has --unicode-subst; glibc (Linux) does not,
# and there //TRANSLIT maps unknown characters to '?'.
utf8_to_cp1252() {
    if printf 'x' | iconv --unicode-subst='?' -f UTF-8 -t CP1252 &>/dev/null; then
        iconv --unicode-subst='?' -f UTF-8 -t CP1252
    else
        iconv -f UTF-8 -t CP1252//TRANSLIT
    fi
}

# Detect file encoding (prints: utf-8, cp1252, or ascii)
detect_encoding() {
    local file="$1"
    local mime
    # Try 'file --mime-encoding' first (most reliable)
    if command -v file &>/dev/null; then
        mime=$(file --mime-encoding --brief "$file" 2>/dev/null || true)
        case "$mime" in
            utf-8|utf-8-bom) echo "utf-8"; return ;;
            us-ascii)        echo "ascii"; return ;;
            *)               echo "cp1252"; return ;;
        esac
    fi
    # Fallback: try strict UTF-8 decode with iconv
    if iconv -f utf-8 -t utf-8 "$file" &>/dev/null; then
        # Check for high bytes (multi-byte UTF-8)
        if LC_ALL=C grep -Pq '[\x80-\xff]' "$file" 2>/dev/null; then
            echo "utf-8"; return
        fi
        echo "ascii"; return
    fi
    echo "cp1252"
}

# Check and strip UTF-8 BOM
has_bom() {
    local file="$1"
    local head_bytes
    head_bytes=$(head -c 3 "$file" | od -An -tx1 | tr -d ' \n')
    [[ "$head_bytes" == "efbbbf" ]]
}

# Convert a single file
convert_file() {
    local file="$1"
    total=$((total + 1))

    if [[ ! -f "$file" ]]; then
        echo "SKIP (not a file): $file"
        skipped=$((skipped + 1))
        return
    fi

    # Check encoding
    local enc
    enc=$(detect_encoding "$file")

    if [[ "$enc" == "ascii" ]]; then
        echo "SKIP (pure ASCII, compatible with CP1252): $file"
        skipped=$((skipped + 1))
        return
    fi

    if [[ "$enc" == "cp1252" ]]; then
        echo "SKIP (already CP1252 or non-UTF-8): $file"
        skipped=$((skipped + 1))
        return
    fi

    # File is UTF-8 — needs conversion
    local bom_note=""
    if has_bom "$file"; then
        bom_note=" [BOM removed]"
    fi

    if $dry_run; then
        echo "WOULD CONVERT (UTF-8${bom_note} -> CP1252): $file"
        converted=$((converted + 1))
        return
    fi

    # Create temp file for safe atomic conversion
    local tmpfile
    tmpfile=$(mktemp "${file}.tmp.XXXXXX")
    _tmpfiles+=("$tmpfile")

    # Strip BOM if present, then convert
    local iconv_status=0
    if has_bom "$file"; then
        tail -c +4 "$file" | utf8_to_cp1252 > "$tmpfile" || iconv_status=$?
    else
        utf8_to_cp1252 < "$file" > "$tmpfile" || iconv_status=$?
    fi

    # Warn when characters had no CP1252 mapping (strict pass fails on them)
    local strict_status=0
    if has_bom "$file"; then
        tail -c +4 "$file" | iconv -f UTF-8 -t CP1252 &>/dev/null || strict_status=$?
    else
        iconv -f UTF-8 -t CP1252 < "$file" &>/dev/null || strict_status=$?
    fi
    if [[ $iconv_status -eq 0 && $strict_status -ne 0 ]]; then
        echo "WARNING (characters without CP1252 mapping replaced by '?'): $file" >&2
    fi

    if [[ $iconv_status -ne 0 ]]; then
        echo "ERROR (iconv failed — unmappable characters?): $file"
        rm -f "$tmpfile"
        errors=$((errors + 1))
        return
    fi

    # Verify the converted file is not empty (guard against silent failures)
    if [[ ! -s "$tmpfile" ]] && [[ -s "$file" ]]; then
        echo "ERROR (conversion produced empty file): $file"
        rm -f "$tmpfile"
        errors=$((errors + 1))
        return
    fi

    # Replace original with converted file (preserve permissions via cp + rm)
    chmod --reference="$file" "$tmpfile" 2>/dev/null || true
    mv -f "$tmpfile" "$file"

    # Remove tmpfile from cleanup tracker (it was already moved)
    _tmpfiles=("${_tmpfiles[@]/$tmpfile}")

    echo "CONVERTED (UTF-8${bom_note} -> CP1252): $file"
    converted=$((converted + 1))
}

# Collect and process files from a directory
process_directory() {
    local dir="$1"
    local ext
    for ext in $extensions; do
        while IFS= read -r -d '' file; do
            convert_file "$file"
        done < <(find "$dir" -type f -iname "*.${ext}" -print0 2>/dev/null | sort -z)
    done
}

# --- Main ---

check_dependencies

# Parse arguments
paths=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--recursive)  recursive=true; shift ;;
        --dry-run)       dry_run=true; shift ;;
        -e|--extensions) extensions="$2"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        -v|--version)    echo "convert-encoding.sh v${VERSION}"; exit 0 ;;
        -*)              echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *)               paths+=("$1"); shift ;;
    esac
done

if [[ ${#paths[@]} -eq 0 ]]; then
    echo "Error: No files or directories specified." >&2
    usage
    exit 1
fi

# Process each path
for path in "${paths[@]}"; do
    if [[ -f "$path" ]]; then
        convert_file "$path"
    elif [[ -d "$path" ]]; then
        if $recursive; then
            process_directory "$path"
        else
            echo "SKIP (use -r to process directories): $path" >&2
            skipped=$((skipped + 1))
        fi
    else
        echo "SKIP (path not found): $path" >&2
        skipped=$((skipped + 1))
    fi
done

# Summary
echo ""
echo "--- Summary ---"
if $dry_run; then
    echo "Would convert: ${converted} | Skipped: ${skipped} | Errors: ${errors} | Total: ${total}"
else
    echo "Converted: ${converted} | Skipped: ${skipped} | Errors: ${errors} | Total: ${total}"
fi

[[ $errors -eq 0 ]]
