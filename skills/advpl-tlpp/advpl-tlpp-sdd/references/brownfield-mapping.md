# Brownfield Mapping — Protheus

**Trigger:** "Map codebase", "Analyze existing code", "Document current architecture"

**Purpose:** Understand the structure of an existing Protheus project before adding features.

## Process

Before starting, check whether the `codenavi` skill is available for code exploration (see Skill Integrations in SKILL.md). If available, prefer it for all the discovery and navigation tasks below.

**High-level approach:**

1. Explore the repository structure systematically (modules, extensions, `.PRJ` manifests)
2. Identify the stack via SIGAADVPL.INI, `.PRJ`, file extensions
3. Extract patterns from representative source samples (AdvPL vs. TLPP, MVC vs. legacy)
4. Document observed conventions and architectures
5. Catalog external integrations (REST, services, third-party APIs)
6. Identify concerns: tech debt, known bugs, security risks, performance bottlenecks

**Analysis depth:**

- Sample 5-10 representative files per category / per major module
- Focus on consistency and patterns, not exhaustive coverage
- Extract real examples, not assumptions

## Output: 7 Files in .specs/codebase/

---

### 1. STACK.md

**Purpose:** Document the tech stack and dependencies of the Protheus ecosystem.

**Size limit:** 2,000 tokens (~1,200 words)

**Extract from:**

- File extensions present (`.prw`, `.prg`, `.prx`, `.tlpp`)
- Build manifests (`.PRJ`)
- Configuration files (`SIGAADVPL.INI`, `appserver.ini`)
- AppServer/DBAccess version (if available in INI or logs)
- Test runtime (Python/TIR)

**Document:**

```markdown
# Tech Stack

**Analyzed on:** [date]

## Core Protheus

- AppServer: [version, if detected]
- DBAccess: [version, if detected]
- Main language: [AdvPL (.prw) / TLPP (.tlpp) / mixed]
- Database: [Oracle / SQL Server / Postgres — detect from INI]

## Identified Modules

| Module | Prefix | Sources (.prw) | Sources (.tlpp) | Notes |
|---|---|---|---|---|
| [e.g., Financial] | FINA | [N] | [N] | [e.g., partial migration to TLPP] |

## Build

- Compiler: RDMake (AppServer)
- Manifests: `.PRJ` listing sources per module
- Output: RPO (compiled `.O`)

## Tests

- TIR (e2e): [yes/no] — location: Testes/Automação Protheus/<Country>/<MODULE>/Scripts Web/
- Python version (TIR): [if detectable]
```

---

### 2. ARCHITECTURE.md

**Purpose:** Document architectural patterns and data flow in the Protheus project.

**Size limit:** 4,000 tokens (~2,400 words)

**Extract from:**

- Directory organization (modules, submodules)
- Code structure analysis (MVC, legacy Browse/AxCadastro, REST)
- Repeated patterns across files

**Document:**

```markdown
# Architecture

**Main pattern:** [MVC FWFormModel / legacy AxCadastro / mixed]

## High-Level Structure

[Description of per-module organization]

## Identified Patterns

### [Pattern Name] — e.g., MVC Model 1

**Location:** [modules or directories]
**Purpose:** [what this pattern implements]
**Implementation:** [how it's structured — ModelDef/ViewDef/MenuDef]
**Example:** [reference to real file/function]

### [Pattern Name] — e.g., REST Annotation

**Location:** [modules or directories]
**Purpose:** REST endpoints via @Get/@Post/...
**Example:** [reference to real file]

## Data Flow

### [Main flow — e.g., CRUD via MVC]

[Mapping of ModelDef → ViewDef → MenuDef → BrowseDef]

### [Flow — e.g., REST API]

[oRest → @Get/@Post → handler function → JSON response]

## Module Organization

**Approach:** [per business module / per layer]
**Structure:**
[Real directory tree]
```

---

### 3. CONVENTIONS.md

**Purpose:** Document the project's code and naming conventions.

**Size limit:** 3,000 tokens (~1,800 words)

**Extract from:**

- Analyzing 5-10 representative files per module
- Identifying consistent patterns
- Observing real conventions in use

**Document:**

```markdown
# Code Conventions

## Naming

**Source files:**
Pattern: `[PREFIX][NNN]` — e.g., `MATA010`, `FINA138`, `ATFA002`
Module prefix (4 chars) + sequential number (3 digits)

**Table fields:**
Pattern: `[ALIAS]_[FIELD]` — e.g., `A1_COD`, `E1_FILIAL`

**Variables (Hungarian Notation) — mandatory:**
| Prefix | Type | Example |
|---|---|---|
| `c` | Character | `cNome`, `cFilial` |
| `n` | Numeric | `nTotal`, `nQtd` |
| `l` | Logical | `lOk`, `lEncontrado` |
| `a` | Array | `aItems`, `aParams` |
| `o` | Object | `oModel`, `oView` |
| `d` | Date | `dVencto`, `dEmissao` |
| `b` | Codeblock | `bValid`, `bWhen` |
| `x` | Variant | `xRetorno` |
| `j` | JSON | `jBody`, `jResp` |

**Multilingual constants:** `STR0001` through `STR9999` defined in `.ch`

## Language in use in this project

[AdvPL predominant / TLPP predominant / Migration in progress]
[Notes on which language is used by module]

## Observed include pattern

[totvs.ch / tlpp-core.th + totvs.ch / other]
[examples from real files]

## Observed code style

[If/Else/EndIf vs IIF, error handling, etc.]
[real examples]
```

---

### 4. STRUCTURE.md

**Purpose:** Document directory layout and file organization in Protheus.

**Size limit:** 2,000 tokens (~1,200 words)

**Document:**

```markdown
# Project Structure

**Root:** [repository root path]

## Directory Tree (up to 3 levels)

[Visual tree of the real structure]

Expected standard Protheus structure:
Fontes_Doc/Master/Fontes/
  ├── <Module>/             → Sources of each module (e.g., Financeiro/, Compras/)
  │   └── *.prw, *.tlpp
  ├── *.PRJ                 → Build manifests per module
  └── Rdmake Padrao/        → RDMake compiler
Testes/Automação Protheus/<Country>/
  ├── <MODULE>/Scripts Web/ → TIR tests (Python) — e2e via Webapp
  └── <MODULE>/Dados/       → Test data

## Modules and Responsibilities

### [Module Name]

**Purpose:** [what this module manages]
**Location:** [relative path]
**Key files:** [main sources]

## Where things live

**[Capability/Feature]:**

- CRUD screens: [location]
- Business rules: [location]
- Entry Points: [location, if any]
- Tests: [location]
```

---

### 5. TESTING.md

**Purpose:** Document the testing infrastructure and patterns of the Protheus project.

**Size limit:** 4,000 tokens (~2,400 words)

**Document:**

```markdown
# Testing Infrastructure

## Test Frameworks

**TIR (e2e):** tir.Webapp (Python) — `.py` in Scripts Web/
**Coverage:** [if tracked]

## Test Organization

## Test Organization

**TIR:**
- Location: `Testes/Automação Protheus/<Country>/<MODULE>/Scripts Web/`
- Naming: [observed pattern]
- Structure: unittest.TestCase with setUpClass(), test_CTNNN(), tearDownClass()

## Observed Test Patterns

### TIR — e2e Tests

[Observed pattern: CRUD, grid, report, validation]
[Example from real file]

## Execution

## Execution

**TIR:** `python -m pytest <path>` or TIR runner

## Test Coverage Matrix

| Code Layer | Required Test Type | Location Pattern | Command |
|---|---|---|---|
| CRUD screen (UI) | TIR (e2e) | Scripts Web/ | [command] |

## Parallelism Assessment

| Test Type | Parallel-Safe? | Isolation Model |
|---|---|---|
| TIR | No (by default) | Shares SmartClient/Webapp session |

## Gate Check Commands

| Level | When to use | Command |
|---|---|---|
| Quick | After simple tasks | [compile] |
| Full | After tasks with TIR | [compile + TIR] |
| Build | After phase completion | [compile + SonarQube + TIR] |
```

---

### 6. INTEGRATIONS.md

**Purpose:** Document external integrations of the Protheus project.

**Size limit:** 5,000 tokens (~3,000 words)

**Document:**

```markdown
# External Integrations

## Exposed REST APIs

**Endpoint/Resource:** [e.g., /api/pedidos]
**File:** [source location]
**Authentication:** [Basic / JWT / Token]
**Pattern:** [@Get/@Post/... annotations — TLPP]

## Integrations with External Services

**Service:** [name]
**Purpose:** [what this integration provides]
**Implementation:** [where it lives in code]
**Configuration:** [how it's configured — MV_XXX parameter, .INI]

## System Parameters (GetMV/SuperGetMV)

| Parameter | Module | Purpose |
|---|---|---|
| MV_XXXX | [module] | [description] |

## Relevant Entry Points

| Entry Point (U_XXXX) | Module | Event | File |
|---|---|---|---|
```

---

### 7. CONCERNS.md

See [concerns.md](concerns.md) for the full process and template.

**Specific to Protheus — common concerns to look for:**

- SQL without `D_E_L_E_T_` or without branch filter
- `Function` used in customization code (should be `User Function` or `Static Function`)
- UI inside `Begin/End Transaction`
- `FwFreeObj()` / `FreeObj()` instead of `Destroy()`
- `ConOut()` / `?` for logging
- `%nolock%` / lock hints in embedded SQL (not translated — fails at runtime)
- Variables without Hungarian Notation
- `cFilial` used directly as a variable
- Code in UTF-8 not converted to CP-1252
- `static method` with parameters in the declaration (inside the `class` block)
- `.tlpp` files without `#include "tlpp-core.th"`
