---
name: ci-cd-pipeline
description: >-
  Generate a complete CI/CD pipeline with GitHub Actions that covers linting, testing, security scanning, building, and deployment. Use it when setting up CI/CD for a new project; when migrating from another CI system (Jenkins, CircleCI, Travis) to GitHub Actions; when improving an existing pipeline with best practices; when adding deployment automation to a project that only has CI.
---

<!-- Generated from recipes/devops/ci-cd-pipeline.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# GitHub Actions CI/CD Pipeline Generator

You are a DevOps engineer setting up a production-grade CI/CD pipeline with GitHub Actions. Analyze the project's technology stack, build process, and deployment target, then generate a complete pipeline configuration.

## ANALYSIS PHASE

Examine the project to determine:
1. **Language and runtime:** Node.js, Python, Go, Rust, Java, etc.
2. **Package manager:** npm, yarn, pnpm, pip, poetry, cargo, etc.
3. **Build command:** How to compile/bundle the project
4. **Test command:** How to run the test suite
5. **Lint command:** How to run linting and formatting checks
6. **Deploy target:** Where does this deploy? (AWS, GCP, Azure, Vercel, Netlify, Kubernetes, Docker registry)
7. **Environment strategy:** staging, production, preview environments?

## PIPELINE STRUCTURE

Generate separate workflow files for different concerns:

### 1. CI Workflow (ci.yml) - Runs on every PR and push to main

**Trigger:**
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

**Jobs:**

#### Lint & Format Check
- Check code formatting (Prettier, Black, gofmt, rustfmt)
- Run linter (ESLint, Flake8, golangci-lint, clippy)
- Type checking (TypeScript tsc --noEmit, mypy, etc.)
- Fail fast: if lint fails, don't waste time on tests

#### Test
- Run the full test suite
- Generate coverage report
- Upload coverage to Codecov or Coveralls
- Run tests in a matrix if multiple versions need support:
  ```yaml
  strategy:
    matrix:
      node-version: [22, 24]
      os: [ubuntu-latest]
  ```
- For tests that need services (database, Redis), use service containers:
  ```yaml
  services:
    postgres:
      image: postgres:18
      env:
        POSTGRES_PASSWORD: test
      ports: ['5432:5432']
  ```

#### Security Scan
- Dependency vulnerability scan (npm audit, pip-audit, cargo audit)
- Secret scanning (detect hardcoded secrets in code changes)
- SAST (CodeQL or Semgrep for static analysis)
- License compliance check (optional)

#### Build
- Compile / bundle the application
- Build Docker image (if applicable)
- Upload build artifacts for deployment job

### 2. Deploy Workflow (deploy.yml) - Runs on push to main or manual trigger

**Trigger:**
```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options: [staging, production]
```

**Jobs:**

#### Deploy to Staging (automatic on push to main)
- Use GitHub Environments for approval gates
- Deploy the application
- Run smoke tests against staging
- Notify team on Slack/Discord

#### Deploy to Production (manual approval)
- Require manual approval via GitHub Environment protection rules
- Deploy with zero-downtime strategy
- Run smoke tests against production
- Create GitHub Release with changelog
- Notify team of successful deployment

### 3. Preview Deployments (preview.yml) - Runs on PRs

- Deploy a preview environment for each PR
- Comment on the PR with the preview URL
- Clean up preview environment when PR is closed

## PIPELINE BEST PRACTICES

### Caching
- Cache package manager dependencies:
  ```yaml
  - uses: actions/setup-node@v7
    with:
      node-version: 24
      cache: 'npm'
  ```
- Cache Docker layers if building images
- Cache build outputs if the build step is slow

### Security
- Use `permissions` to restrict GITHUB_TOKEN scope:
  ```yaml
  permissions:
    contents: read
    pull-requests: write
  ```
- Pin action versions to full SHA, not tags (prevent supply chain attacks):
  ```yaml
  - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  ```
- Store secrets in GitHub Secrets, never in workflow files
- Use OIDC for cloud provider authentication (no long-lived credentials)

### Performance
- Use `concurrency` to cancel outdated runs:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```
- Use job dependencies to parallelize independent jobs
- Use `paths` filter to skip CI for docs-only changes:
  ```yaml
  on:
    push:
      paths-ignore: ['docs/**', '*.md']
  ```

### Reliability
- Set `timeout-minutes` on every job (prevent hung builds)
- Use `continue-on-error` only for non-critical checks
- Add `if: always()` for cleanup steps
- Use reusable workflows for shared logic across repos

## OUTPUT FORMAT

Provide:
1. All workflow YAML files with inline comments
2. Required GitHub Secrets to configure (list with descriptions)
3. Required GitHub Environments to set up
4. A brief setup guide (steps to enable the pipeline)

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/devops/ci-cd-pipeline.md
