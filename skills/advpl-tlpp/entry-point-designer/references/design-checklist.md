# Entry Point Design Checklist

Use this checklist before delivering any Entry Point implementation.

## Interface Design

- [ ] PARAMIXB layout is fully documented (position, type, description, example value)
- [ ] Return type and its effect on the standard routine are documented
- [ ] The entry point trigger moment is clearly identified (before validation, after save, during grid processing, etc.)

## Defensive Programming

- [ ] PARAMIXB existence is checked (`Type("PARAMIXB") == "A"`)
- [ ] PARAMIXB length is validated before accessing elements
- [ ] Parameter types are validated before use
- [ ] Error handling prevents the entry point from crashing the standard routine
- [ ] Default return value is fail-safe (does not block the standard flow)

## Code Quality

- [ ] `/*/{Protheus.doc}` block present na `User Function` com `@type user function`, `@author`, `@since`, `@return` e `@obs`
- [ ] `/*/{Protheus.doc}` block presente em cada `Static Function` helper com `@param` e `@return`
- [ ] Business logic is extracted to `Static Function` helpers
- [ ] Function name **does NOT** have the `U_` prefix — e.g., `User Function MT410INC()`, never `User Function U_MT410INC()`
- [ ] File name matches the Entry Point name exactly — e.g., `MT410INC.tlpp` or `MT410INC.prw` — **no** namespace-based or compound file naming
- [ ] Variables use `Local` scope (not `Private`)
- [ ] TLPP type annotations are present (if `.tlpp` file)
- [ ] Header comment block includes: EP name, routine, description, PARAMIXB layout, return type

## Testing

- [ ] Entry Point tested with all expected PARAMIXB variations
- [ ] Tested with empty/nil PARAMIXB (defensive case)
- [ ] Return values verified in all code paths
- [ ] Side effects (database writes, API calls) tested independently

## SonarQube Compliance

- [ ] Error handling uses `Try-Catch` exclusively — **never** use `ErrorBlock` in Entry Points
- [ ] No `StaticCall()` — use `FWLoadModel()`, `FWLoadMenuDef()`, or namespace-based calls
- [ ] Entry Points triggered during transactions (Before Save, After Save) do **NOT** call UI functions (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`)
- [ ] No assignment to `__cUserID` or `cEmpAnt`
- [ ] No `IIF()` — use `If/Else/EndIf` blocks
- [ ] `GetMV()` / `ExistBlock()` results cached before use in loops
- [ ] Logging via `FWLogMsg()`, not `ConOut()`

> For the complete SonarQube rules reference, see [sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md).
