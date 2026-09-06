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

No unit tests. `bash scripts/lint-recipes.sh` checks every recipe against the format in CONTRIBUTING.md and checks the README index in both directions; the Recipe Lint workflow runs it on every PR. Recipe *quality* is still manual: per CONTRIBUTING.md, every recipe must be tested against at least one real AI coding agent before submission.

## Entry points

- `README.md` -- recipe index; every recipe has a table row here, grouped by category
- `recipes/<category>/<name>.md` -- the recipes themselves (22 across code-review, testing, migrations, documentation, security, devops)

## Key files

- `CONTRIBUTING.md` -- canonical recipe format (title, `>` description, When to Use, The Prompt, Example with Input/Output, Customization Tips, optional Cost, Tags) and quality standards
- `scripts/lint-recipes.sh` -- the format and README index check, run by CI
- `scripts/extract-prompt.sh` -- prints only the fenced prompt from a recipe, so an agent is not fed the worked example as an instruction
- `.github/ISSUE_TEMPLATE/recipe-request.yml` -- intake for new recipe ideas

## Gotchas

- `.github/workflows/` holds `link-check.yml` (lychee, on PRs and every Monday) and `recipe-lint.yml` (the format lint, on PRs and pushes to main). Renovate config extends `Sagargupta16/shared-workflows`.
- New recipe = two edits plus a check: the recipe file in the right `recipes/` subfolder (kebab-case name), its README table row, then `bash scripts/lint-recipes.sh`.
- Prompts and example outputs live inside fenced blocks, and prompt bodies carry their own `##` headings. Anything that scans a recipe's structure has to skip fenced content or it will read `## OUTPUT FORMAT` as a recipe section.

## Repo-specific rules

- CONTRIBUTING.md defines its own commit convention for external contributors (`add:` / `improve:` recipe prefixes). Sagar's own commits still follow root conventional commits (`feat:` / `fix:` / `docs:`).
- One recipe per PR unless closely related (per CONTRIBUTING.md).
