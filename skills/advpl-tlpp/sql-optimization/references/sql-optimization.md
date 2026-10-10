# Protheus SQL Optimization

The TOTVS Protheus ERP has specific database access patterns and constraints that require targeted optimization strategies.

> **Cross-Database Compatibility:** Protheus supports PostgreSQL, MSSQL Server, and Oracle. Use `ChangeQuery()` to automatically translate SQL syntax to the active database dialect. Use `TCGetDB()` (returns `"MSSQL"`, `"ORACLE"`, or `"POSTGRES"`) for runtime DB detection when DB-specific optimization is needed. Prefer ANSI SQL functions (`COALESCE`, `CASE WHEN`, `CONCAT`, `FETCH FIRST`) for maximum portability.

## High-Volume Transactional Tables

These Protheus tables commonly grow to millions of rows and are the primary targets for optimization:

| Table | Module | Description | Typical Volume |
|-------|--------|-------------|----------------|
| SD1 | SIGACOM | Purchase items | Very High |
| SD2 | SIGAFAT | Sales items | Very High |
| SE1 | SIGAFIN | Accounts Receivable | Very High |
| SE2 | SIGAFIN | Accounts Payable | Very High |
| CT2 | SIGACTB | Accounting entries | Very High |
| SB2 | SIGAEST | Inventory balances | High |
| SC6 | SIGAFAT | Sales order items | High |

> **Note on SE5:** The SE5 (Cash Movements) table is deprecated. New code should use the `FKx` family functions + `ExecAuto` instead of direct SE5 access.

> **Cloud compatibility (CS1000):** Direct SQL queries in AdvPL/TLPP require evaluation for Cloud environments. Assess whether framework APIs can replace raw queries. When direct queries are necessary, ensure they comply with all security and performance rules.

## Index-Aligned Query Optimization

Protheus indexes are defined in the SIX dictionary. Queries must align with available indexes to avoid full table scans.

```sql
-- BAD: WHERE clause doesn't match any SIX index (left-to-right)
SELECT D2_DOC, D2_SERIE, D2_TOTAL
FROM SD2010
WHERE D_E_L_E_T_ = ' '
  AND D2_EMISSAO >= '20250101'
-- No index starts with D2_EMISSAO → full table scan

-- GOOD: Matches SIX index 1 (D2_FILIAL + D2_DOC + D2_SERIE)
SELECT D2_DOC, D2_SERIE, D2_TOTAL
FROM SD2010
WHERE D_E_L_E_T_ = ' '
  AND D2_FILIAL = '01'
  AND D2_DOC    = '000001'
  AND D2_SERIE  = '1'
```

**Rule:** Always check the SIX dictionary for available indexes and align `WHERE` clause columns left-to-right with the index columns.

## Avoid SELECT * on Protheus Tables

Protheus tables typically have 50–200+ columns including system fields (`R_E_C_N_O_`, `R_E_C_D_E_L_`, `D_E_L_E_T_`, `D_MUL_FIL`, etc.). Always select only needed columns.

```sql
-- BAD: Retrieves all 150+ columns
SELECT * FROM SA1010 WHERE D_E_L_E_T_ = ' '

-- GOOD: Select only what is needed
SELECT A1_COD, A1_NOME, A1_CGC, A1_EST
FROM SA1010
WHERE D_E_L_E_T_ = ' '
  AND A1_FILIAL = '01'
```

## Lock Hints (`%nolock%`)

Do not use lock hints in embedded SQL. `%nolock%` is not a BeginSQL/DBAccess macro: the preprocessor leaves it untranslated, it reaches the database literally and the query fails at runtime (e.g. SQL Server error 102, `Incorrect syntax near '%'`).

```sql
-- BAD: fails at runtime
SELECT A1_COD, A1_NOME
FROM SA1010 WITH (%nolock%)
WHERE D_E_L_E_T_ = ' '
  AND A1_FILIAL = '01'

-- GOOD
SELECT A1_COD, A1_NOME
FROM SA1010 SA1
WHERE SA1.D_E_L_E_T_ = ' '
  AND SA1.A1_FILIAL = '01'
```

## FWExecStatement / TCSqlExec Performance

> **Prefer `FWExecStatement` over the legacy `TCQuery cQuery New Alias ...` macro:** it parameterizes user input (avoiding SQL injection), binds at the DB side via `TCGenQry2`, and can reuse the DBAccess query cache via `cLifeTime`/`cTimeout`.

```advpl
// BAD: Opening TCQuery inside a loop (N round-trips + SQL injection risk)
For nI := 1 To Len(aClients)
  cQuery := "SELECT A1_NOME FROM " + RetSqlName("SA1") + " WHERE ... AND A1_COD = '" + aClients[nI] + "'"
  TCQuery cQuery New Alias "TMP"
  // process...
  TMP->(DbCloseArea())
Next nI

// GOOD: Single query with bound IN clause via FWExecStatement
Local cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1") + ;
                " WHERE D_E_L_E_T_ = ? AND A1_FILIAL = ? AND A1_COD IN (?)" as Character
Local oExec  := FWExecStatement():New(ChangeQuery(cQuery)) as Object
Local cAlias as Character

oExec:SetString(1, ' ')
oExec:SetString(2, FWxFilial("SA1"))
oExec:SetIn(3, aClients)                // SetIn binds the array safely — no manual concat
cAlias := oExec:OpenAlias()
// process all results in one pass
(cAlias)->(DBCloseArea())
oExec:Destroy()
```

> For hot, repeated reference queries, `OpenAlias` / `ExecScalar` accept optional `cLifeTime`/`cTimeout` (seconds, as character) to reuse cached results from DBAccess.

## Workarea vs. Embedded SQL Performance

| Scenario | Winner | Reason |
|----------|--------|--------|
| Single-key lookup | Workarea | DbSeek is extremely fast on indexed data |
| Range scan (<1000 rows) | Workarea | Sequential DbSkip is efficient for small sets |
| Range scan (>1000 rows) | Embedded SQL | SQL engine optimizes large result sets better |
| Multi-table join | Embedded SQL | Nested workarea loops are O(n²); SQL joins are optimized |
| Aggregations (SUM/COUNT) | Embedded SQL | Database engine processes aggregates server-side |
| Bulk INSERT/UPDATE | TCSqlExec | Single statement vs. N RecLock/MsUnlock cycles |
