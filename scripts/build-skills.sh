#!/usr/bin/env bash
# Generate an Agent Skill (skills/<name>/SKILL.md) from every recipe, so the
# recipes install with `npx skills add Sagargupta16/agent-recipes` or as the
# agent-recipes Claude Code plugin instead of being copied by hand.
#
# The recipe stays the source of truth. A skill carries the recipe's prompt as
# its instructions and the recipe's "When to Use" bullets in its description,
# which is what an agent reads to decide when to load it. The worked example is
# left out for the same reason scripts/extract-prompt.sh leaves it out: an agent
# would read the example output as part of its instructions.
#
# Usage:
#   bash scripts/build-skills.sh           regenerate skills/ from recipes/
#   bash scripts/build-skills.sh --check   fail if skills/ is stale or invalid
#
# Exits 0 on success, 1 with a list of problems otherwise.

set -uo pipefail

cd "$(dirname "$0")/.."

REPO_URL="https://github.com/Sagargupta16/agent-recipes"
# Limits from the Agent Skills specification (agentskills.io/specification).
MAX_NAME=64
MAX_DESCRIPTION=1024
MAX_BODY_LINES=500

mode="write"
case "${1:-}" in
"") ;;
--check) mode="check" ;;
*)
	printf 'usage: %s [--check]\n' "$0" >&2
	exit 64
	;;
esac

FAILURES=0
fail() {
	printf '%s\n' "$1"
	FAILURES=$((FAILURES + 1))
}

out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

# "When to Use" bullets, minus the Prerequisites one, joined into one clause:
# "before merging ...; when reviewing ...". Each bullet's first letter is
# lowercased unless the word is an acronym, so "CI" stays "CI".
when_clause() {
	awk '
		$0 == "## When to Use" { s = 1; next }
		s && /^## / { exit }
		s && /^- / && !/^- Prerequisites/ {
			b = substr($0, 3)
			sub(/\.$/, "", b)
			if (substr(b, 2, 1) ~ /[a-z]/) b = tolower(substr(b, 1, 1)) substr(b, 2)
			print b
		}
	'
}

count=0
seen=" "
while IFS= read -r recipe; do
	[ -n "$recipe" ] || continue
	count=$((count + 1))
	name="$(basename "$recipe" .md)"
	text="$(tr -d '\r' < "$recipe")"

	if ! printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
		fail "$recipe: '$name' is not a valid skill name (lowercase letters, digits, single hyphens)"
		continue
	fi
	if [ "${#name}" -gt "$MAX_NAME" ]; then
		fail "$recipe: skill name '$name' is longer than $MAX_NAME characters"
	fi
	case "$seen" in
	*" $name "*)
		fail "$recipe: another recipe already uses the file name '$name.md', and skill names must be unique"
		continue
		;;
	esac
	seen="$seen$name "

	title="$(printf '%s\n' "$text" | sed -n '1s/^# //p')"
	summary="$(printf '%s\n' "$text" | sed -n '3s/^> //p')"
	if [ -z "$title" ] || [ -z "$summary" ]; then
		fail "$recipe: needs a '# Title' on line 1 and a '> description' on line 3"
		continue
	fi

	if ! prompt="$(bash scripts/extract-prompt.sh "$recipe" 2>/dev/null)"; then
		fail "$recipe: scripts/extract-prompt.sh cannot read a prompt out of this file"
		continue
	fi

	# Build the description, dropping trailing bullets until it fits the limit.
	bullets=()
	while IFS= read -r b; do
		[ -n "$b" ] && bullets+=("$b")
	done <<EOF
$(printf '%s\n' "$text" | when_clause)
EOF
	n=${#bullets[@]}
	while :; do
		description="$summary"
		if [ "$n" -gt 0 ]; then
			clause="$(printf '%s; ' "${bullets[@]:0:$n}")"
			description="$summary Use it ${clause%; }."
		fi
		if [ "${#description}" -le "$MAX_DESCRIPTION" ] || [ "$n" -eq 0 ]; then
			break
		fi
		n=$((n - 1))
	done
	if [ "${#description}" -gt "$MAX_DESCRIPTION" ]; then
		fail "$recipe: the '>' description alone is longer than $MAX_DESCRIPTION characters"
	fi

	mkdir -p "$out/$name"
	{
		printf -- '---\n'
		printf 'name: %s\n' "$name"
		printf 'description: >-\n  %s\n' "$description"
		printf -- '---\n\n'
		printf '<!-- Generated from %s by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->\n\n' "$recipe"
		printf '# %s\n\n' "$title"
		printf '%s\n\n' "$prompt"
		printf -- '---\n\n'
		printf 'The source recipe, with a worked example and customization tips, is %s/blob/main/%s\n' "$REPO_URL" "$recipe"
	} > "$out/$name/SKILL.md"

	body_lines="$(awk 'f == 2 { n++ } /^---$/ && f < 2 { f++ } END { print n + 0 }' "$out/$name/SKILL.md")"
	if [ "$body_lines" -gt "$MAX_BODY_LINES" ]; then
		fail "$recipe: the generated SKILL.md body is $body_lines lines, over the $MAX_BODY_LINES the spec recommends"
	fi
done <<EOF
$(find recipes -type f -name '*.md' | sort)
EOF

if [ "$count" -eq 0 ]; then
	fail "recipes/: no recipe files found"
fi

# The plugin manifest and the marketplace entry must carry the same version, or
# /plugin shows one number while the install pins another.
if command -v jq > /dev/null 2>&1; then
	plugin_version="$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)"
	market_version="$(jq -r '.plugins[] | select(.name == "agent-recipes") | .version' .claude-plugin/marketplace.json 2>/dev/null)"
	if [ -z "$plugin_version" ] || [ "$plugin_version" = "null" ]; then
		fail ".claude-plugin/plugin.json: missing or unreadable version"
	elif [ "$plugin_version" != "$market_version" ]; then
		fail ".claude-plugin/marketplace.json: agent-recipes is version '$market_version' but plugin.json says '$plugin_version'"
	fi
	changelog_version="$(tr -d '\r' < CHANGELOG.md | sed -n 's/^## \[\([^]]*\)\].*/\1/p' | head -1)"
	if [ -n "$plugin_version" ] && [ "$plugin_version" != "$changelog_version" ]; then
		fail ".claude-plugin/plugin.json: version '$plugin_version' does not match the newest CHANGELOG.md entry '$changelog_version'"
	fi
	# Both descriptions open with the skill count, so a new recipe has to update them.
	for manifest in plugin.json marketplace.json; do
		if ! jq -r '.. | .description? // empty' ".claude-plugin/$manifest" | grep -q "^$count developer-task recipes"; then
			fail ".claude-plugin/$manifest: the plugin description must start with '$count developer-task recipes'"
		fi
	done
else
	printf 'jq not found, skipping the plugin version check\n' >&2
fi

if [ "$FAILURES" -gt 0 ]; then
	printf '\n%s skill build problem(s) across %s recipe file(s).\n' "$FAILURES" "$count"
	exit 1
fi

if [ "$mode" = "check" ]; then
	if ! diff -r "$out" skills > /dev/null 2>&1; then
		diff -r "$out" skills | head -40
		printf '\nskills/ is out of date with recipes/. Run: bash scripts/build-skills.sh\n'
		exit 1
	fi
	printf 'All %s skills in skills/ match their recipes.\n' "$count"
	exit 0
fi

rm -rf skills
cp -r "$out" skills
printf 'Generated %s skills in skills/ from recipes/.\n' "$count"
