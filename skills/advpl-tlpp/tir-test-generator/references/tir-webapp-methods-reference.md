# TIR Webapp Key Methods Reference

## Setup & Lifecycle

| Method | Description | Parameters |
|--------|-------------|------------|
| `Webapp()` | Creates a new TIR Webapp instance | — |
| `Setup(initial_program, date='', group='99', branch='01', module='')` | Configures the Protheus session | `initial_program`: module code (e.g., `'SIGAFAT'`); `date`: date string; `group`: user group (default `'99'`); `branch`: branch code (default `'01'`); `module`: initial module (optional) |
| `Program(cRoutine)` | Opens a specific routine | `cRoutine`: routine name (e.g., `'MATA010'`) |
| `TearDown()` | Closes the session and collects results | — |
| `Finish()` | Alternative session closer | — |

## Field Interaction

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `SetValue(field, value, grid=False, grid_number=1, row=None, check_value=True, name_attr=False, direction=None)` | Sets a field value on screen | `field`: field label or name; `value`: value to set; `grid`: True for grid fields; `grid_number`: which grid (default 1); `row`: row number; `check_value`: verify after set (default True) |
| `SetValue(field, value, grid=True, grid_number=N, row=N)` | Sets a grid cell value | Use `grid=True`, `grid_number` and `row` for grid cells. Always call `LoadGrid()` after. |
| `GetValue(cField)` | Returns the current field value | `cField`: field label or name |
| `SetButton(cButton)` | Clicks a button by label | `cButton`: button text (e.g., `'Incluir'`, `'Salvar'`, `'Confirmar'`) |
| `SetButton(cButton, sub_item=cSub)` | Clicks a menu button with sub-item | `cButton`: main button; `cSub`: sub-item text. **Nested sub-menus are comma-separated** (`sub_item='Level1, Level2'`), never pipe — the parser splits on `,` |
| `SetKey(cKey, grid=False, grid_number=1)` | Sends a keyboard key | `cKey`: key name (`'ENTER'`, `'DOWN'`, `'F12'`, `'DELETE'`, etc.) |

## Browse & Navigation

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `SearchBrowse(term, key=None, column=None, identifier=None, index=False, filters=[])` | Searches for a record in the browse grid. When `filters` is supplied, the call **routes transparently to `FilterBrowse`** on the new browse (kendo-grid) while keeping `key=`/`term` behavior on the legacy browse — so one call works on **both** browse technologies | `term`: search value; `key`: search key name (e.g., `'Filial+codigo + Loja'`); `column`: search column name; `identifier`: search box identifier; `filters`: list of dicts for pre-filtering (drives the new browse) |
| `ClickFolder(cFolder)` | Clicks a folder/tab on screen | `cFolder`: tab label (e.g., `'Complementos'`) |
| `SetLateralMenu(cItem)` | Clicks a lateral menu item | `cItem`: menu item text |
| `ClickTree(cItem)` | Clicks a tree node | `cItem`: node text |

## Grid Operations

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `ClickGridCell(cColumn, row=N, grid_number=N)` | Clicks a specific grid cell | `cColumn`: column header; `row`: row number; `grid_number`: grid index |
| `ClickGridHeader(cColumn, grid_number=N)` | Clicks a grid column header | `cColumn`: column text |
| `LoadGrid()` | Reloads/refreshes the grid data | — |
| `ScrollGrid(cColumn, match_value=cVal, grid_number=N)` | Scrolls grid to find a value | `cColumn`: column; `match_value`: value to find |
| `LengthGridLines(grid_number=N)` | Returns the number of grid rows | `grid_number`: which grid |
| `ClickBox(cField, cValue, select_all=False, grid_number=N)` | Clicks checkbox in a grid row | `cField`: column; `cValue`: matching value |
| `ClickCheckBox(cLabel)` | Clicks a standalone checkbox | `cLabel`: checkbox label |

## Assertions & Validation

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `CheckResult(cField, xExpected)` | Asserts a field value equals expected | `cField`: field name; `xExpected`: expected value |
| `CheckResult(cField, xExpected, grid=True, line=N, grid_number=N)` | Asserts a grid cell value | Additional grid parameters |
| `CheckHelp(text_help=cText, button=cBtn)` | Validates a help/error message and clicks button | `text_help`: expected help ID; `button`: button to click |
| `AssertTrue()` | Asserts no errors occurred in the test | **Call with no arguments — do not pass any parameters** |
| `AssertFalse()` | Asserts that errors were expected (negative test) | **Call with no arguments — do not pass any parameters** |
| `WaitFieldValue(cField, xValue)` | Waits until a field has a specific value | `cField`: field; `xValue`: expected value |
| `WaitShow(cTitle)` | Waits for a screen/dialog to appear | `cTitle`: window title |
| `WaitHide(cTitle)` | Waits for a screen/dialog to disappear | `cTitle`: window title |
| `WaitProcessing(cMessage)` | Waits for a processing screen to finish | `cMessage`: processing message |

## Dialog Handling

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `MessageBoxClick(cMessage, cButton)` | Handles a message box dialog | `cMessage`: expected message; `cButton`: button to click |
| `SetCalendar(cField, cDate)` | Sets a calendar/date picker field | `cField`: field label; `cDate`: date string |
| `SetFilePath(cPath)` | Sets a file path in a file dialog | `cPath`: file path |

## Parameters & Configuration

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `SetParameters(aParams)` | Sets multiple parameters at once | `aParams`: list of parameter tuples |
| `AddParameter(cParamName, cBranch, cType, cContent, cContent2)` | Adds an individual parameter | Various parameter attributes |
| `RestoreParameters()` | Restores original parameter values | — |
| `SetBranch(cBranch)` | Changes the current branch | `cBranch`: branch code |
| `ChangeEnvironment(cEnv, cDate, cGroup, cBranch)` | Changes the full environment | All environment fields |

---

## Poui Class — SmartX / PO-UI Screens

Use `from tir import Poui` when testing **SmartX native routines** (routines with `totvs.framework.structure` classes). The `Poui` class has different methods from `Webapp` — it maps to PO-UI components.

> **`Poui` has NO `Setup()`, `SearchBrowse()`, `SetValue()`, `SetButton()`, `ClickFolder()`,
> `SetBranch()`, `CheckHelp()` or `WaitHide()`.** These belong to `Webapp`. To reach a PO-UI screen that
> requires login, environment/branch selection or a legacy browse, use the **dual-helper**: `Poui()`
> (autostart, opens the browser) plus `Webapp(autostart=False)` (shared driver). Run `Setup()`,
> `Program()`, `SearchBrowse()` and `TearDown()` on the `Webapp` helper; run the PO-UI interactions on
> the `Poui` helper.

### Setup & Lifecycle

| Method | Description | Parameters |
|--------|-------------|------------|
| `Poui(config_path='', autostart=True)` | Creates a new TIR Poui instance. With `autostart=False`, reuses the shared driver (`Base._shared_driver`) — used by the non-browser helper in the dual-helper pattern | — |
| `Program(program_name='', module='')` | Sets the program in the initial menu search field (only when the initial program is a module like `SIGAFAT`). `module` is used for the "Change module" dialog | `program_name`: routine name; `module`: optional module |
| `TearDown()` | Closes the webdriver and ends the test case | — |

> `Setup()` is **not** a `Poui` method — perform login/environment on the paired `Webapp` helper.

### Field Interaction

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `InputValue(field, value, position=1)` | Fills a `po-input` component | `field`: input label; `value`: value to set |
| `ClickButton(button, position=1)` | Clicks a `po-button` component | `button`: button label (e.g., `'Novo'`, `'Salvar'`, `'Cancelar'`) |
| `ClickCombo(field, value, position=1)` | Selects a value in a `po-combo` | `field`: combo label; `value`: option to select |
| `ClickSelect(field, value, position=1)` | Selects a value in a `po-select` | `field`: select label; `value`: option to select |
| `ClickCheckBox(label)` | Checks/unchecks a `po-checkbox` | `label`: checkbox label |
| `ClickSwitch(label, value=True, position=1)` | Toggles a `po-switch` | `label`: switch label; `value`: True/False |
| `ClickLookUp(label, search_value='')` | Opens and searches a `po-lookup` | `label`: lookup field label; `search_value`: value to search |

### Navigation & Browse

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `POtabs(label)` | Clicks a tab in `po-tabs` | `label`: tab label name |
| `POSearch(content, placeholder='')` | Fills the `po-page-dynamic-search` component | `content`: search term |
| `FilterBrowse(filters)` | Fills POUI filter/browse with filters | `filters`: list of dicts `[{'Field': 'value'}]` |
| `ClickMenu(menu_item)` | Clicks a `po-menu` item | `menu_item`: menu item name |
| `ClickDropdown(label, subitems='', position=1)` | Clicks a `po-dropdown` and optionally a subitem | `label`: dropdown label; `subitems`: subitem text |

### Table Interaction

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `ClickTable(columns=None, values=None, click_cell=None, checkbox=None, radio_input=None, table_number=1, match_all=False, icon_class=None)` | Interacts with a `po-table` / THF kendo-grid row (new syntax) | `columns`: column name(s); `values`: value(s) to match; `click_cell`: column to click; `checkbox`/`radio_input`: True/False to toggle; `match_all`: act on all matching rows. **Legacy `first_column`/`first_content`/`second_column`/`second_content` are deprecated — do not mix with the new syntax** |

**Examples:**
```python
# Click 'Editar' action in row where Código = '000001'
self.oHelper.ClickTable(columns='Código', values='000001', click_cell='Editar')

# Filter by multiple columns
self.oHelper.ClickTable(columns=['Código', 'Nome'], values=['000001', 'Test'], click_cell='Excluir')

# Toggle checkbox in row
self.oHelper.ClickTable(columns='Código', values='000001', checkbox=True)
```

### Assertions & Validation

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| `CheckResult(field=None, user_value=None, po_component='po-input', position=1)` | Checks a field value in a PO-UI component | `field`: field/label; `user_value`: expected value; `po_component`: PO component type (e.g., `'po-input'`, `'po-select'`) — default `'po-input'` |
| `AssertTrue()` | Asserts no errors occurred | **Call with no arguments — do not pass any parameters** |
| `AssertFalse()` | Asserts errors were expected | **Call with no arguments — do not pass any parameters** |
| `WaitShow(string, timeout=None, throw_error=True)` | Waits for a string/element to appear | `string`: text to wait for |
| `WaitProcessing(itens, timeout=None)` | Waits for a processing screen (uses WaitShow + WaitHide internally) | `itens`: processing message |
| `IfExists(string, timeout=5)` | Returns True if element exists | `string`: element text; `timeout`: seconds |

> **`Poui` has no `WaitHide`.** For synchronization use `WaitShow`, `WaitProcessing` or `IfExists`, then
> assert content. `WaitHide` exists only on `Webapp`.

### Key Differences: Webapp vs Poui

| Action | Webapp | Poui |
|--------|--------|------|
| Login / environment | `Setup(...)` | **No `Setup`** — run it on the paired `Webapp` helper |
| Open routine | `Program('MATA010')` | `Program('MATA010')` (via the module initial program) |
| Fill a field | `SetValue('Label', 'value')` | `InputValue('Label', 'value')` |
| Click a button | `SetButton('Salvar')` | `ClickButton('Salvar')` |
| Switch tab | `ClickFolder('Tab')` | `POtabs(label='Tab')` |
| Combo vs select | `SetValue('Field', 'Option')` | `ClickCombo('Field', 'Option')` for `po-combo`; `ClickSelect('Field', 'Option')` for `po-select` |
| Search browse | `SearchBrowse(term, key='...')` | **No `SearchBrowse`** — use the `Webapp` helper, or `FilterBrowse(filters)` on a kendo-grid, or `ClickTable(columns=..., values=...)` on a `po-table` |
| Check field | `CheckResult('FIELD', 'value')` | `CheckResult('Field', 'value', 'po-input')` |
| Error dialog | `CheckHelp(text_help='...', button='...')` | `WaitShow('message')` / `IfExists('message')` (no `CheckHelp`) |
| Wait for element to hide | `WaitHide('title')` | **No `WaitHide`** — use `WaitProcessing` / `IfExists` |
| Set branch | `SetBranch('D MG 01')` | On the `Webapp` helper (during Incluir/Setup flow) |
