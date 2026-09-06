# Changelog

## [Unreleased]

Everything landed since 1.0.0. The repository has no git tags and no GitHub releases, so this stays `[Unreleased]` until one is cut.

The repository now checks itself: a link check plus a lint that enforces the recipe format and keeps the README index in sync. The three recipes added on 2026-03-24, after 1.0.0 shipped, are also brought up to the format CONTRIBUTING.md documents, which they did not follow when they landed.

### Added

- Three recipes, added on 2026-03-24 in db9f319: Multi-Repo PR Check, Upgrade Dependencies, and Background Deploy Monitor. Total is now 22 recipes across 6 categories
- Link checking in CI via lychee, on every pull request and every Monday, covering the README, the recipes, and the contributor docs
- `scripts/lint-recipes.sh` and a Recipe Lint workflow. For every recipe it asserts the title, the `>` description, the section headings in order with `## Cost` as the only optional one, a fenced prompt that `scripts/extract-prompt.sh` can read back, tags that are non-empty and carry no difficulty, and a row in a README index table. It also checks that every README link into `recipes/` points at a file that exists
- `scripts/extract-prompt.sh`, which prints only the prompt from a recipe so the worked example is not fed to the agent as an instruction
- Roadmap and cross-project sections in the README, plus a composing-recipes section showing how to chain recipes
- Renovate configuration for monthly grouped dependency updates
- License, recipe count, and contributions badges in the README
- `[*.md] trim_trailing_whitespace = false` in `.editorconfig`, so an editor does not strip the two trailing spaces that make a markdown hard line break

### Changed

- Multi-Repo PR Check, Upgrade Dependencies, and Background Deploy Monitor now follow the format in CONTRIBUTING.md: a one-line description, a fenced prompt, a worked example with input and output, customization tips, and tags. Their cost estimates are preserved in an optional `## Cost` section, which CONTRIBUTING.md now documents
- CONTRIBUTING.md is the single source of truth for the recipe format. The README's Recipe Format section summarizes it and links there, instead of specifying a second, conflicting version
- The documented tag convention no longer includes a difficulty tag, since no recipe uses one
- The README usage commands extract just the prompt block rather than piping the whole recipe file, and create `.claude/commands/` before writing to it

### Fixed

- Removed a duplicate pull request template that collided on case-insensitive filesystems (#45, #46)
- `.editorconfig` set a 3 space indent, inherited from the `.prettierrc` deleted in 2d3e46a, which fought the 2 space indentation used across the recipes and the workflow files. It is now 2
- SECURITY.md now says what a security report means for a collection of prompts, instead of a bare `Version: 1` line

### Removed

- Scaffolding leftovers with no code behind them: `.nvmrc`, `.python-version`, `.prettierrc`, `.dockerignore`, and the `.maintenance` placeholder

## [1.0.0] - 2026-03-16

- Add PR template for recipe contributions
- Fix broken links and add .gitignore

## [0.1.0] - 2026-03-04

- Initial release: 19 AI agent recipes across 6 categories
