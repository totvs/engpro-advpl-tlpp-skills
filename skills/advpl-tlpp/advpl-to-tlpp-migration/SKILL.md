---
name: advpl-to-tlpp-migration
description: "Guide the migration of legacy AdvPL (Advanced Programming Language) code to modern TLPP (TOTVS Language Plus Plus). Covers feature comparison, syntax transformation, include/namespace adoption, typing, Try-Catch, REST migration, long identifiers, JSON inline, named parameters, access modifiers, and StaticCall removal. Use when user says 'migrate to TLPP', 'convert AdvPL', 'modernize .prw to .tlpp', 'add typing'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.1.0'
  category: Migration and Modernization
---

# AdvPL-to-TLPP Migration

## Overview

Migrate legacy AdvPL source files (`.prw`, `.prx`) to modern TLPP (`.tlpp`) incrementally and safely. TLPP is an evolution of AdvPL that introduces modern language features while maintaining full backward compatibility with existing AdvPL constructs. This skill provides a structured migration path that can be applied gradually — no forced rewrite is required.

## When to Use

Use this skill when:

- Modernizing legacy AdvPL code to TLPP
- Converting `.prw` files to `.tlpp`
- Adopting TLPP-exclusive features (typing, try-catch, namespace, etc.)
- Replacing prohibited constructs (e.g., `StaticCall`) in TLPP sources
- Preparing code for TLPP REST migration from WsRESTful
- Onboarding developers transitioning from AdvPL to TLPP

---

## Feature Comparison: AdvPL vs. TLPP

For the complete feature-by-feature comparison table (19 features covering scoping, control structures, typing, namespaces, Try-Catch, JSON inline, class modifiers, REST, and StaticCall status), see [advpl-tlpp-feature-comparison.md](references/advpl-tlpp-feature-comparison.md).

---

## Migration Process

> **MANDATORY RULE — File Extension:** Any source file that includes `#include "tlpp-core.th"` or uses TLPP-exclusive features **must** use the `.tlpp` extension. If a `.prw` or `.prx` file is being migrated or modified to adopt TLPP constructs, rename it to `.tlpp` as part of the same change. The AdvPL compiler silently ignores TLPP directives in `.prw`/`.prx` files, which leads to hard-to-diagnose failures. **Always change the extension first.**

The migration involves 15 steps, each addressing a specific AdvPL → TLPP transformation:

1. **File Extension and Includes** — `.prw` → `.tlpp`, add `#include "tlpp-core.th"`
2. **Add Namespace** — Organize code with `Namespace company.module.feature`
3. **Add Type Annotations** — Variables, parameters, return values (`as Type`)
4. **Replace ErrorBlock with Try-Catch** — Modern exception handling
5. **Replace StaticCall** — Use `FWLoadMenuDef`, `FWLoadModel`, namespace calls
6. **Use Long Identifier Names** — TLPP removes the 10-char limit
7. **Use Named Parameters** — Improve readability at call sites
8. **Use JSON Inline** — Replace `JsonObject():New()` chains
9. **Add Class Access Modifiers** — `Private`, `Protected`, `Public`
10. **Migrate WsRESTful to TLPP REST** — Annotation-based `@Get`, `@Post`, etc.
11. **Fix Incorrect Inheritance** — `LongNameClass` (not `LongClassName`)
12. **Remove ISAM Driver Usage** — Migrate to `FWTemporaryTable`
13. **Migrate Console APIs to FWLogMsg** — Replace `ConOut`, `OutErr`, `?`
14. **Remove IIF Usage** — Replace with `If/Else/EndIf`
15. **Migrate FormCommit Override to FWModelEvent** — Use `FWFormCommit(oModel)`

For complete before/after diff examples for all 15 steps, see [tlpp-migration-patterns.md](references/tlpp-migration-patterns.md).

---

## Migration Checklist

### Pre-Migration

- [ ] Source file is under version control with a clean commit
- [ ] Existing tests pass (or tests exist for the code)
- [ ] Dependencies on the file are identified (callers, includes)
- [ ] Team is aware of the migration (naming changes affect callers)

### File Transformation

- [ ] File extension changed from `.prw` to `.tlpp`
- [ ] `#include "tlpp-core.th"` added as the first include
- [ ] `Namespace` declaration added
- [ ] All `StaticCall()` replaced with direct calls or `FWLoad*` functions
- [ ] User Function return types added (`as Type`)
- [ ] Parameter types added (`as Type`)
- [ ] Variable types added (`as Type`)

### Modernization (Incremental)

- [ ] `ErrorBlock` patterns replaced with `Try-Catch` where appropriate
- [ ] Short identifier names expanded to descriptive names
- [ ] `Private` variable scope replaced with `Local` where possible
- [ ] Class access modifiers added (`Private`, `Protected`, `Public`)
- [ ] Named parameters used for functions with 3+ parameters
- [ ] JSON inline syntax used for JSON object construction
- [ ] WsRESTful services migrated to TLPP REST annotations
- [ ] `LongNameClass` used for inheritance (not `LongClassName`)
- [ ] ISAM drivers (`MSCREATE`, `DBCREATE`, `CRIATRAB`) replaced with `FWTemporaryTable`
- [ ] `ConOut()` / `OutErr()` / `?` replaced with `FWLogMsg()`
- [ ] `IIF()` replaced with `If/Else/EndIf` blocks
- [ ] `FormCommit` overrides migrated to `FWModelEvent` / `FWFormCommit(oModel)` pattern

> Refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

### Post-Migration

- [ ] Source compiles without errors
- [ ] All unit/integration tests pass
- [ ] Callers updated if function signatures changed
- [ ] RPO recompiled and tested in development environment
- [ ] No regression in existing functionality

---

## Common Migration Pitfalls

| Pitfall                                                 | Symptom                                                     | Resolution                                                         |
| ------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------ |
| Using `#include "tlpp-core.th"` in a `.prw`/`.prx` file | TLPP features silently ignored; unexpected runtime behavior | Rename the file to `.tlpp` before adding TLPP includes or features |
| Using long identifiers in `.prw` files                  | Silent truncation, wrong function calls                     | Only use long names in `.tlpp` files                               |
| `StaticCall` in `.tlpp` file                            | Compilation error                                           | Replace with `FWLoadMenuDef`, `FWLoadModel`, or namespace call     |
| Missing `#include "tlpp-core.th"`                       | TLPP features not recognized                                | Add as the first include                                           |
| Default access modifier changed                         | Class members inaccessible from outside                     | Explicitly add `Public` to members that need external access       |
| `Try-Catch` around non-TLPP calls                       | ErrorBlock still needed for pure AdvPL error flows          | Use `Try-Catch` regardless — it captures AdvPL throws too          |
| JSON inline without line continuations                  | Compilation error                                           | Use `;` at end of each line in JSON inline blocks                  |
| Access modifiers or `static` in method implementation   | Compilation error or unexpected behavior                    | Method implementations use bare `method` — NEVER `public method`, `static method`, etc. Modifiers are ONLY in the class declaration |

---

## Incremental Migration Strategy

Migration does not need to be all-or-nothing. Follow this priority order:

1. **Mandatory for TLPP:** File extension + `tlpp-core.th` include + remove `StaticCall`
2. **High value:** Add `Namespace` + type annotations (catches bugs at compile time)
3. **Medium value:** Replace `ErrorBlock` with `Try-Catch`, add class access modifiers, fix `LongNameClass` inheritance
4. **SonarQube compliance:** Remove `IIF`, `ConOut` → `FWLogMsg`, ISAM → `FWTemporaryTable`, `FormCommit` → `FWModelEvent`
5. **Nice to have:** Long identifiers, named parameters, JSON inline

> **AdvPL and TLPP coexist.** A `.tlpp` file can call AdvPL functions and vice versa. You don't need to migrate everything at once.

---

## Troubleshooting

- **`StaticCall` not compiling in TLPP**: `StaticCall` is prohibited in TLPP. Replace `StaticCall(TClass, Method, params)` with `TClass():Method(params)`.
- **Include conflicts after renaming to `.tlpp`**: Replace `#include "protheus.ch"` with `#include "tlpp-core.th"`. Add `#include "totvs.ch"` if the source uses Protheus framework functions. Do not keep `protheus.ch` — use `totvs.ch` instead.
- **Namespace resolution errors**: Ensure the `Namespace` declaration matches the directory structure and that callers use the fully qualified name or a `Using` directive.
- **Functions not found after migration**: AdvPL and TLPP can coexist. If a `.tlpp` file calls an AdvPL function, the AdvPL source must still be compiled in the RPO.
- **Type mismatch at compile time**: TLPP type annotations are strict. Ensure parameter types and return types match exactly — implicit conversions allowed in AdvPL may fail in TLPP.

