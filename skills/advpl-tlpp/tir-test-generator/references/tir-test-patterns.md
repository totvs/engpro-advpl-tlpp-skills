# TIR Test Script Patterns

All patterns below show only the TESTCASE methods. The TESTSUITE file always follows the same structure — see the SKILL.md for the TESTSUITE template.

---

## Pattern 1: Standard CRUD — Include Record

```python
def test_{ROUTINE}_CT001(self):
    """CT001 — Include a new record with required fields"""

    self.oHelper.SetButton('Incluir')
    self.oHelper.SetBranch('{BRANCH}')

    # Fill required fields
    self.oHelper.SetValue('{Field Label 1}', '{value1}')
    self.oHelper.SetValue('{Field Label 2}', '{value2}')
    self.oHelper.SetValue('{Field Label 3}', '{value3}')

    self.oHelper.SetButton('Salvar')

    # Verify the record was created
    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Visualizar')
    self.oHelper.CheckResult('{FIELD_NAME}', '{expected_value}')
    self.oHelper.SetButton('Cancelar')

    self.oHelper.AssertTrue()
```

## Pattern 2: Standard CRUD — Edit Record

```python
def test_{ROUTINE}_CT002(self):
    """CT002 — Edit an existing record"""

    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Alterar')

    # Modify field values
    self.oHelper.SetValue('{Field Label}', '{new_value}')

    self.oHelper.SetButton('Salvar')

    # Verify the modification
    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Visualizar')
    self.oHelper.CheckResult('{FIELD_NAME}', '{expected_new_value}')
    self.oHelper.SetButton('Cancelar')

    self.oHelper.AssertTrue()
```

## Pattern 3: Standard CRUD — Delete Record

```python
def test_{ROUTINE}_CT003(self):
    """CT003 — Delete an existing record"""

    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Outras Ações', sub_item='Excluir')
    self.oHelper.SetButton('Confirmar')

    self.oHelper.AssertTrue()
```

## Pattern 4: Master-Detail with Grid

```python
def test_{ROUTINE}_CT004(self):
    """CT004 — Include record with grid items (master-detail)"""

    self.oHelper.SetButton('Incluir')
    self.oHelper.SetBranch('{BRANCH}')

    # Fill header fields
    self.oHelper.SetValue('{Header Field 1}', '{value1}')
    self.oHelper.SetValue('{Header Field 2}', '{value2}')

    # Fill grid row 1
    self.oHelper.SetValue('{Grid Column 1}', '{item_value1}', grid=True, grid_number=1, row=1)
    self.oHelper.SetValue('{Grid Column 2}', '{item_value2}', grid=True, grid_number=1, row=1)
    self.oHelper.LoadGrid()

    # Fill grid row 2 (new line)
    self.oHelper.SetValue('{Grid Column 1}', '{item_value3}', grid=True, grid_number=1, row=2)
    self.oHelper.SetValue('{Grid Column 2}', '{item_value4}', grid=True, grid_number=1, row=2)
    self.oHelper.LoadGrid()

    self.oHelper.SetButton('Salvar')

    self.oHelper.AssertTrue()
```

## Pattern 5: Screen with Tabs/Folders

```python
def test_{ROUTINE}_CT005(self):
    """CT005 — Include record navigating through tabs"""

    self.oHelper.SetButton('Incluir')
    self.oHelper.SetBranch('{BRANCH}')

    # Tab 1 — Main (default tab)
    self.oHelper.SetValue('{Field 1}', '{value1}')
    self.oHelper.SetValue('{Field 2}', '{value2}')

    # Switch to second tab
    self.oHelper.ClickFolder('{Tab Name}')

    self.oHelper.SetValue('{Field 3}', '{value3}')
    self.oHelper.SetValue('{Field 4}', '{value4}')

    self.oHelper.SetButton('Salvar')

    self.oHelper.AssertTrue()
```

## Pattern 6: View/Validate Record

```python
def test_{ROUTINE}_CT006(self):
    """CT006 — View record and validate multiple field values"""

    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Visualizar')

    # Check field values (use technical field names, not labels)
    self.oHelper.CheckResult('{FIELD_NAME_1}', '{expected_1}')
    self.oHelper.CheckResult('{FIELD_NAME_2}', '{expected_2}')
    self.oHelper.CheckResult('{FIELD_NAME_3}', '{expected_3}')

    # Check grid values
    self.oHelper.CheckResult('{Grid Column}', '{expected_grid_value}', grid=True, line=1, grid_number=1)

    self.oHelper.SetButton('Cancelar')

    self.oHelper.AssertTrue()
```

## Pattern 7: Validation Error Test (Negative)

```python
def test_{ROUTINE}_CT007(self):
    """CT007 — Validate that required field error is shown"""

    self.oHelper.SetButton('Incluir')
    self.oHelper.SetBranch('{BRANCH}')

    # Intentionally leave required field empty — only fill optional fields
    self.oHelper.SetValue('{Optional Field}', '{value}')

    self.oHelper.SetButton('Salvar')

    # Expect a help/error dialog
    self.oHelper.CheckHelp(text_help='{HELP_ID}', button='Fechar')

    self.oHelper.SetButton('Cancelar')

    self.oHelper.AssertFalse()
```

## Pattern 8: Other Actions Menu

```python
def test_{ROUTINE}_CT008(self):
    """CT008 — Execute an action from the 'Other Actions' menu"""

    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('Outras Ações', sub_item='{Action Name}')

    # Handle the action-specific screen
    self.oHelper.SetValue('{Action Field}', '{value}')
    self.oHelper.SetButton('Confirmar')

    self.oHelper.AssertTrue()
```

> **Nested sub-menus use commas, not pipes.** For `Outras Ações → Level1 → Level2` use
> `sub_item='Level1, Level2'` — the parser splits on `,`. A pipe (`Level1|Level2`) is searched as a
> single caption and never found (`Couldn't find element`). Never skip an intermediate level.

## Pattern 9: Report Test with Parameters

```python
# TESTCASE
from tir import Webapp
import unittest

class {REPORT}(unittest.TestCase):

    @classmethod
    def setUpClass(inst):
        inst.oHelper = Webapp()
        inst.oHelper.Setup('{MODULE}', '{DATE}', 'T1', '{BRANCH}')
        inst.oHelper.Program('{REPORT_ROUTINE}')

    def test_{REPORT}_CT001(self):
        """CT001 — Execute report with parameters and validate"""

        # Fill report parameters
        self.oHelper.SetValue('{Param 1 Label}', '{param_value_1}')
        self.oHelper.SetValue('{Param 2 Label}', '{param_value_2}')

        # Execute the report
        self.oHelper.SetButton('OK')

        # Wait for processing
        self.oHelper.WaitProcessing('{Processing message}')

        self.oHelper.AssertTrue()

    @classmethod
    def tearDownClass(inst):
        inst.oHelper.TearDown()

if __name__ == '__main__':
    unittest.main()


# TESTSUITE
import unittest
from {REPORT}TESTCASE import {REPORT}

suite = unittest.TestSuite()
suite.addTest({REPORT}('test_{REPORT}_CT001'))

runner = unittest.TextTestRunner(verbosity=2)
runner.run(suite)
```

## Pattern 10: Grid Checkbox Selection

```python
def test_{ROUTINE}_CT010(self):
    """CT010 — Select items via grid checkboxes"""

    self.oHelper.SearchBrowse(f'{BRANCH}{search_key}', 'Filial+{Search Column}')
    self.oHelper.SetButton('{Action}')

    # Select specific items by checkbox
    self.oHelper.ClickBox('{Column}', '{value1}', grid_number=1)
    self.oHelper.ClickBox('{Column}', '{value2}', grid_number=1)

    self.oHelper.SetButton('Confirmar')

    self.oHelper.AssertTrue()
```

## Pattern 11: SmartX / PO-UI Screen (dual-helper)

`Poui` has no `Setup()`, `SearchBrowse()`, `SetValue()`, `SetButton()`, `ClickFolder()` or `SetBranch()`.
When the path to the PO-UI screen goes through login, environment/branch or a legacy browse, use the
**dual-helper**: instantiate `Poui()` (autostart, opens the browser) and `Webapp(autostart=False)`
(shares the same driver). Login, environment and legacy browse run on the `Webapp` helper; the PO-UI
screen runs on the `Poui` helper.

```python
from tir import Poui, Webapp
import unittest

class {ROUTINE}(unittest.TestCase):

    @classmethod
    def setUpClass(inst):
        inst.oHelper_Poui   = Poui()                     # autostart=True: opens the browser
        inst.oHelper_Webapp = Webapp(autostart=False)     # shares the same driver
        inst.oHelper_Webapp.Setup('{MODULE}', '{DATE}', 'T1', '{BRANCH}')
        inst.oHelper_Webapp.Program('{ROUTINE}')

    def test_{ROUTINE}_CT001(self):
        """CT001 — Include record on a PO-UI screen"""

        self.oHelper_Poui.ClickButton('Novo')
        self.oHelper_Poui.InputValue('{Field Label 1}', '{value1}')
        self.oHelper_Poui.InputValue('{Field Label 2}', '{value2}')
        self.oHelper_Poui.ClickButton('Salvar')

        # Locate the record on the po-table and open it
        self.oHelper_Poui.ClickTable(columns='{Column}', values='{search_key}', click_cell='Visualizar')
        self.oHelper_Poui.CheckResult('{Field Label}', '{expected_value}', 'po-input')
        self.oHelper_Poui.ClickButton('Cancelar')

        self.oHelper_Poui.AssertTrue()

    def test_{ROUTINE}_CT002(self):
        """CT002 — Required field validation (negative)"""

        self.oHelper_Poui.ClickButton('Novo')
        self.oHelper_Poui.ClickButton('Salvar')
        # Poui has no WaitHide — sync with WaitShow / WaitProcessing / IfExists, then assert content
        self.oHelper_Poui.WaitShow('{validation_message}')
        self.oHelper_Poui.ClickButton('Cancelar')

        self.oHelper_Poui.AssertFalse()

    @classmethod
    def tearDownClass(inst):
        inst.oHelper_Webapp.TearDown()   # close on the helper that owns the session

if __name__ == '__main__':
    unittest.main()
```

**Notes:**
- `config.json` for this pattern: `"POUI": false`, `"POUILogin": true` (never `"POUI": true` in Protheus).
- Combo vs select: `ClickCombo` for `po-combo`, `ClickSelect` for `po-select`.
- On a new (kendo-grid) browse, `Poui.FilterBrowse(filters)` replaces `SearchBrowse`.

---

## Real-World Example (MATA030 — Clientes)

Based on the official TIR template repository:

### MATA030TESTCASE.py

```python
from tir import Webapp
import unittest

class MATA030(unittest.TestCase):

    @classmethod
    def setUpClass(inst):
        inst.oHelper = Webapp()
        inst.oHelper.Setup('SIGAFAT', '11/04/2019', 'T1', 'D MG 01 ', '05')
        inst.oHelper.Program('MATA030')

    def test_MATA030_CT133(self):
        """CT133 — Include customer with required fields"""

        cliente = 'FTC138'
        loja = '01'

        self.oHelper.SetButton('Incluir')
        self.oHelper.SetBranch('D MG 01')
        self.oHelper.ClickFolder('Cadastrais')
        self.oHelper.SetValue('A1_COD', cliente)
        self.oHelper.SetValue('A1_LOJA', loja)
        self.oHelper.SetValue('A1_PESSOA', 'F - Fisica')
        self.oHelper.SetValue('A1_NOME', 'FAT TIR CT133 MATA030 INCLUSAO')
        self.oHelper.SetValue('A1_NREDUZ', 'TIR CT133 MATA030')
        self.oHelper.SetValue('A1_END', 'RUA DAS ORQUIDEAS, 100')
        self.oHelper.SetValue('A1_TIPO', 'F - Cons.Final')
        self.oHelper.SetValue('A1_EST', 'SP')
        self.oHelper.SetValue('A1_COD_MUN', '50308')
        self.oHelper.SetButton('Salvar')
        self.oHelper.SetButton('Não')
        self.oHelper.SetButton('Cancelar')
        self.oHelper.SearchBrowse(f'D MG    {cliente+loja}', 'Filial+codigo + Loja')
        self.oHelper.SetButton('Visualizar')
        self.oHelper.ClickFolder('Cadastrais')
        self.oHelper.CheckResult('A1_COD', cliente)
        self.oHelper.CheckResult('A1_LOJA', loja)
        self.oHelper.CheckResult('A1_PESSOA', 'F - Fisica')
        self.oHelper.CheckResult('A1_NOME', 'FAT TIR CT133 MATA030 INCLUSAO')
        self.oHelper.CheckResult('A1_NREDUZ', 'TIR CT133 MATA030')
        self.oHelper.CheckResult('A1_END', 'RUA DAS ORQUIDEAS, 100')
        self.oHelper.CheckResult('A1_TIPO', 'F - Cons.Final')
        self.oHelper.CheckResult('A1_EST', 'SP')
        self.oHelper.CheckResult('A1_COD_MUN', '50308')
        self.oHelper.SetButton('Cancelar')

        self.oHelper.AssertTrue()

    @classmethod
    def tearDownClass(inst):
        inst.oHelper.TearDown()

if __name__ == '__main__':
    unittest.main()
```

### MATA030TESTSUITE.py

```python
import unittest

from MATA030TESTCASE import MATA030

suite = unittest.TestSuite()

suite.addTest(MATA030('test_MATA030_CT133'))

runner = unittest.TextTestRunner(verbosity=2)
runner.run(suite)
```

---

## Key Observations from Real Example

1. **`SetBranch`** is called after `SetButton('Incluir')` — not in `setUpClass`
2. **`SetValue` uses field technical names** (e.g., `'A1_COD'`) directly — TIR accepts both labels and technical names
3. **`SearchBrowse` key format**: `f'D MG    {cliente+loja}'` — branch with spaces padding, then concatenated key fields
4. **`SearchBrowse` column**: `'Filial+codigo + Loja'` — composite column name as shown in the browse header
5. **`SetButton('Não')`** — handles confirmation dialogs that appear after Salvar
6. **`SetButton('Cancelar')`** — closes the form after Visualizar (not `'Fechar'`)
7. **`ClickFolder`** — used both before filling fields and before checking results when tabs are involved
8. **`AssertTrue()`** — always called without parameters
