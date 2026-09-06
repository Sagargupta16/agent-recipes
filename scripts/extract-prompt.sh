#!/usr/bin/env bash
# Print only the fenced prompt from a recipe, so you can pipe it straight into
# an agent without also feeding it the recipe's example output and tags.
#
# Usage:
#   bash scripts/extract-prompt.sh recipes/code-review/pr-review.md
#   claude -p "$(bash scripts/extract-prompt.sh recipes/code-review/pr-review.md)"

set -uo pipefail

if [ "$#" -ne 1 ]; then
	printf 'usage: %s <recipe.md>\n' "$0" >&2
	exit 64
fi

recipe="$1"

if [ ! -f "$recipe" ]; then
	printf '%s: not a file\n' "$recipe" >&2
	exit 66
fi

# The prompt is the outer fenced block under "## The Prompt". Some prompts
# contain nested fences (for example ```suggestion), so track them rather than
# stopping at the first closing fence. Headings inside the prompt body such as
# "## 1. DISCOVERY" are part of the prompt, not the end of the section.
prompt=$(tr -d '\r' < "$recipe" | awk '
	state == 0 && $0 == "## The Prompt" { state = 1; next }
	state == 1 && /^```/ { state = 2; next }
	state == 1 && /^## / { exit }
	state == 2 {
		if ($0 ~ /^```[^`]/) { nested = 1; print; next }
		if ($0 == "```") {
			if (nested) { nested = 0; print; next }
			exit
		}
		print
	}
')

if [ -z "$prompt" ]; then
	printf '%s: no fenced block found under "## The Prompt"\n' "$recipe" >&2
	exit 65
fi

printf '%s\n' "$prompt"
