# Troubleshooting

## Entry Point not triggered

The function name must match the expected EP name **exactly** (spelling and any `U_` prefix; ADVPL function names are not case-sensitive). Verify:
1. No `U_` prefix in the `User Function` declaration
2. The EP name exists for the standard routine version currently in use
3. The source file was compiled and is present in the RPO

## PARAMIXB is NIL or empty

Not all Entry Points pass parameters. Check the TDN documentation for the specific EP to confirm which parameters are available and their positions. Always guard with:

```advpl
If Type("PARAMIXB") == "A" .And. Len(PARAMIXB) >= {expected_count}
```

## Entry Point crashes the standard routine

Always wrap EP logic in `Try-Catch`. An unhandled error in an EP propagates up and can abort the entire standard operation. The `Catch` block must return the fail-safe default value.

## Return value ignored

Some EPs require a specific return type (e.g., `.T.`/`.F.` for validation EPs). If the return type is wrong, the standard routine may ignore it silently. Confirm the expected return type in TDN for the specific EP.

## EP works in one environment but not another

Check:
- RPO build: the compiled file may not be deployed in the target environment
- Protheus version: some EPs are version-specific; confirm the EP exists in the target release
- Module: Entry Points are module-specific. An EP registered for SIGAFIN will not fire in SIGAFAT even if the function name is identical

## UI function call inside a transactional EP causes lock or crash

Entry Points triggered during transactions (Before Save, After Save) must **never** call UI functions (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`). Move any user interaction to a non-transactional EP (e.g., Before Validation) or use `FWLogMsg()` for logging only.
