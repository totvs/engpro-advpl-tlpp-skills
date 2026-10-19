---
name: tlpp-rest-endpoint-generator
description: "Generate TLPP REST endpoints using annotation-based routing (@Get, @Post, @Put, @Patch, @Delete) with the oRest object. Follows TOTVS API standards (TTALK) including pagination, error model, standard headers, and Swagger documentation. Use when user says 'create REST endpoint', 'TLPP REST', '@Get annotation', 'oRest endpoint'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Generation
---

# TLPP REST Endpoint Generator

## Overview

Generate production-ready TLPP REST endpoints using the native annotation-based REST framework. TLPP REST replaces the legacy WsRESTful pattern with a simpler, annotation-driven approach. Each endpoint is a function decorated with an HTTP verb annotation and uses the global `oRest` object to handle requests and responses.

## When to Use

Use this skill when:

- Creating new REST API endpoints in TLPP
- Implementing TOTVS TTALK-compliant APIs
- Generating CRUD endpoints for Protheus entities
- Building integration APIs for external systems
- Migrating WsRESTful services to TLPP REST

---

## TLPP REST Architecture

### How It Works

1. A function is annotated with an HTTP verb annotation (e.g., `@Get("/path")`)
2. The TLPP REST Server automatically registers the route at startup via annotation scanning
3. When a request matches the route, the annotated function is invoked
4. The function uses the global `oRest` object to read the request and write the response
5. Swagger/OpenAPI documentation is generated automatically from the annotations

### Available Annotations

| Annotation            | HTTP Verb | Typical Use                  |
| --------------------- | --------- | ---------------------------- |
| `@Get("endpoint")`    | GET       | Retrieve resource(s)         |
| `@Post("endpoint")`   | POST      | Create a new resource        |
| `@Put("endpoint")`    | PUT       | Full update of a resource    |
| `@Patch("endpoint")`  | PATCH     | Partial update of a resource |
| `@Delete("endpoint")` | DELETE    | Remove a resource            |

**Annotation properties:**

- `endpoint` (required): The URI path for the route
- `description` (optional): Description shown in Swagger docs

```tlpp
// Minimal form (endpoint only)
@Get("/api/v1/customers")

// Full form (named properties)
@Get(endpoint="/api/v1/customers", description="List all customers")
```

---

## The oRest Object

The `oRest` object is a global object available inside any annotated REST function. It provides all methods for reading requests and writing responses.

### Request Methods

| Method                         | Returns   | Description                            |
| ------------------------------ | --------- | -------------------------------------- |
| `oRest:getQueryRequest()`      | Json      | Query string parameters (`?key=value`) |
| `oRest:getBodyRequest()`       | Character | Raw request body as string             |
| `oRest:getPathParamsRequest()` | Json      | Path parameters (e.g., `:id`)          |
| `oRest:getHeaderRequest()`     | Json      | All request headers                    |
| `oRest:getClientIP()`          | Character | Client IP address                      |

### Response Methods

| Method                                        | Parameters           | Description                                               |
| --------------------------------------------- | -------------------- | --------------------------------------------------------- |
| `oRest:setResponse(cBody)`                    | Character            | Set response body (concatenates if called multiple times) |
| `oRest:setStatusResponse(nCode, cBody)`       | Numeric, Character   | Set HTTP status code and body; returns Logical            |
| `oRest:setKeyHeaderResponse(cKey, cValue)`    | Character, Character | Set a response header                                     |
| `oRest:updateKeyHeaderResponse(cKey, cValue)` | Character, Character | Update an existing response header                        |
| `oRest:resetResponse()`                       | —                    | Clear the response body                                   |
| `oRest:getBodyResponse()`                     | —                    | Get current response body                                 |

### Path Parameters

Use `:paramName` syntax in the endpoint path to define path parameters:

```tlpp
@Get("/api/v1/customers/:id")
User Function getCustomer() as Logical
  Local jPathParams := oRest:getPathParamsRequest() as Json
  Local cId := jPathParams["id"] as Character
  // ...
Return oRest:setStatusResponse(200, cResponse)
```

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers the architecture, decision logic, and the generation checklist. Detailed endpoint templates, TTALK standards, and troubleshooting are in the `references/` directory — read them on demand based on the scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/tlpp-rest-endpoint-templates.md](references/tlpp-rest-endpoint-templates.md) | Generating **any CRUD endpoint** — GET list (paginated), GET by ID, POST, PUT, or DELETE | Full code templates for all 5 HTTP verbs, shared helper functions (`BuildErrorResponse`, `BuildValidationErrorResponse`) |
| [references/ttalk-standards-and-configuration.md](references/ttalk-standards-and-configuration.md) | Checking **TTALK response formats**, **HTTP status codes**, **REST server `appserver.ini` configuration**, or **debugging endpoint issues** | TTALK collection/error JSON formats, pagination query parameters, status code table, `appserver.ini` REST section, troubleshooting guide |

> Also refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Endpoint Generation Workflow

### Step 1: Gather Requirements

Determine from the user's request:

- Which HTTP verb(s) to generate (GET, POST, PUT, PATCH, DELETE, or full CRUD)
- The target Protheus entity/table (e.g., SA1 = Customers, SA2 = Suppliers)
- The endpoint base path (e.g., `/api/v1/customers`)
- Whether TTALK-compliant pagination is needed (collection endpoints)

### Step 2: Load Templates

Read [references/tlpp-rest-endpoint-templates.md](references/tlpp-rest-endpoint-templates.md) for the code templates matching the required verb(s). Adapt the templates to the target entity by replacing table aliases, field names, and namespace.

### Step 3: Apply TTALK Standards

For TOTVS-ecosystem APIs, read [references/ttalk-standards-and-configuration.md](references/ttalk-standards-and-configuration.md) to ensure responses follow the standard collection format, error model, and HTTP status codes.

### Step 4: Validate Against Checklist

Use the checklist below to verify the generated code covers all requirements.

---

## Endpoint Generation Checklist

### Structure

- [ ] `#include "tlpp-core.th"` is the first include
- [ ] `Namespace` declaration matches project convention
- [ ] User Function name is descriptive and uses camelCase
- [ ] HTTP verb annotation matches the operation semantics
- [ ] Endpoint path follows RESTful conventions (`/api/v1/{resource}`)
- [ ] Path parameters use `:paramName` syntax

### Request Handling

- [ ] Body parsed and validated for POST/PUT/PATCH
- [ ] Path parameters extracted via `oRest:getPathParamsRequest()`
- [ ] Query parameters extracted via `oRest:getQueryRequest()`
- [ ] Input sanitized before use in SQL queries (`FWExecStatement`)

### Response

- [ ] `Content-Type` header set to `application/json`
- [ ] Correct HTTP status code used
- [ ] Success response follows TTALK format
- [ ] Error response follows TTALK error model
- [ ] Collection endpoints include pagination (`hasNext`, `items`, `remainingRecords`)

### Data Access

- [ ] Workarea positioned correctly before read/write
- [ ] Database locks acquired with `RecLock()` and released with `MsUnlock()`
- [ ] `D_E_L_E_T_` filter always included in queries
- [ ] Branch filter (`FWxFilial`) always included
- [ ] Temporary aliases closed with `DBCloseArea()`
- [ ] SQL injection prevented (`FWExecStatement`)

### Error Handling

- [ ] `Try-Catch` wraps database operations
- [ ] Errors logged with `FWLogMsg()` including function context
- [ ] Error responses use TTALK error format
- [ ] Lock failures handled gracefully

### Security

- [ ] Authentication verified (if applicable)
- [ ] Authorization checked for the operation
- [ ] Input validated against expected types and ranges
- [ ] No sensitive data in error messages

### SonarQube Compliance

- [ ] No `RpcSetEnv` / `RpcSetType` calls in REST endpoint functions — use REST Server `PrepareIn` configuration instead
- [ ] No assignment to `__cUserID` or `cEmpAnt` — these are protected system variables
- [ ] No `StaticCall()` — use `FWLoadModel()`, `FWLoadMenuDef()`, or namespace-based calls
- [ ] No hardcoded passwords or credentials in source code
- [ ] `FWExecStatement` used for all queries with dynamic parameters
- [ ] Logging via `FWLogMsg()`, not `ConOut()`
- [ ] No `IIF()` — use `If/Else/EndIf` blocks
- [ ] `GetMV()` / `ExistBlock()` calls moved outside of loops
- [ ] No UI functions (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`) inside transaction-scoped handlers
- [ ] Includes in lowercase (e.g., `#include "totvs.ch"`)

> Refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

