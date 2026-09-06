# Background Deploy Monitor

> Watch a running deployment or CI job in the background, polling until it finishes, so you can keep working and still get told what happened.

## When to Use

- Right after pushing a branch that triggers a long CI or deploy pipeline
- When watching a Render, Vercel, or Amplify deployment that takes several minutes to go live
- When a test suite on a large repo runs long enough that you would otherwise sit and watch it
- When a deploy needs a post-deploy smoke check and you want the failure logs pulled automatically
- Prerequisites: a CLI that can report the job's status non-interactively (`gh run view`, `vercel inspect`, `aws amplify get-job`) and a run or deployment ID to watch

## The Prompt

```
Monitor a running job until it reaches a terminal state, then report what happened. Poll; do not block on a single long-running command.

## 1. IDENTIFY THE RUN

If I gave you a run ID, use it. If I did not, find the most recent run for the current branch:
gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,workflowName

Report which run you are watching before you start polling, so I can correct you if it is the wrong one.

## 2. POLL

Loop:
- Run: gh run view <run-id> --json status,conclusion,jobs
- If status is queued or in_progress, wait 60 seconds and poll again.
- If status is completed, stop polling and go to step 3.
- Print one short line per poll: elapsed time, status, and which job is currently running. Nothing more. Do not narrate.

Stop conditions, whichever comes first:
- The run reaches a terminal status.
- 30 minutes of polling have elapsed. Report a timeout and the last known status rather than polling forever.

## 3. REPORT

If the conclusion is success:
- Report the total duration and the per-job durations.
- Name the slowest job, so it is visible when it starts creeping up.

If the conclusion is failure, cancelled, or timed_out:
- Identify which job and which step failed: gh run view <run-id> --log-failed
- Quote only the relevant failing output, not the whole log.
- State in one sentence what broke and the most likely cause.
- Do not attempt a fix and do not re-run the job. Report and stop.

Rules:
- Never push, re-run, cancel, or deploy anything. This job only observes.
- Keep the polling output to one line per check. The point of running in the background is that it stays quiet.
- If the run does not exist or the CLI is not authenticated, fail fast with that message instead of polling a missing run.
```

## Example

### Input

"Monitor the deploy I just pushed." The branch has one workflow that builds, tests, and deploys to a staging environment.

### Output

```
Watching run 18442310771 (Deploy Staging) on branch feat/orders-pagination.

00:00 in_progress -- build
01:00 in_progress -- build
02:00 in_progress -- test
03:00 in_progress -- test
04:00 in_progress -- deploy
05:00 completed

Conclusion: failure

Failed job: deploy
Failed step: Run database migrations

  Error: relation "orders_customer_id_idx" already exists
    at migrate (scripts/migrate.js:58:11)

What broke: the migration that creates orders_customer_id_idx ran against a
staging database where the index already exists, so it aborted before the
container swap. Most likely cause: the index was created by hand on staging
earlier, so the migration is not idempotent against it. Build and test both
passed (build 1m52s, test 2m04s, deploy failed at 0m41s).

Not re-running. Over to you.
```

## Customization Tips

- **In Claude Code, run it detached** so the polling never occupies your session: start it with `--bg` (or launch it as a subagent with `run_in_background: true`) and pick it back up when it reports.
- **To watch a platform deploy instead of GitHub Actions**, swap the poll command: `vercel inspect <url> --wait`, `aws amplify get-job --app-id X --branch-name Y --job-id Z`, or the provider's status endpoint via `curl`. Keep the same 60 second interval and terminal-state logic.
- **To tighten the loop for short jobs**, drop the interval to 15 seconds and the timeout to 5 minutes. For a nightly pipeline, go the other way: 5 minute interval, 2 hour timeout.
- **To add a smoke check**, append: "Once the conclusion is success, curl the health endpoint at <url>, and report the status code and response time. Treat a non-200 as a failed deploy."
- **To make failures louder**, append a notification step: post the failure summary to a Slack webhook, or open a GitHub issue with the failing step and log excerpt attached.
- **Use a cheap model, and cap the spend.** This prompt is mostly polling and one short summary, so Haiku is enough; reserve a larger model for the run that actually diagnoses the failure. `claude --help` documents `--max-budget-usd` as only working with `--print`, so the cap goes on a print-mode run: `claude -p "$(bash scripts/extract-prompt.sh recipes/devops/background-deploy-monitor.md)" --model haiku --max-budget-usd 1.00`.

## Cost

~$0.10-0.50 with Haiku (depends on deploy duration and check frequency)

## Tags

`devops` `deployment` `monitoring` `ci-cd` `github-actions` `automation`
