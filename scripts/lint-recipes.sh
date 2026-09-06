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

REQUIRED_HEADINGS=(
	"## When to Use"
	"## The Prompt"
	"## Example"
	"### Input"
	"### Output"
	"## Customization Tips"
	"## Tags"
)

if [ ! -f "$README" ]; then
	fail "$README: not found, cannot verify the recipe index"
	exit 1
fi

# Strip carriage returns so the checks behave the same on CRLF checkouts.
readme_text="$(tr -d '\r' < "$README")"

recipes=$(find recipes -type f -name '*.md' | sort)

if [ -z "$recipes" ]; then
	fail "recipes/: no recipe files found"
	exit 1
fi

count=0
for recipe in $recipes; do
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

	for heading in "${REQUIRED_HEADINGS[@]}"; do
		if ! printf '%s\n' "$text" | grep -qxF "$heading"; then
			fail "$recipe: missing required heading '$heading'"
		fi
	done

	# Tags must not be empty.
	tags=$(printf '%s\n' "$text" | sed -n '/^## Tags$/,$p' | sed -n '2,$p' | grep -m1 '[^[:space:]]' || true)
	case "$tags" in
	'`'*) ;;
	*) fail "$recipe: '## Tags' must be followed by at least one \`tag\`" ;;
	esac

	# Every recipe needs an index row in the README.
	if ! printf '%s\n' "$readme_text" | grep -qF "]($recipe)"; then
		fail "$recipe: no link to it in $README (every recipe needs an index row)"
	fi
done

# And every README index link must point at a recipe that exists.
while IFS= read -r link; do
	[ -n "$link" ] || continue
	if [ ! -f "$link" ]; then
		fail "$README: index links to $link, which does not exist"
	fi
done <<EOF
$(printf '%s\n' "$readme_text" | grep -o '](recipes/[^)]*\.md)' | sed 's/^](//; s/)$//' | sort -u)
EOF

if [ "$FAILURES" -gt 0 ]; then
	printf '\n%s recipe lint problem(s) across %s recipe file(s).\n' "$FAILURES" "$count"
	exit 1
fi

printf 'All %s recipes conform to the format in CONTRIBUTING.md and are indexed in %s.\n' "$count" "$README"
