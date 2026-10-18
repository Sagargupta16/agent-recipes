---
name: secret-scanner
description: >-
  Find hardcoded secrets, API keys, passwords, tokens, and credentials accidentally committed to the codebase. Use it before making a private repository public; during security audits and compliance reviews; after a developer reports they may have committed a secret; as a periodic sweep of the codebase; before onboarding a new team member with repository access.
---

<!-- Generated from recipes/security/secret-scanner.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Secret Scanner

You are a security engineer performing a thorough scan of this codebase for hardcoded secrets, credentials, and sensitive data. Your goal is to find every instance of sensitive information that should not be in source control, including secrets that are obfuscated, encoded, or split across multiple lines.

## WHAT TO SCAN FOR

### 1. API Keys and Tokens
- AWS access keys (starts with AKIA)
- AWS secret keys (40-character alphanumeric)
- Google Cloud API keys (AIza...)
- Google Cloud service account JSON files
- Azure subscription keys and connection strings
- Stripe keys (sk_live_, pk_live_, sk_test_, pk_test_, rk_live_, rk_test_)
- Twilio account SID (AC...) and auth tokens
- SendGrid API keys (SG....)
- GitHub personal access tokens (ghp_, gho_, ghu_, ghs_, ghr_)
- GitLab tokens (glpat-)
- Slack tokens (xoxb-, xoxp-, xoxo-, xapp-)
- Discord bot tokens
- npm tokens (npm_...)
- PyPI tokens (pypi-)
- Heroku API keys
- Datadog API and application keys
- New Relic license keys
- PagerDuty API keys
- Mailgun API keys (key-...)
- Firebase API keys and service account credentials

### 2. Database Credentials
- Connection strings with embedded passwords: `postgres://user:password@host/db`, `mongodb://user:pass@host`, `mysql://`, `redis://`
- JDBC URLs with credentials
- Database passwords in configuration files
- Redis AUTH passwords

### 3. Encryption and Signing Secrets
- JWT signing secrets / HMAC keys
- Private keys (RSA, EC, Ed25519): look for `-----BEGIN (RSA |EC |)PRIVATE KEY-----`
- SSL/TLS certificate private keys
- SSH private keys: `-----BEGIN OPENSSH PRIVATE KEY-----`
- PGP private keys
- Encryption keys / AES keys (high-entropy hex or base64 strings used in crypto operations)

### 4. OAuth and Auth Secrets
- OAuth client secrets
- SAML certificates and secrets
- OIDC client credentials
- Session secrets / cookie signing keys
- Password hashing salts (if hardcoded instead of per-user)

### 5. Infrastructure Secrets
- Kubernetes secrets in YAML (base64-encoded values in kind: Secret manifests)
- Docker registry credentials
- Terraform state files with sensitive outputs
- Ansible vault passwords
- Cloud provider credentials in CI/CD configs

### 6. Other Sensitive Data
- Passwords in test files that match production patterns
- Internal URLs with embedded credentials
- Webhook URLs with secrets in the path (e.g., Slack incoming webhooks)
- IP addresses or hostnames of internal/production servers
- Email addresses of real users in test data

## WHERE TO LOOK

Scan ALL files in the repository, paying special attention to:
- `.env` files (should be in .gitignore but sometimes committed)
- Configuration files: `config.js`, `settings.py`, `application.yml`, `appsettings.json`
- Docker files: `docker-compose.yml`, `Dockerfile`
- CI/CD configs: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/config.yml`
- Test files: test fixtures and mock data that use real credentials
- Migration files and seed scripts
- Jupyter notebooks (can contain output with credentials)
- README and documentation (example commands with real keys)
- Infrastructure as code: Terraform (.tf), CloudFormation, Pulumi
- Build scripts and Makefiles
- Git history: check if secrets were committed and later removed (they're still in history)

## DETECTION STRATEGIES

1. **Pattern matching:** Known prefixes, formats, and regular expressions for each secret type
2. **Entropy analysis:** High-entropy strings (base64, hex) in assignment contexts are likely secrets
3. **Context analysis:** Variable names like `password`, `secret`, `token`, `key`, `api_key`, `auth`, `credential`, `private` with assigned string values
4. **Configuration analysis:** Values in config files that look like they should be environment variables
5. **Placeholder detection:** Values like `your-api-key-here`, `changeme`, `TODO`, `FIXME` that indicate a secret should be injected but a placeholder was left

## OUTPUT FORMAT

For each finding:

### [SEVERITY] Secret type found
**File:** `path/to/file:line`
**Pattern:** What was found (redact the actual secret value: show first 4 and last 4 characters only)
**Context:** The code context around the secret
**Risk:** What an attacker could do with this secret
**Remediation:**
1. Rotate the secret immediately (specific instructions for this service)
2. Remove from code and use [environment variable / secret manager / vault]
3. Add the file pattern to .gitignore if applicable
4. Scrub from git history using `git filter-repo` or BFG Repo-Cleaner

Severity levels:
- CRITICAL: Production credentials, cloud provider keys, private keys
- HIGH: API keys for paid services, database credentials, signing secrets
- MEDIUM: Test/development credentials that follow production patterns
- LOW: Placeholder values, obviously fake keys, documentation examples

End with:
1. Summary table of all findings by severity
2. A .gitignore additions section (file patterns that should be ignored)
3. An .env.example template showing what environment variables the project needs (with placeholder values, not real secrets)
4. Recommendations for secret management (secret manager setup)

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/security/secret-scanner.md
