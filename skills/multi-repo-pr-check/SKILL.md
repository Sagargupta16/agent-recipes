---
name: multi-repo-pr-check
description: >-
  Triage every open pull request you own across all your repositories in one pass, reporting CI status, review state, and the next action for each. Use it at the start of a coding session, to see which PRs need attention before you open anything new; before rebasing or updating a branch, to confirm nothing upstream has changed the plan; during weekly PR triage when you maintain more than a handful of repositories; when PRs go stale because nothing surfaces them in a single place.
---

<!-- Generated from recipes/code-review/multi-repo-pr-check.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Multi-Repo PR Check

Triage all of my open pull requests across every repository I contribute to. This is a read-only report: do not push, merge, close, approve, or comment on anything.

## 1. DISCOVERY

Run: gh search prs author:@me is:open --json repository,title,number,url

## 2. PER-PR CHECKS

For each PR found, gather:

- Merge readiness: gh api repos/{owner}/{repo}/pulls/{number} -- read `draft`, `mergeable`, `mergeable_state`, `head.sha`, `created_at`, `updated_at`
- CI detail: gh api repos/{owner}/{repo}/commits/{head_sha}/check-runs -- name every failing or pending check, not just the rollup
- Review state: gh api repos/{owner}/{repo}/pulls/{number}/reviews -- approvals, change requests, and who asked for them
- Open feedback: gh api repos/{owner}/{repo}/pulls/{number}/comments -- treat comments newer than my last commit as unaddressed
- Age: days since the PR was opened, and days since the last push

These calls are independent and read-only, so fetch the PRs concurrently rather than one after another.

## 3. CLASSIFICATION

Put each PR in exactly one bucket:

- BLOCKED: failing CI, merge conflicts, or requested changes I have not answered
- READY: approved (or review not required), all checks green, mergeable
- WAITING: green and conflict-free, but review has not happened yet
- PENDING: checks still queued or running, so there is nothing to act on yet
- DRAFT: still marked as a draft

Then, on top of its bucket, flag any PR with no push and no review activity for more than 14 days as STALE.

## 4. OUTPUT

Start with one table, sorted BLOCKED, READY, WAITING, PENDING, DRAFT:

| Repo | # | Title | CI | Reviews | Age | Next action |

Then, in priority order, list only the PRs that need something from me. For each one, state the single concrete next step: rebase onto the base branch, fix a named failing check, reply to a specific review comment, or merge.

Rules for the report:
- Name the failing check and its failure reason. "CI red" is not an acceptable answer.
- If `mergeable_state` is `dirty`, say which base branch it conflicts with.
- Call out any PR older than 14 days explicitly, even if it is green.
- End with a one-line count per bucket, plus how many of them are flagged STALE.

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/code-review/multi-repo-pr-check.md
