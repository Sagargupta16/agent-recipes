# Multi-Repo PR Check

> Triage every open pull request you own across all your repositories in one pass, reporting CI status, review state, and the next action for each.

## When to Use

- At the start of a coding session, to see which PRs need attention before you open anything new
- Before rebasing or updating a branch, to confirm nothing upstream has changed the plan
- During weekly PR triage when you maintain more than a handful of repositories
- When PRs go stale because nothing surfaces them in a single place
- Prerequisites: the GitHub CLI (`gh`) installed and authenticated for every account whose PRs you want to see

## The Prompt

```
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
- DRAFT: still marked as a draft
- STALE: no push and no review activity for more than 14 days, whatever the other signals say

## 4. OUTPUT

Start with one table, sorted BLOCKED, READY, WAITING, DRAFT:

| Repo | # | Title | CI | Reviews | Age | Next action |

Then, in priority order, list only the PRs that need something from me. For each one, state the single concrete next step: rebase onto the base branch, fix a named failing check, reply to a specific review comment, or merge.

Rules for the report:
- Name the failing check and its failure reason. "CI red" is not an acceptable answer.
- If `mergeable_state` is `dirty`, say which base branch it conflicts with.
- Call out any PR older than 14 days explicitly, even if it is green.
- End with a one-line count per bucket.
```

## Example

### Input

"Triage my open PRs." The author has five open PRs across four repositories.

### Output

```
| Repo              | #  | Title                          | CI              | Reviews          | Age | Next action              |
|-------------------|----|--------------------------------|-----------------|------------------|-----|--------------------------|
| acme/api          | 214 | Add rate limiting middleware   | 1 failing       | changes requested | 9d  | Fix lint, answer review  |
| acme/api          | 209 | Bump node to 22               | conflicts       | none             | 21d | Rebase onto main         |
| acme/web          | 88  | Extract Money component        | green           | approved         | 2d  | Merge                    |
| acme/web          | 91  | Dark mode tokens              | green           | none             | 1d  | Ping a reviewer          |
| acme/infra        | 37  | Terraform state migration     | pending         | none             | 4d  | Wait for plan job        |

## BLOCKED

### acme/api #214 -- Add rate limiting middleware
- Failing check: `lint` -- `no-floating-promises` on src/middleware/rateLimit.ts line 41.
- Unaddressed review: reviewer asked for the limiter window to be configurable (comment is newer than my last commit).
- Next: fix the lint error, then reply to the window question in the same push.

### acme/api #209 -- Bump node to 22
- `mergeable_state: dirty`, conflicts with `main` in package-lock.json.
- No review activity for 21 days: STALE.
- Next: rebase onto main, regenerate the lock file, then re-request review.

## READY

### acme/web #88 -- Extract Money component
- Approved, all 4 checks green, no conflicts. Next: merge.

## WAITING

### acme/web #91 -- Dark mode tokens
- Green and mergeable, no reviewer has looked yet. Next: request a reviewer.

## DRAFT / PENDING

### acme/infra #37 -- Terraform state migration
- `terraform-plan` still running. Nothing to do until it reports.

Counts: BLOCKED 2, READY 1, WAITING 1, PENDING 1, of which STALE 1.
```

## Customization Tips

- **To run it as parallel subagents in Claude Code**, tell the agent to launch one subagent per PR, each doing the step 2 API calls for its own PR and returning a single row plus its next action. The main agent only assembles the table. This is noticeably faster once you pass roughly ten PRs.
- **To include PRs you are reviewing rather than authoring**, swap the search to `gh search prs review-requested:@me is:open`, or run both searches and label each row with `author` or `reviewer`.
- **To scope it to one organization**, add `org:your-org` to the `gh search prs` query. Add `--limit 100` if you have more than the default page of results.
- **To catch bot PRs piling up**, run `gh search prs author:app/renovate is:open org:your-org` as a second pass and report those separately -- they usually need batching, not individual triage.
- **To make it a daily habit**, save the prompt as a custom command and have it end with only the BLOCKED section, so the report is short enough to read before your first commit.

## Cost

~$0.20-0.50 with Sonnet for 5-10 PRs

## Tags

`code-review` `pull-request` `github` `triage` `automation` `workflow`
