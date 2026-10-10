# Query Patterns and Code Examples

Complete AdvPL/TLPP code templates for each Protheus query pattern. Use these as starting points and adapt to the specific table, fields, and business logic.

---

## Pattern 1: Simple Select with Workarea

Use **Workarea access** when:

- Navigating records sequentially by an existing index
- Performing record-by-record operations (locking, updating)
- The table has a suitable index for the access pattern

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Static Function GetCustomerName(cCustCode as Character) as Character
  Local cName := "" as Character
  Local aArea := SA1->(GetArea()) as Array

  DbSelectArea("SA1")
  SA1->(DbSetOrder(1))  // Index 1: A1_FILIAL + A1_COD + A1_LOJA

  If SA1->(DbSeek(FWxFilial("SA1") + cCustCode))
    cName := AllTrim(SA1->A1_NOME)
  EndIf

  SA1->(RestArea(aArea))
Return cName
```

---

## Pattern 2: Simple Select with Embedded SQL (FWExecStatement)

> **Prefer `FWExecStatement` over the legacy `TCQuery cQuery New Alias ...` macro.** `FWExecStatement` provides DB-side bind parameters (`TCGenQry2`), DBAccess query cache, and prevents SQL injection by design.

Use **Embedded SQL** when:

- Performing complex joins across multiple tables
- Using aggregation functions (SUM, COUNT, AVG, MAX, MIN)
- The query doesn't map cleanly to a single index seek
- Reading large datasets where Workarea would be too slow

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Static Function GetCustomerBalance(cCustCode as Character) as Numeric
  Local nBalance := 0 as Numeric
  Local cQuery   := "" as Character
  Local oStatement := Nil as Object

  cQuery := "SELECT SUM(E1_SALDO) AS BALANCE " + ;
    "FROM " + RetSQLName("SE1") + " SE1 " + ;
    "WHERE SE1.D_E_L_E_T_ = ? " + ;
    "AND SE1.E1_FILIAL = ? " + ;
    "AND SE1.E1_CLIENTE = ? " + ;
    "AND SE1.E1_SALDO > 0 "

  oStatement := FWExecStatement():New(ChangeQuery(cQuery))
  oStatement:SetString(1, ' ')
  oStatement:SetString(2, FWxFilial("SE1"))
  oStatement:SetString(3, cCustCode)

  // ExecScalar runs the query and returns the requested column directly
  // (no alias to manage). Equivalent to MPSysExecScalar.
  nBalance := oStatement:ExecScalar("BALANCE")

  oStatement:Destroy()
  oStatement := Nil
Return nBalance
```

> **Note:** `FWExecStatement` accepts the query in the constructor (`:New(cQuery)`) or via `:SetQuery()` (inherited from `FWPreparedStatement`). Parameters are bound at the database side via `TCGenQry2`, so call `ChangeQuery()` on the SQL once before passing it in.

---

## Pattern 3: Multi-Table Join

```tlpp
Static Function GetInvoiceDetails(cInvDoc as Character) as Array
  Local cQuery := "" as Character
  Local cAlias := GetNextAlias() as Character
  Local aResult := {} as Array
  Local oStatement as Object

  cQuery := "SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, "
  cQuery += "       SD2.D2_COD, SD2.D2_QUANT, SD2.D2_TOTAL, "
  cQuery += "       SB1.B1_DESC "
  cQuery += "FROM " + RetSQLName("SF2") + " SF2 "
  cQuery += "INNER JOIN " + RetSQLName("SD2") + " SD2 "
  cQuery += "  ON SD2.D_E_L_E_T_ = ' ' "
  cQuery += "  AND SD2.D2_FILIAL = SF2.F2_FILIAL "
  cQuery += "  AND SD2.D2_DOC = SF2.F2_DOC "
  cQuery += "  AND SD2.D2_SERIE = SF2.F2_SERIE "
  cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 "
  cQuery += "  ON SB1.D_E_L_E_T_ = ' ' "
  cQuery += "  AND SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' "
  cQuery += "  AND SB1.B1_COD = SD2.D2_COD "
  cQuery += "WHERE SF2.D_E_L_E_T_ = ' ' "
  cQuery += "AND SF2.F2_FILIAL = '" + FWxFilial("SF2") + "' "
  cQuery += "AND SF2.F2_DOC = ? "

  oStatement := FWExecStatement():New(ChangeQuery(cQuery))
  oStatement:SetString(1, cInvDoc)

  // OpenAlias executes the prepared query with DB-side bind and returns
  // the created alias. Optional cLifeTime / cTimeout enable DBAccess query cache.
  cAlias := oStatement:OpenAlias(cAlias)

  While !(cAlias)->(Eof())
    aAdd(aResult, { ;
      AllTrim((cAlias)->F2_DOC),   ;
      AllTrim((cAlias)->D2_COD),   ;
      (cAlias)->D2_QUANT,          ;
      (cAlias)->D2_TOTAL,          ;
      AllTrim((cAlias)->B1_DESC)   ;
    })
    (cAlias)->(DBSkip())
  EndDo

  (cAlias)->(DBCloseArea())
  oStatement:Destroy()
Return aResult
```

---

## Pattern 4: INSERT/UPDATE via TCSqlExec

Use `TCSqlExec` for direct SQL operations. Prefer Workarea `RecLock`/`MsUnlock` for standard Protheus operations since they trigger data dictionary validations and events.

`FWExecStatement` does not open an alias for DML; combine the prepared/parameterized query with `TCSqlExec(oStatement:GetFixQuery())`:

```tlpp
// Direct SQL update — use FWExecStatement for safety
Static Function UpdateCustomerFlag(cCustCode as Character, cFlag as Character) as Logical
  Local nResult := 0 as Numeric
  Local cQuery  := "" as Character
  Local oStatement := Nil as Object

  cQuery := "UPDATE " + RetSQLName("SA1") + " " + ;
    "SET A1_XFLAG = ? " + ;
    "WHERE D_E_L_E_T_ = ? " + ;
    "AND A1_FILIAL = ? " + ;
    "AND A1_COD = ? "

  oStatement := FWExecStatement():New(ChangeQuery(cQuery))
  oStatement:SetString(1, cFlag)
  oStatement:SetString(2, ' ')
  oStatement:SetString(3, FWxFilial("SA1"))
  oStatement:SetString(4, cCustCode)

  nResult := TCSqlExec(oStatement:GetFixQuery())

  oStatement:Destroy()
Return (nResult == 0)
```

---

## Pattern 5: Counting Records

```tlpp
Static Function CountActiveCustomers() as Numeric
  Local cQuery := "" as Character
  Local oExec  := Nil as Object
  Local nCount := 0 as Numeric

  cQuery := "SELECT COUNT(*) AS TOTAL "
  cQuery += "FROM " + RetSQLName("SA1") + " SA1 "
  cQuery += "WHERE SA1.D_E_L_E_T_ = ? "
  cQuery += "AND SA1.A1_FILIAL = ? "
  cQuery += "AND SA1.A1_MSBLQL <> ? "  // Not blocked

  oExec := FWExecStatement():New(ChangeQuery(cQuery))
  oExec:SetString(1, ' ')
  oExec:SetString(2, FWxFilial("SA1"))
  oExec:SetString(3, '1')

  nCount := oExec:ExecScalar("TOTAL")

  oExec:Destroy()
Return nCount
```

---

## SQL Injection Prevention — Detailed Examples

**Never concatenate user input directly into SQL strings.** Use `FWExecStatement` to parameterize all dynamic values:

```tlpp
// DANGEROUS: SQL injection vulnerability
// cQuery += "AND A1_COD = '" + cUserInput + "' "

// SAFE: Parameterized via FWExecStatement (DB-side bind via TCGenQry2)
Local cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSQLName("SA1") + " SA1 " + ;
  "WHERE SA1.D_E_L_E_T_ = ? " + ;
  "AND SA1.A1_FILIAL = ? " + ;
  "AND SA1.A1_COD = ? " as Character
Local oStatement := FWExecStatement():New(ChangeQuery(cQuery)) as Object
oStatement:SetString(1, ' ')
oStatement:SetString(2, FWxFilial("SA1"))
oStatement:SetString(3, cUserInput)

cAlias := oStatement:OpenAlias()
// ... consume (cAlias)->fields ...
(cAlias)->(DBCloseArea())
oStatement:Destroy()
```

For LIKE clauses:

```tlpp
// SAFE: Parameterized LIKE — prepend/append % on the AdvPL side for cross-DB safety
// (MSSQL uses + for concat, PostgreSQL/Oracle use || — avoid both in SQL)
Local cSearchParam := "%" + cSearch + "%" as Character

oStatement := FWExecStatement():New(ChangeQuery( ;
  "SELECT A1_COD, A1_NOME FROM " + RetSQLName("SA1") + " SA1 " + ;
  "WHERE SA1.D_E_L_E_T_ = ? " + ;
  "AND SA1.A1_FILIAL = ? " + ;
  "AND SA1.A1_NOME LIKE ? "))
oStatement:SetString(1, ' ')
oStatement:SetString(2, FWxFilial("SA1"))
oStatement:SetString(3, cSearchParam)

cAlias := oStatement:OpenAlias()
```

### `setUnsafe()` — only for trusted, non-user-controlled values

Use `setUnsafe()` **only** to inject values you fully control (e.g. column or table names built from constants). It bypasses bind safety and is vulnerable to SQL injection if fed user input.

```tlpp
// Safe: column name comes from a hardcoded constant, not from user input
Local cColumn := "E1_NUM" as Character
Local oExec := FWExecStatement():New(ChangeQuery( ;
  "SELECT ? FROM " + RetSQLName("SE1") + " WHERE E1_FABOV = ? AND D_E_L_E_T_ = ?"))

oExec:SetUnsafe(1, cColumn)   // identifier — not a bindable value
oExec:SetNumeric(2, 0)
oExec:SetString(3, ' ')

cAlias := oExec:OpenAlias()
```

---

## FWExecStatement Method Reference (quick)

| Method | Purpose |
| --- | --- |
| `New(cQuery)` | Constructor. `cQuery` uses `?` placeholders. Inherits `SetQuery()` from `FWPreparedStatement`. |
| `SetString(n, c)` | Bind string parameter (1-based). Pass raw text — no surrounding quotes. |
| `SetNumeric(n, n)` | Bind numeric parameter. |
| `SetDate(n, d)` | Bind Protheus date. |
| `SetBoolean(n, l [, lProtheus])` | Bind boolean. `lProtheus=.T.` (default) maps to Protheus `'T'`/`'F'`. |
| `SetIn(n, aValues)` | Bind a list of values for an `IN (?)` clause. |
| `SetUnsafe(n, x)` | Inject raw value — **never** with user input; use only for identifiers/constants. |
| `SetParams(aParams)` | Bind all parameters from an array (uses `Valtype` — slower than typed setters). |
| `OpenAlias([cAlias] [, cLifeTime] [, cTimeout])` | Execute SELECT and return the opened alias. `cLifeTime`/`cTimeout` (strings, seconds) enable DBAccess query cache. |
| `ExecScalar(cColumn [, cLifeTime] [, cTimeout])` | Execute and return a single column value (`MPSysExecScalar`-equivalent). |
| `GetFixQuery()` | Return the final bound SQL string — use with `TCSqlExec()` for DML or `TCGenQry()` if you need legacy behavior. |
| `Destroy()` | Release the prepared statement. Always call when done. |

> **Cache parameters:** `cLifeTime` is how long (in seconds, as a character) the cached result lives in DBAccess; `cTimeout` is the cache lookup timeout. Both must be provided together. Useful for hot, repeatedly executed reference queries.

> **Availability:** `FWExecStatement` requires lib label `20211116` or newer. On older builds, fall back to `FWPreparedStatement` (same API, no cache/DB-side bind).
