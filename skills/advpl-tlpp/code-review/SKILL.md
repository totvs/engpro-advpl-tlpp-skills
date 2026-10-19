---
name: code-review
description: 'Perform comprehensive AdvPL/TLPP code review covering SonarQube rules, Protheus.doc documentation, security, performance, clean code, and TOTVS Protheus framework best practices. Use when a user says "review this code", "code review", "check this source", "audit this AdvPL/TLPP", or needs a structured quality assessment of .prw/.tlpp/.prx files.'
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Quality and Review
---

# AdvPL/TLPP Code Review

You are an expert AdvPL/TLPP code reviewer. Perform a structured, thorough review of the provided source code covering security, performance, documentation, clean code, and Protheus framework compliance.

## Overview

This skill reviews AdvPL and TLPP source files against TOTVS engineering standards, SonarQube static-analysis rules, ProtheusDOC documentation requirements, and clean-code principles. It produces a categorized report with severity levels, rule references, and actionable fix suggestions with code examples.

## When to Use

- Reviewing new or modified `.prw`, `.tlpp`, or `.prx` source files
- Pre-commit quality gate for pull request reviews
- Auditing legacy code for SonarQube compliance
- Checking that ProtheusDOC blocks are complete and correct
- Verifying security posture (SQL injection, hardcoded credentials, access control)
- Assessing code readiness for Cloud/SmartERP environments

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers the review workflow, category definitions, checklist, and output format. Detailed code examples, anti-patterns, and rule-specific fixes are in the `references/` directory — read them on demand based on the review scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/security-review-patterns.md](references/security-review-patterns.md) | Reviewing **security concerns** — SQL injection, hardcoded credentials, restricted APIs, environment context | SQL injection examples, `FWExecStatement` patterns, restricted functions table, REST/SOAP environment rules |
| [references/code-quality-patterns.md](references/code-quality-patterns.md) | Reviewing **performance, legacy code, metadata access, or compilation** issues | Loop/transaction anti-patterns, ISAM migration, deprecated API replacements, SX* metadata access table, encoding rules |
| [references/documentation-and-conventions.md](references/documentation-and-conventions.md) | Reviewing **ProtheusDOC, naming conventions, clean code**, or **TLPP-specific** patterns | ProtheusDOC tag reference, common documentation mistakes, variable naming/scope conventions, TLPP type annotations, namespace, Try-Catch |

> Also refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Review Process

### Step 1 — Understand the Code

Before reviewing:

1. Read the **entire file** to understand purpose, scope, and dependencies
2. Identify the **element types** (Functions, Static Functions, Classes, Methods)
3. Note the **file extension** — `.prw` (AdvPL), `.tlpp` (TLPP), `.prx` (legacy)
4. Check the **includes** — `totvs.ch`, `tlpp-core.th`, custom `.ch`/`.th` files

### Step 2 — Load Relevant References

Based on the code under review, read the appropriate reference files:

- **Security findings** → read [references/security-review-patterns.md](references/security-review-patterns.md)
- **Performance / legacy / metadata findings** → read [references/code-quality-patterns.md](references/code-quality-patterns.md)
- **Documentation / clean code / TLPP findings** → read [references/documentation-and-conventions.md](references/documentation-and-conventions.md)
- **Full review** → read all three reference files

### Step 3 — Run Review Categories

Apply each review category below in order. For every finding, record:

- **Category** (Security, Performance, Documentation, Clean Code, Framework)
- **Severity** (CRITICAL, MAJOR, MINOR, INFO)
- **Rule ID** (SonarQube rule when applicable, e.g., CA2050)
- **Location** (function/method name and approximate line)
- **Finding** (what is wrong)
- **Fix** (how to correct it, with code example when helpful)

### Step 4 — Produce the Report

Output findings as a structured report grouped by category, ordered by severity (CRITICAL first). End with a summary and overall assessment.

---

## Review Categories

### 1. Security (SonarQube G1)

Check for vulnerabilities that expose the application to attacks or data leaks. Key rules:

- **CA2050 / CA2051** — SQL Injection: concatenating user input in SQL strings → use `FWExecStatement` (CRITICAL)
- **CA2052** — Hardcoded credentials in source → use environment configuration (CRITICAL)
- **BG1000** — `RpcSetEnv`/`RpcSetType` in REST/SOAP services → configure `PrepareIn` (MAJOR)
- **CA2022–CA2025, CA2053** — Restricted/prohibited functions and assignments (CRITICAL)
- **BG1200** — `ErrorBlock` override → migrate to `Try-Catch` in TLPP (INFO)

### 2. Performance and Loops (SonarQube G2)

Detect patterns that degrade runtime performance:

- **CA1003** — Prohibited APIs inside loops (`GetMV`, `SuperGetMV`, `ExistBlock`, `AllUsers`, `Type`, `Pergunte`) → cache before loop (MAJOR)
- **CA1002** — UI APIs inside transactions (`MsgAlert`, `MsgYesNo`, etc.) → move UI after transaction (MAJOR)
- **CS1000** — Direct SQL without evaluation → prefer framework APIs or `ChangeQuery()`/`BeginSQL` (MAJOR)

### 3. Legacy and Deprecated Code (SonarQube G3)

Identify deprecated APIs and legacy patterns:

- **CA1000** — ISAM driver access (`MSCREATE`, `DBCREATE`) → `FWTemporaryTable` (MAJOR)
- **CA1001** — File-based semaphores → `LockByName()` (MAJOR)
- **CA1004** — Console output (`ConOut`) → `FWLogMsg()` (MINOR)
- **CA4000** — `IIF` inline → explicit `If/Else/EndIf` (INFO)
- **CA3001** — Uppercase `#INCLUDE` → lowercase `#include` (MINOR)

**Obsolete Include Directives** — Flag any of these legacy includes and recommend replacement:

| Obsolete Include | Replacement Include | Modern Class/API |
|---|---|---|
| `Ap5Mail.ch` | `totvs.ch` | `TMailMessage()` |
| `ApWizard.ch` | `totvs.ch` | `FWWizardControl()` |
| `FileIO.ch` | `totvs.ch` | `FWFileWriter()` / `FWFileReader()` |
| `Font.ch` | `totvs.ch` | `TFont()` |
| `ParmType.ch` | `totvs.ch` | `Default` prefix for parameter handling |
| `protheus.ch` | `totvs.ch` | — |
| `RWMake.ch` | `totvs.ch` | — |

### 4. Metadata Access (SonarQube G4)

Direct `DbSelectArea` on Protheus system tables (SX\*) is **prohibited**. All SX* tables (SM0, SIX, SX1–SXG, SXD, SE5, SPF) must be accessed through framework APIs. Key rules: **CA2000–CA2013, CA2017–CA2019, CA2021** (CRITICAL/MAJOR).

### 5. ProtheusDOC Documentation

Every public element must have a complete `/*/{Protheus.doc}` block with mandatory tags: `@type`, `@author`, `@since`, `@param` (per parameter), `@return`. Static Functions should also be documented.

### 6. Clean Code and Naming Conventions

Check variable naming prefixes (`c`=Character, `n`=Numeric, `l`=Logical, etc.), `Local` vs `Private` scope, function size (< 50 lines), magic numbers, and dead code.

### 7. TLPP-Specific Checks

For `.tlpp` files: verify file extension consistency, type annotations on variables and functions, namespace usage, and `Try-Catch` error handling instead of `ErrorBlock`.

### 8. Compilation and Encoding (SonarQube G5)

Check syntax errors (**CA0000**), file encoding (Windows-1252), INI references (**CA1005**), and I18N compliance (**CA2016**).

---

## Report Format

Output the review as follows:

````markdown
# Code Review: <filename>

## Summary

- **Total Findings:** <count>
- **Critical:** <count> | **Major:** <count> | **Minor:** <count> | **Info:** <count>
- **Overall Assessment:** <PASS | PASS WITH OBSERVATIONS | NEEDS REVISION | FAIL>

## Critical Findings

### [CA####] <Title>

- **Location:** `FunctionName` (line ~NN)
- **Finding:** <description>
- **Fix:** <how to fix>

```advpl
// suggested fix code
```
````

## Major Findings

(same structure)

## Minor Findings

(same structure)

## Info / Recommendations

(same structure)

## Documentation Review

- [ ] All public elements documented with ProtheusDOC
- [ ] @type, @author, @since present on all blocks
- [ ] @param tags match function signatures
- [ ] @return documented for non-void functions
- [ ] Identifiers match element names exactly

## Assessment Criteria

| Category               | Status   | Notes           |
| ---------------------- | -------- | --------------- |
| Security (G1)          | ✅/⚠️/❌ |                 |
| Performance (G2)       | ✅/⚠️/❌ |                 |
| Legacy/Deprecated (G3) | ✅/⚠️/❌ |                 |
| Metadata Access (G4)   | ✅/⚠️/❌ |                 |
| Documentation          | ✅/⚠️/❌ |                 |
| Clean Code             | ✅/⚠️/❌ |                 |
| TLPP Compliance        | ✅/⚠️/❌ | (if .tlpp file) |
| Compilation (G5)       | ✅/⚠️/❌ |                 |

```

### Overall Assessment Criteria

| Assessment | Condition |
|------------|-----------|
| **PASS** | Zero CRITICAL, zero MAJOR findings |
| **PASS WITH OBSERVATIONS** | Zero CRITICAL, ≤ 3 MAJOR findings |
| **NEEDS REVISION** | Zero CRITICAL, > 3 MAJOR findings |
| **FAIL** | Any CRITICAL finding |

---

## Quick Reference: All SonarQube Rules

For the complete rule definitions, severity levels, prohibited patterns, and required alternatives, consult [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md).

| Group | Rules | Focus |
|-------|-------|-------|
| G1 — Security | BG1000, CA2022–CA2053, BG1200 | Injection, credentials, restricted APIs |
| G2 — Performance | CA1002, CA1003, CS1000 | Loops, transactions, queries |
| G3 — Legacy | CA1000–CA1006, CA2014–CA2020, CA3001–CA3002, CA4000, BG1100 | Deprecated APIs, ISAM, console |
| G4 — Metadata | CA2000–CA2013, CA2021 | Direct SX* table access |
| G5 — Compilation | CA0000, CA1005, CA2016 | Syntax, encoding, I18N |

