# Agent Recipes

> Copy-paste AI agent workflows for real-world developer tasks.

A community-driven collection of ready-to-use AI agent workflows. Each recipe is a self-contained prompt you can drop into Claude Code, Cursor, Aider, or any AI coding assistant.

## Recipes

### Code Review

| Recipe | Description |
|--------|-------------|
| [PR Review](recipes/code-review/pr-review.md) | Comprehensive pull request review with security, performance, and style checks |
| [Architecture Review](recipes/code-review/architecture-review.md) | High-level codebase architecture analysis and recommendations |
| [Dependency Audit](recipes/code-review/dependency-audit.md) | Check for outdated, vulnerable, or unnecessary dependencies |
| [Performance Review](recipes/code-review/performance-review.md) | Identify performance bottlenecks and optimization opportunities |

### Testing

| Recipe | Description |
|--------|-------------|
| [Generate Unit Tests](recipes/testing/generate-unit-tests.md) | Auto-generate unit tests for uncovered functions |
| [E2E Test Writer](recipes/testing/e2e-test-writer.md) | Generate end-to-end tests from user stories |
| [Coverage Gap Finder](recipes/testing/coverage-gap-finder.md) | Find untested code paths and edge cases |

### Migrations

| Recipe | Description |
|--------|-------------|
| [JavaScript to TypeScript](recipes/migrations/js-to-ts.md) | Migrate JS files to TypeScript with proper types |
| [React Class to Hooks](recipes/migrations/class-to-hooks.md) | Convert React class components to functional + hooks |
| [CJS to ESM](recipes/migrations/cjs-to-esm.md) | Convert CommonJS requires to ES module imports |

### Documentation

| Recipe | Description |
|--------|-------------|
| [README Generator](recipes/documentation/readme-generator.md) | Generate comprehensive README from repo analysis |
| [API Docs Generator](recipes/documentation/api-docs-generator.md) | Generate OpenAPI/Swagger docs from code |
| [Changelog Writer](recipes/documentation/changelog-writer.md) | Generate changelog from git commits |

### Security

| Recipe | Description |
|--------|-------------|
| [Secret Scanner](recipes/security/secret-scanner.md) | Find hardcoded secrets, keys, and credentials |
| [OWASP Top 10 Audit](recipes/security/owasp-audit.md) | Check code against OWASP Top 10 vulnerabilities |
| [Input Validation](recipes/security/input-validation.md) | Add input validation and sanitization to API endpoints |

### DevOps

| Recipe | Description |
|--------|-------------|
| [Dockerfile Generator](recipes/devops/dockerfile-generator.md) | Generate optimized multi-stage Dockerfiles |
| [CI/CD Pipeline](recipes/devops/ci-cd-pipeline.md) | Generate GitHub Actions / GitLab CI from project analysis |
| [Monitoring Setup](recipes/devops/monitoring-setup.md) | Add health checks, metrics, and alerting |

## How to Use

### With Claude Code

```bash
# Copy a recipe and run it
claude -p "$(cat recipes/code-review/pr-review.md)"

# Or save as a custom command
cp recipes/code-review/pr-review.md .claude/commands/review.md
# Then use: /review
```

### With Cursor / Windsurf / Any AI Assistant

1. Open the recipe `.md` file
2. Copy the prompt into your AI chat
3. Run on your codebase

## Recipe Format

Every recipe follows this structure:

```markdown
# Recipe Name

> One-line description

## When to Use
- Bullet points of use cases

## Prompt
The exact prompt to copy-paste into your AI assistant.

## Example
Input -> Output showing what the recipe produces.

## Customization
How to modify the recipe for specific needs.

## Tags
`category` `language` `difficulty`
```

## Contributing

Have a useful AI workflow? Share it!

1. Fork this repo
2. Create a recipe in the appropriate `recipes/` subdirectory
3. Follow the [recipe format](#recipe-format)
4. Submit a PR

**Ideas for new recipes?** [Open an issue](https://github.com/Sagargupta16/agent-recipes/issues/new?template=recipe-request.yml)!

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

## License

[MIT](LICENSE)
