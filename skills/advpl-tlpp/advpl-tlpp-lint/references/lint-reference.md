# AdvPL/TLPP Lint — Reference

## Three checks, three verdicts

`advpls appre`, the language server linter and the AppServer compiler are **not the same check**. The difference always goes in the same direction: cases that `appre` accepts with exit 0 and the AppServer refuses at compile time.

| Case | `advpls appre` | Language server linter (`scripts/lint.js`) | AppServer compile |
|---|---|---|---|
| Missing parenthesis | `C2002` | `C2002` | `C2002` |
| `Catch` without variable | exit 0 (accepted) | `Syntax Error` on the `Catch` line | `C2003 Syntax Error` |

If `appre` is your only check, a source can look clean and still fail at compile time. The linter is the closer approximation of the compiler without an AppServer. It still does not replace compiling.

## Tested `@totvs/tds-ls` versions

Measured on Windows 11 with the npm package `@totvs/tds-ls`:

| Version | `--includes` on the command line | Includes in `initialize` (`initializationOptions.settings`) | Start-up |
|---|---|---|---|
| 2.2.0 – 2.2.6 | works | works | under 4 s |
| 2.2.7 | **process exits with `0xC0000409`** (Windows fail-fast) | works | about 30 s |

This is why `scripts/lint.js` never passes `--includes` to the server. The include folders go in the `initialize` request, in `initializationOptions.settings`, as `{"scope": "linter", "key": "includes", "value": "dir1;dir2"}` — the same way the TDS-VSCode extension sends them. This works in every version above.

Two folders separated by `;` both resolve, so a `.ch` that exists only in the second folder is found.

## Behavior the script relies on

- Each source receives exactly one `textDocument/publishDiagnostics`, and it is the final result. A clean source receives an empty list, which counts as "analyzed".
- A source outside the workspace folders is **not** analyzed. The server reports it as information ("outside the workspace"). The script treats that as exit `2`, never as a clean result, and sends the folders of the sources as workspace folders.
- The script kills the language server on every exit path (success, error, timeout).

## Exit codes

| Exit | Meaning | What the agent does |
|---|---|---|
| `0` | Sources analyzed, no error | Report success |
| `1` | At least one error | Fix and run again |
| `2` | Usage or environment problem — nothing was linted | Report to the user; never treat as success |
