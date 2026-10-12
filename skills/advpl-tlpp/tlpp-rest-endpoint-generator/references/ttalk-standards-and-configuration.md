# TTALK Standards, Configuration and Troubleshooting

TOTVS TTALK API standards, REST server configuration, and common troubleshooting scenarios.

---

## TOTVS TTALK API Standards

When building APIs that integrate with the TOTVS ecosystem, follow TTALK standards:

### Standard Response Format — Collection (GET List)

```json
{
  "hasNext": true,
  "items": [
    { "code": "000001", "name": "Customer A" },
    { "code": "000002", "name": "Customer B" }
  ],
  "remainingRecords": 48
}
```

### Standard Error Format

```json
{
  "code": "404",
  "message": "Resource not found",
  "detailedMessage": "Customer with code 000999 was not found in branch 01"
}
```

### Standard Query Parameters for Pagination

| Parameter  | Type      | Default | Description                      |
| ---------- | --------- | ------- | -------------------------------- |
| `page`     | Numeric   | 1       | Page number (1-based)            |
| `pageSize` | Numeric   | 20      | Items per page (max: 100)        |
| `order`    | Character | —       | Sort order (e.g., `name ASC`)    |
| `fields`   | Character | —       | Comma-separated fields to return |

### Standard HTTP Status Codes

| Code | Meaning               | When to Use                        |
| ---- | --------------------- | ---------------------------------- |
| 200  | OK                    | Successful GET, PUT, PATCH         |
| 201  | Created               | Successful POST (resource created) |
| 204  | No Content            | Successful DELETE                  |
| 400  | Bad Request           | Validation error, malformed JSON   |
| 401  | Unauthorized          | Missing or invalid authentication  |
| 404  | Not Found             | Resource does not exist            |
| 500  | Internal Server Error | Unhandled server exception         |

---

## REST Server Configuration

For the TLPP REST server to serve endpoints, the `appserver.ini` must include:

```ini
[HTTPREST]
Port=8282
URIs=HTTPURI

[HTTPURI]
URL=/api
PrepareIn=ALL
Instances=1,3
CORSAllowOrigin=*
```

> Swagger documentation is automatically served at `http://{server}:{port}/api/swagger/index.html` when endpoints are registered.

---

## Troubleshooting

- **Endpoint returns 404**: Verify the REST section is configured in `appserver.ini` with `URL=/api` and `PrepareIn=ALL`. The annotation path must match the request URL exactly.
- **Annotations not detected**: The `.tlpp` file must compile without errors into the RPO. Restart the AppServer after compiling — annotations are registered at server startup.
- **oRest object is NIL**: Ensure the endpoint is a `User Function` (or a class method) with the HTTP annotation (`@Get`, `@Post`, ...) immediately above it, declared without parameters. `oRest` is a global object available inside the annotated function, not an argument.
- **CORS errors in browser**: Add `CORSAllowOrigin=*` (or specific origins) to the `[HTTPURI]` section of `appserver.ini` (the same section shown in REST Server Configuration above).
- **500 error with no details**: Wrap endpoint logic in `Try-Catch` and return `oRest:setStatusResponse(500, errorJson)` in the catch block. Use `FWLogMsg()` to log errors and check the AppServer log for stack traces.
