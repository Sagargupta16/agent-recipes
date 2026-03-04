# OWASP Top 10 Security Audit

> Audit application code against the OWASP Top 10 web application security risks with specific vulnerability identification and remediation guidance.

## When to Use

- During security reviews before a major release
- When preparing for a penetration test or security audit
- When building a new web application and want to ensure security from the start
- When a security incident has occurred and you need to assess overall security posture
- For compliance requirements that reference OWASP (PCI DSS, SOC 2, ISO 27001)

## The Prompt

```
You are an application security expert performing an OWASP Top 10 audit. Analyze this codebase for vulnerabilities matching each of the OWASP Top 10 (2021) categories. For each category, examine the code systematically and report specific, exploitable vulnerabilities with proof-of-concept descriptions and concrete remediation code.

## AUDIT EACH CATEGORY

### A01:2021 - Broken Access Control

Check for:
- Missing authorization checks on endpoints (any route accessible without proper role/permission verification)
- Insecure Direct Object References (IDOR): can user A access user B's resources by changing an ID in the URL or request body?
- Missing function-level access control: can a regular user call admin endpoints?
- CORS misconfiguration: overly permissive Access-Control-Allow-Origin
- Path traversal: can file paths be manipulated to access files outside intended directories?
- Missing rate limiting on sensitive operations
- JWT token manipulation: can the algorithm be changed, can claims be modified?
- Forced browsing: can users access pages/endpoints not linked in the UI?

### A02:2021 - Cryptographic Failures

Check for:
- Sensitive data transmitted without TLS (HTTP links, insecure cookie flags)
- Weak hashing algorithms for passwords (MD5, SHA1, SHA256 without salt, bcrypt with cost < 10)
- Sensitive data stored in plaintext (PII, credit cards, health data in database without encryption)
- Hardcoded encryption keys or use of weak algorithms (DES, RC4, ECB mode)
- Missing Strict-Transport-Security header
- Cookies without Secure and HttpOnly flags
- Predictable random values used for tokens or secrets (Math.random instead of crypto.randomBytes)
- Client-side storage of sensitive data (localStorage, sessionStorage for tokens)

### A03:2021 - Injection

Check for:
- **SQL Injection:** String concatenation in SQL queries, missing parameterized queries
- **NoSQL Injection:** Unvalidated objects passed to MongoDB queries ($where, $regex from user input)
- **Command Injection:** User input passed to exec(), spawn(), system(), or backticks
- **XSS (Cross-Site Scripting):** User input rendered in HTML without escaping (innerHTML, dangerouslySetInnerHTML, template literals in HTML, unescaped template variables)
- **LDAP Injection:** User input in LDAP queries without escaping
- **Template Injection:** User input passed to server-side template engines without sandboxing
- **Header Injection:** User input reflected in HTTP headers (CRLF injection)
- **Log Injection:** User input written to logs without sanitization (log forging)

### A04:2021 - Insecure Design

Check for:
- Missing rate limiting on authentication endpoints (brute force possible)
- No account lockout mechanism after failed login attempts
- Missing CAPTCHA or bot protection on public forms
- Sensitive operations without re-authentication (password change without current password)
- Missing fraud detection on financial operations
- No audit logging for security-sensitive actions
- Missing input length limits that could cause DoS

### A05:2021 - Security Misconfiguration

Check for:
- Debug mode enabled in production configuration
- Default credentials in configuration files
- Unnecessary features enabled (directory listing, TRACE method, detailed error pages)
- Missing security headers: Content-Security-Policy, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy
- Stack traces or internal error details exposed to users
- Default or example configurations used in production
- Unnecessary open ports or services
- Missing CSRF protection on state-changing operations

### A06:2021 - Vulnerable and Outdated Components

Check for:
- Dependencies with known CVEs (check package-lock.json, yarn.lock, etc.)
- Outdated framework versions with known vulnerabilities
- Components that are no longer maintained
- Client-side libraries loaded from CDN without integrity checks (missing SRI hashes)
- Components used that have unnecessary permissions or capabilities

### A07:2021 - Identification and Authentication Failures

Check for:
- Weak password policies (no minimum length, no complexity requirements)
- Missing brute force protection
- Session tokens that don't expire or have excessively long lifetimes
- Session fixation vulnerabilities (session ID not rotated after login)
- Credentials sent in URL parameters (visible in logs and browser history)
- Missing multi-factor authentication on sensitive operations
- Password recovery that reveals whether an account exists
- Insecure "remember me" implementation

### A08:2021 - Software and Data Integrity Failures

Check for:
- CI/CD pipeline without integrity verification (no signing of artifacts)
- Auto-update mechanisms without signature verification
- Deserialization of untrusted data (JSON.parse of user input used to create objects, pickle/yaml.load in Python)
- Missing Subresource Integrity (SRI) for CDN-hosted scripts
- npm/pip packages pulled without lock file verification

### A09:2021 - Security Logging and Monitoring Failures

Check for:
- Missing logging for: login attempts (success and failure), authorization failures, input validation failures, application errors
- Sensitive data logged (passwords, tokens, PII in log messages)
- Logs stored without integrity protection
- No alerting on suspicious patterns (multiple failed logins, unusual access patterns)
- Missing request IDs for tracing across services

### A10:2021 - Server-Side Request Forgery (SSRF)

Check for:
- User-supplied URLs fetched by the server without validation
- URL allow/block lists that can be bypassed (IP addresses, DNS rebinding, URL encoding tricks)
- Internal service URLs accessible through user input
- File upload features that fetch from URLs
- Webhook URLs that can target internal services

## OUTPUT FORMAT

For each OWASP category:

## A0X: Category Name - [VULNERABLE / PARTIALLY PROTECTED / PROTECTED]

### Finding: Short description
**Severity:** Critical / High / Medium / Low
**Location:** `file:line`
**Vulnerability:** Describe what is wrong and how it could be exploited
**Proof of Concept:**
```
// Show how an attacker would exploit this
// Example malicious request, input, or sequence of actions
```
**Remediation:**
```
// Show the corrected code
```
**References:** Link to OWASP documentation, CWE ID

If a category has no findings, explicitly state: "No vulnerabilities identified in this category. Controls in place: [list the security controls found in the code]."

End with an executive summary:
- Overall risk rating (Critical / High / Medium / Low)
- Number of findings by severity
- Top 3 most urgent issues to fix
- Positive security practices already in place
```

## Example

### Input

"Perform an OWASP Top 10 audit on this Express.js API. Source code is in `src/`, focusing on routes, middleware, and database queries."

### Output

```
# OWASP Top 10 Audit Report

## A01: Broken Access Control - VULNERABLE

### Finding: Insecure Direct Object Reference in user profile endpoint
**Severity:** Critical
**Location:** `src/routes/users.js:34`
**Vulnerability:** The `GET /api/users/:id` endpoint returns any user's full
profile (including email, phone, address) based on the URL parameter. There is
no check that the authenticated user is authorized to view this profile.
**Proof of Concept:**
```bash
# Authenticated as user 1, access user 2's data
curl -H "Authorization: Bearer <user1_token>" \
     https://api.example.com/api/users/2
# Returns user 2's full profile including PII
```
**Remediation:**
```javascript
router.get('/users/:id', authenticate, async (req, res) => {
  // Only allow users to access their own profile, or admins to access any
  if (req.user.id !== req.params.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const user = await User.findById(req.params.id);
  res.json(user);
});
```
**References:** CWE-639, https://owasp.org/Top10/A01_2021-Broken_Access_Control/

...

## Executive Summary

**Overall Risk Rating: HIGH**

| Severity | Count |
|----------|-------|
| Critical | 3     |
| High     | 5     |
| Medium   | 8     |
| Low      | 4     |

### Top 3 Urgent Issues
1. SQL injection in search endpoint (A03) - allows full database access
2. Missing access control on user profiles (A01) - exposes all user PII
3. Hardcoded JWT secret (A02) - allows token forgery

### Positive Practices Found
- Password hashing uses bcrypt with cost factor 12
- CORS is configured with specific allowed origins
- Input validation with Joi on most endpoints
```

## Customization Tips

- **For API-only applications**, add: "Skip browser-specific checks (XSS via DOM, clickjacking) and focus on API-specific issues: mass assignment, excessive data exposure, lack of resource rate limiting, and broken object-level authorization."
- **For single-page applications (SPA)**, add: "Focus on client-side security: XSS via DOM manipulation, insecure token storage, open redirects, client-side routing bypass, and sensitive data in browser storage."
- **For microservices**, add: "Check inter-service authentication (mTLS, service tokens), ensure each service validates its own authorization (don't trust upstream services), check for SSRF between services, and verify network segmentation."
- **For compliance mapping**, add: "Map each finding to the relevant compliance requirement: PCI DSS requirement number, SOC 2 criteria, or ISO 27001 control. Include this mapping in the output for each finding."

## Tags

`security` `owasp` `audit` `vulnerability` `web-security` `compliance`
