# Multi-Repo PR Check

Check all your open PRs across multiple repos in parallel.

## Recipe

```bash
claude -p "Check all my open PRs: run 'gh search prs author:@me is:open --json repository,title,number,url' then for each PR check CI status, review comments, and merge readiness. Report a summary table." --model sonnet
```

## Claude Code Version

Use multiple parallel Agent calls:

```
For each open PR, launch a subagent to:
1. gh api repos/{owner}/{repo}/pulls/{num} -- check mergeable state
2. gh api repos/{owner}/{repo}/pulls/{num}/comments -- check for new reviews
3. gh api repos/{owner}/{repo}/pulls/{num}/reviews -- check approval status
4. Report: PR title, CI status, review status, action needed
```

## When to Use

- Start of each coding session
- Before rebasing or force-pushing
- Weekly PR triage

## Cost

~$0.20-0.50 with Sonnet for 5-10 PRs
