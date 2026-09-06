# Changelog

## [1.1.0] - 2026-09-06

Three new recipes bring the collection to 22, and the repository now checks itself: a weekly link check plus a lint that enforces the recipe format and keeps the README index in sync. This release also brings the three 2026-03-24 recipes up to the documented format, which they never followed.

### Added

- Three recipes: Multi-Repo PR Check, Upgrade Dependencies, and Background Deploy Monitor. Total is now 22 recipes across 6 categories
- Link checking in CI via lychee, on every pull request and every Monday, covering the README, the recipes, and the contributor docs
- `scripts/lint-recipes.sh` and a Recipe Lint workflow, asserting the required headings, the one-line description, non-empty tags, and a README index row for every recipe
- `scripts/extract-prompt.sh`, which prints only the prompt from a recipe so the worked example is not fed to the agent as an instruction
- Roadmap and cross-project sections in the README, plus a composing-recipes section showing how to chain recipes
- Renovate configuration for monthly grouped dependency updates
- License, recipe count, and contributions badges in the README

### Changed

- Multi-Repo PR Check, Upgrade Dependencies, and Background Deploy Monitor now follow the format in CONTRIBUTING.md: a one-line description, a fenced prompt, a worked example with input and output, customization tips, and tags. Their cost estimates are preserved in an optional `## Cost` section, which CONTRIBUTING.md now documents
- CONTRIBUTING.md is the single source of truth for the recipe format. The README's Recipe Format section summarizes it and links there, instead of specifying a second, conflicting version
- The documented tag convention no longer includes a difficulty tag, since no recipe uses one
- The README usage commands extract just the prompt block rather than piping the whole recipe file, and create `.claude/commands/` before writing to it

### Fixed

- Removed a duplicate pull request template that collided on case-insensitive filesystems (#45, #46)
- `.editorconfig` set a 3 space indent, inherited from a deleted Prettier config, which fought the 2 space indentation used across the recipes and the workflow files. It is now 2, and markdown keeps its trailing whitespace so hard line breaks survive a save
- SECURITY.md now says what a security report means for a collection of prompts, instead of a bare `Version: 1` line

### Removed

- Scaffolding leftovers with no code behind them: `.nvmrc`, `.python-version`, `.prettierrc`, `.dockerignore`, and the `.maintenance` placeholder

## [1.0.0] - 2026-03-16

- Add PR template for recipe contributions
- Fix broken links and add .gitignore

## [0.1.0] - 2026-03-04

- Initial release: 19 AI agent recipes across 6 categories
