# GitHub Actions CI/CD Pipeline Generator

> Generate a complete CI/CD pipeline with GitHub Actions that covers linting, testing, security scanning, building, and deployment.

## When to Use

- When setting up CI/CD for a new project
- When migrating from another CI system (Jenkins, CircleCI, Travis) to GitHub Actions
- When improving an existing pipeline with best practices
- When adding deployment automation to a project that only has CI

## The Prompt

```
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
      node-version: [18, 20, 22]
      os: [ubuntu-latest]
  ```
- For tests that need services (database, Redis), use service containers:
  ```yaml
  services:
    postgres:
      image: postgres:16
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
  - uses: actions/setup-node@v4
    with:
      node-version: 20
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
  - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
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
```

## Example

### Input

"Set up GitHub Actions CI/CD for this Node.js TypeScript API. It uses npm for packages, Jest for tests, ESLint for linting, and deploys as a Docker image to AWS ECR + ECS."

### Output

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  pull-requests: write
  security-events: write

jobs:
  lint:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: ESLint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Check formatting
        run: npx prettier --check .

  test:
    name: Test
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: lint
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Run database migrations
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

      - name: Run tests
        run: npm test -- --coverage --ci
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
          JWT_SECRET: test-secret-for-ci

      - name: Upload coverage
        if: github.event_name == 'pull_request'
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - name: Dependency audit
        run: npm audit --audit-level=high

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript

      - name: Run CodeQL analysis
        uses: github/codeql-action/analyze@v3

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: [test, security]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    permissions:
      id-token: write # OIDC for AWS
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ steps.ecr-login.outputs.registry }}/my-api:${{ github.sha }}
            ${{ steps.ecr-login.outputs.registry }}/my-api:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  workflow_run:
    workflows: [CI]
    branches: [main]
    types: [completed]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deploy target'
        required: true
        type: choice
        options:
          - staging
          - production

concurrency:
  group: deploy-${{ github.event.inputs.environment || 'staging' }}
  cancel-in-progress: false # Never cancel an in-progress deploy

permissions:
  id-token: write
  contents: write

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    timeout-minutes: 20
    if: >-
      (github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'success') ||
      (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'staging')
    environment:
      name: staging
      url: https://staging-api.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster my-api-staging \
            --service my-api \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster my-api-staging \
            --services my-api

      - name: Smoke test
        run: |
          for i in {1..10}; do
            status=$(curl -s -o /dev/null -w "%{http_code}" https://staging-api.example.com/health)
            if [ "$status" = "200" ]; then
              echo "Health check passed"
              exit 0
            fi
            echo "Attempt $i: status $status, retrying..."
            sleep 5
          done
          echo "Smoke test failed"
          exit 1

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: deploy-staging
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'production'
    environment:
      name: production
      url: https://api.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: us-east-1

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster my-api-production \
            --service my-api \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster my-api-production \
            --services my-api

      - name: Smoke test
        run: |
          status=$(curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health)
          if [ "$status" != "200" ]; then
            echo "Production smoke test failed!"
            exit 1
          fi
```

**Required GitHub Secrets:**
| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for staging OIDC authentication |
| `AWS_ROLE_ARN_PROD` | IAM role ARN for production OIDC authentication |
| `CODECOV_TOKEN` | Token for Codecov coverage uploads |

**Required GitHub Environments:**
- `staging` - No protection rules (auto-deploy on push to main)
- `production` - Required reviewers, deployment branch restriction to `main`

## Customization Tips

- **For Vercel/Netlify deployments**, replace the Docker build and ECS deploy with the platform's GitHub integration or CLI deploy commands
- **For monorepos**, add: "Use `paths` filters to run only affected package pipelines. Use Turborepo or Nx for efficient build caching. Add a `changes` job that detects which packages were modified."
- **For release-based deploys**, add: "Trigger production deploy on GitHub Release creation instead of manual dispatch. Auto-generate release notes from conventional commits."
- **For Kubernetes deployments**, replace ECS steps: "Use `kubectl set image` or Helm upgrade. Add ArgoCD sync step for GitOps. Include Kubernetes manifest validation with kubeval or kubeconform."
- **For self-hosted runners**, add: "Use `runs-on: self-hosted` with appropriate labels. Add runner cleanup steps. Configure runner groups for security isolation between environments."

## Tags

`devops` `ci-cd` `github-actions` `automation` `deployment` `pipeline`
