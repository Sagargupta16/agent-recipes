# Unit Test Generator

> Generate comprehensive unit tests with edge cases, mocking strategies, and clear test descriptions that follow testing best practices.

## When to Use

- When adding tests to an existing codebase that has low coverage
- When you have written a new module and need thorough test coverage
- When you want to ensure edge cases and error paths are tested
- When onboarding onto a codebase and wanting to understand behavior through tests

## The Prompt

```
You are a senior test engineer. Generate comprehensive unit tests for the provided code. Your tests should serve as living documentation of the code's behavior and catch regressions before they reach production.

Follow these principles:

## TEST DESIGN PRINCIPLES

1. **Test behavior, not implementation.** Tests should verify WHAT the code does, not HOW it does it. If the code is refactored but behavior stays the same, tests should still pass.
2. **One assertion per logical concept.** Each test should verify one specific behavior. Use descriptive test names that explain the expected behavior.
3. **Arrange-Act-Assert pattern.** Every test should clearly separate setup, execution, and verification.
4. **Test the contract, not the internals.** Focus on public APIs. Only test private methods indirectly through the public interface.

## WHAT TO TEST

For each function/method/class, generate tests for:

### Happy Path
- Normal inputs that exercise the primary use case
- Multiple valid input variations (different types, sizes, formats that are all valid)

### Edge Cases
- Empty inputs (empty string, empty array, null, undefined, zero)
- Boundary values (min/max of ranges, exactly at limits, one above/below limits)
- Single element collections
- Very large inputs (long strings, large numbers, big arrays)
- Unicode and special characters in string inputs
- Negative numbers where positive are expected
- Floating point precision issues where relevant

### Error Handling
- Invalid input types (string where number expected, object where array expected)
- Missing required parameters
- Null and undefined arguments
- Inputs that should trigger validation errors
- External dependency failures (network errors, database errors, file not found)

### State Transitions (for stateful code)
- Initial state correctness
- State after each operation
- Invalid state transitions (calling methods in wrong order)
- Idempotency (calling the same operation twice)

### Concurrency (if applicable)
- Concurrent calls to the same function
- Race conditions in shared state

## MOCKING STRATEGY

- Mock external dependencies (database, HTTP, file system, timers) at the boundary
- Do NOT mock the code under test
- Use the simplest mock that works: prefer stubs over full mocks
- Verify mock interactions only when the interaction IS the behavior being tested (e.g., "verify this function sends an email" -> verify the email service was called with correct arguments)
- Reset mocks between tests to prevent test pollution

## TEST NAMING CONVENTION

Use descriptive names that describe the scenario and expected outcome:
`[methodName]_[scenario]_[expectedResult]`

Examples:
- `calculateTotal_withEmptyCart_returnsZero`
- `login_withInvalidPassword_throwsAuthError`
- `parseDate_withISO8601String_returnsDateObject`

Or use the `describe/it` style:
```
describe('calculateTotal', () => {
  it('should return zero for an empty cart', () => { ... });
  it('should sum item prices with correct tax', () => { ... });
  it('should throw if cart contains negative prices', () => { ... });
});
```

## OUTPUT FORMAT

For each test file:
1. List the module under test and its dependencies
2. Describe the mocking strategy
3. Write the complete test file with all imports, setup, and teardown
4. Add a comment above each test group explaining what aspect of behavior it covers

Use the project's existing test framework and assertion library. If none is set up, use:
- JavaScript/TypeScript: Jest or Vitest
- Python: pytest
- Go: standard testing package
- Rust: built-in #[test]
- Java: JUnit 5

Generate tests that are ready to run without modification.
```

## Example

### Input

```javascript
// src/utils/cart.js
export function calculateTotal(items, taxRate = 0) {
  if (!Array.isArray(items)) {
    throw new TypeError('Items must be an array');
  }
  if (taxRate < 0 || taxRate > 1) {
    throw new RangeError('Tax rate must be between 0 and 1');
  }
  const subtotal = items.reduce((sum, item) => {
    if (item.price < 0) throw new RangeError('Price cannot be negative');
    return sum + (item.price * item.quantity);
  }, 0);
  const tax = subtotal * taxRate;
  return Math.round((subtotal + tax) * 100) / 100;
}
```

### Output

```javascript
// src/utils/__tests__/cart.test.js
import { describe, it, expect } from 'vitest';
import { calculateTotal } from '../cart';

describe('calculateTotal', () => {
  // --- Happy Path ---

  it('should calculate total for a single item with no tax', () => {
    const items = [{ price: 10, quantity: 2 }];
    expect(calculateTotal(items)).toBe(20);
  });

  it('should calculate total for multiple items with no tax', () => {
    const items = [
      { price: 10, quantity: 2 },
      { price: 5.50, quantity: 1 },
    ];
    expect(calculateTotal(items)).toBe(25.50);
  });

  it('should apply tax rate correctly', () => {
    const items = [{ price: 100, quantity: 1 }];
    expect(calculateTotal(items, 0.08)).toBe(108);
  });

  it('should round to two decimal places', () => {
    const items = [{ price: 10.33, quantity: 3 }];
    // 30.99 * 1.07 = 33.1593 -> 33.16
    expect(calculateTotal(items, 0.07)).toBe(33.16);
  });

  // --- Edge Cases ---

  it('should return 0 for an empty items array', () => {
    expect(calculateTotal([])).toBe(0);
  });

  it('should handle zero-priced items', () => {
    const items = [{ price: 0, quantity: 5 }];
    expect(calculateTotal(items)).toBe(0);
  });

  it('should handle zero quantity', () => {
    const items = [{ price: 100, quantity: 0 }];
    expect(calculateTotal(items)).toBe(0);
  });

  it('should handle tax rate of exactly 0', () => {
    const items = [{ price: 50, quantity: 1 }];
    expect(calculateTotal(items, 0)).toBe(50);
  });

  it('should handle tax rate of exactly 1 (100%)', () => {
    const items = [{ price: 50, quantity: 1 }];
    expect(calculateTotal(items, 1)).toBe(100);
  });

  it('should handle fractional quantities', () => {
    const items = [{ price: 10, quantity: 0.5 }];
    expect(calculateTotal(items)).toBe(5);
  });

  // --- Error Handling ---

  it('should throw TypeError if items is not an array', () => {
    expect(() => calculateTotal(null)).toThrow(TypeError);
    expect(() => calculateTotal('not array')).toThrow(TypeError);
    expect(() => calculateTotal(42)).toThrow(TypeError);
  });

  it('should throw RangeError if tax rate is negative', () => {
    expect(() => calculateTotal([], -0.1)).toThrow(RangeError);
  });

  it('should throw RangeError if tax rate exceeds 1', () => {
    expect(() => calculateTotal([], 1.5)).toThrow(RangeError);
  });

  it('should throw RangeError if any item has a negative price', () => {
    const items = [{ price: -5, quantity: 1 }];
    expect(() => calculateTotal(items)).toThrow(RangeError);
  });
});
```

## Customization Tips

- **For React components**, add: "Use React Testing Library. Test user interactions (click, type, submit), rendered output, and accessibility. Never test component state directly."
- **For API route handlers**, add: "Use supertest or equivalent. Test HTTP status codes, response bodies, headers, and authentication requirements for each endpoint."
- **For database-dependent code**, add: "Use an in-memory database or test containers. Test CRUD operations, constraint violations, concurrent access, and transaction rollback scenarios."
- **For higher coverage**, add: "Aim for 100% branch coverage. Identify every if/else, switch case, try/catch, ternary, and short-circuit evaluation and ensure each branch has a dedicated test."
- **For property-based testing**, add: "In addition to example-based tests, write property-based tests using fast-check (JS), Hypothesis (Python), or QuickCheck (Haskell/Rust) for functions with well-defined mathematical properties."

## Tags

`testing` `unit-tests` `tdd` `coverage` `mocking` `best-practices`
