---
name: fwrest-client-generator
description: "Generate AdvPL/TLPP code that CONSUMES external REST APIs using the FWRest client class. Covers GET, POST, PUT, DELETE verbs, header construction, query/path parameters, JSON body serialization, authentication (No Auth, HTTP Basic, Bearer Token/JWT, OAuth 2.0), timeout, SSL, status code handling, error treatment, and TLPP try/catch patterns. Use when user says 'consume REST API', 'call external API', 'FWRest', 'oRestClient', 'integrate with third-party API', 'HTTP client AdvPL', 'POST JSON Protheus', 'Bearer token AdvPL'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.1.0'
  category: Code Generation
---

# FWRest Client Generator

## Overview

Generate production-ready AdvPL/TLPP code that **consumes** external REST APIs using the framework `FWRest` class. `FWRest` is the **HTTP client** class — it is the counterpart to the `@Get/@Post` annotation-based REST server (see `tlpp-rest-endpoint-generator` for *exposing* endpoints, not consuming them).

`FWRest` wraps low-level HTTP socket calls and supports the four standard verbs **GET, POST, PUT, DELETE** (no native PATCH support). It handles SSL automatically through `appserver.ini` socket configuration.

## When to Use

Use this skill when generating code that:

- Calls a third-party REST API from inside Protheus (integrations with CRMs, payment gateways, ERPs, government services, etc.)
- Sends JSON payloads to external services
- Pulls data from external endpoints into a Protheus routine
- Needs HTTP Basic, Bearer/JWT, or OAuth 2.0 authentication
- Replaces legacy `HTTPCGet` / `HTTPCPost` / `HTTPQuote` calls with the framework client

**Do NOT use** this skill for:

- Exposing endpoints from Protheus → use [`../tlpp-rest-endpoint-generator/SKILL.md`](../tlpp-rest-endpoint-generator/SKILL.md)
- Workstation-side HTTP calls that must run on the user's machine → use `HTTPCGet`/`HTTPCPost` with WebAgent
- File downloads from non-REST endpoints → use `HTTPQuote` or `WSDownload`

---

## FWRest Architecture

### Lifecycle

A typical FWRest call follows this five-step lifecycle:

1. **Instantiate** — `oClient := FWRest():New(cHost)` where `cHost` is the **base URL only** (scheme + host + optional port), e.g. `"https://api.example.com"`.
2. **Configure** — `SetPath()`, `SetPostParams()`, `SetGetParams()`, `SetTimeOut()`, `SetChkStatus()`, `SetLegacySuccess()`.
3. **Build headers** — Plain `Array` of `"Key: Value"` strings, e.g. `{"Content-Type: application/json", "Authorization: Bearer xyz"}`.
4. **Invoke verb** — `:Get(aHead)`, `:Post(aHead)`, `:Put(aHead, cBody)`, `:Delete(aHead, cBody)`. All return `.T.` on success.
5. **Read result** — `GetResult()` on success (response body as character), `GetLastError()` on failure, `GetHTTPCode()` for the numeric status.

### Path vs Query Parameters

| Concern | API | Example |
| --- | --- | --- |
| Path segments | `SetPath("/api/v1/customers/123")` | URL: `/api/v1/customers/123` |
| Query string (inline) | `SetPath("/api/v1/customers?page=1")` | URL: `/api/v1/customers?page=1` |
| Query string (separate) | `SetGetParams("page=1&size=20")` | Appended after path |
| GET param via verb | `:Get(aHead, "page=1")` | Appended after path |

> **Special characters in query values must be URI-encoded** via the `Escape()` function — otherwise the request will fail or be misinterpreted.

### Status Code Semantics

| Method | Behavior |
| --- | --- |
| `Get()` | Returns `.T.` only for HTTP **200** (legacy) or **200–299** (with `SetLegacySuccess(.F.)`) |
| `Post()` | Returns `.T.` for **200** or **201** (legacy) or **200–299** (with `SetLegacySuccess(.F.)`) |
| `Put()` / `Delete()` | Returns `.T.` for **200** or **201** (legacy) or **200–299** (with `SetLegacySuccess(.F.)`) |
| `SetChkStatus(.F.)` | Disables internal HTTP code validation — verb returns `.T.` if **the connection succeeded**, regardless of HTTP code. You then call `GetHTTPCode()` to decide. **Use this for APIs that return 204, 207, 3xx, or 4xx as part of the contract.** |

### No PATCH Support

`FWRest` does **not** support the PATCH verb. If the target API requires PATCH, generate code using `HTTPQuote()` instead and note this limitation explicitly.

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers the architecture, decision logic, and the generation checklist. Detailed method reference, code templates, and authentication patterns are in the `references/` directory — read them on demand based on the scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/fwrest-api-reference.md](references/fwrest-api-reference.md) | Looking up **exact method signatures**, **parameter types**, **minimum LIB version** per method, or behavior of `SetChkStatus`/`SetLegacySuccess`/`SetTimeOut`/`GetHTTPCode` | Complete `FWRest` method reference table with syntax, parameters, returns, LIB version requirements |
| [references/fwrest-client-templates.md](references/fwrest-client-templates.md) | Generating **any FWRest call** — GET, POST, PUT, DELETE, JSON parsing, error handling, file upload (.gz), header construction | Full code templates for all 4 HTTP verbs, JSON body construction, response parsing, generic error-handling wrapper |
| [references/fwrest-authentication-patterns.md](references/fwrest-authentication-patterns.md) | Implementing **HTTP Basic**, **Bearer Token / JWT**, **API Key**, or **OAuth 2.0 (client credentials / authorization code)** authentication | Header templates for each auth scheme, token-refresh pattern, secret storage guidance |

> Also refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Generation Workflow

### Step 1: Gather Requirements

Identify from the user's request:

- **Target API** — base URL, path, and HTTP verb(s)
- **Authentication scheme** — None, Basic, Bearer/JWT, API Key, or OAuth 2.0
- **Payload format** — JSON (default), XML, form-encoded, binary/gzip
- **Expected response codes** — only 2xx, or also 204/3xx/4xx as part of contract
- **Timeout requirement** — default 120s vs custom (e.g. webhook endpoints with 5s SLA)
- **Whether the call is part of a transaction** — affects error handling strategy

### Step 2: Load Templates

Read [references/fwrest-client-templates.md](references/fwrest-client-templates.md) for the verb-specific template. Combine with the auth header pattern from [references/fwrest-authentication-patterns.md](references/fwrest-authentication-patterns.md).

### Step 3: Pick the Status-Code Strategy

- **Standard CRUD** (200/201 only matter): leave defaults.
- **API uses full 2xx range** (e.g. 202 Accepted, 204 No Content): call `oClient:SetLegacySuccess(.F.)` (requires LIB 20240812+).
- **Need to read body of 4xx/5xx responses**: call `oClient:SetChkStatus(.F.)` and inspect `GetHTTPCode()` + `GetResult()` manually.

### Step 4: Wrap in Try/Catch + Logging

Wrap every FWRest invocation in a TLPP `Try/Catch` block. Log failures via `FWLogMsg()` including the URL, HTTP code, and the truncated response body. Never log secrets (tokens, passwords).

### Step 5: Validate Against Checklist

Use the checklist below to verify the generated code covers all requirements.

---

## FWRest Client Generation Checklist

### Structure

- [ ] `#include "totvs.ch"` (AdvPL) or `#include "tlpp-core.th"` (TLPP) present, in lowercase
- [ ] User Function declares `oClient`, `aHeader`, `cBody`, `cResponse`, `nHttpCode` as locals with explicit types (TLPP `as Object`, `as Array`, etc.)
- [ ] `FWRest():New(cHost)` receives ONLY the base URL — path is set via `SetPath()`

### Request Construction

- [ ] `SetPath()` called with leading `/`
- [ ] Query parameter values passed through `Escape()` when they may contain spaces or special chars
- [ ] Headers built as an `Array` of `"Key: Value"` strings (note the literal space after the colon)
- [ ] `Content-Type` header included for POST/PUT bodies (`application/json`, `application/xml`, etc.)
- [ ] Body serialized via `oJson:toJson()` — never built by string concatenation when the data is dynamic
- [ ] `SetPostParams(cBody)` called **before** `:Post()` (Post body is NOT a parameter of `:Post()`)
- [ ] PUT/DELETE bodies passed as the **second positional argument** of `:Put(aHead, cBody)` / `:Delete(aHead, cBody)`

### Authentication

- [ ] Secrets read from `GetMV()` parameter or environment, **never** hardcoded
- [ ] HTTP Basic: `"Authorization: Basic " + Encode64(cUser + ":" + cPass)`
- [ ] Bearer/JWT: `"Authorization: Bearer " + cToken`
- [ ] OAuth 2.0 token-acquisition call is a **separate FWRest call** to the auth server, cached for the token's `expires_in` window
- [ ] Token never logged or echoed in error responses

### Response Handling

- [ ] Verb result captured in a local `lOk` (e.g. `lOk := oClient:Post(aHeader)`)
- [ ] `GetHTTPCode()` retrieved into a local before any branching
- [ ] `GetResult()` parsed via `JsonObject():New() + :fromJson()` and the `fromJson()` return checked (returns `Nil` on success, error string otherwise)
- [ ] Failure branch reads `GetLastError()` AND `GetHTTPCode()` (both can be informative)

### Robustness

- [ ] `SetTimeOut()` set explicitly (default 120s is often too long for synchronous calls)
- [ ] Calls wrapped in `Try/Catch` to capture transport-layer exceptions
- [ ] `SetChkStatus(.F.)` used when the API returns 204/4xx as part of contract
- [ ] `SetLegacySuccess(.F.)` used when the API uses the full 2xx range
- [ ] `FreeObj(oClient)` after use in long-running routines to release the socket promptly

### Logging & Observability

- [ ] Successful calls logged at `INFO` level with URL + HTTP code (no body)
- [ ] Failed calls logged at `ERROR` level with URL + HTTP code + truncated response (max ~500 chars)
- [ ] `FWLogMsg("ERROR", , "REST_CLIENT", FunName(), , "01", cMessage, 0, 0, {})` pattern used
- [ ] No use of `ConOut()` for production logging (only acceptable in standalone smoke tests)
- [ ] No secrets, tokens, passwords, or full request bodies emitted to logs

### SonarQube Compliance

- [ ] No hardcoded passwords, tokens, or API keys in source code
- [ ] No `IIF()` — use `If/Else/EndIf` blocks
- [ ] `GetMV()` calls outside of loops
- [ ] No UI functions (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`) inside the call path of a transaction or scheduled job
- [ ] Includes in lowercase (e.g., `#include "totvs.ch"`)
- [ ] No use of `RpcSetEnv` inside REST endpoint handlers that themselves invoke FWRest — environment must already be prepared

> Refer to [references/sonarqube-rules-reference.md](https://github.com/totvs/engpro-advpl-tlpp-skills/blob/main/skills/advpl-tlpp/references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

---

## Common Pitfalls

| Pitfall | Symptom | Fix |
| --- | --- | --- |
| Full URL passed to `New()` | 404 or empty result | Pass only `https://host:port`; use `SetPath()` for the path |
| Body passed to `:Post()` as argument | Body ignored, empty POST sent | Use `SetPostParams(cBody)` before `:Post(aHead)` |
| 204 response hangs ~2 minutes | Slow integrations | Set `SetTimeOut(nSec)` to a small value, or use `HTTPQuote()` as alternative |
| Header missing space after colon | Server rejects request | Always write `"Key: Value"` with a space |
| Query string not escaped | Garbled parameters | Wrap values with `Escape()` |
| 4xx body unreadable | `GetResult()` returns empty | Call `SetChkStatus(.F.)` first; then read `GetResult()` even on failure |
| Hardcoded credentials | SonarQube blocker | Read from `GetMV("MV_XYZTOK",,"")` parameter |
| PATCH attempted | Compile error / no such method | FWRest does not support PATCH — use `HTTPQuote()` |
