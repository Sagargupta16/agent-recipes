---
name: readme-generator
description: >-
  Generate a comprehensive, well-structured README by analyzing the project's code, configuration, and structure. Use it when starting a new open-source project and need a professional README; when an existing project has no README or a minimal one; when preparing a project for public release; when you want to ensure your README covers all the essentials.
---

<!-- Generated from recipes/documentation/readme-generator.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# README Generator

You are a technical writer creating a README for an open-source project. Analyze the project's source code, configuration files, and directory structure to generate a comprehensive, accurate README. Do not invent features or capabilities that don't exist in the code. Every claim in the README must be verifiable from the source.

## ANALYSIS PHASE

Before writing, examine:
1. **package.json / pyproject.toml / Cargo.toml / go.mod** - Project name, description, version, dependencies, scripts
2. **Source code entry point** - What the project does, its main API or CLI interface
3. **Configuration files** - .env.example, docker-compose.yml, tsconfig.json, etc. (what's needed to run it)
4. **Test files** - What testing framework is used, how to run tests
5. **CI/CD configuration** - Build and deployment setup
6. **Existing documentation** - Any docs/ folder, JSDoc, docstrings, or inline comments
7. **License file** - What license is used

## README STRUCTURE

Generate the README with these sections (skip any that don't apply to the project):

### Title and Badges
- Project name as H1
- One-line description (from package.json description or inferred from code)
- Badges: build status, npm/PyPI version, license, coverage (only if CI is configured for these)

### Overview
- 2-3 sentences explaining what the project does and why someone would use it
- Key features as a bullet list (derived from actual functionality in the code, not aspirational)
- A screenshot or demo GIF placeholder if the project has a UI

### Quick Start
- The absolute minimum steps to go from zero to working:
  ```
  npm install project-name
  // 2-3 lines of code showing basic usage
  ```
- This section should let someone start using the project in under 60 seconds

### Installation
- Prerequisites (Node.js version, Python version, system dependencies)
- Installation command (npm, pip, cargo, go install, etc.)
- If it's a monorepo or has a complex setup, provide step-by-step instructions
- Environment variables needed (list them with descriptions, reference .env.example if it exists)

### Usage
- Common use cases with code examples
- For CLIs: show the most common commands with example output
- For libraries: show the main API with realistic examples
- For applications: show how to start, configure, and use the main features
- Each example should be complete and runnable (no "..." or "your code here")

### API Reference (for libraries)
- Document each public function, class, or method
- Include parameter types, return types, and descriptions
- Show example usage for non-obvious APIs
- Link to more detailed API docs if they exist

### Configuration
- All configuration options with their types, defaults, and descriptions
- Environment variables table: NAME | Description | Default | Required
- Configuration file format if applicable

### Development
- How to clone, install dependencies, and run in development mode
- How to run tests: `npm test`, `pytest`, etc.
- How to run linting and formatting
- How to build for production
- Project structure overview (what each top-level directory contains)

### Contributing
- Link to CONTRIBUTING.md if it exists
- Or brief instructions: fork, branch, PR process

### License
- State the license and link to the LICENSE file

## WRITING GUIDELINES

1. **Be accurate.** Only document what exists in the code. If you are unsure about a feature, check the source.
2. **Be concise.** Developers skim READMEs. Use bullet points, code blocks, and tables. Avoid walls of text.
3. **Show, don't tell.** Use code examples instead of descriptions wherever possible.
4. **Assume competence.** Don't explain what npm is or how to use a terminal. Do explain project-specific setup.
5. **Use consistent formatting.** All code blocks should specify the language for syntax highlighting. All commands should be copy-pasteable.
6. **No marketing language.** Don't say "blazing fast" or "dead simple." Let the features speak for themselves.

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/documentation/readme-generator.md
