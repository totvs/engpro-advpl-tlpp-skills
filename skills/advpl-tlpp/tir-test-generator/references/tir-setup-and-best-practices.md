# TIR Setup and Best Practices

## Three Required Files

Every TIR test project requires **three files**:

| File | Required | Description |
|------|----------|-------------|
| `{ROUTINE}TESTCASE.py` | ✅ | Test class with `unittest.TestCase`, `setUpClass`, test methods, `tearDownClass` |
| `{ROUTINE}TESTSUITE.py` | ✅ | Runner: imports TESTCASE, builds `unittest.TestSuite`, executes with `TextTestRunner` |
| `config.json` | ✅ | Environment configuration — URL, browser, credentials, environment name |

**Without `config.json` in the same directory, TIR cannot connect to Protheus.**

---

## config.json — Complete Reference

The `config.json` file must be placed in the same directory as the test scripts (or its path passed to the class constructor).

### Webapp (MVC/Legacy) — Minimal config.json

```json
{
    "Url": "http://{server}:{port}/",
    "Browser": "Firefox",
    "Environment": "{environment_name}",
    "User": "{username}",
    "Password": "{password}",
    "Language": "pt-br"
}
```

### Poui (SmartX / PO-UI inside Protheus) — config.json

```json
{
    "Url": "http://{server}:{port}/",
    "Browser": "Firefox",
    "Environment": "{environment_name}",
    "User": "{username}",
    "Password": "{password}",
    "Language": "pt-br",
    "POUI": false,
    "POUILogin": true
}
```

> **Never use `"POUI": true` to automate Protheus.** That key is exclusively for a standalone PO-UI application running **outside** Protheus — with it on, TIR skips the initial-program/environment screen (`#selectStartProg`) and breaks `Setup()`. Inside Protheus, the PO-UI **login** key is `"POUILogin": true` with `"POUI": false`. Testing PO-UI components (the `Poui` class) does not require `"POUI": true`.
>
> Add `"NewHome": true` only when the environment renders the new PO-UI card home instead of the classic `tmenu`.

### Required Parameters

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `Url` | str | The URL that will run the tests | `"http://localhost:8080/"` |
| `Browser` | str | Browser: `Firefox` or `Chrome` | `"Firefox"` |
| `Environment` | str | Target Protheus environment name | `"ENVIRONMENT"` |
| `User` | str | Username to login | `"admin"` |
| `Password` | str | User password | `"admin"` |
| `Language` | str | Language: `pt-br`, `en-us`, `es-es` | `"pt-br"` |
| `POUILogin` | bool | Poui Login inteface: `true`, `false` | `true` |

### POUI Interface Parameters

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `POUI` | bool | Interface mode for a **standalone PO-UI app outside Protheus** — do **not** set to `true` for Protheus tests | `false` |
| `POUILogin` | bool | Enable when the Protheus environment uses the **PO-UI login screen**. This is the Protheus PO-UI login key (`"POUI": false` + `"POUILogin": true`) | `false` |
| `NewHome` | bool | Enable when the environment renders the new PO-UI card home instead of the classic `tmenu` — independent of `POUI`/`POUILogin` | `false` |
| `SSOLogin` | bool | Enable when SSO login is configured — skips login screen | `false` |

### Additional Parameters

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `Headless` | bool | Run browser without visible window | `false` |
| `DebugLog` | bool | Show debug logs during execution | `false` |
| `ScreenShot` | bool | Save screenshots on errors | `true` |
| `ScreenshotFolder` | str | Path for screenshots | Current path |
| `TimeOut` | int | Seconds before test expires | `90` |
| `SkipEnvironment` | bool | Skip module selection screen | `false` |
| `StartProgram` | str | Start test directly in program URL | `"SIGAFAT"` |
| `Country` | str | Country code for log | `"BRA"` |

### Chrome-specific Parameters

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `ChromeDriverAutoInstall` | bool | Automatically install ChromeDriver | `false` |
| `SSLChromeInstallDisable` | bool | Disable SSL for driver download | `false` |

### Logging Parameters

| Key | Type | Description |
|-----|------|-------------|
| `NewLog` | bool | Enable new JSON API log |
| `MotExec` | str | Identifier log tag (e.g., `"HOMOLOG_TIR"`) |
| `LogFolder` | str | Folder to save log files |
| `LogUrl1` | str | URL/API to send execution logs |

### Database Parameters (optional — for `QueryExecute`)

| Key | Type | Description |
|-----|------|-------------|
| `DBDriver` | str | ODBC driver name |
| `DBServer` | str | Database host address |
| `DBPort` | str | Database port (default: `1521`) |
| `DBName` | str | Database name |
| `DBUser` | str | Database user |
| `DBPassword` | str | Database password |

---

## Two-File Structure

Every TIR test project requires two Python files:

- **`{ROUTINE}TESTCASE.py`** — the test class (never run directly in CI)
- **`{ROUTINE}TESTSUITE.py`** — the runner (this is what CI/CD executes)

The TESTSUITE imports the TESTCASE and selects which test methods to run via `suite.addTest()`. This allows running a subset of tests without modifying the TESTCASE file.

---

## Best Practices

### Webapp vs Poui Selection

- Use `Webapp` for **MVC/legacy** routines (ModelDef/ViewDef/MenuDef, MBrowse, AxCadastro)
- Use `Poui` for **SmartX native** routines (files with `totvs.framework.structure` classes)
- **Never set `"POUI": true` for Protheus** — use `"POUILogin": true` (+ `"POUI": false`) when the login screen is PO-UI
- `Poui` has **no `Setup()`/`SearchBrowse()`/`SetValue()`/`SetButton()`/`ClickFolder()`/`SetBranch()`/`CheckHelp()`**. When the path to the PO-UI screen needs login, environment/branch or a legacy browse, use the **dual-helper**: `Poui()` (autostart, opens the browser) + `Webapp(autostart=False)` (shared driver). Run login/environment/browse/`TearDown()` on the `Webapp` helper and the PO-UI interactions on the `Poui` helper

### Test Independence
- Each `test_` method should be independent of other tests
- Use `setUpClass` for environment configuration only — not for creating test data
- If tests have data dependencies (e.g., CT002 edits what CT001 created), document this clearly and ensure test execution order via naming convention (`test_CT001`, `test_CT002`)
- Python's `unittest` runs methods in alphabetical order by default — use `CT001`, `CT002` naming to control order

### Naming Conventions
- TESTCASE file: `{ROUTINE}TESTCASE.py` (e.g., `MATA010TESTCASE.py`)
- TESTSUITE file: `{ROUTINE}TESTSUITE.py` (e.g., `MATA010TESTSUITE.py`)
- config.json: always `config.json` in the same directory
- Test class: Same as routine name (e.g., `MATA010`)
- Test methods: `test_{ROUTINE}_CT{NNN}` (e.g., `test_MATA010_CT001`)
- Docstrings on each test method describing the scenario

### Branch Handling (Webapp only)
- Call `SetBranch('{BRANCH}')` after `SetButton('Incluir')` when the branch selection dialog appears
- The branch format in `SearchBrowse` must match exactly — use spaces for padding (e.g., `'D MG 01 '`)
- The `Setup()` branch parameter and the `SearchBrowse` branch prefix must be consistent

### Screen Interactions (Webapp)
- Always call `LoadGrid()` after `SetValue` on grid cells to ensure values are applied
- Use `SearchBrowse(term, key='Filial+{Column}')` with `key=` as a named parameter
- The `key` value must match the browse column header exactly (e.g., `'Filial+codigo + Loja'`)
- Handle unexpected dialogs with `CheckHelp` or `MessageBoxClick`
- Use `WaitProcessing` when operations trigger server-side processing
- Use `SetButton('Cancelar')` to close forms after Visualizar
- Use `SetButton('Não')` or `SetButton('Sim')` to handle confirmation dialogs after Salvar

### Screen Interactions (Poui / SmartX)
- Run PO-UI interactions on the `Poui` helper; run login/environment/browse on the paired `Webapp` helper (dual-helper)
- Use `InputValue(field, value)` to fill `po-input` fields
- Use `ClickButton(button)` to click PO-UI buttons
- Use `ClickTable(columns=..., values=..., click_cell=...)` to interact with table rows (new syntax; legacy `first_column`/`first_content` is deprecated)
- Use `POtabs(label=...)` to switch tabs
- Use `ClickCombo(field, value)` for `po-combo` and `ClickSelect(field, value)` for `po-select` (distinct components)
- Use `WaitShow(string)` / `WaitProcessing(itens)` / `IfExists(string)` for async operations — `Poui` has **no** `WaitHide`
- Use `CheckResult(field, value, 'po-input')` — always specify the PO component type

### Assertions
- End positive tests with `self.oHelper.AssertTrue()` — **do not pass any parameters**
- End negative tests (expected errors) with `self.oHelper.AssertFalse()` — **do not pass any parameters**
- Use `CheckResult` before `AssertTrue` to validate specific field values
- Use `RestoreParameters` before `AssertTrue` for the correct restoration of the parameters

### Environment Isolation
- Use a dedicated Protheus environment for TIR execution
- Ensure test data doesn't interfere with other testing or development
- Use unique test data values (e.g., prefix with `'TIR'` or `'AUT'`) to avoid conflicts

### TESTSUITE Best Practices
- Add only the tests you want to run in the current suite — not necessarily all tests
- Order matters: add tests in the sequence they should execute
- For CI/CD, the TESTSUITE is the entry point — never run TESTCASE directly in automation
