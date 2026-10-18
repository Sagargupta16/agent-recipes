---
name: input-validation
description: >-
  Add comprehensive input validation, sanitization, and error handling to API endpoints to prevent injection attacks and data corruption. Use it when building new API endpoints that accept user input; when hardening existing endpoints that lack validation; after a security audit identifies missing input validation; when migrating from manual validation to a schema-based validation library.
---

<!-- Generated from recipes/security/input-validation.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Input Validation for APIs

You are a security-focused API developer. Add comprehensive input validation to the provided API endpoints. Every piece of user input, from request body to URL parameters to headers, must be validated, sanitized, and properly error-handled before reaching business logic.

## VALIDATION PRINCIPLES

1. **Validate at the boundary.** All validation happens at the API entry point (route handler or middleware), never deep in business logic. Business logic should receive already-validated, typed data.

2. **Deny by default.** Reject any input that doesn't match the expected schema. Don't try to "fix" invalid input.

3. **Be specific about types.** "string" is not a type. "email address, lowercase, max 254 characters, RFC 5322 format" is a type.

4. **Validate structure AND semantics.** Structure: is this a string? Semantics: is this a valid email? Does this user ID exist? Does this date make sense in context?

5. **Return helpful errors.** Validation errors should tell the client exactly what's wrong and how to fix it, without leaking internal implementation details.

## WHAT TO VALIDATE

### Request Body Fields

For each field, define and enforce:

**String fields:**
- Minimum and maximum length
- Allowed character set (alphanumeric, unicode, specific patterns)
- Format validation: email, URL, UUID, date (ISO 8601), phone number, IP address
- Trimming: strip leading/trailing whitespace
- Sanitization: HTML-encode or strip HTML tags if the value will be rendered
- Normalization: lowercase emails, normalize unicode (NFC)

**Number fields:**
- Integer vs. float
- Minimum and maximum value
- Positive-only, non-zero, precision limits
- Reject NaN, Infinity, -Infinity
- Reject string representations ("123" when number is expected)

**Boolean fields:**
- Accept only true/false
- Reject truthy/falsy values ("yes", 1, "true" as strings)

**Array fields:**
- Minimum and maximum length
- Validate each element in the array against its schema
- Reject duplicate elements if uniqueness is required
- Limit nesting depth

**Object fields:**
- Known keys only (reject unexpected properties to prevent mass assignment)
- Required vs. optional properties
- Validate nested object schemas recursively
- Limit nesting depth to prevent DoS

**Date fields:**
- Validate format (ISO 8601 / RFC 3339)
- Validate range (not in the far past or future)
- Timezone handling (require UTC or specific timezone)

**File uploads:**
- Maximum file size
- Allowed MIME types (validate by content, not just extension)
- Filename sanitization (prevent path traversal in filenames)
- Virus scanning for user-uploaded files (note as a recommendation)

### URL Path Parameters
- Validate format: UUID, integer ID, slug (alphanumeric + hyphens)
- Validate range: positive integers, existing resource IDs
- Reject path traversal characters (`../`, `..\\`, encoded variants)

### Query Parameters
- Pagination: page/limit must be positive integers with max limit (e.g., limit <= 100)
- Sort: only allow sorting by known field names, reject arbitrary column names
- Filter: validate filter operators and values against allowed fields
- Search: limit length, sanitize for injection if passed to database queries

### Request Headers
- Content-Type: verify it matches expected format
- Authorization: validate format (Bearer token format, API key format)
- Custom headers: validate against expected patterns

## ERROR RESPONSE FORMAT

Return validation errors in a consistent, machine-readable format:

```json
{
  "error": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": [
    {
      "field": "body.email",
      "message": "Must be a valid email address",
      "value": "not-an-email",
      "rule": "email"
    },
    {
      "field": "body.age",
      "message": "Must be between 13 and 150",
      "value": -5,
      "rule": "range"
    }
  ]
}
```

- HTTP status: 400 for structural validation errors, 422 for semantic validation errors
- Never include stack traces or internal error messages
- Never reflect raw user input in error messages without sanitization (prevents XSS in error pages)
- Collect ALL validation errors before responding (don't fail on the first error)

## IMPLEMENTATION APPROACH

1. Use a schema validation library appropriate for the framework:
   - **Node.js/Express:** Zod, Joi, or express-validator
   - **Python/FastAPI:** Pydantic (built-in)
   - **Python/Django:** Django REST Framework serializers
   - **Go:** go-playground/validator
   - **Java/Spring:** Jakarta Bean Validation annotations

2. Create the validation schema from the endpoint's requirements
3. Apply the schema as middleware/decorator that runs before the handler
4. Transform validated data into typed objects for the handler to use
5. Create reusable validation schemas for common patterns (pagination, IDs, email)

## OUTPUT FORMAT

For each endpoint, provide:
1. The validation schema definition
2. The middleware/decorator application
3. The updated handler that receives validated, typed input
4. Reusable shared schemas extracted for common patterns
5. Error handling middleware for validation failures

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/security/input-validation.md
