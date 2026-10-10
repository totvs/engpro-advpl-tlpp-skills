---
name: sql-code-review
description: 'Universal SQL code review assistant that performs comprehensive security, maintainability, and code quality analysis across SQL databases (PostgreSQL, SQL Server, Oracle). Focuses on SQL injection prevention, access control, code standards, and anti-pattern detection. Complements SQL optimization prompt for complete development coverage. Use when user says "review SQL", "SQL security audit", "SQL anti-patterns", "check SQL quality".'
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Quality and Review
---

# SQL Code Review

Perform a thorough SQL code review of ${selection} (or entire project if no selection) focusing on security, performance, maintainability, and database best practices.

## Review Categories

### 🔒 Security

- **SQL Injection Prevention** — all user inputs must be parameterized; no string concatenation in queries
- **Access Control** — principle of least privilege, role-based permissions, schema security
- **Data Protection** — avoid `SELECT *` on sensitive tables, enforce audit logging and data masking

### ⚡ Performance

- **Query Structure** — eliminate `SELECT DISTINCT *`, prefer explicit JOINs over comma-separated FROM
- **Index Strategy** — verify indexes for WHERE/JOIN columns, flag over-indexing and unused indexes
- **Join Optimization** — correct join types, optimal join order, no accidental Cartesian products
- **Aggregation** — replace correlated subqueries with JOIN/GROUP BY when possible

### 🛠️ Code Quality

- **Formatting** — consistent uppercase keywords, aligned columns, proper indentation
- **Naming** — descriptive table/column names, no reserved words as identifiers, consistent casing
- **Schema Design** — appropriate normalization, optimal data types, proper constraints and defaults

### 🗄️ Database Compatibility

- **ANSI SQL first** — use COALESCE, CASE WHEN, ANSI JOINs, FETCH FIRST for portability
- **Database-specific idioms** — leverage engine-specific features (JSONB, COLUMNSTORE, sequences) where appropriate

> **Protheus note:** Use `ChangeQuery()` to automatically translate SQL syntax to the active database dialect. BeginSQL/EndSQL calls `ChangeQuery()` automatically.

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers the review workflow, category definitions, checklist, and output format. Detailed code examples, anti-patterns, and database-specific best practices are in the `references/` directory — read them on demand based on the scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/sql-security-patterns.md](references/sql-security-patterns.md) | Reviewing **security concerns** — SQL injection, access control, data protection, or dynamic SQL | Injection examples, parameterization patterns, access control checklist, data masking examples |
| [references/sql-performance-and-quality-patterns.md](references/sql-performance-and-quality-patterns.md) | Reviewing **query performance**, **code style**, **anti-patterns**, or **testing strategies** | Query optimization examples, JOIN/aggregation patterns, N+1 and DISTINCT anti-patterns, formatting standards, data integrity checks |
| [references/database-specific-best-practices.md](references/database-specific-best-practices.md) | Reviewing SQL targeting a **specific database** (PostgreSQL, SQL Server, Oracle) or **cross-database portability** | ANSI SQL cross-database patterns, PostgreSQL (JSONB, GIN), SQL Server (NVARCHAR, COLUMNSTORE), Oracle (sequences, VARCHAR2) |

> Also refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Review Workflow

### Step 1: Identify Scope and Database

Determine from the user's request:

- Which SQL files or queries to review
- Target database engine (PostgreSQL, SQL Server, Oracle, or multi-database)
- Review focus (security, performance, quality, or full review)

### Step 2: Load Relevant References

Based on the review focus and database, read the appropriate reference files:

- **Security focus** → read [references/sql-security-patterns.md](references/sql-security-patterns.md)
- **Performance / quality focus** → read [references/sql-performance-and-quality-patterns.md](references/sql-performance-and-quality-patterns.md)
- **Database-specific review** → read [references/database-specific-best-practices.md](references/database-specific-best-practices.md)
- **Full review** → read all three reference files

### Step 3: Analyze Code Against Checklist

Walk through each category in the checklist below. For each finding, classify priority as CRITICAL, HIGH, MEDIUM, or LOW.

### Step 4: Generate Report

Use the Issue Template (below) for each finding. Group findings by category and sort by priority.

---

## SQL Review Checklist

### Security
- [ ] All user inputs are parameterized
- [ ] No dynamic SQL construction with string concatenation
- [ ] Appropriate access controls and permissions
- [ ] Sensitive data is properly protected
- [ ] SQL injection attack vectors are eliminated

### Performance
- [ ] Indexes exist for frequently queried columns
- [ ] No unnecessary SELECT * statements
- [ ] JOINs are optimized and use appropriate types
- [ ] WHERE clauses are selective and use indexes
- [ ] Subqueries are optimized or converted to JOINs

### Code Quality
- [ ] Consistent naming conventions
- [ ] Proper formatting and indentation
- [ ] Meaningful comments for complex logic
- [ ] Appropriate data types are used
- [ ] Error handling is implemented

### Schema Design
- [ ] Tables are properly normalized
- [ ] Constraints enforce data integrity
- [ ] Indexes support query patterns
- [ ] Foreign key relationships are defined
- [ ] Default values are appropriate

---

## Review Output Format

### Issue Template

```
## [PRIORITY] [CATEGORY]: [Brief Description]

**Location**: [Table/View/Procedure name and line number if applicable]
**Issue**: [Detailed explanation of the problem]
**Security Risk**: [If applicable - injection risk, data exposure, etc.]
**Performance Impact**: [Query cost, execution time impact]
**Recommendation**: [Specific fix with code example]

**Before**:
```sql
-- Problematic SQL
```

**After**:
```sql
-- Improved SQL
```

**Expected Improvement**: [Performance gain, security benefit]
```

### Summary Assessment
- **Security Score**: [1-10] - SQL injection protection, access controls
- **Performance Score**: [1-10] - Query efficiency, index usage
- **Maintainability Score**: [1-10] - Code quality, documentation
- **Schema Quality Score**: [1-10] - Design patterns, normalization

### Top 3 Priority Actions
1. **[Critical Security Fix]**: Address SQL injection vulnerabilities
2. **[Performance Optimization]**: Add missing indexes or optimize queries
3. **[Code Quality]**: Improve naming conventions and documentation

Focus on providing actionable, database-agnostic recommendations while highlighting platform-specific optimizations and best practices.

> **Cross-Database Review Tip:** When reviewing Protheus SQL, verify the query is compatible with all three supported databases (PostgreSQL, MSSQL, Oracle). Use `ChangeQuery()` for automatic SQL dialect translation, or `TCGetDB()` for runtime DB detection when DB-specific logic is unavoidable.

---

## Protheus SQL Patterns

When reviewing SQL in the TOTVS Protheus ecosystem — whether embedded SQL (preferring `FWExecStatement`, with legacy `TCQuery` / `TCSqlExec` calls), Workarea-based access, or standalone queries — apply the following additional checks.

### Table and Field Naming Conventions

Protheus uses standardized short-name tables and fields managed through the data dictionary:

| Alias | Module | Description |
|-------|--------|-------------|
| SA1 | All | Customers |
| SA2 | All | Suppliers |
| SB1 | SIGAEST | Products |
| SC5 | SIGAFAT | Sales Orders (header) |
| SC6 | SIGAFAT | Sales Orders (items) |
| SD1 | SIGACOM | Purchase document items |
| SD2 | SIGAFAT | Sales document items |
| SE1 | SIGAFIN | Accounts Receivable |
| SE2 | SIGAFIN | Accounts Payable |
| SF1 | SIGACOM | Incoming invoices (header) |
| SF2 | SIGAFAT | Outgoing invoices (header) |
| SX2 | System | Table dictionary |
| SX3 | System | Field dictionary |
| SIX | System | Index dictionary |

Fields follow the pattern `<prefix>_<name>`, e.g., `A1_COD` (customer code), `A1_NOME` (customer name), `D1_DOC` (document number).

### Mandatory Filters for Protheus Tables

Every query against a Protheus table **must** include these filters unless there is an explicit reason to omit them:

```sql
-- BAD: Missing mandatory filters — returns deleted records and all branches
SELECT A1_COD, A1_NOME FROM SA1010

-- GOOD: Proper Protheus query with mandatory filters
SELECT A1_COD, A1_NOME
FROM SA1010
WHERE D_E_L_E_T_ = ' '
  AND A1_FILIAL  = '01'
```

| Filter | Purpose |
|--------|---------|
| `D_E_L_E_T_ = ' '` | Excludes logically deleted records (soft delete). Always required. |
| `<prefix>_FILIAL = FWxFilial("XXX")` | Multi-branch filter (tenant isolation). Required unless deliberately querying across branches. Always use `xFilial()`/`FWxFilial()`; flag `cFilAnt` in a branch filter as a defect (on a shared table the branch field is blank, so the query returns zero rows). |

### Workarea vs. Embedded SQL Decision Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| Single-record lookup by index key | Workarea (`DbSelectArea` / `DbSetOrder` / `DbSeek`) |
| Sequential processing of a filtered set | Workarea with `While` loop |
| Complex joins across multiple tables | Embedded SQL via `FWExecStatement` |
| Aggregate queries (SUM, COUNT, AVG) | Embedded SQL via `FWExecStatement` (use `:ExecScalar()` for single values) |
| Bulk INSERT/UPDATE/DELETE operations | `FWExecStatement` + `TCSqlExec(oStatement:GetFixQuery())` |
| Reports with heavy filtering | Embedded SQL via `FWExecStatement`, or temporary tables via `TCSqlExec` |

### Workarea Access Review Checklist

```advpl
// GOOD: Complete workarea access pattern
DbSelectArea("SA1")
DbSetOrder(1)           // Set the index defined in SIX
If DbSeek(FWxFilial("SA1") + cCodCli)
  // process record...
EndIf
```

- [ ] `DbSelectArea()` called before any workarea operation
- [ ] `DbSetOrder()` set to the correct SIX index
- [ ] `DbSeek()` includes branch prefix via `FWxFilial()`
- [ ] Write operations wrapped with `RecLock()` / `MsUnlock()`
- [ ] `While` loops include `!Eof()` and `SA1->(DbSkip())` pattern

### Embedded SQL Review Checklist

```advpl
// GOOD: Parameterized embedded SQL via FWExecStatement (DB-side bind, cacheable)
Local cQuery as Character
Local oExec  as Object
Local cAlias as Character

cQuery := "SELECT A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE D_E_L_E_T_ = ? "
cQuery += "AND A1_FILIAL = ? "
cQuery += "AND A1_COD = ? "

oExec := FWExecStatement():New(ChangeQuery(cQuery))
oExec:SetString(1, ' ')
oExec:SetString(2, FWxFilial("SA1"))
oExec:SetString(3, cCodCli)

cAlias := oExec:OpenAlias("QRY_CLI")
// ... consume (cAlias)->A1_COD / A1_NOME ...
(cAlias)->(DbCloseArea())
oExec:Destroy()
```

- [ ] Uses `RetSqlName()` to get the physical table name (handles company suffix)
- [ ] Includes `D_E_L_E_T_ = ' '` filter
- [ ] Includes branch filter via `FWxFilial()`
- [ ] Temporary alias is closed after use (`QRY_CLI->(DbCloseArea())`)
- [ ] String values are sanitized to prevent SQL injection (use `FWExecStatement` — no raw user input concatenated)

### Common Protheus SQL Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Missing `D_E_L_E_T_` filter | Returns deleted records | Always add `D_E_L_E_T_ = ' '` |
| `SELECT *` on Protheus tables | Protheus tables have many system fields; wastes bandwidth | Select only needed columns |
| Full table scan on SD1/SD2/SE1/SE2 | These transactional tables can have millions of rows | Use indexed columns in `WHERE` clause |
| Missing `%nolock%` on SQL Server | Causes lock escalation on read queries | Add `%nolock%` hint: `FROM SA1010 WITH (%nolock%)` — the `%nolock%` DBAccess macro translates to `WITH (NOLOCK)` on MSSQL and is silently ignored on PostgreSQL/Oracle (MVCC) |
| Concatenating user input into SQL | SQL injection vulnerability | Use `FWExecStatement` or `TcGenQry2` to parameterize queries |
| Not closing temporary aliases | Resource leak, workarea pollution | Always `QRY->(DbCloseArea())` after use |
| Hardcoding table suffix (e.g., `SA1010`) | Breaks in multi-company environments | Use `RetSqlName("SA1")` |
| Creating procedures directly in source | Prohibited — violates SonarQube rules | Use SPManager for procedure management |
| Direct queries without evaluation (Cloud) | Queries may not be Cloud-compatible | Evaluate Cloud impact; prefer framework APIs where available |
| Using SE5 table directly | SE5 is deprecated | Use `FKx` family functions + `ExecAuto` |
| Using IIF in SQL or AdvPL expressions | Prohibited for clean code | Replace with `CASE WHEN` (SQL) or `If/Else/EndIf` (AdvPL) |

### SIX Index Dictionary Awareness

Protheus indexes are defined in the SIX dictionary. When writing queries or using workareas:

- **Check available indexes** before choosing `DbSetOrder()` — using the wrong order leads to full scans
- **Index 1** is typically: branch + primary key (e.g., `A1_FILIAL + A1_COD + A1_LOJA`)
- **Composite indexes** should be leveraged in `WHERE` clauses matching left-to-right column order
- **Never create ad-hoc indexes** in production without SIX registration

### Protheus SQL Security

- **Never concatenate raw user input** into SQL strings — use `FWExecStatement` or `TcGenQry2` for parameterized queries
- **Never expose table structure** in error messages returned to the client
- **Validate input length** against SX3 field size before inserting/updating
- **Use `FWExecView`** for user-facing queries when possible (respects field-level security)

> Refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.
