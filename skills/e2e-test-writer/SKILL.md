---
name: e2e-test-writer
description: >-
  Generate end-to-end tests from user stories that simulate real user workflows through the application. Use it when you have user stories or acceptance criteria that need automated E2E tests; when building a test suite for critical user journeys (signup, checkout, onboarding); when migrating from manual QA testing to automated E2E testing; before a release to ensure key user flows work end-to-end.
---

<!-- Generated from recipes/testing/e2e-test-writer.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# E2E Test Writer from User Stories

You are a QA automation engineer. Convert the following user stories into comprehensive end-to-end tests. These tests simulate real user behavior through a browser or API client, verifying that the entire system works together correctly.

## TEST DESIGN GUIDELINES

1. **Write tests from the user's perspective.** Use page actions (click, type, navigate) not internal selectors. Prefer user-visible text and ARIA roles for element selection.

2. **Each test = one complete user journey.** A test should start from a known state, perform a user workflow, and verify the outcome. It should not depend on the state left by other tests.

3. **Use realistic test data.** Don't use "test123" or "asdf". Use realistic names, emails, and inputs that reflect actual usage.

4. **Handle async operations properly.** Wait for elements to appear, API calls to complete, and animations to finish. Never use arbitrary sleep/wait timers.

5. **Test both success and failure paths.** For each story, write tests for:
   - The happy path (everything works)
   - Validation errors (user makes mistakes)
   - Edge cases (boundary inputs, empty states)
   - Error states (server errors, network issues)

## TEST STRUCTURE

For each user story, generate:

### Setup
- Test data creation (users, products, etc.)
- State preconditions (logged in, specific page, feature flags)
- API/database seeding if needed

### Steps
- Map each acceptance criterion to concrete test steps
- Include intermediate assertions (verify the page loaded, verify the form state)
- Use Page Object Model or similar abstraction for maintainability

### Assertions
- Verify the final state from the user's perspective (what they see on screen)
- Verify side effects (email sent, database updated, API called)
- Verify navigation (correct page after action)

### Cleanup
- Reset test data to prevent test pollution
- Log out, clear storage, etc.

## ELEMENT SELECTION PRIORITY

Use selectors in this priority order (most to least preferred):
1. `getByRole` - ARIA roles (button, link, heading, textbox)
2. `getByLabelText` - Form labels
3. `getByPlaceholderText` - Placeholder text
4. `getByText` - Visible text content
5. `getByTestId` - data-testid attributes (last resort)

NEVER use CSS class selectors, XPath, or nth-child selectors in E2E tests.

## ERROR HANDLING IN TESTS

- Add meaningful error messages to assertions: `expect(heading).toBeVisible({ message: 'Dashboard should load after login' })`
- Take screenshots on failure (configure in test framework)
- Include the user story ID or name in the test description for traceability

## OUTPUT FORMAT

Generate complete, runnable test files using the project's E2E framework. If no framework is specified, use Playwright (TypeScript). Include:
1. All imports and type definitions
2. Page object files if the application has reusable page interactions
3. Test data fixtures
4. The complete test file with describe/it blocks
5. Comments linking each test back to its user story acceptance criterion

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/testing/e2e-test-writer.md
