# TLPP Migration Patterns

Detailed step-by-step migration examples for converting AdvPL code to TLPP.

## Step 1: File Extension and Includes

Change the file extension and update the include directive. The file extension change is **mandatory** — `#include "tlpp-core.th"` is only effective in `.tlpp` files.

```diff
- // myfile.prw
- #include "protheus.ch"
+ // myfile.tlpp
+ #include "tlpp-core.th"
+ #include "totvs.ch"
```

> **Note:** `totvs.ch` can coexist with `tlpp-core.th`. Keep it when using Protheus framework functions (MVC, FW\* classes, etc.). Remove it only if the source has no Protheus dependencies.

## Step 2: Add Namespace

Organize code into logical namespaces.

```diff
+ #include "tlpp-core.th"
  #include "totvs.ch"

+ Namespace company.module.feature
+
  User Function MyRoutine()
```

**Namespace conventions:**

- `company.module.feature` — e.g., `acme.finance.cashflow`
- Use lowercase, dot-separated tokens
- Group related functions and classes under the same namespace

## Step 3: Add Type Annotations

Add types to variables, parameters, and return values.

```diff
- User Function CalcTotal(cCustCode, nDiscount)
-   Local cName   := ""
-   Local nTotal  := 0
-   Local lFound  := .F.
-   Local dDate   := CToD("")
-   Local aItems  := {}
-   Local oModel  := Nil
+ User Function CalcTotal(cCustCode as Character, nDiscount as Numeric) as Numeric
+   Local cName   := "" as Character
+   Local nTotal  := 0 as Numeric
+   Local lFound  := .F. as Logical
+   Local dDate   := CToD("") as Date
+   Local aItems  := {} as Array
+   Local oModel  := Nil as Object
```

**TLPP type keywords:**
| Type | Keyword | Hungarian Prefix |
|------|---------|-----------------|
| Character/String | `Character` | `c` |
| Numeric | `Numeric` | `n` |
| Logical | `Logical` | `l` |
| Date | `Date` | `d` |
| Array | `Array` | `a` |
| Object | `Object` | `o` |
| Code Block | `CodeBlock` | `b` |
| JSON | `Json` | `j` |
| Variant (any) | `Variant` | `x` |

## Step 4: Replace ErrorBlock with Try-Catch

```diff
- // AdvPL: ErrorBlock pattern
- Local bOldError := ErrorBlock({|oErr| MyErrorHandler(oErr)})
- BEGIN SEQUENCE
-   nResult := DangerousOperation()
- RECOVER
-   nResult := 0
-   ConOut("Error occurred")
- END SEQUENCE
- ErrorBlock(bOldError)

+ // TLPP: Try-Catch pattern
+ Try
+   nResult := DangerousOperation()
+ Catch oError
+   nResult := 0
+   ConOut("[MyFunction] Error: " + oError:Description)
+ EndTry
```

**Key differences:**

- `Try-Catch` captures implicit exceptions (e.g., undefined class usage) without needing `BREAK`
- The caught object is of class `ErrorClass()` with properties: `Description`, `ErrorLine`, `ProcName`, etc.
- `ErrorBlock` still works in TLPP but `Try-Catch` is preferred for new code
- `Try-Catch` can call AdvPL functions that throw inside the `Try` block

## Step 5: Replace StaticCall with Direct Calls

`StaticCall` is **prohibited** in TLPP. Replace with `FWLoadMenuDef`, direct function calls, or Namespace-based references.

```diff
- // AdvPL: StaticCall for MenuDef
- aRotina := StaticCall(MATA010, MenuDef)

+ // TLPP: Use FWLoadMenuDef
+ aRotina := FWLoadMenuDef("MATA010")
```

```diff
- // AdvPL: StaticCall for ModelDef/ViewDef
- oModel := StaticCall(MATA010, ModelDef)
- oView  := StaticCall(MATA010, ViewDef)

+ // TLPP: Use FWLoadModel/FWLoadView
+ oModel := FWLoadModel("MATA010")
+ oView  := FWLoadView("MATA010")
```

```diff
- // AdvPL: StaticCall for custom static functions
- cResult := StaticCall(MYLIB, MyHelper, cParam1, nParam2)

+ // TLPP: Direct call via namespace (if migrated)
+ Using Namespace company.mylib
+ cResult := MyHelper(cParam1, nParam2)
```

## Step 6: Use Long Identifier Names

AdvPL limits identifiers to 10 characters. TLPP removes this restriction.

```diff
- Static Function PrcOrdCal()
-   Local cCodPrd := ""
-   Local nVlrTot := 0
-   Local nVlrDsc := 0

+ Static Function ProcessOrderCalculation() as Numeric
+   Local cProductCode  := "" as Character
+   Local nTotalValue   := 0 as Numeric
+   Local nDiscountValue := 0 as Numeric
```

> **Warning:** Only rename identifiers in TLPP files. Long names in `.prw` files will be silently truncated by the compiler to 10 characters, causing hard-to-debug issues.

## Step 7: Use Named Parameters

TLPP supports named parameters for better readability at call sites.

```diff
- // AdvPL: Positional parameters (easy to confuse)
- lResult := CreateDocument("NF", "001", .T., .F., 3)

+ // TLPP: Named parameters
+ lResult := CreateDocument(      ;
+   cDocType    := "NF",          ;
+   cBranch     := "001",         ;
+   lApproved   := .T.,           ;
+   lCancelled  := .F.,           ;
+   nCopies     := 3              ;
+ )
```

## Step 8: Use JSON Inline

TLPP supports native JSON object creation syntax.

```diff
- // AdvPL: Verbose JSON construction
- Local oJson := JsonObject():New()
- oJson["name"]    := "John"
- oJson["age"]     := 30
- oJson["active"]  := .T.
- oJson["address"] := JsonObject():New()
- oJson["address"]["city"]  := "São Paulo"
- oJson["address"]["state"] := "SP"

+ // TLPP: JSON inline (concise)
+ Local jData := {;
+   "name": "John",;
+   "age": 30,;
+   "active": .T.,;
+   "address": {;
+     "city": "São Paulo",;
+     "state": "SP";
+   };
+ } as Json
```

## Step 9: Add Class Access Modifiers

TLPP supports `Private`, `Protected`, and `Public` scoping for class members. If not specified, TLPP defaults to `Private` (unlike AdvPL where everything is Public).

```diff
- // AdvPL: All members are public
- Class TCustomer
-   Data cCode
-   Data cName
-   Data nBalance
-   Method New() Constructor
-   Method GetBalance()
-   Method SetBalance(nValue)
- EndClass

+ // TLPP: Encapsulated class with access modifiers
+ #include "tlpp-core.th"
+
+ Class TCustomer
+   Private Data cCode    as Character
+   Private Data cName    as Character
+   Private Data nBalance as Numeric
+
+   Public Method New(cCode as Character, cName as Character) as Object
+   Public Method GetBalance() as Numeric
+   Public Method SetBalance(nValue as Numeric) as Logical
+
+   Protected Method ValidateBalance(nValue as Numeric) as Logical
+ EndClass
```

## Step 10: Migrate WsRESTful to TLPP REST

```diff
- // AdvPL: WsRESTful legacy REST
- #include "protheus.ch"
- #include "restful.ch"
-
- WsRESTful Customers Description "Customer API"
-   WsData id as String
-
-   WsMethod GET Description "Get customer"
- End WsRESTful
-
- WsMethod GET WsRESTful Customers
-   Local cId := Self:id
-   // ... logic
-   Self:SetResponse(cJson)
- Return .T.

+ // TLPP: Annotation-based REST
+ #include "tlpp-core.th"
+
+ Namespace company.api.customers
+
+ @Get("/api/v1/customers/:id")
+ User Function getCustomer() as Logical
+   Local cId    := oRest:getPathParamsRequest()["id"] as Character
+   Local jResp  := JsonObject():New() as Json
+
+   // ... logic
+   jResp["id"]   := cId
+   jResp["name"] := GetCustomerName(cId)
+
+   oRest:setKeyHeaderResponse("Content-Type", "application/json")
+   oRest:setResponse(jResp:toJson())
+ Return oRest:setStatusResponse(200)
```

## Step 11: Fix Incorrect Inheritance (LongNameClass)

TLPP requires `LongNameClass` (not `LongClassName`) when using long class names in inheritance.

```diff
- // BAD: Incorrect inheritance keyword
- Class TMyChild From LongClassName TMyParent

+ // GOOD: Correct TLPP inheritance
+ Class TMyChild From LongNameClass TMyParent
```

## Step 12: Remove ISAM Driver Usage

ISAM drivers are deprecated. Migrate to `FWTemporaryTable` with relational mode.

```diff
- // BAD: ISAM driver usage
- cTmpFile := CriaTrab(Nil, .F.)
- DbCreate(cTmpFile, aStruct, "DBFCDXADS")
- DbUseArea(.T., "DBFCDXADS", cTmpFile, cAlias)

+ // GOOD: FWTemporaryTable with relational mode
+ Local oTempTable := FWTemporaryTable():New(cAlias)
+ oTempTable:SetFields(aStruct)
+ oTempTable:Create()
```

## Step 13: Migrate Console APIs to FWLogMsg

`ConOut()`, `OutErr()`, and `?` are prohibited. Use `FWLogMsg()` for all logging.

```diff
- // BAD: Console APIs
- ConOut("[MyFunction] Processing started")
- OutErr("Error occurred: " + cError)
- ? "Debug: nValue = " + cValToChar(nValue)

+ // GOOD: FWLogMsg
+ FWLogMsg("INFO", , "APP", "MyFunction", , "01", "Processing started", 0, 0, {})
+ FWLogMsg("ERROR", , "APP", "MyFunction", , "01", "Error occurred: " + cError, 0, 0, {})
+ FWLogMsg("DEBUG", , "APP", "MyFunction", , "01", "nValue = " + cValToChar(nValue), 0, 0, {})
```

## Step 14: Remove IIF Usage

`IIF()` is prohibited for clean code. Replace with explicit `If/Else/EndIf`.

```diff
- // BAD: IIF ternary
- cStatus := IIF(lActive, "Active", "Inactive")
- nDiscount := IIF(nTotal > 1000, 10, 0)

+ // GOOD: Explicit If/Else
+ If lActive
+   cStatus := "Active"
+ Else
+   cStatus := "Inactive"
+ EndIf
+
+ If nTotal > 1000
+   nDiscount := 10
+ Else
+   nDiscount := 0
+ EndIf
```

## Step 15: Migrate FormCommit Override to the MPFormModel bCommit Parameter

Direct override of the `FormCommit` method is prohibited. There is no `SetCommit()` method on the model object — pass the commit block as the 4th positional parameter (`bCommit`) of `MPFormModel():New()`, and call `FWFormCommit(oModel)` inside it for standard persistence.

```diff
- // BAD: Overriding FormCommit directly
- Method FormCommit(oModel) Class TMyModel
-   // custom logic
-   _Super:FormCommit(oModel)
- Return

+ // GOOD: Pass the commit block as the 4th positional parameter of
+ // MPFormModel():New() — there is no SetCommit() method in the Protheus
+ // MVC API. See the mvc-generator skill for the full verified signature.
+ // In ModelDef:
+ // oModel := MPFormModel():New(cModelId, bPreValid, bPosValid, {|oModel| MyCommitHandler(oModel)}, bCancel)
+
+ Static Function MyCommitHandler(oModel as Object) as Logical
+   // Pre-commit custom logic
+   FWFormCommit(oModel)  // Standard persistence
+   // Post-commit custom logic
+ Return .T.
```
