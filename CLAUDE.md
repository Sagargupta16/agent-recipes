# CLAUDE.md

> This file stacks on top of the workspace root at `C:\Code\GitHub\`:
> - Root [`CLAUDE.md`](../../CLAUDE.md) -- voice, rules, routing map, references, skills, slash commands, conventions.
> - Root [`MEMORY.md`](../../MEMORY.md) -- live facts across repos.
> - Root [`STATUS.md`](../../STATUS.md) -- live PR/CI/security dashboard.
> - [`.claude/resources/`](../../.claude/resources/README.md) -- deep reference for collaboration, workflow, git, OSS, debugging, voice.
>
> Read those first. The guidance below only adds **repo-specific context** -- it does not override anything in the root.

## Project

Community-driven collection of copy-paste AI agent prompts ("recipes") for developer tasks -- code review, testing, migrations, docs, security, DevOps. Public repo at github.com/Sagargupta16/agent-recipes, MIT, consumed directly from GitHub (no site, no package).

## Stack

- **Language**: Markdown only -- no application code
- **Framework**: none
- **Database**: none
- **Package manager**: none (no package.json / pyproject)
- **Deploy target**: none -- users copy recipes straight from the repo

## Run

Nothing to install, build, or run. Edit markdown, commit, push.

## Test

No test suite. Quality bar is manual: per CONTRIBUTING.md, every recipe must be tested against at least one real AI coding agent before submission.

## Entry points

- `README.md` -- recipe index; every recipe has a table row here, grouped by category
- `recipes/<category>/<name>.md` -- the recipes themselves (22 across code-review, testing, migrations, documentation, security, devops)

## Key files

- `CONTRIBUTING.md` -- canonical recipe format (title, When to Use, The Prompt, Example, Customization Tips, Tags) and quality standards
- `.github/ISSUE_TEMPLATE/recipe-request.yml` -- intake for new recipe ideas

## Gotchas

- README's "Recipe Format" snippet drifts from CONTRIBUTING.md (`## Prompt` vs `## The Prompt`, `## Customization` vs `## Customization Tips`). CONTRIBUTING.md is the contributor-facing spec; reconcile before enforcing either.
- `.nvmrc` (19), `.python-version` (3.14), `.prettierrc` (tabWidth 3), `.dockerignore` are scaffolding leftovers -- there is no JS/Python/Docker code. Don't infer a toolchain from them.
- `.github/workflows/` exists but is empty -- no CI. Renovate config extends `Sagargupta16/shared-workflows`.
- New recipe = two edits: the recipe file in the right `recipes/` subfolder (kebab-case name) plus its README table row.

## Repo-specific rules

- CONTRIBUTING.md defines its own commit convention for external contributors (`add:` / `improve:` recipe prefixes). Sagar's own commits still follow root conventional commits (`feat:` / `fix:` / `docs:`).
- One recipe per PR unless closely related (per CONTRIBUTING.md).
