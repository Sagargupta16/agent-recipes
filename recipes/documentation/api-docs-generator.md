# API Documentation Generator

> Generate OpenAPI/Swagger documentation from API source code by analyzing routes, handlers, validation schemas, and response patterns.

## When to Use

- When your API has no documentation or the docs are outdated
- When you need an OpenAPI spec for client SDK generation
- When onboarding new developers who need to understand the API
- When adding Swagger UI to an existing API project
- When migrating API documentation from ad-hoc docs to a standard format

## The Prompt

```
You are an API documentation specialist. Analyze the API source code and generate a complete OpenAPI 3.0 specification. Extract all information from the actual code: routes, HTTP methods, request/response schemas, authentication requirements, and error responses. Do not invent endpoints or fields that don't exist in the code.

## ANALYSIS PHASE

Examine the codebase for:

1. **Route definitions** - Express router files, FastAPI decorators, Spring annotations, Go handlers, etc.
2. **Request validation** - Joi, Zod, Pydantic, class-validator schemas, or manual validation logic
3. **Response structures** - What objects are returned in successful responses
4. **Error handling** - Error response formats, status codes, error messages
5. **Authentication** - Middleware, decorators, or guards that enforce auth
6. **Middleware** - Rate limiting, CORS, request parsing, logging

## OPENAPI SPECIFICATION REQUIREMENTS

### Info Section
- Extract name, version, and description from package.json / pyproject.toml or equivalent
- Add a clear description of what the API does

### Server Section
- List environments from configuration (development, staging, production)
- Use environment variable placeholders for URLs

### Security Schemes
- Detect authentication methods from middleware/decorators:
  - Bearer token (JWT) -> securitySchemes with bearerAuth
  - API key (header or query) -> securitySchemes with apiKey
  - OAuth2 -> securitySchemes with oauth2 flows
  - Cookie-based -> securitySchemes with apiKey in cookie
- Apply security at the operation level (not globally) if some routes are public

### Path Definitions
For each route, document:

**Operation:**
- HTTP method and path
- operationId (derived from handler function name)
- summary (one line, from code comments or function name)
- description (detailed, from docstrings or JSDoc)
- tags (group by resource: users, orders, products)

**Parameters:**
- Path parameters with types: `/users/{userId}` -> `userId: string (UUID format)`
- Query parameters: pagination (page, limit, offset), filters, sort, search
- Include required/optional, default values, and enum constraints
- Add descriptions and examples for every parameter

**Request Body:**
- Extract schema from validation library (Joi schema, Zod schema, Pydantic model)
- Include all fields with types, required/optional, constraints (min, max, pattern)
- Add realistic examples that would pass validation
- Document content types (application/json, multipart/form-data, etc.)

**Responses:**
- 200/201: Success response with full schema
- 400: Validation error response (extract format from error handler)
- 401: Unauthorized (if route requires auth)
- 403: Forbidden (if route has role-based access)
- 404: Not found (for routes with path parameters)
- 409: Conflict (for create operations that can have duplicates)
- 422: Unprocessable entity (if used instead of 400)
- 429: Rate limited (if rate limiting middleware exists)
- 500: Internal server error (generic format)

For each response, include the schema and a realistic example.

### Component Schemas
- Extract reusable schemas from models, types, and validation schemas
- Use `$ref` to reference shared schemas instead of duplicating
- Document all model properties with types, formats, descriptions, and examples
- Use proper OpenAPI types: string (with format: date-time, email, uuid, uri), integer, number, boolean, array, object

### Examples
- Provide complete request/response examples for every endpoint
- Use realistic data (real names, plausible emails, UUIDs, timestamps)
- Show examples for error responses too

## OUTPUT FORMAT

Generate:
1. The complete OpenAPI 3.0 YAML specification
2. A summary of all endpoints found with their HTTP methods
3. A list of any ambiguities or assumptions made (e.g., "Response schema for GET /users inferred from the User model since no explicit response type was defined")
4. Suggestions for improving the API (missing error handling, inconsistent response formats, undocumented behavior)
```

## Example

### Input

"Generate OpenAPI documentation for this Express.js API. Routes are in `src/routes/`, validation schemas in `src/schemas/`, and models in `src/models/`."

### Output

```yaml
openapi: 3.0.3
info:
  title: Acme Store API
  version: 2.1.0
  description: |
    REST API for the Acme Store e-commerce platform. Provides endpoints
    for managing users, products, orders, and payments.

servers:
  - url: http://localhost:3000/api/v2
    description: Development
  - url: https://api.acme-store.com/v2
    description: Production

security:
  - bearerAuth: []

paths:
  /users:
    post:
      operationId: createUser
      summary: Register a new user account
      tags: [Users]
      security: []  # Public endpoint
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            example:
              email: "jane.doe@example.com"
              password: "Str0ng!Pass#2024"
              name: "Jane Doe"
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'
              example:
                id: "550e8400-e29b-41d4-a716-446655440000"
                email: "jane.doe@example.com"
                name: "Jane Doe"
                createdAt: "2025-01-15T10:30:00Z"
        '400':
          $ref: '#/components/responses/ValidationError'
        '409':
          description: Email already registered
          content:
            application/json:
              example:
                error: "CONFLICT"
                message: "A user with this email already exists"

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    CreateUserRequest:
      type: object
      required: [email, password, name]
      properties:
        email:
          type: string
          format: email
          description: User's email address (must be unique)
          example: "jane.doe@example.com"
        password:
          type: string
          format: password
          minLength: 8
          description: "Must contain uppercase, lowercase, number, and special character"
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: User's display name

    UserResponse:
      type: object
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
        createdAt:
          type: string
          format: date-time
# ... continued for all endpoints
```

## Customization Tips

- **For GraphQL APIs**, change the approach: "Instead of OpenAPI, generate a documented GraphQL schema (SDL) with descriptions on every type, field, query, mutation, and argument. Include example queries and mutations."
- **For gRPC APIs**, change the approach: "Generate or enhance the .proto file with comments on every service, RPC, and message. Include example request/response payloads as comments."
- **For internal APIs**, add: "Include a section on authentication setup (how to get a token), rate limits per endpoint, and common error troubleshooting."
- **To generate Postman collection**, add: "Also generate a Postman Collection v2.1 JSON file with pre-configured requests, environment variables, and test scripts for each endpoint."
- **For API versioning**, add: "Document which version each endpoint belongs to. Note breaking changes between versions. Include deprecation notices with migration instructions."

## Tags

`documentation` `api` `openapi` `swagger` `rest` `technical-writing`
