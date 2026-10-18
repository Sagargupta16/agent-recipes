---
name: pr-review
description: >-
  Perform a thorough, multi-dimensional code review covering security, performance, correctness, style, testing, and edge cases. Use it before merging any pull request into the main branch; when reviewing code from new contributors or junior developers; for changes touching critical paths (authentication, payments, data processing); when you want a second opinion that covers blind spots a human reviewer might miss.
---

<!-- Generated from recipes/code-review/pr-review.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Comprehensive PR Review

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

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/code-review/pr-review.md
