# Comprehensive PR Review

> Perform a thorough, multi-dimensional code review covering security, performance, correctness, style, testing, and edge cases.

## When to Use

- Before merging any pull request into the main branch
- When reviewing code from new contributors or junior developers
- For changes touching critical paths (authentication, payments, data processing)
- When you want a second opinion that covers blind spots a human reviewer might miss

## The Prompt

```
You are a senior staff engineer performing a comprehensive code review. Analyze every changed file in this pull request with the rigor you would apply to production code at a company where outages cost millions per minute.

Review the diff and provide findings organized into these sections. For each finding, reference the specific file and line number, explain the problem, and provide a concrete fix.

## 1. CRITICAL ISSUES (Must fix before merge)

Check for:
- Security vulnerabilities: SQL injection, XSS, CSRF, path traversal, command injection, insecure deserialization, hardcoded secrets, missing authentication/authorization checks
- Data loss risks: missing transactions, race conditions, incorrect cascade deletes, unbacked destructive operations
- Breaking changes: changed public API contracts, removed fields, altered return types without versioning
- Correctness bugs: off-by-one errors, null/undefined dereferences, incorrect boolean logic, missed error handling that could crash the process

## 2. PERFORMANCE CONCERNS

Check for:
- N+1 query patterns or unnecessary database round-trips
- Missing database indexes for new query patterns
- Unbounded data fetching (no LIMIT, no pagination)
- Blocking the event loop (for Node.js) or main thread with synchronous heavy work
- Memory leaks: event listeners not removed, growing caches without eviction, closures holding references
- Unnecessary re-renders (for frontend code), missing memoization for expensive computations
- Large payloads being serialized/deserialized unnecessarily

## 3. ERROR HANDLING & RESILIENCE

Check for:
- Catch blocks that swallow errors silently
- Missing error handling on I/O operations (network calls, file operations, database queries)
- Missing timeouts on external service calls
- Missing retry logic for idempotent operations that can transiently fail
- Unhandled promise rejections or missing async/await
- Error messages that leak internal implementation details to users

## 4. TESTING GAPS

Check for:
- New code paths that lack corresponding tests
- Modified logic where existing tests were not updated
- Missing edge case tests: empty inputs, boundary values, concurrent access, error scenarios
- Tests that test implementation details rather than behavior (brittle tests)
- Missing integration tests for code that interacts with external systems

## 5. CODE QUALITY & MAINTAINABILITY

Check for:
- Functions or methods that are too long (>40 lines) or do too many things
- Unclear naming: variables like `data`, `result`, `temp`, `flag`
- Magic numbers or hardcoded strings that should be named constants
- Duplicated logic that should be extracted into shared functions
- Complex nested conditionals that could be simplified with early returns or guard clauses
- Missing or misleading comments (comments that describe "what" instead of "why")
- Dead code: unreachable branches, unused imports, commented-out code

## 6. STYLE & CONSISTENCY

Check for:
- Deviations from the existing codebase style and conventions
- Inconsistent naming conventions (mixing camelCase and snake_case)
- Import ordering inconsistencies
- Missing TypeScript types or use of `any` where a specific type exists

## 7. EDGE CASES TO CONSIDER

List specific edge cases that the author may not have considered, given the nature of the change. For each edge case, state whether the current code handles it correctly or not.

## OUTPUT FORMAT

For each finding, use this format:

### [SEVERITY] Title
**File:** `path/to/file.ext` line XX
**Problem:** Clear explanation of the issue.
**Fix:**
```suggestion
// The corrected code
```

Severity levels: CRITICAL, WARNING, SUGGESTION, NITPICK

End with a summary: total findings by severity, an overall assessment (APPROVE, REQUEST_CHANGES, or COMMENT), and one sentence on what this PR does well.
```

## Example

### Input

A pull request that adds a new REST endpoint for user profile updates, including a new route handler, service function, database query, and validation logic.

### Output

```
## 1. CRITICAL ISSUES

### [CRITICAL] SQL Injection via unsanitized user input
**File:** `src/services/userService.js` line 42
**Problem:** The `updateProfile` function interpolates `req.body.name` directly
into a SQL query string. An attacker can inject arbitrary SQL.
**Fix:**
```suggestion
const result = await db.query(
  'UPDATE users SET name = $1, bio = $2 WHERE id = $3 RETURNING *',
  [name, bio, userId]
);
```

### [CRITICAL] Missing authorization check
**File:** `src/routes/profile.js` line 15
**Problem:** The PUT /users/:id/profile endpoint does not verify that the
authenticated user matches the :id parameter. Any logged-in user can edit
any other user's profile.
**Fix:**
```suggestion
if (req.user.id !== req.params.id) {
  return res.status(403).json({ error: 'Forbidden' });
}
```

## 2. PERFORMANCE CONCERNS

### [WARNING] N+1 query in profile fetch
**File:** `src/services/userService.js` line 28
**Problem:** For each user, a separate query fetches their avatar URL. With 100
users this fires 101 queries.
**Fix:**
```suggestion
const users = await db.query(`
  SELECT u.*, a.url as avatar_url
  FROM users u
  LEFT JOIN avatars a ON a.user_id = u.id
  WHERE u.id = ANY($1)
`, [userIds]);
```

...

## Summary
- CRITICAL: 2, WARNING: 3, SUGGESTION: 4, NITPICK: 2
- **Verdict: REQUEST_CHANGES** - The SQL injection and missing auth check must
  be fixed before merge.
- **Strength:** Good separation of concerns between route handler and service
  layer; clear input validation schema.
```

## Customization Tips

- **For frontend PRs**, add a section for accessibility (missing ARIA labels, keyboard navigation, color contrast) and responsive design issues
- **For infrastructure/DevOps PRs**, add a section for configuration safety (missing env var validation, secret exposure, resource limits)
- **For API PRs**, add a section for backward compatibility and API contract verification
- **To make it stricter**, add: "Treat every WARNING as a CRITICAL if this code touches authentication, payments, or PII"
- **For specific languages**, add language-specific checks (e.g., goroutine leaks for Go, GIL concerns for Python, ownership issues for Rust)

## Tags

`code-review` `pull-request` `security` `performance` `testing` `quality`
