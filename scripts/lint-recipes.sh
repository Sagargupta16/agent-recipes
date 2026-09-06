#!/usr/bin/env bash
# Check every recipe against the format defined in CONTRIBUTING.md, and check
# that the README index and the recipes/ tree agree with each other.
#
# Usage: bash scripts/lint-recipes.sh
# Exits 0 when everything conforms, 1 with a list of problems otherwise.

set -uo pipefail

cd "$(dirname "$0")/.."

README="README.md"
FAILURES=0

fail() {
	printf '%s\n' "$1"
	FAILURES=$((FAILURES + 1))
}

# The section sequence every recipe must follow, in this order. "## Cost" is the
# one optional section and may only appear between Customization Tips and Tags.
REQUIRED_SECTIONS="## When to Use
## The Prompt
## Example
### Input
### Output
## Customization Tips
## Tags"

OPTIONAL_SECTIONS="## When to Use
## The Prompt
## Example
### Input
### Output
## Customization Tips
## Cost
## Tags"

# The tag convention has no difficulty axis, so these are not valid tags.
DIFFICULTY_TAGS="beginner intermediate advanced easy medium hard difficulty"

if [ ! -f "$README" ]; then
	fail "$README: not found, cannot verify the recipe index"
	exit 1
fi

# Strip carriage returns so the checks behave the same on CRLF checkouts.
readme_text="$(tr -d '\r' < "$README")"

if [ -z "$(find recipes -type f -name '*.md')" ]; then
	fail "recipes/: no recipe files found"
	exit 1
fi

count=0
while IFS= read -r recipe; do
	[ -n "$recipe" ] || continue
	count=$((count + 1))
	text="$(tr -d '\r' < "$recipe")"

	# Line 1 must be the recipe title.
	case "$(printf '%s\n' "$text" | sed -n '1p')" in
	'# '*) ;;
	*) fail "$recipe: line 1 must be a level-1 title (# Recipe Title)" ;;
	esac

	# Line 3 must be the one-line blockquote description.
	case "$(printf '%s\n' "$text" | sed -n '3p')" in
	'> '*) ;;
	*) fail "$recipe: line 3 must be a '>' one-line description (see CONTRIBUTING.md)" ;;
	esac

	# Section headings only count outside fenced blocks. A prompt body routinely
	# contains its own "## OUTPUT FORMAT" or "### Input" lines, and so does the
	# fenced example output, and neither is a section of the recipe.
	sections="$(printf '%s\n' "$text" | awk '
		/^```/ {
			if (!fence) { fence = 1; nested = 0; next }
			if ($0 ~ /^```[^`]/) { nested = 1; next }
			if (nested) { nested = 0; next }
			fence = 0
			next
		}
		!fence && /^#{2,}[[:space:]]/ { print }
	')"

	if [ "$sections" != "$REQUIRED_SECTIONS" ] && [ "$sections" != "$OPTIONAL_SECTIONS" ]; then
		fail "$recipe: sections must be exactly, in order: When to Use, The Prompt, Example (Input, Output), Customization Tips, optionally Cost, Tags"
	fi

	# "## The Prompt" must open a fenced block immediately, because that fence is
	# what scripts/extract-prompt.sh hands to an agent.
	after_prompt="$(printf '%s\n' "$text" | sed -n '/^## The Prompt$/,$p' | sed -n '2,$p' | grep -m1 '[^[:space:]]' || true)"
	case "$after_prompt" in
	'```'*) ;;
	*) fail "$recipe: '## The Prompt' must be followed by a fenced code block holding only the prompt" ;;
	esac

	# And the fence has to be one extract-prompt.sh can actually read back.
	if ! extracted="$(bash scripts/extract-prompt.sh "$recipe" 2>/dev/null)" || [ -z "$extracted" ]; then
		fail "$recipe: scripts/extract-prompt.sh cannot read a prompt out of this file"
	fi

	# Tags must not be empty, and must not encode a difficulty.
	tags=$(printf '%s\n' "$text" | sed -n '/^## Tags$/,$p' | sed -n '2,$p' | grep -m1 '[^[:space:]]' || true)
	case "$tags" in
	'`'*) ;;
	*) fail "$recipe: '## Tags' must be followed by at least one \`tag\`" ;;
	esac
	for banned in $DIFFICULTY_TAGS; do
		if printf '%s\n' "$tags" | grep -qF "\`$banned\`"; then
			fail "$recipe: '\`$banned\`' is a difficulty tag, which the convention in CONTRIBUTING.md does not use"
		fi
	done

	# Every recipe needs a row in one of the README index tables. A prose link
	# elsewhere in the README is not an index row.
	recipe_pattern="$(printf '%s\n' "$recipe" | sed 's/[.[\*^$]/\\&/g')"
	if ! printf '%s\n' "$readme_text" | grep -qE "^\| \[[^]]+\]\($recipe_pattern\) \|.*\|[[:space:]]*$"; then
		fail "$recipe: no index table row for it in $README (expected '| [Title]($recipe) | Description |')"
	fi
done <<EOF
$(find recipes -type f -name '*.md' | sort)
EOF

# And every README link into recipes/ must point at a recipe that exists, with or
# without a trailing #anchor.
while IFS= read -r link; do
	[ -n "$link" ] || continue
	if [ ! -f "$link" ]; then
		fail "$README: links to $link, which does not exist"
	fi
done <<EOF
$(printf '%s\n' "$readme_text" | grep -o '](recipes/[^)]*\.md[^)]*)' | sed 's/^](//; s/)$//; s/#.*$//' | sort -u)
EOF

if [ "$FAILURES" -gt 0 ]; then
	printf '\n%s recipe lint problem(s) across %s recipe file(s).\n' "$FAILURES" "$count"
	exit 1
fi

printf 'All %s recipes conform to the format in CONTRIBUTING.md and are indexed in %s.\n' "$count" "$README"
