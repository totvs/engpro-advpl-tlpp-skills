# MVC Code Templates

Complete AdvPL/TLPP code templates for Protheus MVC screen generation. Use these as starting points and adapt to the specific table, fields, and business logic.

---

## Table of Contents

- [Template: Single Entity (Modelo 1)](#template-single-entity-modelo-1)
- [Template: Master-Detail (Modelo 3)](#template-master-detail-modelo-3)
- [Model Event Handlers](#model-event-handlers)
- [Master-Detail Validation and Commit Handlers](#master-detail-validation-and-commit-handlers)

---

## Template: Single Entity (Modelo 1)

A simple CRUD form for one table, with no grid (master-detail).

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"
#include "fwmvcdef.ch"

Namespace company.module.feature

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
  // bPreValid, bPosValid, and bCommit are passed positionally to MPFormModel():New() —
  // there are no SetActivate()/SetCommit()/SetVldActive() methods on the model object.
  oModel := MPFormModel():New("MYMOD01M", ;
    {|oModel| OnModelActivate(oModel)}, ;
    {|oModel| OnModelValidate(oModel)}, ;
    {|oModel| OnModelCommit(oModel)})
  oModel:AddFields("ZZ1MASTER", /*cOwner*/, oStruct)
  oModel:SetDescription("My Custom Registration")
  oModel:SetPrimaryKey({})
  oModel:GetModel("ZZ1MASTER"):SetDescription("Registration Data")

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

Event handler functions for Single Entity (Modelo 1):

```tlpp
//===================================================================
// Model Event Handlers
//===================================================================
Static Function OnModelActivate(oModel as Object) as Logical
  // Called when the model is activated (screen opens)
Return .T.

Static Function OnModelCommit(oModel as Object) as Logical
  // Called when the user confirms the operation
  // Custom post-save logic here
Return .T.

Static Function OnModelValidate(oModel as Object) as Logical
  // Called before commit to validate the entire model
  Local lValid := .T. as Logical

  // Example: Validate required business rule
  If Empty(oModel:GetValue("ZZ1MASTER", "ZZ1_DESCR"))
    Help(,, "MYMOD01", , "Description is required", 1, 0)
    lValid := .F.
  EndIf

Return lValid
```

---

## Template: Master-Detail (Modelo 3)

A form with header fields and a grid of detail items (e.g., invoice header + line items).

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"
#include "fwmvcdef.ch"

Namespace company.module.feature

//===================================================================
// Main Function — Browse screen
//===================================================================
User Function MYMOD03()
  Local oBrowse as Object

  oBrowse := FWMBrowse():New()
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
  // bPosValid and bCommit are passed positionally to MPFormModel():New() — there are no
  // SetVldActive()/SetCommit() methods on the model object.
  oModel := MPFormModel():New("MYMOD03M", , ;
    {|oModel| ValidateModel(oModel)}, ;
    {|oModel| CommitModel(oModel)})

  // Add master (form fields)
  oModel:AddFields("ZZ2MASTER", /*cOwner*/, oStructMaster)

  // Add detail (grid) linked to master.
  // Grid line validation is wired here too: AddGrid's 4th/5th positional params are
  // bPreLine (runs on SETVALUE/DELETE actions) and bPosLine (runs on line change,
  // equivalent to the old LinhaOk) — there is no SetVldLine()/SetPreLine() method.
  oModel:AddGrid("ZZ3DETAIL", "ZZ2MASTER", oStructDetail, , {|oGridModel| ValidateGridLine(oGridModel)})

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
//===================================================================
Static Function ValidateModel(oModel as Object) as Logical
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

Static Function ValidateGridLine(oGridModel as Object) as Logical
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

Static Function CommitModel(oModel as Object) as Logical
  // FWFormCommit performs standard database persistence
  // WARNING: Do NOT override a FormCommit method.
  // FWFormCommit(oModel) is the correct way to persist data.
  // This function itself is the interception point — it's passed as the bCommit
  // (4th positional) parameter of MPFormModel():New() above.
  FWFormCommit(oModel)

  // Post-commit custom logic (e.g., generate financial entries, update stock)
  // ...

Return .T.
```
