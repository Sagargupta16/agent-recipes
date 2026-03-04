# E2E Test Writer from User Stories

> Generate end-to-end tests from user stories that simulate real user workflows through the application.

## When to Use

- When you have user stories or acceptance criteria that need automated E2E tests
- When building a test suite for critical user journeys (signup, checkout, onboarding)
- When migrating from manual QA testing to automated E2E testing
- Before a release to ensure key user flows work end-to-end

## The Prompt

```
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
```

## Example

### Input

**User Story: User Login**

As a registered user, I want to log in with my email and password so I can access my dashboard.

Acceptance criteria:
- User can log in with valid credentials
- User sees an error message for invalid credentials
- User is redirected to the dashboard after successful login
- "Remember me" keeps the user logged in after closing the browser
- Account is locked after 5 failed attempts

### Output

```typescript
// tests/e2e/login.spec.ts
import { test, expect } from '@playwright/test';

// Test data
const validUser = {
  email: 'sarah.chen@example.com',
  password: 'Str0ng!Pass#2024',
  name: 'Sarah Chen',
};

const invalidCredentials = {
  email: 'sarah.chen@example.com',
  password: 'WrongPassword123!',
};

test.describe('User Login', () => {
  test.beforeEach(async ({ page }) => {
    // Seed test user via API
    await page.request.post('/api/test/seed-user', { data: validUser });
    await page.goto('/login');
  });

  test.afterEach(async ({ page }) => {
    // Cleanup: reset login attempts and session
    await page.request.post('/api/test/reset-user', {
      data: { email: validUser.email },
    });
  });

  // AC: User can log in with valid credentials
  // AC: User is redirected to the dashboard after successful login
  test('should log in with valid credentials and redirect to dashboard', async ({ page }) => {
    await page.getByLabel('Email').fill(validUser.email);
    await page.getByLabel('Password').fill(validUser.password);
    await page.getByRole('button', { name: 'Log in' }).click();

    // Should redirect to dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(
      page.getByRole('heading', { name: `Welcome, ${validUser.name}` })
    ).toBeVisible();
  });

  // AC: User sees an error message for invalid credentials
  test('should show error message for invalid password', async ({ page }) => {
    await page.getByLabel('Email').fill(invalidCredentials.email);
    await page.getByLabel('Password').fill(invalidCredentials.password);
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(
      page.getByText('Invalid email or password. Please try again.')
    ).toBeVisible();

    // Should stay on login page
    await expect(page).toHaveURL('/login');
  });

  test('should show error for non-existent email', async ({ page }) => {
    await page.getByLabel('Email').fill('nobody@example.com');
    await page.getByLabel('Password').fill('SomePassword1!');
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(
      page.getByText('Invalid email or password. Please try again.')
    ).toBeVisible();
  });

  // AC: Account is locked after 5 failed attempts
  test('should lock account after 5 failed login attempts', async ({ page }) => {
    for (let i = 0; i < 5; i++) {
      await page.getByLabel('Email').fill(validUser.email);
      await page.getByLabel('Password').fill('WrongPassword!');
      await page.getByRole('button', { name: 'Log in' }).click();

      if (i < 4) {
        await expect(page.getByText('Invalid email or password')).toBeVisible();
        // Clear fields for next attempt
        await page.getByLabel('Email').clear();
        await page.getByLabel('Password').clear();
      }
    }

    await expect(
      page.getByText('Account locked. Please try again in 30 minutes or reset your password.')
    ).toBeVisible();

    // Verify even correct password doesn't work while locked
    await page.getByLabel('Email').clear();
    await page.getByLabel('Password').clear();
    await page.getByLabel('Email').fill(validUser.email);
    await page.getByLabel('Password').fill(validUser.password);
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(page.getByText('Account locked')).toBeVisible();
  });

  // AC: "Remember me" keeps the user logged in
  test('should persist session when "Remember me" is checked', async ({ page, context }) => {
    await page.getByLabel('Email').fill(validUser.email);
    await page.getByLabel('Password').fill(validUser.password);
    await page.getByLabel('Remember me').check();
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(page).toHaveURL('/dashboard');

    // Simulate closing and reopening browser by clearing session storage
    // but keeping cookies (which "Remember me" sets)
    await page.evaluate(() => sessionStorage.clear());
    await page.goto('/dashboard');

    // Should still be logged in
    await expect(page).toHaveURL('/dashboard');
    await expect(
      page.getByRole('heading', { name: `Welcome, ${validUser.name}` })
    ).toBeVisible();
  });

  // Validation edge cases
  test('should show validation error for empty email', async ({ page }) => {
    await page.getByLabel('Password').fill(validUser.password);
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(page.getByText('Email is required')).toBeVisible();
  });

  test('should show validation error for malformed email', async ({ page }) => {
    await page.getByLabel('Email').fill('not-an-email');
    await page.getByLabel('Password').fill(validUser.password);
    await page.getByRole('button', { name: 'Log in' }).click();

    await expect(page.getByText('Please enter a valid email address')).toBeVisible();
  });
});
```

## Customization Tips

- **For Cypress**, change the output framework: "Use Cypress with TypeScript. Use cy.get, cy.contains, and cy.intercept for network mocking."
- **For API-only E2E tests**, replace browser steps: "Write API E2E tests using supertest or the framework's HTTP client. Chain API calls to simulate user workflows. Verify response bodies, status codes, and database state."
- **For mobile apps**, adjust selectors: "Use Detox (React Native) or Appium selectors. Account for gestures (swipe, long press), device rotation, and push notifications."
- **For visual regression**, add: "Include visual comparison assertions using `toHaveScreenshot()` for key states: empty, loading, loaded, and error."
- **For accessibility**, add: "After each major page interaction, run an automated accessibility audit using @axe-core/playwright and assert zero violations."

## Tags

`testing` `e2e` `playwright` `user-stories` `acceptance-testing` `automation`
