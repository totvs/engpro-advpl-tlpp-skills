---
name: query-builder
description: "Build optimized and safe SQL queries for Protheus tables. Automatically includes mandatory filters (D_E_L_E_T_, branch), suggests appropriate indexes from SIX patterns, generates both Embedded SQL (preferring FWExecStatement) and Workarea (DBSelectArea/DBSeek) versions, and warns about common Protheus SQL pitfalls. Use when user says 'build query', 'SQL for Protheus table', 'FWExecStatement', 'TCQuery', 'Workarea vs SQL'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Generation
---

# Protheus Query Builder

## Overview

Build correct, safe, and optimized SQL queries for Protheus ERP tables. Protheus has unique database conventions — mandatory soft-delete filters, multi-branch filtering, Hungarian notation for fields, data dictionary-driven schemas, and specific index patterns — that every query must respect. This skill generates queries that follow these conventions and helps choose between Workarea access and Embedded SQL.

## When to Use

Use this skill when:

- Writing SQL queries against Protheus tables (SA1, SD1, SF2, etc.)
- Building parameterized SQL queries (`FWExecStatement`, `TCSqlExec`) in AdvPL/TLPP
- Optimizing existing queries for Protheus-specific patterns
- Deciding between Workarea access and Embedded SQL
- Ensuring mandatory filters are not missing
- Generating safe queries that prevent SQL injection

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers conventions, decision logic, the checklist, and anti-patterns. Detailed code templates and cross-database reference tables are in the `references/` directory — read them on demand based on the scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/query-patterns-and-examples.md](references/query-patterns-and-examples.md) | Generating **query code** — Workarea, Embedded SQL, multi-table JOINs, TCSqlExec updates, counting, or reviewing SQL injection prevention examples | Full code templates for all 5 query patterns, safe/unsafe FWExecStatement examples, LIKE clause parameterization |
| [references/cross-database-compatibility.md](references/cross-database-compatibility.md) | Handling **cross-database concerns** — ChangeQuery(), TCGetDB(), DBAccess macros, or translating functions between MSSQL / PostgreSQL / Oracle | ChangeQuery and TCGetDB code examples, DBAccess macros table, cross-database function equivalents (9 operations × 4 dialects) |

> Also refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Protheus Database Conventions

### Table Naming

Protheus table aliases follow the pattern `XXN` where `XX` is the module prefix and `N` is a sequence:

| Prefix | Module            | Example Tables                                                                                                            |
| ------ | ----------------- | ------------------------------------------------------------------------------------------------------------------------- |
| SA     | Customers/Vendors | SA1 (Customers), SA2 (Vendors), SA3 (Salespeople)                                                                         |
| SB     | Products          | SB1 (Products), SB2 (Stock Balances), SB5 (Supplements)                                                                   |
| SC     | Purchasing        | SC1 (Purchase Requests), SC5 (Sales Orders Header), SC6 (Sales Orders Items), SC7 (Purchase Orders)                       |
| SD     | Documents         | SD1 (Incoming Invoices Items), SD2 (Outgoing Invoices Items), SD3 (Internal Movements)                                    |
| SE     | Financial         | SE1 (Accounts Receivable), SE2 (Accounts Payable), SE5 (Cash Movements)                                                   |
| SF     | Invoices          | SF1 (Incoming Invoices Header), SF2 (Outgoing Invoices Header)                                                            |
| SX     | Data Dictionary   | SX1 (Parameters), SX2 (Tables), SX3 (Fields), SX5 (Lookup Tables), SX6 (System Parameters), SX7 (Triggers), SIX (Indexes) |
| ZZ     | Custom            | ZZ1-ZZZ (Custom tables created by customer, also Z01-Z99, ZA0-ZAZ, etc.)                                                  |

### Physical Table Names

The physical table name in the database appends the company code:

| Alias | Physical Name | Rule                                          |
| ----- | ------------- | --------------------------------------------- |
| SA1   | SA1010        | Alias + Company ("01") + Branch padding ("0") |
| SD1   | SD1010        | Same pattern                                  |

Use `RetSQLName("SA1")` to get the correct physical table name dynamically.

### Field Naming

Fields follow the pattern `XX_FIELD` where `XX` matches the table alias prefix:

| Table | Field    | Meaning                 |
| ----- | -------- | ----------------------- |
| SA1   | A1_COD   | Customer code           |
| SA1   | A1_NOME  | Customer name           |
| SD1   | D1_DOC   | Invoice document number |
| SD1   | D1_TOTAL | Invoice item total      |
| SF2   | F2_DOC   | Outgoing invoice number |

### Mandatory System Fields

**Every query against Protheus tables MUST include these filters:**

| Field        | Filter                              | Purpose                                                    |
| ------------ | ----------------------------------- | ---------------------------------------------------------- |
| `D_E_L_E_T_` | `= ' '` (single space)              | Soft-delete flag. Records with `'*'` are logically deleted |
| `XX_FILIAL`  | `= cFilAnt` or `= FWxFilial("XXX")` | Multi-branch filter                                        |

```sql
-- ALWAYS include both filters
SELECT A1_COD, A1_NOME
FROM SA1010 SA1
WHERE SA1.D_E_L_E_T_ = ' '
  AND SA1.A1_FILIAL = FWxFilial("SA1")
```

> **Warning:** Omitting `D_E_L_E_T_` will return deleted records. Omitting the branch filter will return records from all branches, which is usually incorrect and a security risk.

---

## Query Patterns

This skill supports five query patterns. Read [references/query-patterns-and-examples.md](references/query-patterns-and-examples.md) for the full code templates.

| Pattern | Approach | When to Use |
| --- | --- | --- |
| 1 — Simple Select (Workarea) | `DbSelectArea` + `DbSeek` | Single record lookup by existing index, record-by-record operations |
| 2 — Simple Select (Embedded SQL) | `FWExecStatement` + `OpenAlias` / `ExecScalar` | Aggregations, complex filters, no suitable index for Workarea |
| 3 — Multi-Table Join | Embedded SQL with `INNER JOIN` | Cross-table reporting, invoice details with product names |
| 4 — INSERT/UPDATE (TCSqlExec) | `FWExecStatement` + `TCSqlExec` | Direct SQL writes (bypasses data dictionary triggers) |
| 5 — Counting Records | `FWExecStatement:ExecScalar()` on `SELECT COUNT(*)` | Record counts with filters |

> **Important:** Pattern 4 (TCSqlExec) bypasses data dictionary validations and triggers. Prefer Workarea `RecLock`/`MsUnlock` for standard CRUD operations.

---

## Workarea vs. Embedded SQL Decision Matrix

| Criterion                            | Workarea (DBSeek)            | Embedded SQL (`FWExecStatement`)  |
| ------------------------------------ | ---------------------------- | --------------------------------- |
| Single record lookup by key          | **Best choice**              | Acceptable                        |
| Sequential scan by index             | **Best choice**              | Acceptable                        |
| Complex multi-table joins            | Poor (requires nested seeks) | **Best choice**                   |
| Aggregations (SUM, COUNT)            | Very poor                    | **Best choice**                   |
| Large result sets                    | **Better memory control**    | Good (but watch alias handling)   |
| Record locking for update            | **Required**                 | Use `FWExecStatement` + `TCSqlExec` (bypasses triggers) |
| Performance (key-based)              | **Fastest**                  | Slight overhead                   |
| Data dictionary trigger execution    | **Automatic**                | **Not triggered**                 |
| Index requirement                    | Must have suitable SIX index | Any column                        |
| Code readability for complex queries | Poor                         | **Best choice**                   |

> **Rule of thumb:** Use Workarea for CRUD operations on single records. Use Embedded SQL for reporting, aggregation, and complex joins.

---

## Index Awareness (SIX Dictionary)

Protheus indexes are defined in the SIX table. The first index of each table (order 1) is typically the primary key.

### Common Index Patterns

| Table | Order | Key Expression                                                            | Use Case                      |
| ----- | ----- | ------------------------------------------------------------------------- | ----------------------------- |
| SA1   | 1     | `A1_FILIAL + A1_COD + A1_LOJA`                                            | Primary key — customer lookup |
| SA1   | 3     | `A1_FILIAL + A1_CGC`                                                      | Find customer by tax ID       |
| SA2   | 1     | `A2_FILIAL + A2_COD + A2_LOJA`                                            | Primary key — vendor lookup   |
| SB1   | 1     | `B1_FILIAL + B1_COD`                                                      | Primary key — product lookup  |
| SD1   | 1     | `D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA + D1_COD + D1_ITEM` | Incoming invoice item         |
| SD2   | 1     | `D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA + D2_COD + D2_ITEM` | Outgoing invoice item         |
| SE1   | 1     | `E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO`                  | Accounts receivable           |
| SF2   | 1     | `F2_FILIAL + F2_DOC + F2_SERIE`                                           | Outgoing invoice header       |

### Using Indexes in Embedded SQL

For SQL Server, use the `%nolock%` DBAccess macro on read queries. This macro translates to `WITH (NOLOCK)` on MSSQL and is silently ignored on PostgreSQL/Oracle (MVCC), making it safe to use in cross-database code:

```sql
SELECT A1_COD, A1_NOME
FROM SA1010 SA1 WITH (%nolock%)
WHERE SA1.D_E_L_E_T_ = ' '
  AND SA1.A1_FILIAL = FWxFilial("SA1")
  AND SA1.A1_COD = '000001'
  AND SA1.A1_LOJA = '01'
```

> **Tip:** Always order WHERE clauses to match the index key expression order for the query optimizer.

---

## SQL Injection Prevention

**Never concatenate user input directly into SQL strings.** Use `FWExecStatement` to parameterize all dynamic values.

The safe pattern:
1. Build the SQL with `?` placeholders for every dynamic value (filter, branch, deletion flag).
2. Wrap it in `ChangeQuery()` for cross-database compatibility.
3. Instantiate with `FWExecStatement():New(cQuery)` (or `FWPreparedStatement` on libs older than `20211116`).
4. Bind values 1..N with `SetString()`, `SetNumeric()`, `SetDate()`, `SetBoolean()`, `SetIn()`.
5. Execute:
   - SELECT returning a cursor → `cAlias := oStatement:OpenAlias([cAlias][, cLifeTime, cTimeout])`
   - SELECT returning a single scalar → `xValue := oStatement:ExecScalar(cColumn[, cLifeTime, cTimeout])`
   - INSERT / UPDATE / DELETE → `TCSqlExec(oStatement:GetFixQuery())`
6. Always close opened aliases (`(cAlias)->(DBCloseArea())`) and call `oStatement:Destroy()`.

For LIKE clauses, build the `%` wildcard on the AdvPL side (`"%" + cSearch + "%"`) and bind the whole string as a single `?` parameter — this avoids cross-DB concat operator differences.

> **Do not use `SetUnsafe()` with user input.** It bypasses bind safety and reintroduces SQL injection risk; reserve it for identifiers built from constants.

> **Cache (optional):** `OpenAlias` / `ExecScalar` accept `cLifeTime` and `cTimeout` (seconds, as character) to reuse a cached result from DBAccess for hot, repeatedly executed queries.

> Read [references/query-patterns-and-examples.md](references/query-patterns-and-examples.md) for complete safe/unsafe code examples, the full method reference, and LIKE-clause examples.

---

## Common Anti-Patterns

| Anti-Pattern                                  | Problem                                              | Fix                                                                                   |
| --------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Missing `D_E_L_E_T_` filter                   | Returns deleted records                              | Always add `WHERE D_E_L_E_T_ = ' '`                                                   |
| Missing branch filter                         | Returns records from all branches                    | Always add `AND XX_FILIAL = '...'`                                                    |
| `SELECT *` on Protheus tables                 | Returns dozens of system fields, slow                | List only the fields you need                                                         |
| Full table scan on SD1/SD2                    | Millions of rows, very slow                          | Use indexed columns in WHERE                                                          |
| Not using `%nolock%`                          | Lock contention on read queries                      | Add `WITH (%nolock%)` to SELECT tables — cross-DB safe (ignored on PostgreSQL/Oracle) |
| `D_E_L_E_T_` filter on JOINs missing          | Joined table returns deleted records                 | Add `D_E_L_E_T_ = ' '` to every table in JOIN                                         |
| Hardcoded company/branch codes                | Breaks in multi-company environments                 | Use `FWxFilial()`, `RetSQLName()`                                                     |
| Not closing query aliases / `FWExecStatement` | Memory leak, alias exhaustion                        | Always call `(cAlias)->(DBCloseArea())` and `oStatement:Destroy()`                    |
| Macro execution in SQL                        | SQL injection risk                                   | Use `FWExecStatement` for parameterized values                                    |
| Missing `RetSQLName()`                        | Wrong physical table name in multi-company           | Always use `RetSQLName("XXX")`                                                        |
| Creating procedures in source                 | Prohibited by SonarQube                              | Use SPManager for procedure management                                                |
| Using IIF in SQL expressions                  | Prohibited — use CASE WHEN or If/Else in AdvPL logic | Replace `IIF()` with `If/Else/EndIf` or SQL `CASE WHEN`                               |
| Direct access to SIX/SX2/SX3 via DbSelectArea | Prohibited metadata access                           | Use `RetSqlName()` for SX2, `FWSX3Util()` for SX3, standard APIs for SIX              |
| GetMV/ExistBlock inside loops                 | Performance degradation                              | Cache result in a variable before the loop                                            |

---

## Query Building Checklist

### Mandatory

- [ ] `D_E_L_E_T_ = ' '` included for every table in the query
- [ ] Branch filter (`XX_FILIAL`) included for every table
- [ ] Physical table name obtained via `RetSQLName("XXX")`
- [ ] User-provided values parameterized with `FWExecStatement` (preferred over raw `TCQuery`)
- [ ] Result alias name generated with `GetNextAlias()` and opened via `FWExecStatement:OpenAlias()`
- [ ] Opened alias closed with `DBCloseArea()` in all code paths (including errors) and `FWExecStatement:Destroy()` is called

### Performance

- [ ] Only required fields listed (no `SELECT *`)
- [ ] WHERE clause order matches index key expression
- [ ] `%nolock%` hint used for SQL Server read queries
- [ ] Pagination used for large result sets
- [ ] JOINs reference indexed columns

### Safety

- [ ] No macro-execution (`&cExpr`) in SQL strings
- [ ] No hardcoded company/branch codes
- [ ] Error handling wraps the query execution (Try-Catch)
- [ ] Workarea area saved and restored with `GetArea()`/`RestArea()`
- [ ] No `IIF()` in query construction or expressions — use `If/Else/EndIf` or SQL `CASE WHEN`
- [ ] No `CREATE PROCEDURE` in source — use SPManager
- [ ] `GetMV()`/`ExistBlock()` results cached before use in loops

> Refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

---

## Cross-Database Compatibility

Protheus supports **PostgreSQL**, **MSSQL Server**, and **Oracle**. All generated SQL must work across all three, or use framework tools to handle differences:

- **`ChangeQuery(cQuery)`** — translates SQL syntax to the active database dialect (`TOP` → `LIMIT`, etc.). BeginSQL/EndSQL calls it automatically.
- **`TCGetDB()`** — returns `"MSSQL"`, `"ORACLE"`, or `"POSTGRES"` for DB-specific branching when `ChangeQuery()` is insufficient.
- **DBAccess macros** — `%nolock%`, `%notDel%`, `%table:XXX%`, `%Order:XXX%` — translated per database in SQL strings.
- **Best practice:** Always use ANSI-compatible SQL (`COALESCE`, `CASE WHEN`, `CONCAT`, `FETCH FIRST`) or rely on `ChangeQuery()`.

> Read [references/cross-database-compatibility.md](references/cross-database-compatibility.md) for full code examples, the DBAccess macros table, and the cross-database function equivalents reference (MSSQL vs PostgreSQL vs Oracle).

---

## Troubleshooting

- **Missing `D_E_L_E_T_` filter**: All Protheus queries must include `D_E_L_E_T_ = ' '` (or equivalent `%notDel%`) to exclude logically deleted records. Omitting this returns deleted rows.
- **Wrong physical table name**: Use `RetSQLName('alias')` to get the physical table name. Hardcoded names like `SA1010` will break across environments with different company codes.
- **Index not being used**: Ensure the `WHERE` clause column order matches the SIX index key expression. Use `%nolock%` hint for SQL Server read-only queries to avoid lock contention.
- **Branch/company filter missing**: Use `FWxFilial('alias')` for the branch filter. Hardcoding branch codes causes cross-branch data leakage.
- **SQL injection via macro-execution**: Never use `&(cExpr)` to build SQL strings. Use `FWExecStatement` to parameterize all dynamic values in queries.

