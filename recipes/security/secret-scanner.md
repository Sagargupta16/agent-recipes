# Secret Scanner

> Find hardcoded secrets, API keys, passwords, tokens, and credentials accidentally committed to the codebase.

## When to Use

- Before making a private repository public
- During security audits and compliance reviews
- After a developer reports they may have committed a secret
- As a periodic sweep of the codebase
- Before onboarding a new team member with repository access

## The Prompt

```
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
```

## Example

### Input

"Scan this project for hardcoded secrets. Check all files including configuration and CI/CD."

### Output

```
# Secret Scan Report

## Findings

### [CRITICAL] AWS Secret Access Key in configuration
**File:** `src/config/aws.js:8`
**Pattern:** `awsSecretKey: "wJaL...dkQ9"` (40-character key)
**Context:**
```javascript
const awsConfig = {
  accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
  secretAccessKey: 'wJaLrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  region: 'us-east-1',
};
```
**Risk:** Full access to AWS account. Attacker could provision resources,
access S3 buckets, read databases, and incur charges.
**Remediation:**
1. Immediately rotate the AWS key in IAM console
2. Replace with `process.env.AWS_SECRET_ACCESS_KEY`
3. Check CloudTrail for unauthorized usage

### [HIGH] Stripe live secret key in environment file
**File:** `.env:12`
**Pattern:** `STRIPE_SECRET_KEY=sk_live_51Hx...Y4mZ`
**Context:** The .env file is committed to the repository and not in .gitignore
**Risk:** Full access to Stripe account: can create charges, view customer
data, issue refunds.
**Remediation:**
1. Rotate the Stripe key in the Stripe Dashboard immediately
2. Add `.env` to `.gitignore`
3. Remove .env from git history using BFG Repo-Cleaner

### [MEDIUM] Database password in docker-compose.yml
**File:** `docker-compose.yml:15`
**Pattern:** `POSTGRES_PASSWORD: "dev_p...rd_1"`
**Context:** Development database password. While labeled as "dev", this
pattern suggests it may match the production password.
**Risk:** Database access if the same password is used in production.
**Remediation:**
1. Use `${POSTGRES_PASSWORD}` with env_file directive
2. Verify production uses a different, strong password

...

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 2     |
| HIGH     | 3     |
| MEDIUM   | 4     |
| LOW      | 2     |

## Recommended .gitignore Additions
```
.env
.env.*
!.env.example
*.pem
*.key
config/secrets.*
```

## .env.example Template
```
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
STRIPE_SECRET_KEY=sk_test_your-test-key
POSTGRES_PASSWORD=your-database-password
JWT_SECRET=generate-a-random-64-char-string
```
```

## Customization Tips

- **For git history scanning**, add: "Also scan the full git history for secrets that were committed and later removed. Use `git log -p --all -S 'AKIA'` for known prefixes. Secrets in history are still exposed and must be rotated."
- **For CI/CD-focused scanning**, add: "Pay special attention to CI/CD configuration files. Check for secrets passed as plaintext in build commands, secrets in artifact outputs, and secrets logged in build output."
- **For compliance (SOC 2, PCI)**, add: "Classify each finding by compliance framework impact. Flag any PII (names, emails, addresses) in test fixtures. Check for logging statements that could output sensitive data at runtime."
- **For pre-commit hook integration**, add: "Generate a regex pattern file compatible with detect-secrets, git-secrets, or trufflehog that can be used as a pre-commit hook to prevent future secret commits."

## Tags

`security` `secrets` `credentials` `audit` `compliance` `devops`
