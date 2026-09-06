# Agent Recipes

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Recipes](https://img.shields.io/badge/recipes-22-brightgreen.svg)](#recipes)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-orange.svg)](CONTRIBUTING.md)

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
| [Multi-Repo PR Check](recipes/code-review/multi-repo-pr-check.md) | Check all your open PRs across multiple repos in parallel |

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
| [Upgrade Dependencies](recipes/migrations/upgrade-dependencies.md) | Safely upgrade all project dependencies with automated testing |

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
| [Background Deploy Monitor](recipes/devops/background-deploy-monitor.md) | Monitor a deployment in the background while continuing other work |

## How to Use

Run the prompt, not the whole file. A recipe also contains a worked example, and if you pipe the entire file into an agent it reads that example's output as part of its instructions. `scripts/extract-prompt.sh` prints only the fenced block under `## The Prompt`.

### With Claude Code

```bash
# Run a recipe's prompt directly
claude -p "$(bash scripts/extract-prompt.sh recipes/code-review/pr-review.md)"

# Or save it as a custom command
mkdir -p .claude/commands
bash scripts/extract-prompt.sh recipes/code-review/pr-review.md > .claude/commands/review.md
# Then use: /review
```

### With Cursor / Windsurf / Any AI Assistant

1. Open the recipe `.md` file
2. Copy the fenced block under `## The Prompt` into your AI chat
3. Run on your codebase

### Composing Recipes

Each recipe does one thing, so chain them when the task is bigger than one prompt. Run the first, then feed its report to the second:

- [Coverage Gap Finder](recipes/testing/coverage-gap-finder.md) to find the untested paths, then [Generate Unit Tests](recipes/testing/generate-unit-tests.md) for the gaps it named
- [Secret Scanner](recipes/security/secret-scanner.md) to clear hardcoded credentials first, then [OWASP Top 10 Audit](recipes/security/owasp-audit.md) on the rest of the surface
- [Dependency Audit](recipes/code-review/dependency-audit.md) to get the license and maintenance picture, then [Upgrade Dependencies](recipes/migrations/upgrade-dependencies.md) to actually move the versions
- [Architecture Review](recipes/code-review/architecture-review.md) before any migration recipe, so the migration lands in the structure you want rather than the one you have

## Recipe Format

Every recipe is one markdown file with the same sections in the same order:

| Section | Purpose |
|---------|---------|
| `# Title` and a `>` line | Recipe name plus a one-line description |
| `## When to Use` | The scenario it fits, the problem it solves, any prerequisites |
| `## The Prompt` | The fenced, copy-paste prompt. This is the recipe |
| `## Example` | `### Input` and `### Output` showing realistic results |
| `## Customization Tips` | How to adapt it to other languages, stacks, or stricter rules |
| `## Cost` | Optional: a rough cost range for running the recipe |
| `## Tags` | Backtick-quoted tags for discoverability |

[CONTRIBUTING.md](CONTRIBUTING.md#recipe-format) has the full template and is the source of truth for the format. `bash scripts/lint-recipes.sh` checks every recipe against it, and CI runs the same check on every pull request.

## Contributing

Have a useful AI workflow? Share it!

1. Fork this repo
2. Create a recipe in the appropriate `recipes/` subdirectory
3. Follow the [recipe format](#recipe-format)
4. Add a row for it to the index above
5. Run `bash scripts/lint-recipes.sh` to check both
6. Submit a PR

**Ideas for new recipes?** [Open an issue](https://github.com/Sagargupta16/agent-recipes/issues/new?template=recipe-request.yml)!

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

## Roadmap

The open issues are a curated backlog of wanted recipes, not a bug list. Most are one recipe each, and several are labelled as good first issues:

- [Accessibility audit recipe](https://github.com/Sagargupta16/agent-recipes/issues/1)
- [Database schema reviewer recipe](https://github.com/Sagargupta16/agent-recipes/issues/2)
- [Python-specific recipes](https://github.com/Sagargupta16/agent-recipes/issues/4)
- [Refactoring recipes category](https://github.com/Sagargupta16/agent-recipes/issues/8)
- [Infrastructure recipes (K8s, Terraform, Helm)](https://github.com/Sagargupta16/agent-recipes/issues/13)

Browse the full backlog by label: [good first issue](https://github.com/Sagargupta16/agent-recipes/labels/good%20first%20issue), [help wanted](https://github.com/Sagargupta16/agent-recipes/labels/help%20wanted), [roadmap](https://github.com/Sagargupta16/agent-recipes/labels/roadmap).

## More AI Developer Tools

| Project | Description |
|---------|-------------|
| [claude-code-recipes](https://github.com/Sagargupta16/claude-code-recipes) | 47 copy-paste recipes for Claude Code - commands, subagents, hooks, skills, MCP integration, and workflow patterns |
| [claude-cost-optimizer](https://github.com/Sagargupta16/claude-cost-optimizer) | Save 30-60% on Claude Code costs -- proven strategies, real benchmarks, copy-paste configs, and interactive tools |
| [ai-git-hooks](https://github.com/Sagargupta16/ai-git-hooks) | AI-powered git hooks - auto-review diffs, generate commit messages, scan for secrets. Supports Claude, OpenAI, and Ollama |
| [mcp-toolkit](https://github.com/Sagargupta16/mcp-toolkit) | TypeScript middleware toolkit for MCP servers - authentication, caching, rate limiting, CORS, logging (beta) |
| [claude-skills](https://github.com/Sagargupta16/claude-skills) | Custom Claude Code plugin marketplace with skills for FARM stack, open source contributions, repo maintenance, and portfolio management |

## License

[MIT](LICENSE)
