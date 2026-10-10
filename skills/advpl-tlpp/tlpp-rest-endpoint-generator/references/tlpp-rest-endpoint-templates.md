# TLPP REST Endpoint Templates

Complete CRUD endpoint templates and shared helper functions for TLPP REST APIs.

---

## GET — List Resources (with Pagination)

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace company.api.customers

//-------------------------------------------------------------------
// GET /api/v1/customers
// Description: List customers with pagination and filtering
// Query Params: page, pageSize, search
// Response: 200 OK with TTALK-compliant paginated response
//-------------------------------------------------------------------
@Get("/api/v1/customers")
User Function listCustomers() as Logical
  Local jQuery    := oRest:getQueryRequest() as Json
  Local nPage     := 1 as Numeric
  Local nPageSize := 20 as Numeric
  Local cSearch   := "" as Character
  Local cQuery    := "" as Character
  Local cAlias    := GetNextAlias() as Character
  Local jResponse := JsonObject():New() as Json
  Local jItems    := {} as Array
  Local nTotal    := 0 as Numeric
  Local cLike     := "" as Character
  Local oStatement as Object

  // Parse query parameters
  If jQuery <> Nil
    If jQuery["page"] <> Nil
      nPage := Val(cValToChar(jQuery["page"]))
    EndIf
    If jQuery["pageSize"] <> Nil
      nPageSize := Val(cValToChar(jQuery["pageSize"]))
    EndIf
    If jQuery["search"] <> Nil
      cSearch := jQuery["search"]
    EndIf
  EndIf

  // Build the LIKE pattern in ADVPL (concat operators differ across databases)
  If !Empty(cSearch)
    cLike := "%" + cSearch + "%"
  EndIf

  // Constrain pageSize
  nPageSize := Min(Max(nPageSize, 1), 100)

  // Build query
  cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_NREDUZ, A1_CGC "
  cQuery += "FROM " + RetSQLName("SA1") + " SA1 "
  cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
  cQuery += "AND SA1.A1_FILIAL = '" + FWxFilial("SA1") + "' "

  If !Empty(cSearch)
    cQuery += "AND (SA1.A1_NOME LIKE ? "
    cQuery += " OR SA1.A1_COD LIKE ?) "
  EndIf

  cQuery += "ORDER BY SA1.A1_COD, SA1.A1_LOJA "

  // Execute query using FWExecStatement to prevent SQL injection
  oStatement := FWExecStatement():New(ChangeQuery(cQuery))
  If !Empty(cSearch)
    oStatement:SetString(1, cLike)
    oStatement:SetString(2, cLike)
  EndIf

  // Count total
  nTotal := FWCountRows(oStatement:GetFixQuery())

  // Apply pagination
  cQuery := oStatement:GetFixQuery()
  cQuery += "OFFSET " + cValToChar((nPage - 1) * nPageSize) + " "
  cQuery += "ROWS FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY"

  Try
    DBUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
      aAdd(jItems, {;
        "code":      AllTrim((cAlias)->A1_COD),;
        "store":     AllTrim((cAlias)->A1_LOJA),;
        "name":      AllTrim((cAlias)->A1_NOME),;
        "shortName": AllTrim((cAlias)->A1_NREDUZ),;
        "taxId":     AllTrim((cAlias)->A1_CGC);
      })
      (cAlias)->(DBSkip())
    EndDo

    (cAlias)->(DBCloseArea())
  Catch oError
    FWLogMsg("ERROR", , "REST", "listCustomers", , "01", oError:Description, 0, 0, {})
    Return oRest:setStatusResponse(500, BuildErrorResponse("500", oError:Description))
  EndTry

  // TTALK standard response
  jResponse["hasNext"]  := (nPage * nPageSize) < nTotal
  jResponse["items"]    := jItems
  jResponse["remainingRecords"] := Max(nTotal - (nPage * nPageSize), 0)

  oRest:setKeyHeaderResponse("Content-Type", "application/json")
Return oRest:setStatusResponse(200, jResponse:toJson())
```

---

## GET — Single Resource by ID

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace company.api.customers

//-------------------------------------------------------------------
// GET /api/v1/customers/:code/:store
// Description: Get a single customer by code and store
// Path Params: code, store
// Response: 200 OK or 404 Not Found
//-------------------------------------------------------------------
@Get("/api/v1/customers/:code/:store")
User Function getCustomer() as Logical
  Local jParams  := oRest:getPathParamsRequest() as Json
  Local cCode    := jParams["code"] as Character
  Local cStore   := jParams["store"] as Character
  Local jResp    := JsonObject():New() as Json

  DbSelectArea("SA1")
  SA1->(DbSetOrder(1))  // A1_FILIAL + A1_COD + A1_LOJA

  If !SA1->(DbSeek(FWxFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1])))
    Return oRest:setStatusResponse(404, BuildErrorResponse("404", "Customer not found"))
  EndIf

  jResp["code"]      := AllTrim(SA1->A1_COD)
  jResp["store"]     := AllTrim(SA1->A1_LOJA)
  jResp["name"]      := AllTrim(SA1->A1_NOME)
  jResp["shortName"] := AllTrim(SA1->A1_NREDUZ)
  jResp["taxId"]     := AllTrim(SA1->A1_CGC)
  jResp["email"]     := AllTrim(SA1->A1_EMAIL)
  jResp["phone"]     := AllTrim(SA1->A1_TEL)

  oRest:setKeyHeaderResponse("Content-Type", "application/json")
Return oRest:setStatusResponse(200, jResp:toJson())
```

---

## POST — Create Resource

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace company.api.customers

//-------------------------------------------------------------------
// POST /api/v1/customers
// Description: Create a new customer
// Body: JSON with customer data
// Response: 201 Created or 400 Bad Request
//-------------------------------------------------------------------
@Post("/api/v1/customers")
User Function createCustomer() as Logical
  Local cBody   := oRest:getBodyRequest() as Character
  Local jBody   := JsonObject():New() as Json
  Local jResp   := JsonObject():New() as Json
  Local aErrors := {} as Array

  // Parse body
  If jBody:fromJson(cBody) <> Nil
    Return oRest:setStatusResponse(400, BuildErrorResponse("400", "Invalid JSON body"))
  EndIf

  // Validate required fields
  If Empty(jBody["name"])
    aAdd(aErrors, "Field 'name' is required")
  EndIf

  If Len(aErrors) > 0
    Return oRest:setStatusResponse(400, BuildValidationErrorResponse(aErrors))
  EndIf

  // Create customer using Protheus standard
  Try
    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    If RecLock("SA1", .T.)  // .T. = inclusion
      SA1->A1_FILIAL := FWxFilial("SA1")
      SA1->A1_COD    := GetSXENum("SA1", "A1_COD")
      SA1->A1_LOJA   := "01"
      SA1->A1_NOME   := PadR(jBody["name"], TamSX3("A1_NOME")[1])
      SA1->A1_NREDUZ := PadR(jBody:GetJsonText("shortName"), TamSX3("A1_NREDUZ")[1])
      SA1->A1_CGC    := PadR(jBody:GetJsonText("taxId"), TamSX3("A1_CGC")[1])
      SA1->A1_EMAIL  := PadR(jBody:GetJsonText("email"), TamSX3("A1_EMAIL")[1])
      SA1->(MsUnlock())
      ConfirmSX8()

      jResp["code"]  := AllTrim(SA1->A1_COD)
      jResp["store"] := AllTrim(SA1->A1_LOJA)
      jResp["name"]  := AllTrim(SA1->A1_NOME)
    EndIf
  Catch oError
    RollBackSX8()
    FWLogMsg("ERROR", , "REST", "createCustomer", , "01", oError:Description, 0, 0, {})
    Return oRest:setStatusResponse(500, BuildErrorResponse("500", oError:Description))
  EndTry

  oRest:setKeyHeaderResponse("Content-Type", "application/json")
Return oRest:setStatusResponse(201, jResp:toJson())
```

---

## PUT — Full Update

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace company.api.customers

//-------------------------------------------------------------------
// PUT /api/v1/customers/:code/:store
// Description: Full update of a customer
// Path Params: code, store
// Body: JSON with all customer fields
// Response: 200 OK, 404 Not Found, or 400 Bad Request
//-------------------------------------------------------------------
@Put("/api/v1/customers/:code/:store")
User Function updateCustomer() as Logical
  Local jParams := oRest:getPathParamsRequest() as Json
  Local cCode   := jParams["code"] as Character
  Local cStore  := jParams["store"] as Character
  Local cBody   := oRest:getBodyRequest() as Character
  Local jBody   := JsonObject():New() as Json

  If jBody:fromJson(cBody) <> Nil
    Return oRest:setStatusResponse(400, BuildErrorResponse("400", "Invalid JSON body"))
  EndIf

  DbSelectArea("SA1")
  SA1->(DbSetOrder(1))

  If !SA1->(DbSeek(FWxFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1])))
    Return oRest:setStatusResponse(404, BuildErrorResponse("404", "Customer not found"))
  EndIf

  Try
    If RecLock("SA1", .F.)  // .F. = update
      SA1->A1_NOME   := PadR(jBody["name"], TamSX3("A1_NOME")[1])
      SA1->A1_NREDUZ := PadR(jBody:GetJsonText("shortName"), TamSX3("A1_NREDUZ")[1])
      SA1->A1_CGC    := PadR(jBody:GetJsonText("taxId"), TamSX3("A1_CGC")[1])
      SA1->A1_EMAIL  := PadR(jBody:GetJsonText("email"), TamSX3("A1_EMAIL")[1])
      SA1->(MsUnlock())
    EndIf
  Catch oError
    FWLogMsg("ERROR", , "REST", "updateCustomer", , "01", oError:Description, 0, 0, {})
    Return oRest:setStatusResponse(500, BuildErrorResponse("500", oError:Description))
  EndTry

  oRest:setKeyHeaderResponse("Content-Type", "application/json")
Return oRest:setStatusResponse(200, '{"message":"Customer updated successfully"}')
```

---

## DELETE — Remove Resource

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace company.api.customers

//-------------------------------------------------------------------
// DELETE /api/v1/customers/:code/:store
// Description: Logically delete a customer
// Path Params: code, store
// Response: 204 No Content or 404 Not Found
//-------------------------------------------------------------------
@Delete("/api/v1/customers/:code/:store")
User Function deleteCustomer() as Logical
  Local jParams := oRest:getPathParamsRequest() as Json
  Local cCode   := jParams["code"] as Character
  Local cStore  := jParams["store"] as Character

  DbSelectArea("SA1")
  SA1->(DbSetOrder(1))

  If !SA1->(DbSeek(FWxFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1])))
    Return oRest:setStatusResponse(404, BuildErrorResponse("404", "Customer not found"))
  EndIf

  Try
    If RecLock("SA1", .F.)
      DBDelete()
      SA1->(MsUnlock())
    EndIf
  Catch oError
    FWLogMsg("ERROR", , "REST", "deleteCustomer", , "01", oError:Description, 0, 0, {})
    Return oRest:setStatusResponse(500, BuildErrorResponse("500", oError:Description))
  EndTry

Return oRest:setStatusResponse(204)
```

---

## Shared Helper Functions

Include these utility functions in your REST module:

```tlpp
#include "tlpp-core.th"

Namespace company.api.helpers

//-------------------------------------------------------------------
// Build a standard TTALK error response JSON string
//-------------------------------------------------------------------
Static Function BuildErrorResponse(cCode as Character, cMessage as Character) as Character
  Local jError := JsonObject():New() as Json

  jError["code"]        := cCode
  jError["message"]     := cMessage
  jError["detailedMessage"] := cMessage

Return jError:toJson()

//-------------------------------------------------------------------
// Build a validation error response with multiple messages
//-------------------------------------------------------------------
Static Function BuildValidationErrorResponse(aErrors as Array) as Character
  Local jResp   := JsonObject():New() as Json
  Local aDetails := {} as Array
  Local nI as Numeric

  jResp["code"]    := "400"
  jResp["message"] := "Validation failed"

  For nI := 1 To Len(aErrors)
    aAdd(aDetails, { "message": aErrors[nI] })
  Next nI

  jResp["details"] := aDetails

Return jResp:toJson()
```
