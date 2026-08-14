# MVC Code Templates

Complete AdvPL/TLPP code templates for Protheus MVC screen generation. Use these as starting points and adapt to the specific table, fields, and business logic.

> **TLPP requirements:** Protheus **12.1.2410** or higher, Lib **20240520** or higher, source files with the `.tlpp` extension. Versions prior to 12.1.2410 do not support MVC in TLPP — use the legacy `.prw` / `Static Function` templates below instead.

---

## Table of Contents

- [What changes from AdvPL to TLPP?](#what-changes-from-advpl-to-tlpp)
- [Template: Single Entity (Modelo 1) — TLPP (Namespace)](#template-single-entity-modelo-1--tlpp-namespace)
- [Template: Single Entity (Modelo 1) — Legacy AdvPL (Static Function)](#template-single-entity-modelo-1--legacy-advpl-static-function)
- [Model Event Handlers](#model-event-handlers)
- [Template: Master-Detail (Modelo 3) — TLPP (Namespace)](#template-master-detail-modelo-3--tlpp-namespace)
- [Template: Master-Detail (Modelo 3) — Legacy AdvPL (Static Function)](#template-master-detail-modelo-3--legacy-advpl-static-function)
- [Master-Detail Validation and Commit Handlers](#master-detail-validation-and-commit-handlers)
- [Entry Points in TLPP](#entry-points-in-tlpp)
- [Migration Checklist: AdvPL → TLPP](#migration-checklist-advpl--tlpp)

---

## What changes from AdvPL to TLPP?

In legacy AdvPL (`.prw`), the MVC helper functions were **static** and identified by the source file name:

```advpl
// Legacy AdvPL (.prw) — identified by the file name
Static Function MenuDef()
Static Function ModelDef()
Static Function ViewDef()
```

In TLPP, **static functions no longer exist for this purpose**. The identifier becomes the **full namespace + main function name**. All helper functions become `User Function` (or `Function`):

```tlpp
// TLPP (.tlpp) — identified by the namespace
Namespace custom.mymodule.myroutine

User Function MenuDef() as Array
User Function ModelDef() as Object
User Function ViewDef()  as Object
```

### Impact on framework calls

| Context            | AdvPL (legacy)                | TLPP                                              |
|---------------------|-------------------------------|----------------------------------------------------|
| `FWLoadModel`       | `FWLoadModel("MYFUNC")`       | `FWLoadModel("custom.module.routine.MYFUNC")`      |
| `FWLoadView`        | `FWLoadView("MYFUNC")`        | `FWLoadView("custom.module.routine.MYFUNC")`       |
| `FWLoadMenuDef`     | `FWLoadMenuDef("MYFUNC")`     | `FWLoadMenuDef("custom.module.routine.MYFUNC")`    |
| Action in `MenuDef` | `"ViewDef.MYFUNC"`            | `"ViewDef.custom.module.routine.MYFUNC"`           |
| Entry points        | `ExecBlock("U_MYFUNC")`       | `ExecBlock("custom.module.routine.MYFUNC")`        |

> **General rule:** wherever the source file name used to go, now goes `namespace.mainFunctionName`.

Browse creation also prefers `FWMBrowse()` in TLPP sources over the legacy `FWFormBrowse()`/`FWBrowse()` classes, though both remain functional.

---

## Template: Single Entity (Modelo 1) — TLPP (Namespace)

A simple CRUD form for one table, with no grid (master-detail), using native TLPP syntax (namespace + `User Function`).

```tlpp
#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#include "tlpp-core.th"

Namespace custom.module.feature

//===================================================================
// Main Function — Browse screen
//===================================================================
User Function MYMOD01()
    Local oBrowse as Object

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZZ1")
    oBrowse:SetDescription("My Custom Registration")
    oBrowse:AddLegend("ZZ1_STATUS == '1'", "GREEN", "Active")
    oBrowse:AddLegend("ZZ1_STATUS == '2'", "RED",   "Inactive")
    oBrowse:Activate()

Return NIL

//===================================================================
// MenuDef — Available browse actions
// TLPP: User Function (no longer Static Function)
// Action: "ViewDef." + full namespace + "." + main function name
//===================================================================
User Function MenuDef() as Array
    Local aRotina := {} as Array

    Add Option aRotina Title "Incluir"    Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_INCLUIR  Access 0
    Add Option aRotina Title "Alterar"    Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_ALTERAR  Access 0
    Add Option aRotina Title "Excluir"    Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_EXCLUIR  Access 0
    Add Option aRotina Title "Visualizar" Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_VISUALIZAR Access 0
    Add Option aRotina Title "Copiar"     Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_COPIAR   Access 0
    Add Option aRotina Title "Imprimir"   Action "ViewDef.custom.module.feature.MYMOD01" Operation OP_IMPRIMIR Access 0

Return aRotina

//===================================================================
// ModelDef — Business rules and data structure
// TLPP: User Function (no longer Static Function)
//===================================================================
User Function ModelDef() as Object
    Local oModel    as Object
    Local oStruct   as Object

    // Load structure from the data dictionary (SX3)
    oStruct := FWFormStruct(1, "ZZ1")

    // Optional: remove fields not managed by the model
    // oStruct:RemoveField("ZZ1_XFIELD")

    // Optional: set field as non-editable
    // oStruct:SetProperty("ZZ1_STATUS", MODEL_FIELD_WHEN, FWBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

    // Optional: set initial value
    // oStruct:SetProperty("ZZ1_STATUS", MODEL_FIELD_INIT, FWBuildFeature(STRUCT_FEATURE_INIPAD, "'1'"))

    // Create the model
    oModel := MPFormModel():New("MYMOD01M")
    oModel:AddFields("ZZ1MASTER", /*cOwner*/, oStruct)
    oModel:SetDescription("My Custom Registration")
    oModel:SetPrimaryKey({})
    oModel:GetModel("ZZ1MASTER"):SetDescription("Registration Data")

    // Validations
    oModel:SetActivate({|oModel| OnModelActivate(oModel)})
    oModel:SetCommit({|oModel|   OnModelCommit(oModel)})
    oModel:SetVldActive({|oModel| OnModelValidate(oModel)})

Return oModel

//===================================================================
// ViewDef — Visual layout
// TLPP: User Function (no longer Static Function)
// FWLoadModel: receives the full namespace + main function name
//===================================================================
User Function ViewDef() as Object
    Local oView   as Object
    Local oModel  as Object
    Local oStruct as Object

    // TLPP: pass the full namespace + main function name
    oModel  := FWLoadModel("custom.module.feature.MYMOD01")
    oStruct := FWFormStruct(2, "ZZ1")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZZ1", oStruct, "ZZ1MASTER")
    oView:CreateHorizontalBox("BOXZZ1", 100)
    oView:SetOwnerView("VIEW_ZZ1", "BOXZZ1")

Return oView
```

---

## Template: Single Entity (Modelo 1) — Legacy AdvPL (Static Function)

Equivalent CRUD form using the legacy AdvPL pattern (`.prw`, `Static Function`, identified by the source file name). Use this template for versions prior to 12.1.2410 or when maintaining existing legacy sources.

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"
#include "fwmvcdef.ch"

//===================================================================
// Main Function — Browse screen
//===================================================================
User Function MYMOD01()
  Local oBrowse as Object

  oBrowse := FWFormBrowse():New()
  oBrowse:SetAlias("ZZ1")
  oBrowse:SetDescription("My Custom Registration")
  oBrowse:AddLegend("ZZ1_STATUS == '1'", "GREEN", "Active")
  oBrowse:AddLegend("ZZ1_STATUS == '2'", "RED",   "Inactive")
  oBrowse:Activate()
Return

//===================================================================
// ModelDef — Business rules and data structure
//===================================================================
Static Function ModelDef() as Object
  Local oModel    as Object
  Local oStruct   as Object

  // Load structure from data dictionary (SX3)
  oStruct := FWFormStruct(1, "ZZ1")

  // Optional: Remove fields not managed by the model
  // oStruct:RemoveField("ZZ1_XFIELD")

  // Optional: Set field as non-editable
  // oStruct:SetProperty("ZZ1_STATUS", MODEL_FIELD_WHEN, FWBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

  // Optional: Set initial value
  // oStruct:SetProperty("ZZ1_STATUS", MODEL_FIELD_INIT, FWBuildFeature(STRUCT_FEATURE_INIPAD, "'1'"))

  // Create the model
  oModel := MPFormModel():New("MYMOD01M")
  oModel:AddFields("ZZ1MASTER", /*cOwner*/, oStruct)
  oModel:SetDescription("My Custom Registration")
  oModel:SetPrimaryKey({})
  oModel:GetModel("ZZ1MASTER"):SetDescription("Registration Data")

  // Validations
  oModel:SetActivate({|oModel| OnModelActivate(oModel)})
  oModel:SetCommit({|oModel| OnModelCommit(oModel)})
  oModel:SetVldActive({|oModel| OnModelValidate(oModel)})

  // Field-level validation
  // oModel:AddCalc("ZZ1_FIELD", "ZZ1MASTER", "ZZ1_FIELD", {|oModel| ValidateField(oModel)})

Return oModel

//===================================================================
// ViewDef — Visual layout
//===================================================================
Static Function ViewDef() as Object
  Local oView   as Object
  Local oModel  as Object
  Local oStruct as Object

  // Load the model
  oModel := FWLoadModel("MYMOD01")

  // Load view structure from data dictionary
  oStruct := FWFormStruct(2, "ZZ1")

  // Create the view
  oView := FWFormView():New()
  oView:SetModel(oModel)
  oView:AddField("VIEW_ZZ1", oStruct, "ZZ1MASTER")
  oView:CreateHorizontalBox("BOXZZ1", 100)
  oView:SetOwnerView("VIEW_ZZ1", "BOXZZ1")

Return oView

//===================================================================
// MenuDef — Available actions
//===================================================================
Static Function MenuDef() as Array
  Local aMenu := {} as Array

  aAdd(aMenu, {"Include",   "VIEWDEF.MYMOD01", 0, 1, 0, Nil})
  aAdd(aMenu, {"Edit",      "VIEWDEF.MYMOD01", 0, 2, 0, Nil})
  aAdd(aMenu, {"Delete",    "VIEWDEF.MYMOD01", 0, 3, 0, Nil})
  aAdd(aMenu, {"View",      "VIEWDEF.MYMOD01", 0, 4, 0, Nil})
  aAdd(aMenu, {"Copy",      "VIEWDEF.MYMOD01", 0, 5, 0, Nil})

Return aMenu
```

---

## Model Event Handlers

Event handler functions for Single Entity (Modelo 1). They stay as `User Function` inside the same namespace in TLPP sources, or `Static Function` in legacy AdvPL sources:

```tlpp
//===================================================================
// Model Event Handlers (TLPP — same namespace, outside the main functions)
//===================================================================
User Function OnModelActivate(oModel as Object) as Logical
  // Called when the model is activated (screen opens)
Return .T.

User Function OnModelCommit(oModel as Object) as Logical
  // Called when the user confirms the operation
  // Custom post-save logic here
Return .T.

User Function OnModelValidate(oModel as Object) as Logical
  // Called before commit to validate the entire model
  Local lValid := .T. as Logical

  // Example: Validate required business rule
  If Empty(oModel:GetValue("ZZ1MASTER", "ZZ1_DESCR"))
    Help(,, "MYMOD01", , "Description is required", 1, 0)
    lValid := .F.
  EndIf

Return lValid
```

> In legacy AdvPL sources, replace `User Function` with `Static Function` for these handlers.

---

## Template: Master-Detail (Modelo 3) — TLPP (Namespace)

A form with header fields and a grid of detail items (e.g., invoice header + line items), using native TLPP syntax.

```tlpp
#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#include "tlpp-core.th"

Namespace custom.module.orders

//===================================================================
// Main Function — Browse screen
//===================================================================
User Function MYMOD03()
    Local oBrowse as Object

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZZ2")
    oBrowse:SetDescription("Orders Management")
    oBrowse:Activate()

Return NIL

//===================================================================
// MenuDef — Available browse actions
//===================================================================
User Function MenuDef() as Array
    Local aRotina := {} as Array

    Add Option aRotina Title "Incluir"    Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_INCLUIR  Access 0
    Add Option aRotina Title "Alterar"    Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_ALTERAR  Access 0
    Add Option aRotina Title "Excluir"    Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_EXCLUIR  Access 0
    Add Option aRotina Title "Visualizar" Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_VISUALIZAR Access 0
    Add Option aRotina Title "Copiar"     Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_COPIAR   Access 0
    Add Option aRotina Title "Imprimir"   Action "ViewDef.custom.module.orders.MYMOD03" Operation OP_IMPRIMIR Access 0

Return aRotina

//===================================================================
// ModelDef — Master-detail model
//===================================================================
User Function ModelDef() as Object
    Local oModel        as Object
    Local oStructMaster as Object
    Local oStructDetail as Object

    // Master structure (header)
    oStructMaster := FWFormStruct(1, "ZZ2")

    // Detail structure (items grid)
    oStructDetail := FWFormStruct(1, "ZZ3")
    // Optional: remove auto-generated fields from the grid
    // oStructDetail:RemoveField("ZZ3_ITEM")

    // Create the model
    oModel := MPFormModel():New("MYMOD03M")

    // Add master (form fields)
    oModel:AddFields("ZZ2MASTER", /*cOwner*/, oStructMaster)

    // Add detail (grid) linked to master
    oModel:AddGrid("ZZ3DETAIL", "ZZ2MASTER", oStructDetail)

    // Define the relationship between master and detail
    oModel:SetRelation("ZZ3DETAIL", {;
        {"ZZ3_FILIAL", "FWxFilial('ZZ3')"},;
        {"ZZ3_PEDIDO", "ZZ2_PEDIDO"};
    }, ZZ3->(IndexKey(1)))

    // Grid configuration
    oModel:GetModel("ZZ3DETAIL"):SetDescription("Order Items")
    oModel:GetModel("ZZ3DETAIL"):SetOptional(.F.)  // At least 1 item required

    // Automatic line numbering for the grid
    // oModel:GetModel("ZZ3DETAIL"):SetAutoIncField("ZZ3_ITEM", "01", "01")

    // Descriptions
    oModel:SetDescription("Orders Management")
    oModel:GetModel("ZZ2MASTER"):SetDescription("Order Header")
    oModel:SetPrimaryKey({})

    // Validations
    oModel:SetVldActive({|oModel| ValidateModel(oModel)})
    oModel:SetCommit({|oModel|   CommitModel(oModel)})

    // Grid line validation
    oModel:GetModel("ZZ3DETAIL"):SetVldLine({|oGridModel| ValidateGridLine(oGridModel)})

    // Grid line pre-event
    // oModel:GetModel("ZZ3DETAIL"):SetPreLine({|oGridModel, nLine, cAction| PreGridLine(oGridModel, nLine, cAction)})

Return oModel

//===================================================================
// ViewDef — Master-detail layout
//===================================================================
User Function ViewDef() as Object
    Local oView         as Object
    Local oModel        as Object
    Local oStructMaster as Object
    Local oStructDetail as Object

    // TLPP: pass the full namespace + main function name
    oModel := FWLoadModel("custom.module.orders.MYMOD03")

    oStructMaster := FWFormStruct(2, "ZZ2")
    oStructDetail := FWFormStruct(2, "ZZ3")

    oView := FWFormView():New()
    oView:SetModel(oModel)

    // Master fields (top 40% of screen)
    oView:AddField("VIEW_ZZ2", oStructMaster, "ZZ2MASTER")
    oView:CreateHorizontalBox("BOX_MASTER", 40)
    oView:SetOwnerView("VIEW_ZZ2", "BOX_MASTER")

    // Detail grid (bottom 60% of screen)
    oView:AddGrid("VIEW_ZZ3", oStructDetail, "ZZ3DETAIL")
    oView:CreateHorizontalBox("BOX_DETAIL", 60)
    oView:SetOwnerView("VIEW_ZZ3", "BOX_DETAIL")

    // Enable the grid item counter
    oView:EnableTitleView("VIEW_ZZ3", "Order Items")

Return oView
```

---

## Template: Master-Detail (Modelo 3) — Legacy AdvPL (Static Function)

Equivalent master-detail form using the legacy AdvPL pattern. Use for versions prior to 12.1.2410 or when maintaining existing legacy sources.

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"
#include "fwmvcdef.ch"

//===================================================================
// Main Function — Browse screen
//===================================================================
User Function MYMOD03()
  Local oBrowse as Object

  oBrowse := FWFormBrowse():New()
  oBrowse:SetAlias("ZZ2")
  oBrowse:SetDescription("Orders Management")
  oBrowse:Activate()
Return

//===================================================================
// ModelDef — Master-detail model
//===================================================================
Static Function ModelDef() as Object
  Local oModel       as Object
  Local oStructMaster as Object
  Local oStructDetail as Object

  // Master structure (header)
  oStructMaster := FWFormStruct(1, "ZZ2")

  // Detail structure (items grid)
  oStructDetail := FWFormStruct(1, "ZZ3")
  // Optional: Remove auto-generated fields from grid
  // oStructDetail:RemoveField("ZZ3_ITEM")

  // Create the model
  oModel := MPFormModel():New("MYMOD03M")

  // Add master (form fields)
  oModel:AddFields("ZZ2MASTER", /*cOwner*/, oStructMaster)

  // Add detail (grid) linked to master
  oModel:AddGrid("ZZ3DETAIL", "ZZ2MASTER", oStructDetail)

  // Define the relationship between master and detail
  oModel:SetRelation("ZZ3DETAIL", {;
    {"ZZ3_FILIAL", "FWxFilial('ZZ3')"},;
    {"ZZ3_PEDIDO", "ZZ2_PEDIDO"};
  }, ZZ3->(IndexKey(1)))

  // Configure grid
  oModel:GetModel("ZZ3DETAIL"):SetDescription("Order Items")
  oModel:GetModel("ZZ3DETAIL"):SetOptional(.F.)  // At least 1 item required

  // Automatic line numbering for grid
  // oModel:GetModel("ZZ3DETAIL"):SetAutoIncField("ZZ3_ITEM", "01", "01")

  // Model descriptions
  oModel:SetDescription("Orders Management")
  oModel:GetModel("ZZ2MASTER"):SetDescription("Order Header")
  oModel:SetPrimaryKey({})

  // Validations
  oModel:SetVldActive({|oModel| ValidateModel(oModel)})
  oModel:SetCommit({|oModel| CommitModel(oModel)})

  // Grid line validation
  oModel:GetModel("ZZ3DETAIL"):SetVldLine({|oGridModel| ValidateGridLine(oGridModel)})

  // Grid line pre-event
  // oModel:GetModel("ZZ3DETAIL"):SetPreLine({|oGridModel, nLine, cAction| PreGridLine(oGridModel, nLine, cAction)})

Return oModel

//===================================================================
// ViewDef — Master-detail layout
//===================================================================
Static Function ViewDef() as Object
  Local oView         as Object
  Local oModel        as Object
  Local oStructMaster as Object
  Local oStructDetail as Object

  oModel := FWLoadModel("MYMOD03")

  oStructMaster := FWFormStruct(2, "ZZ2")
  oStructDetail := FWFormStruct(2, "ZZ3")

  oView := FWFormView():New()
  oView:SetModel(oModel)

  // Master fields (top 40% of screen)
  oView:AddField("VIEW_ZZ2", oStructMaster, "ZZ2MASTER")
  oView:CreateHorizontalBox("BOX_MASTER", 40)
  oView:SetOwnerView("VIEW_ZZ2", "BOX_MASTER")

  // Detail grid (bottom 60% of screen)
  oView:AddGrid("VIEW_ZZ3", oStructDetail, "ZZ3DETAIL")
  oView:CreateHorizontalBox("BOX_DETAIL", 60)
  oView:SetOwnerView("VIEW_ZZ3", "BOX_DETAIL")

  // Enable grid item counter
  oView:EnableTitleView("VIEW_ZZ3", "Order Items")

Return oView

//===================================================================
// MenuDef — Available actions
//===================================================================
Static Function MenuDef() as Array
  Local aMenu := {} as Array

  aAdd(aMenu, {"Include",   "VIEWDEF.MYMOD03", 0, 1, 0, Nil})
  aAdd(aMenu, {"Edit",      "VIEWDEF.MYMOD03", 0, 2, 0, Nil})
  aAdd(aMenu, {"Delete",    "VIEWDEF.MYMOD03", 0, 3, 0, Nil})
  aAdd(aMenu, {"View",      "VIEWDEF.MYMOD03", 0, 4, 0, Nil})
  aAdd(aMenu, {"Copy",      "VIEWDEF.MYMOD03", 0, 5, 0, Nil})

Return aMenu
```

---

## Master-Detail Validation and Commit Handlers

```tlpp
//===================================================================
// Validation and Commit Handlers
// TLPP: User Function in the same namespace. Legacy AdvPL: Static Function.
//===================================================================
User Function ValidateModel(oModel as Object) as Logical
  Local lValid     := .T. as Logical
  Local oGridModel as Object
  Local nTotalQty  := 0 as Numeric
  Local nI         as Numeric

  // Validate master fields
  If Empty(oModel:GetValue("ZZ2MASTER", "ZZ2_CLIENT"))
    Help(,, "MYMOD03", , "Customer is required", 1, 0)
    Return .F.
  EndIf

  // Validate grid totals
  oGridModel := oModel:GetModel("ZZ3DETAIL")
  For nI := 1 To oGridModel:Length()
    oGridModel:GoLine(nI)
    If !oGridModel:IsDeleted()
      nTotalQty += oGridModel:GetValue("ZZ3_QUANT")
    EndIf
  Next nI

  If nTotalQty <= 0
    Help(,, "MYMOD03", , "Order must have items with positive quantity", 1, 0)
    lValid := .F.
  EndIf

Return lValid

User Function ValidateGridLine(oGridModel as Object) as Logical
  Local lValid := .T. as Logical

  If oGridModel:IsDeleted()
    Return .T.
  EndIf

  If Empty(oGridModel:GetValue("ZZ3_PRODUT"))
    Help(,, "MYMOD03", , "Product code is required on each line", 1, 0)
    lValid := .F.
  EndIf

  If oGridModel:GetValue("ZZ3_QUANT") <= 0
    Help(,, "MYMOD03", , "Quantity must be greater than zero", 1, 0)
    lValid := .F.
  EndIf

Return lValid

User Function CommitModel(oModel as Object) as Logical
  // FWFormCommit performs standard database persistence.
  // WARNING: Do NOT override the FormCommit method directly.
  // Use FWModelEvent to intercept commit behavior instead.
  FWFormCommit(oModel)

  // Post-commit custom logic (e.g., generate financial entries, update stock)
  // ...

Return .T.
```

---

## Entry Points in TLPP

With TLPP, entry points also use the namespace. The `U_` prefix is omitted:

```tlpp
//===================================================================
// Consuming a TLPP entry point from a Protheus source
//===================================================================
If ExistBlock("custom.module.feature.MYMOD01LOG")
    ExecBlock("custom.module.feature.MYMOD01LOG")
EndIf

//===================================================================
// Declaring the entry point in a custom source
//===================================================================
Namespace custom.module.feature

User Function MYMOD01LOG()
    // Entry point logic
Return
```

---

## Migration Checklist: AdvPL → TLPP

| Item                                | AdvPL (legacy `.prw`)                     | TLPP (`.tlpp` 12.1.2410+)                              |
|--------------------------------------|--------------------------------------------|----------------------------------------------------------|
| Namespace declaration                | Does not exist                             | `Namespace custom.module.routine` required at the top   |
| `MenuDef` / `ModelDef` / `ViewDef`    | `Static Function`                          | `User Function`                                          |
| `FWLoadModel`                         | `FWLoadModel("MYFUNC")`                    | `FWLoadModel("custom.module.routine.MYFUNC")`            |
| Action in `MenuDef`                   | `"ViewDef.MYFUNC"`                         | `"ViewDef.custom.module.routine.MYFUNC"`                 |
| Entry points                          | `ExecBlock("U_MYFUNC")`                    | `ExecBlock("custom.module.routine.MYFUNC")`               |
| REST include                          | `tlpp-rest.th` (only for REST APIs)        | Omit if not a REST API                                    |
| Browse                                | `FWMBrowse` or `FWBrowse`                  | Prefer `FWMBrowse`                                         |
| Variable typing                       | Optional                                   | Recommended (`as Object`, `as Array`, etc.)                |

> This checklist and the TLPP namespace templates above were contributed by GitHub user [@thiagosdealmeida](https://github.com/thiagosdealmeida).
