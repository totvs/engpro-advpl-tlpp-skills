# PARAMIXB & Return Types Reference

## PARAMIXB Documentation Format

Document each PARAMIXB parameter using this standard table. Include it in the header comment block of the Entry Point source file and in any design document.

| Position | Type | Description | Example Value |
|---|---|---|---|
| [1] | Character | Customer code being processed | `"000001"` |
| [2] | Character | Store code | `"01"` |
| [3] | Logical | Indicates if it's an inclusion operation | `.T.` |
| [4] | Object | FWFormModel object (MVC screens) | `oModel` |

> Adapt positions, types, descriptions, and example values to match the specific Entry Point.

---

## Common Return Types

| Return Type | Typical Use |
|---|---|
| `Logical (.T./.F.)` | Approve/reject an action (e.g., allow inclusion, validate deletion) |
| `Array` | Return modified data (e.g., additional fields, modified grid data) |
| `Character` | Return modified query, filter expression, or message |
| `Numeric` | Return a calculated value |
| `Nil` | Entry Point has no return effect (side-effect only) |

---

## Common Entry Point Categories

| Category | Example EPs | Typical PARAMIXB | Notes |
|---|---|---|---|
| **Before Validation** | `MT010INC`, `FA080BUT` | Form fields, model object | |
| **After Validation** | `A010TOK` | Validation result, field values | |
| **Before Save** | `MT100GRV` | Header/item data arrays | Executes inside transaction — **never** call UI functions here |
| **After Save** | `MT100APP` | Document number, saved data | Executes inside transaction — **never** call UI functions here |
| **Before Delete** | `MT010DEL` | Record data | |
| **Grid Processing** | `MT100LIN` | Line number, grid data | |
| **Report Filter** | `MT580FIL` | Filter expression | |
| **Menu Extension** | `FA080BUT` | Button array | |

---

## Naming Convention Reference

Entry Point names are defined by TOTVS in the standard routines and typically follow the pattern `<routine_context>` or `<module><action>`:

| Entry Point | Standard Routine | Module | Trigger Moment |
|---|---|---|---|
| `MT010INC` | MATA010 | SIGAFAT | Before inclusion |
| `A010TOK` | MATA010 | SIGAFAT | After SB1 (product) inclusion validation |
| `FA080BUT` | FATA080 | SIGAFIN | Button rendering |
| `MT100GRV` | MATA100 | SIGAFAT | Before save (inside transaction) |
| `MT100APP` | MATA100 | SIGAFAT | After save (inside transaction) |
