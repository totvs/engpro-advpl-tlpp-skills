---
name: advpl-tlpp-lint
description: "Lint AdvPL/TLPP sources (.prw, .prx, .prg, .tlpp, .ch, .th, .apw, .aph, .apl, .ppx, .ppp) from the command line with the linter of the TOTVS language server (advpls, npm package @totvs/tds-ls), without an AppServer and without touching the RPO. Works with any agent that can run a shell command (Codex, Gemini CLI, Copilot, Cursor, Claude): runs a bundled Node.js script, prints one line per diagnostic and exits 0 (clean), 1 (errors) or 2 (usage/environment problem). Catches errors that advpls appre lets through, such as a Catch without variable that the AppServer rejects. Use right after creating or editing any AdvPL/TLPP source, before declaring the task done and before compiling, or when the user says 'lint', 'check syntax', 'validate the source', 'verificar sintaxe', 'validar fonte', 'lint advpl', 'static analysis'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Luis Montes
  version: '1.0.0'
  category: Build and Compilation
---

# AdvPL/TLPP Lint (language server, any agent)

## Overview

Validate AdvPL/TLPP sources the way the editor does, from a plain shell command. The bundled script `scripts/lint.js` starts the TOTVS language server (`advpls language-server`, from the npm package `@totvs/tds-ls` — the same server the TDS-VSCode extension uses), opens the sources, collects the linter diagnostics and exits.

- **No AppServer, no RPO, no credentials.** It is a local syntax/semantic check, fast enough to run after every edit.
- **Stricter than `advpls appre`.** The language server linter rejects code that `appre` accepts and the AppServer later refuses — for example a `Catch` without a variable. See [references/lint-reference.md](references/lint-reference.md).
- **Agent-agnostic.** Only Node.js built-in modules; no editor, no plugin, no configuration file. Any agent that can run a shell command can use it.

## When to Use

Use this skill:

- **Right after** creating or editing any `.prw`, `.prx`, `.prg`, `.tlpp`, `.ch`, `.th`, `.apw`, `.aph`, `.apl`, `.ppx` or `.ppp` file — before telling the user the change is done.
- Before compiling with `advpl-tlpp-compile`, to catch syntax errors without a round trip to the AppServer.
- When the user asks to lint, check syntax or validate a source.

**Do NOT use when:**

- The user wants to compile and send the source to the RPO — use `advpl-tlpp-compile`. Lint does not replace compilation.
- The file is not AdvPL/TLPP.

---

## CRITICAL — Agent Execution Rules

> **These rules are MANDATORY.**

1. **Lint ALL edited sources in ONE call.** Each call starts a new language server; with `@totvs/tds-ls` 2.2.7 the start alone takes about 30 seconds. Never loop one file per call.
2. **Read the exit code before declaring success.**
   - `0` — no error. The sources were analyzed.
   - `1` — at least one error. Fix each reported line and run the lint again until it exits `0`.
   - `2` — usage or environment problem (no Node/`advpls`, no include folder, source missing, server crashed, timeout, source outside the workspace). **Nothing was linted.** Report the message to the user; never treat `2` as success.
3. **Never edit `scripts/lint.js`.** Problems with the script are reported to the user, not patched in place.
4. **Do not hardcode paths.** Resolve the folder of this skill at runtime and call `scripts/lint.js` from there.

---

## Prerequisites

| Requirement | Check | Install |
|---|---|---|
| Node.js (with `npm`) | `node --version` | https://nodejs.org |
| TOTVS language server | `npm root -g` contains `@totvs/tds-ls` | `npm install -g @totvs/tds-ls` |

If the `advpls` binary lives elsewhere, point the environment variable `ADVPLS_BIN` to it. Installing software is the user's decision: if a prerequisite is missing, tell the user the command and stop.

---

## How to Run

```
node <skill-folder>/scripts/lint.js [--includes <dir1;dir2>] [--timeout <seconds>] <source> [<source>...]
```

| Option | Meaning |
|---|---|
| `--includes <a;b>` | Folders with the `.ch`/`.th` include files, separated by `;` |
| `--timeout <s>` | Total time limit, 1 to 3600 seconds (default 120) |

### Include folders

The linter only reports errors after it resolves every `#include`. The include folders are taken, in this order, from:

1. `--includes`
2. the environment variable `ADVPL_INCLUDES`
3. a search for an `includes` or `.workflow/includes` folder, starting at the folder of the first source and going up the directory tree

With none found, the script exits `2` and says what is missing.

### Output

One line per diagnostic, then a summary:

```
src/MYPE.prw:3:1: erro C2002  Statement unterminated at end of line/unbalanced parentesis/brackets
1 erro(s), 0 aviso(s) em 2 fonte(s)
```

Format: `<path>:<line>:<column>: <erro|aviso|info> <message>` (line and column are 1-based). Use the path and line to go straight to the fix.

---

## Workflow

1. Collect every AdvPL/TLPP source created or edited in the task.
2. Run the lint once with all of them.
3. Exit `1`: fix each reported line, then run again (step 2). Repeat until exit `0`.
4. Exit `2`: report the message to the user and stop; do not claim the code is valid.
5. Exit `0`: tell the user the sources passed the lint. If they also need to go to the RPO, offer `advpl-tlpp-compile`.

---

## Known Limits

- **Include folder with accented characters in its path** (for example a folder named `Inclusões`) produces a false `C2090 File not found` for includes that exist. Use an include folder whose full path has no accented characters. Sources in accented folders work.
- **`@totvs/tds-ls` 2.2.7** takes about 30 seconds to start. This is why rule 1 exists.
- Sources are read as Latin-1. Characters 0x80–0x9F of Windows-1252 (such as `€`) may be shown differently in messages.
- Lint does not check the data dictionary, the RPO or runtime behavior. Compiling remains necessary.

## Bundled Files

| File | Content |
|---|---|
| [scripts/lint.js](scripts/lint.js) | The lint command (Node.js, built-in modules only) |
| [references/lint-reference.md](references/lint-reference.md) | `appre` × language server linter × AppServer, tested `tds-ls` versions and why includes go through `initialize` |
