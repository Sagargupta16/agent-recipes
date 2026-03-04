# Coverage Gap Finder

> Analyze code and existing tests to identify untested code paths, missing edge cases, and weak assertions that create a false sense of coverage.

## When to Use

- When your coverage report shows high percentage but you still have bugs in production
- When you want to go beyond line coverage and find truly untested behavior
- Before a critical release to identify testing blind spots
- When evaluating the quality of an existing test suite

## The Prompt

```
You are a test quality analyst. Analyze the source code and its corresponding test files to find coverage gaps: code paths, edge cases, and behaviors that are not adequately tested. Go beyond what a line-coverage tool reports, which only tells you if a line was executed, not whether it was meaningfully verified.

## ANALYSIS APPROACH

### Step 1: Map all code behaviors
For each function, method, or component, list:
- All possible execution paths (every if/else branch, switch case, try/catch, early return)
- All input validation checks
- All error handling paths
- All side effects (database writes, API calls, events emitted, state mutations)
- All implicit behaviors (default values, type coercions, fallback logic)

### Step 2: Map existing test coverage
For each behavior identified in Step 1:
- Does a test exist that exercises this path?
- Does the test actually ASSERT the correct behavior, or does it just execute the code path without meaningful assertions?
- Does the test use realistic inputs, or toy data that skips edge cases?

### Step 3: Identify gaps

Report gaps in these categories:

## 1. UNTESTED CODE PATHS

Identify branches that no test exercises:
- If/else branches where only one side is tested
- Switch cases with no test (especially default cases)
- Catch blocks that no test triggers
- Early returns / guard clauses with no test
- Ternary expressions where only one path is tested
- Logical short-circuit operators (&& / ||) where both paths aren't tested
- Callback or promise rejection paths

For each gap, specify the exact branch (file, line, condition) and what test should be written.

## 2. MISSING EDGE CASES

Even for tested paths, identify missing boundary conditions:
- Null, undefined, NaN, Infinity, empty string, empty array, empty object
- Boundary values: 0, -1, MAX_SAFE_INTEGER, very long strings
- Unicode: emoji, RTL text, zero-width characters, null bytes
- Concurrent access: what if this function is called twice simultaneously?
- Time-sensitive: daylight saving transitions, leap years, midnight boundary, timezones
- Locale-sensitive: number formatting, date formatting, currency, sorting

## 3. WEAK ASSERTIONS

Find tests that execute code but don't properly verify behavior:
- Tests with no assertions (just calling the function)
- Tests that only check `toBeDefined()` or `not.toThrow()` without verifying the returned value
- Tests that use snapshot testing where they should use specific assertions
- Tests that assert array length but not array contents
- Tests that check only the happy path return value but not side effects
- Tests that mock so aggressively that they don't test anything real

## 4. MISSING INTEGRATION POINTS

Identify boundaries between components that are not tested together:
- Function A calls Function B, but tests for A mock B entirely. What if B's contract changes?
- Database queries that are tested with mocks but never against a real (test) database
- API endpoints tested in isolation but never as part of a user workflow
- Event emitters and listeners that are tested separately but never together
- Middleware that is tested standalone but never in the actual request pipeline

## 5. MISSING ERROR SCENARIO TESTS

Identify error conditions that no test simulates:
- Network failures (timeout, connection refused, DNS failure)
- Database errors (connection lost, constraint violation, deadlock)
- File system errors (permission denied, disk full, file not found)
- Rate limiting and throttling behavior
- Authentication and authorization failures
- Invalid state transitions
- Resource exhaustion (memory, file descriptors, connections)

## 6. RACE CONDITIONS & STATE BUGS

Identify stateful code that is not tested for:
- Concurrent modifications to shared state
- State that persists between tests (test pollution)
- Initialization order dependencies
- Cleanup failures (resources not released in error paths)

## OUTPUT FORMAT

For each gap:

### Gap: [Short description]
**Source:** `file:line` - [the code that is not tested]
**Risk:** What could go wrong if this is not tested (e.g., "Users could submit negative prices")
**Priority:** HIGH (likely to cause a bug) / MEDIUM (edge case) / LOW (unlikely scenario)
**Suggested Test:**
```
// Concrete test code that covers this gap
```

End with a summary:
- Total gaps found by category and priority
- Top 5 highest-risk gaps to fix first
- Overall test suite quality assessment (Thorough / Adequate / Weak / Insufficient)
```

## Example

### Input

"Analyze the test coverage of `src/services/paymentService.js` and its test file `src/services/__tests__/paymentService.test.js`. Identify what behaviors are not adequately tested."

### Output

```
# Coverage Gap Analysis: paymentService

## 1. UNTESTED CODE PATHS

### Gap: Stripe webhook signature verification failure
**Source:** `paymentService.js:89` - catch block for `stripe.webhooks.constructEvent`
**Risk:** If webhook signature verification fails, the current code silently
returns 200 instead of 400. No test verifies this path. A misconfigured webhook
secret in production would silently drop all payment events.
**Priority:** HIGH
**Suggested Test:**
```javascript
it('should return 400 when webhook signature is invalid', async () => {
  const invalidPayload = JSON.stringify({ type: 'payment_intent.succeeded' });
  const invalidSignature = 'invalid_sig';

  const response = await paymentService.handleWebhook(
    invalidPayload,
    invalidSignature
  );

  expect(response.status).toBe(400);
  expect(response.error).toBe('Invalid webhook signature');
  expect(mockOrderService.fulfillOrder).not.toHaveBeenCalled();
});
```

### Gap: Partial refund amount exceeds original charge
**Source:** `paymentService.js:134` - the `amount > charge.amount` branch
**Risk:** The validation exists in code but no test verifies it works. A bug
here could allow refunding more than was charged.
**Priority:** HIGH
**Suggested Test:**
```javascript
it('should reject refund amount greater than original charge', async () => {
  mockStripe.charges.retrieve.mockResolvedValue({ amount: 5000 });

  await expect(
    paymentService.refund('ch_123', 7500)
  ).rejects.toThrow('Refund amount exceeds original charge');
});
```

## 3. WEAK ASSERTIONS

### Gap: processPayment test doesn't verify Stripe call arguments
**Source:** `paymentService.test.js:45`
**Risk:** The test checks that processPayment returns a payment ID, but never
verifies what arguments were passed to `stripe.paymentIntents.create`. The
amount, currency, or metadata could be wrong and the test would still pass.
**Priority:** MEDIUM
**Suggested Test Addition:**
```javascript
expect(mockStripe.paymentIntents.create).toHaveBeenCalledWith({
  amount: 2500,
  currency: 'usd',
  customer: 'cus_456',
  metadata: { orderId: 'order_789' },
});
```

...

## Summary

| Category               | HIGH | MEDIUM | LOW | Total |
|------------------------|------|--------|-----|-------|
| Untested code paths    | 3    | 2      | 1   | 6     |
| Missing edge cases     | 1    | 4      | 2   | 7     |
| Weak assertions        | 2    | 3      | 0   | 5     |
| Missing integration    | 1    | 1      | 0   | 2     |
| Missing error scenarios| 2    | 2      | 1   | 5     |
| **Total**              | **9**| **12** | **4**| **25**|

### Top 5 Highest-Risk Gaps
1. Webhook signature verification failure (silent data loss)
2. Partial refund exceeding original charge (financial loss)
3. Concurrent payment processing for same order (double charge)
4. Stripe API timeout handling (user-facing error)
5. processPayment Stripe call argument verification (incorrect charges)

**Overall Test Suite Quality: Weak** - Happy paths are covered but error
handling, edge cases, and integration boundaries are largely untested.
```

## Customization Tips

- **For React component tests**, add: "Check for missing interaction tests (onClick, onChange, onSubmit handlers), missing accessibility assertions, missing loading/error state rendering, and missing conditional rendering branches."
- **For API tests**, add: "Check for missing HTTP status code scenarios (400, 401, 403, 404, 409, 422, 429, 500), missing request validation tests, missing pagination edge cases, and missing CORS/security header assertions."
- **For strict coverage targets**, add: "Flag any function with less than 100% branch coverage. For each uncovered branch, provide the exact test that would cover it."
- **To quantify risk**, add: "For each gap, estimate the probability of this bug occurring in production (likely/possible/unlikely) and the severity if it does (critical/major/minor). Prioritize by risk = probability * severity."

## Tags

`testing` `coverage` `quality` `edge-cases` `assertions` `test-gaps`
