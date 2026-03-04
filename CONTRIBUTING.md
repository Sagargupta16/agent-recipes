# Contributing to Agent Recipes

Thank you for your interest in contributing to Agent Recipes! This project thrives on community contributions. Whether you're submitting a new recipe, improving an existing one, or fixing a typo, your help is appreciated.

## Table of Contents

- [How to Contribute](#how-to-contribute)
- [Recipe Format](#recipe-format)
- [Quality Standards](#quality-standards)
- [Testing Your Recipe](#testing-your-recipe)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Issues](#reporting-issues)

## How to Contribute

1. **Fork** the repository
2. **Create a branch** for your contribution (`git checkout -b add-recipe/your-recipe-name`)
3. **Write or edit** your recipe following the format below
4. **Test** your recipe with at least one AI coding agent
5. **Submit a pull request** with a clear description

## Recipe Format

Every recipe must follow this structure. Consistency makes the collection easy to browse and use.

```markdown
# Recipe Title

> One-line description of what this recipe does.

## When to Use

Explain the scenario where this recipe is useful. Be specific about:
- What problem it solves
- What kind of codebase or project it applies to
- Any prerequisites or assumptions

## The Prompt

\`\`\`
The actual prompt goes here. This is the core value of the recipe.
Make it detailed, specific, and ready to copy-paste.
\`\`\`

## Example

### Input
Describe or show what the user provides.

### Output
Show a realistic example of what the agent produces.

## Customization Tips

- Bullet points explaining how to adapt the prompt
- Variations for different languages, frameworks, or contexts
- Optional additions or modifications

## Tags

`tag1` `tag2` `tag3`
```

## Quality Standards

Before submitting a recipe, ensure it meets these standards:

### Prompt Quality
- **Specific**: The prompt should give clear, actionable instructions, not vague requests
- **Structured**: Use numbered steps, sections, or checklists within the prompt
- **Complete**: The prompt should produce useful output without needing follow-up clarification
- **Tested**: You have actually used this prompt with an AI coding agent and verified the results

### Documentation Quality
- **Clear "When to Use"**: A reader should immediately know if this recipe fits their situation
- **Realistic Example**: Show a real-world example, not a trivial "hello world" case
- **Useful Customization Tips**: Help users adapt the recipe to their specific needs

### General Guidelines
- Use clear, concise language
- Avoid jargon unless it is standard terminology for the target audience
- Keep prompts focused on a single task (compose multiple recipes for complex workflows)
- Include relevant tags for discoverability

## Testing Your Recipe

Before submitting, test your recipe against at least one of these agents:

- Claude Code (Anthropic)
- GitHub Copilot
- Cursor
- Aider
- Cody (Sourcegraph)

### Testing Checklist

- [ ] The prompt produces correct, useful output on the first try
- [ ] The output follows the instructions in the prompt without omissions
- [ ] The prompt works on a real codebase, not just a toy example
- [ ] Edge cases mentioned in the prompt are actually handled in the output
- [ ] The prompt works without needing additional context beyond what it specifies

## Submitting a Pull Request

1. **One recipe per PR** (unless they are closely related, e.g., a set of migration recipes)
2. **Use the PR template** and fill out all sections
3. **Place your recipe** in the correct category folder under `recipes/`
4. **Name your file** descriptively using kebab-case (e.g., `generate-unit-tests.md`)
5. **Update the README** if you are adding a new category

### Commit Message Convention

```
add: recipe-name - Short description
fix: recipe-name - What was fixed
improve: recipe-name - What was improved
docs: Description of documentation change
```

## Reporting Issues

- **Recipe not working?** Open an issue with the agent you tested, the codebase context, and the output you received.
- **Have an idea for a recipe?** Use the "Recipe Request" issue template.
- **Found a bug in a recipe?** Open an issue describing the problem and expected behavior.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code. Please report unacceptable behavior by opening an issue.

---

Thank you for helping make Agent Recipes a valuable resource for the developer community!
