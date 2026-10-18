---
name: background-deploy-monitor
description: >-
  Watch a running deployment or CI job in the background, polling until it finishes, so you can keep working and still get told what happened. Use it right after pushing a branch that triggers a long CI or deploy pipeline; when watching a Render, Vercel, or Amplify deployment that takes several minutes to go live; when a test suite on a large repo runs long enough that you would otherwise sit and watch it; when a deploy needs a post-deploy smoke check and you want the failure logs pulled automatically.
---

<!-- Generated from recipes/devops/background-deploy-monitor.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Background Deploy Monitor

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

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/devops/background-deploy-monitor.md
