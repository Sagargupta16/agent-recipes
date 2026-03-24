# Background Deploy Monitor

Monitor a deployment in the background while continuing other work.

## Recipe

```bash
# Start a background agent to watch the deploy
claude -p "Monitor this GitHub Actions run until it completes. Check every 60 seconds using 'gh run view <run-id>'. Report final status." --model haiku --max-budget-usd 1.00
```

## Claude Code Version

Use the Agent tool with `run_in_background: true`:

```
Launch a background agent to monitor the deploy:
- Run: gh run view <run-id> --json status,conclusion
- If status is "completed", report the conclusion
- If status is "in_progress", wait and check again
- Notify when done
```

## When to Use

- After pushing to a branch with CI/CD
- Monitoring Render/Vercel/Amplify deployments
- Watching for test suite completion on large repos

## Cost

~$0.10-0.50 with Haiku (depends on deploy duration and check frequency)
