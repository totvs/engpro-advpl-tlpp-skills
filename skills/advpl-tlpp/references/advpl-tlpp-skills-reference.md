# AdvPL/TLPP Agent Skills

A collection of **19 AI agent skills** for the **TOTVS Protheus ERP** ecosystem, covering the **AdvPL** and **TLPP** (TOTVS Language Plus Plus) programming languages. These skills guide AI assistants through structured workflows for code generation, migration, quality review, testing, and documentation within the Protheus platform.

---

## Table of Contents

- [Skills by Category](#skills-by-category)
  - [Code Generation](#code-generation)
  - [Migration and Modernization](#migration-and-modernization)
  - [Code Quality and Review](#code-quality-and-review)
  - [Testing](#testing)
  - [Documentation and Planning](#documentation-and-planning)
- [References](#references)
  - [Shared References](#shared-references)
  - [Per-Skill References](#per-skill-references)
- [Quick Reference: Which Skill to Use?](#quick-reference-which-skill-to-use)

---

## Skills by Category

### Code Generation

Skills that generate production-ready code structures following TOTVS framework standards.

| Skill | Description |
|-------|-------------|
| [mvc-generator](mvc-generator/SKILL.md) | Generates Protheus MVC screen structures — `ModelDef`, `ViewDef`, `MenuDef`, and Browse function — for single-entity (Model 1) and master-detail (Model 3) patterns using `FWFormModel` (`MPFormModel`), `FWFormView`, and `FWMBrowse`. |
| [tlpp-rest-endpoint-generator](tlpp-rest-endpoint-generator/SKILL.md) | Generates TLPP REST endpoints using annotation-based routing (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`) with the `oRest` object. Follows TOTVS TTALK API standards including pagination, error model, and Swagger documentation. |
| [entry-point-designer](entry-point-designer/SKILL.md) | Designs and documents Protheus Entry Points with proper `User Function` signatures, `PARAMIXB` parameter layouts, return value specifications, and defensive programming patterns. |
| [query-builder](query-builder/SKILL.md) | Builds optimized and secure SQL queries for Protheus tables. Includes mandatory filters (`D_E_L_E_T_`, branch), index-driven query design, SQL injection prevention, and patterns for both Embedded SQL (preferring `FWExecStatement`) and Workarea (`DBSelectArea`/`DBSeek`). |

### Migration and Modernization

Skills that guide incremental migration from legacy patterns to modern frameworks.

| Skill | Description |
|-------|-------------|
| [advpl-to-tlpp-migration](advpl-to-tlpp-migration/SKILL.md) | Migrates legacy AdvPL code (`.prw`) to modern TLPP (`.tlpp`). Covers file extension change, `#include "tlpp-core.th"`, namespace adoption, type annotations, Try-Catch, WsRESTful REST migration, long identifiers, inline JSON, named parameters, access modifiers, and `StaticCall` removal. |

### Code Quality and Review

Skills that enforce quality standards, detect issues, and improve existing code.

| Skill | Description |
|-------|-------------|
| [code-review](code-review/SKILL.md) | Comprehensive AdvPL/TLPP code review covering 8 categories: Security (SQL injection, credentials), Performance (workareas, loops), Legacy/Deprecated Constructs, Metadata Access, ProtheusDOC Documentation, Clean Code, TLPP-specific checks, and Compilation. Generates severity-ranked findings with SonarQube rule references. |
| [sql-code-review](sql-code-review/SKILL.md) | SQL-focused code review covering injection prevention, access control, data protection, query structure analysis, index strategy, anti-pattern detection, and database-specific best practices for PostgreSQL, SQL Server, and Oracle. |
| [refactor](refactor/SKILL.md) | Surgical code refactoring to improve maintainability without changing behavior. Addresses 15 code smells (long methods, duplicated code, nested conditionals, magic numbers, etc.) with safe extraction patterns and AdvPL/TLPP-specific guidance. |
| [refactor-method-complexity-reduce](refactor-method-complexity-reduce/SKILL.md) | Targeted cognitive complexity reduction in a specific method through focused helper method extraction. Analyzes nested conditionals, repeated blocks, and complex boolean expressions, then restructures the method as a high-level orchestrator. |
| [sql-optimization](sql-optimization/SKILL.md) | SQL performance optimization including query tuning, index strategy, pagination, batch operations, execution plan analysis, and Protheus-specific database tuning. Works with PostgreSQL, SQL Server, and Oracle. |
| [utf8-to-cp1252-conversion](utf8-to-cp1252-conversion/SKILL.md) | Converts AdvPL/TLPP source files from UTF-8 to Windows-1252 (CP1252) after code generation. The Protheus compiler requires CP1252 — includes dependency-free native scripts (Bash+iconv for Linux/macOS and PowerShell+.NET for Windows) with BOM detection, backup, batch processing, and CI/CD integration. |

### Testing

Skills that generate automated test scripts for both business logic and UI validation.

| Skill | Description |
|-------|-------------|
| [tir-test-generator](tir-test-generator/SKILL.md) | Generates **TIR** (TOTVS Interface Robot) end-to-end test scripts in Python for Protheus SmartClient/Webapp screens. Covers CRUD screen tests, MVC screen tests, grid interaction, report parameter screens, field validation, and message box assertions using `tir.Webapp`. |

### Documentation and Planning

Skills for documenting code and planning implementation work.

| Skill | Description |
|-------|-------------|
| [documentation-writer](documentation-writer/SKILL.md) | Generates ProtheusDOC comment blocks (`/*/{Protheus.doc}`) for AdvPL/TLPP source code. Covers functions, classes, and methods with all supported tags (`@type`, `@param`, `@return`, `@author`, `@since`, `@example`, etc.) following the official TOTVS standard. |
| [data-dictionary-lookup](data-dictionary-lookup/SKILL.md) | Queries the TOTVS Protheus ERP data dictionary (SX2 tables, SX3 fields, SIX indexes, SX6 parameters, SX5 generic tables, SX7 triggers, SX1 questions, SX9 relationships, SXB standard queries, SXG/SXA groups). Also used during refactoring, migration, or code improvements for dictionary impact validation. |
| [context-map](context-map/SKILL.md) | Generates a context map of all files relevant to a task before implementing changes. Identifies files to modify, dependencies, test files, reference patterns, and produces a risk assessment for the planned changes. |
| [create-implementation-plan](create-implementation-plan/SKILL.md) | Creates phased, machine-readable implementation plan files for features, refactoring, upgrades, or architectural changes. Plans are structured for autonomous execution by AI agents or humans, with atomic tasks, validation criteria, and dependency declarations. |

---

## References

### Shared References

Reference materials used by multiple skills.

| Reference | Used By | Description |
|-----------|---------|-------------|
| [references/sonarqube-rules-reference.md](references/sonarqube-rules-reference.md) | `code-review`, `entry-point-designer` | Comprehensive SonarQube rules reference for AdvPL/TLPP organized into 5 groups: Security (G1), Performance (G2), Legacy/Deprecated (G3), Metadata Access (G4), and Compilation (G5) — with rule IDs and severity levels. |

### Per-Skill References

Skill-specific reference materials.

| Skill | Reference | Description |
|-------|-----------|-------------|
| `advpl-to-tlpp-migration` | [advpl-tlpp-feature-comparison.md](advpl-to-tlpp-migration/references/advpl-tlpp-feature-comparison.md) | Feature comparison between AdvPL and TLPP. |
| `advpl-to-tlpp-migration` | [tlpp-migration-patterns.md](advpl-to-tlpp-migration/references/tlpp-migration-patterns.md) | AdvPL to TLPP migration patterns. |
| `code-review` | [code-quality-patterns.md](code-review/references/code-quality-patterns.md) | Code quality patterns — performance, legacy constructs, metadata access, and compilation. |
| `code-review` | [documentation-and-conventions.md](code-review/references/documentation-and-conventions.md) | ProtheusDOC documentation, Clean Code conventions, and TLPP-specific patterns. |
| `code-review` | [security-review-patterns.md](code-review/references/security-review-patterns.md) | Security review patterns including SQL injection prevention and vulnerabilities (SonarQube G1). |
| `data-dictionary-lookup` | [column-reference.md](data-dictionary-lookup/references/column-reference.md) | Detailed reference of all SX* table columns (SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB) with types, possible values, and functional descriptions. |
| `data-dictionary-lookup` | [sql-queries.md](data-dictionary-lookup/references/sql-queries.md) | Complete SQL queries for the 9 dictionary tables, combined queries, and mandatory `execute-sql` rules (TRIM, d_e_l_e_t_, lowercase). |
| `mvc-generator` | [mvc-api-reference.md](mvc-generator/references/mvc-api-reference.md) | MVC API reference — `FWFormStruct` parameters, view layout options, and `MenuDef` action codes. |
| `mvc-generator` | [mvc-code-templates.md](mvc-generator/references/mvc-code-templates.md) | Complete AdvPL/TLPP code templates for Protheus MVC screens (Model 1 and Model 3). |
| `query-builder` | [cross-database-compatibility.md](query-builder/references/cross-database-compatibility.md) | Cross-database compatibility (PostgreSQL, MSSQL, Oracle) and dialect translation via `ChangeQuery()`. |
| `query-builder` | [query-patterns-and-examples.md](query-builder/references/query-patterns-and-examples.md) | Query patterns and complete code examples with workarea patterns. |
| `refactor` | [code-smells-and-patterns.md](refactor/references/code-smells-and-patterns.md) | Before/after examples for 15 code smells and 4 design patterns in AdvPL/TLPP. |
| `sql-code-review` | [database-specific-best-practices.md](sql-code-review/references/database-specific-best-practices.md) | Database-specific best practices and ANSI SQL patterns for cross-database compatibility. |
| `sql-code-review` | [sql-performance-and-quality-patterns.md](sql-code-review/references/sql-performance-and-quality-patterns.md) | SQL performance and quality patterns — query structure analysis and optimization. |
| `sql-code-review` | [sql-security-patterns.md](sql-code-review/references/sql-security-patterns.md) | SQL security patterns — injection prevention, parameterized queries, and secure practices. |
| `sql-optimization` | [sql-optimization.md](sql-optimization/references/sql-optimization.md) | Protheus-specific SQL optimization. |
| `sql-optimization` | [sql-optimization-patterns.md](sql-optimization/references/sql-optimization-patterns.md) | SQL optimization patterns. |
| `tir-test-generator` | [tir-setup-and-best-practices.md](tir-test-generator/references/tir-setup-and-best-practices.md) | TIR test setup and best practices. |
| `tir-test-generator` | [tir-test-patterns.md](tir-test-generator/references/tir-test-patterns.md) | TIR test patterns. |
| `tir-test-generator` | [tir-webapp-methods-reference.md](tir-test-generator/references/tir-webapp-methods-reference.md) | `tir.Webapp` methods reference. |
| `tlpp-rest-endpoint-generator` | [tlpp-rest-endpoint-templates.md](tlpp-rest-endpoint-generator/references/tlpp-rest-endpoint-templates.md) | Complete CRUD endpoint templates and helper functions for TLPP REST APIs. |
| `tlpp-rest-endpoint-generator` | [ttalk-standards-and-configuration.md](tlpp-rest-endpoint-generator/references/ttalk-standards-and-configuration.md) | TOTVS TTALK standards, REST server configuration, and troubleshooting. |

---

## Quick Reference: Which Skill to Use?

| I want to... | Use this skill |
|--------------|----------------|
| Create a new CRUD screen (classic MVC) | `mvc-generator` |
| Build a REST API | `tlpp-rest-endpoint-generator` |
| Customize a standard routine | `entry-point-designer` |
| Write a SQL query for Protheus | `query-builder` |
| Migrate `.prw` to `.tlpp` | `advpl-to-tlpp-migration` |
| Review code quality | `code-review` |
| Review SQL code | `sql-code-review` |
| Improve code structure | `refactor` |
| Reduce method complexity | `refactor-method-complexity-reduce` |
| Optimize SQL performance | `sql-optimization` |
| Create UI/E2E tests | `tir-test-generator` |
| Add ProtheusDOC documentation | `documentation-writer` |
| Query the Protheus data dictionary | `data-dictionary-lookup` |
| Map files before implementing | `context-map` |
| Plan an implementation | `create-implementation-plan` |
| Convert source encoding to CP1252 | `utf8-to-cp1252-conversion` |

