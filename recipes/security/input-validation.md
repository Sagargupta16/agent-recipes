# Input Validation for APIs

> Add comprehensive input validation, sanitization, and error handling to API endpoints to prevent injection attacks and data corruption.

## When to Use

- When building new API endpoints that accept user input
- When hardening existing endpoints that lack validation
- After a security audit identifies missing input validation
- When migrating from manual validation to a schema-based validation library

## The Prompt

```
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
```

## Example

### Input

```javascript
// Current endpoint with no validation
router.post('/api/users', async (req, res) => {
  const user = await db.users.create(req.body);
  res.json(user);
});

router.get('/api/users', async (req, res) => {
  const users = await db.users.find({
    role: req.query.role,
    limit: req.query.limit,
    offset: req.query.offset,
  });
  res.json(users);
});

router.put('/api/users/:id', async (req, res) => {
  const user = await db.users.update(req.params.id, req.body);
  res.json(user);
});
```

### Output

```typescript
// src/schemas/common.ts - Reusable validation schemas
import { z } from 'zod';

export const paginationSchema = z.object({
  limit: z.coerce
    .number()
    .int()
    .min(1)
    .max(100)
    .default(20)
    .describe('Number of items to return'),
  offset: z.coerce
    .number()
    .int()
    .min(0)
    .default(0)
    .describe('Number of items to skip'),
});

export const uuidParam = z.string().uuid('Must be a valid UUID');
```

```typescript
// src/schemas/userSchemas.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  body: z.object({
    email: z
      .string()
      .email('Must be a valid email address')
      .max(254, 'Email must be 254 characters or fewer')
      .transform((email) => email.toLowerCase().trim()),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .max(128, 'Password must be 128 characters or fewer')
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])/,
        'Password must contain uppercase, lowercase, number, and special character'
      ),
    name: z
      .string()
      .min(1, 'Name is required')
      .max(100, 'Name must be 100 characters or fewer')
      .trim()
      .regex(/^[\p{L}\p{M}\s'-]+$/u, 'Name contains invalid characters'),
    role: z.enum(['user', 'admin', 'moderator']).default('user'),
  }).strict(), // Reject unknown properties
});

export const listUsersSchema = z.object({
  query: z.object({
    role: z.enum(['user', 'admin', 'moderator']).optional(),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});

export const updateUserSchema = z.object({
  params: z.object({
    id: z.string().uuid('User ID must be a valid UUID'),
  }),
  body: z.object({
    email: z
      .string()
      .email('Must be a valid email address')
      .max(254)
      .transform((email) => email.toLowerCase().trim())
      .optional(),
    name: z
      .string()
      .min(1)
      .max(100)
      .trim()
      .regex(/^[\p{L}\p{M}\s'-]+$/u, 'Name contains invalid characters')
      .optional(),
    role: z.enum(['user', 'admin', 'moderator']).optional(),
  }).strict()
    .refine(
      (data) => Object.keys(data).length > 0,
      'At least one field must be provided for update'
    ),
});

export type CreateUserInput = z.infer<typeof createUserSchema>['body'];
export type ListUsersInput = z.infer<typeof listUsersSchema>['query'];
export type UpdateUserInput = z.infer<typeof updateUserSchema>['body'];
```

```typescript
// src/middleware/validate.ts
import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      const validated = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      // Replace raw input with validated and transformed data
      req.body = validated.body ?? req.body;
      req.query = validated.query ?? req.query;
      req.params = validated.params ?? req.params;

      next();
    } catch (error) {
      if (error instanceof ZodError) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: error.issues.map((issue) => ({
            field: issue.path.join('.'),
            message: issue.message,
            rule: issue.code,
          })),
        });
      }
      next(error);
    }
  };
}
```

```typescript
// src/routes/users.ts - Updated routes with validation
import { Router } from 'express';
import { validate } from '../middleware/validate';
import {
  createUserSchema,
  listUsersSchema,
  updateUserSchema,
  CreateUserInput,
  ListUsersInput,
  UpdateUserInput,
} from '../schemas/userSchemas';
import { db } from '../db';

const router = Router();

router.post('/api/users', validate(createUserSchema), async (req, res) => {
  const input: CreateUserInput = req.body;
  // input is now validated, typed, sanitized, and safe to use
  const user = await db.users.create(input);
  res.status(201).json(user);
});

router.get('/api/users', validate(listUsersSchema), async (req, res) => {
  const { role, limit, offset }: ListUsersInput = req.query as any;
  const users = await db.users.find({ role, limit, offset });
  res.json(users);
});

router.put('/api/users/:id', validate(updateUserSchema), async (req, res) => {
  const { id } = req.params;
  const updates: UpdateUserInput = req.body;
  const user = await db.users.update(id, updates);
  if (!user) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'User not found' });
  }
  res.json(user);
});

export default router;
```

## Customization Tips

- **For GraphQL APIs**, add: "Validate query depth and complexity to prevent DoS. Limit query depth to 10 levels. Limit total field count per query. Validate all input types in mutation arguments. Disable introspection in production."
- **For file upload endpoints**, add: "Validate file size before fully reading it (check Content-Length header). Validate MIME type by reading magic bytes, not trusting Content-Type header. Sanitize filenames to prevent path traversal. Store files outside the web root."
- **For rate limiting**, add: "Add rate limiting middleware to all endpoints: general rate limit of 100 req/min for authenticated users, 20 req/min for unauthenticated, 5 req/min for auth endpoints (login, register, password reset)."
- **For Python/FastAPI**, change the library: "Use Pydantic models with Field() validators. FastAPI applies validation automatically from the type annotations. Add custom validators with @validator decorator."

## Tags

`security` `validation` `api` `input-sanitization` `injection-prevention` `middleware`
