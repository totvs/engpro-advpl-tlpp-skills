---
name: refactor
description: "Surgical code refactoring to improve maintainability without changing behavior. Covers extracting functions, renaming variables, breaking down god functions, improving type safety, eliminating code smells, and applying design patterns. Less drastic than repo-rebuilder; use for gradual improvements. Use when user says 'refactor this code', 'extract function', 'reduce complexity', 'code smells'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Quality and Review
---

# Refactor

## Overview

Improve code structure and readability without changing external behavior. Refactoring is gradual evolution, not revolution. Use this for improving existing code, not rewriting from scratch.

## When to Use

Use this skill when:

- Code is hard to understand or maintain
- Functions/classes are too large
- Code smells need addressing
- Adding features is difficult due to code structure
- User asks "clean up this code", "refactor this", "improve this"

---

## Refactoring Principles

### The Golden Rules

1. **Behavior is preserved** - Refactoring doesn't change what the code does, only how
2. **Small steps** - Make tiny changes, test after each
3. **Version control is your friend** - Commit before and after each safe state
4. **Tests are essential** - Without tests, you're not refactoring, you're editing
5. **One thing at a time** - Don't mix refactoring with feature changes

### When NOT to Refactor

```
- Code that works and won't change again (if it ain't broke...)
- Critical production code without tests (add tests first)
- When you're under a tight deadline
- "Just because" - need a clear purpose
```

---

## Common Code Smells

Identify and fix these common code smells. See [references/code-smells-and-patterns.md](references/code-smells-and-patterns.md) for detailed before/after examples.

| #   | Smell                           | Fix                                                                         |
| --- | ------------------------------- | --------------------------------------------------------------------------- |
| 1   | Long Method/Function            | Break into focused functions                                                |
| 2   | Duplicated Code                 | Extract common logic                                                        |
| 3   | Large Class/Module              | Single responsibility per class                                             |
| 4   | Long Parameter List             | Group into parameter objects or use builder                                 |
| 5   | Feature Envy                    | Move logic to the object that owns the data                                 |
| 6   | Primitive Obsession             | Use domain types                                                            |
| 7   | Magic Numbers/Strings           | Named constants                                                             |
| 8   | Nested Conditionals             | Guard clauses / early returns                                               |
| 9   | Dead Code                       | Remove it (git has history)                                                 |
| 10  | Inappropriate Intimacy          | Ask, don't tell — use encapsulation                                         |
| 11  | IIF Usage                       | Replace `IIF()` / `IF()` with `If/Else/EndIf` for clarity and testability   |
| 12  | API Calls in Loops              | Move `GetMV()`, `ExistBlock()`, `Type()` out of loops — cache before loop   |
| 13  | UI in Transactions              | Never call `MsgAlert`, `MsgYesNo`, `Aviso`, `Help` inside transaction scope |
| 14  | SQL Injection via Concatenation | Replace string concatenation in queries with `FWExecStatement`          |
| 15  | ISAM Driver Usage               | Migrate `MSCREATE`, `DBCREATE`, `CRIATRAB` to `FWTemporaryTable`            |

## Refactoring Techniques

Detailed examples in [references/code-smells-and-patterns.md](references/code-smells-and-patterns.md):

- **Extract Method** — Turn code fragments into focused methods
- **Introduce Type Safety** — Add types to parameters, returns, and variables
- **Strategy Pattern** — Replace conditional logic with polymorphism
- **Chain of Responsibility** — Replace nested validation with composable validators

---

## Refactoring Steps

### Safe Refactoring Process

```
1. PREPARE
   - Ensure tests exist (write them if missing)
   - Commit current state
   - Create feature branch

2. IDENTIFY
   - Find the code smell to address
   - Understand what the code does
   - Plan the refactoring

3. REFACTOR (small steps)
   - Make one small change
   - Run tests
   - Commit if tests pass
   - Repeat

4. VERIFY
   - All tests pass
   - Manual testing if needed
   - Performance unchanged or improved

5. CLEAN UP
   - Update comments
   - Update documentation
   - Final commit
```

---

## Refactoring Checklist

### Code Quality

- [ ] Functions are small (< 50 lines)
- [ ] Functions do one thing
- [ ] No duplicated code
- [ ] Descriptive names (variables, functions, classes)
- [ ] No magic numbers/strings
- [ ] Dead code removed

### Structure

- [ ] Related code is together
- [ ] Clear module boundaries
- [ ] Dependencies flow in one direction
- [ ] No circular dependencies

### Type Safety

- [ ] Types defined for all public APIs
- [ ] No `any` types without justification
- [ ] Nullable types explicitly marked

### Testing

- [ ] Refactored code is tested
- [ ] Tests cover edge cases
- [ ] All tests pass

---

## Common Refactoring Operations

| Operation                                     | Description                           |
| --------------------------------------------- | ------------------------------------- |
| Extract Method                                | Turn code fragment into method        |
| Extract Class                                 | Move behavior to new class            |
| Extract Interface                             | Create interface from implementation  |
| Inline Method                                 | Move method body back to caller       |
| Inline Class                                  | Move class behavior to caller         |
| Pull Up Method                                | Move method to superclass             |
| Push Down Method                              | Move method to subclass               |
| Rename Method/Variable                        | Improve clarity                       |
| Introduce Parameter Object                    | Group related parameters              |
| Replace Conditional with Polymorphism         | Use polymorphism instead of switch/if |
| Replace Magic Number with Constant            | Named constants                       |
| Decompose Conditional                         | Break complex conditions              |
| Consolidate Conditional                       | Combine duplicate conditions          |
| Replace Nested Conditional with Guard Clauses | Early returns                         |
| Introduce Null Object                         | Eliminate null checks                 |
| Replace Type Code with Class/Enum             | Strong typing                         |
| Replace Inheritance with Delegation           | Composition over inheritance          |

---

## AdvPL/TLPP Refactoring Patterns

When refactoring AdvPL or TLPP source files (`.prw`, `.tlpp`, `.prx`, `.th`), apply the general principles above **plus** these ecosystem-specific patterns.

> **File Extension Rule:** If a refactoring introduces `#include "tlpp-core.th"` or any TLPP-exclusive feature (typing, Try-Catch, Namespace, etc.), the file **must** be renamed from `.prw`/`.prx` to `.tlpp`. TLPP directives are silently ignored in non-`.tlpp` files.

### Variable Scope Tightening

Replace `Private` variables with `Local` wherever the variable is not intentionally shared with called functions. `Private` leaks into every function on the call stack; `Local` does not.

```diff
// BAD: Private leaks into every called function
- User Function ProcessOrder()
-   Private cOrder := ""
-   Private nTotal := 0
-   Private lOk    := .T.
-   // ... business logic ...
- Return

// GOOD: Local variables stay in scope
+ User Function ProcessOrder()
+   Local cOrder := "" as Character
+   Local nTotal := 0  as Numeric
+   Local lOk    := .T. as Logical
+   // ... business logic ...
+ Return
```

### Extract Static Functions from Monolithic User Functions

Protheus legacy routines commonly pack hundreds of lines into a single `User Function`. Extract cohesive blocks into `Static Function` helpers.

```diff
// BAD: Monolithic Function (300+ lines)
- User Function FINA010()
-   // 60 lines: header validation
-   // 80 lines: item processing
-   // 50 lines: tax calculation
-   // 40 lines: ledger posting
-   // 70 lines: notification
- Return

// GOOD: Decomposed into focused Static Functions
+ User Function FINA010()
+   Local lOk as Logical
+   lOk := ValidateHeader()
+   If lOk
+     lOk := ProcessItems()
+   EndIf
+   If lOk
+     lOk := CalculateTaxes()
+   EndIf
+   If lOk
+     lOk := PostToLedger()
+   EndIf
+   If lOk
+     SendNotifications()
+   EndIf
+ Return
+
+ Static Function ValidateHeader() as Logical
+   // focused header validation
+ Return lRet
+
+ Static Function ProcessItems() as Logical
+   // focused item processing
+ Return lRet
```

### Add TLPP Type Annotations

TLPP supports compile-time type checking. Add type annotations to variables, parameters, and return values to catch mismatches early.

```diff
// BAD: Untyped parameters and return (AdvPL legacy style)
- Static Function CalcTotal(cClient, aItems)
-   Local nTotal := 0
-   // ...
- Return nTotal

// GOOD: Fully typed (TLPP)
+ Static Function CalcTotal(cClient as Character, aItems as Array) as Numeric
+   Local nTotal := 0 as Numeric
+   Local nI     := 0 as Numeric
+   For nI := 1 To Len(aItems)
+     nTotal += aItems[nI][2] * aItems[nI][3]  // qty * price
+   Next nI
+ Return nTotal
```

### Replace ErrorBlock with Try-Catch (TLPP)

TLPP provides structured exception handling. Replace legacy `ErrorBlock` / `BEGIN SEQUENCE` patterns.

```diff
// BAD: AdvPL error handling with ErrorBlock
- Local bError := ErrorBlock({|e| DefError(e)})
- BEGIN SEQUENCE
-   // risky operation
- END SEQUENCE
- ErrorBlock(bError)

// GOOD: TLPP Try-Catch
+ Try
+   // risky operation
+ Catch oError
+   FWLogMsg("ERROR", , "APP", "MyFunction", , "01", oError:Description, 0, 0, {})
+   // handle or re-throw
+ EndTry
```

### Eliminate Macro-Execution Where Possible

Macro-execution (`&cExpr`) is a common source of injection risk and hard-to-debug behavior. Replace with safer alternatives.

```diff
// BAD: Macro-execution for dynamic field access
- cField := "SA1->A1_NOME"
- xValue := &(cField)

// GOOD: FieldGet / indirect access
+ cAlias := "SA1"
+ cField := "A1_NOME"
+ xValue := (cAlias)->(FieldGet(FieldPos(cField)))
```

### Replace StaticCall with Direct Method Calls (TLPP)

`StaticCall` is prohibited in TLPP. Convert to direct static method invocation.

```diff
// BAD: AdvPL StaticCall (not allowed in TLPP)
- xResult := StaticCall(TMyClass, MyMethod, cParam)

// GOOD: TLPP direct static method call
+ xResult := TMyClass():MyMethod(cParam)
```

### Workarea / Database Access Safety

Ensure every database write is wrapped in proper lock/unlock, and workareas are selected before use.

```diff
// BAD: Missing DbSelectArea and RecLock
- DbSetOrder(1)
- DbSeek(cKey)
- SA1->A1_NOME := cNewName
- MsUnlock()

// GOOD: Proper workarea selection and locking
+ DbSelectArea("SA1")
+ DbSetOrder(1)
+ If DbSeek(cKey)
+   If RecLock("SA1", .F.)
+     SA1->A1_NOME := cNewName
+     MsUnlock()
+   EndIf
+ EndIf
```

### Replace Obsolete Includes with totvs.ch

Legacy include files are obsolete and must be replaced with `totvs.ch`. The old includes are consolidated into `totvs.ch`, which provides all definitions.

```diff
// BAD: Legacy obsolete includes
- #include "protheus.ch"
- #include "Ap5Mail.ch"
- #include "ApWizard.ch"
- #include "FileIO.ch"
- #include "Font.ch"
- #include "ParmType.ch"
- #include "RWMake.ch"

// GOOD: Single modern include
+ #include "totvs.ch"
```

| Obsolete Include | Modern Class/API |
|---|---|
| `Ap5Mail.ch` | `TMailMessage()` |
| `ApWizard.ch` | `FWWizardControl()` |
| `FileIO.ch` | `FWFileWriter()` / `FWFileReader()` |
| `Font.ch` | `TFont()` |
| `ParmType.ch` | `Default` prefix for parameter handling |
| `protheus.ch` | — (general Protheus definitions) |
| `RWMake.ch` | — (legacy compatibility) |

### Add Namespace Declarations (TLPP)

TLPP supports namespaces for modular code organization. Add them to new or migrated code.

```diff
// BAD: TLPP source without namespace (global scope pollution)
- #include "tlpp-core.th"
- Static Function Helper()
-   // ...
- Return

// GOOD: Namespaced TLPP source
+ #include "tlpp-core.th"
+ Namespace finance.receivable
+
+ Static Function Helper() as Logical
+   // ...
+ Return .T.
```

### AdvPL/TLPP Refactoring Checklist

| Check           | Description                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------- |
| Scope           | All `Private` variables reviewed — changed to `Local` unless intentionally shared                                     |
| Typing          | TLPP sources have type annotations on variables, parameters, and returns                                              |
| Function size   | No `User Function` exceeds ~80 lines; excess extracted to `Static Function`                                           |
| Error handling  | TLPP code uses `Try-Catch` instead of `ErrorBlock`                                                                    |
| Macro-execution | `&(cExpr)` eliminated or justified with a comment                                                                     |
| StaticCall      | Converted to direct static method calls in TLPP                                                                       |
| Workarea safety | Database operations use `DbSelectArea`, `RecLock`, `MsUnlock`                                                         |
| Namespaces      | TLPP sources declare a `Namespace`                                                                                    |
| Includes        | Correct headers: `totvs.ch` (AdvPL) or `tlpp-core.th` (TLPP)                                                       |
| File extension  | Files using `#include "tlpp-core.th"` or TLPP features must have `.tlpp` extension — rename `.prw`/`.prx` accordingly |
| Logging         | `FWLogMsg()` used instead of `ConOut()` / `OutErr()` / `?`                                                            |
| IIF             | All `IIF()` / `IF()` inline replaced with `If/Else/EndIf` blocks                                                      |
| SQL Safety      | Dynamic SQL values use `FWExecStatement`, not string concatenation                                                |
| ISAM            | `MSCREATE` / `DBCREATE` / `CRIATRAB` migrated to `FWTemporaryTable`                                                   |

> Refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.
