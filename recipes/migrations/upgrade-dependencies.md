# Upgrade Dependencies

> Upgrade a project's dependencies one at a time, running the test suite after each bump and reverting the ones that break it.

## When to Use

- During routine dependency maintenance, when a batch of updates has accumulated
- Before a major release, to go into it on current and patched dependencies
- When Renovate or Dependabot PRs have piled up and you want them resolved locally in one sitting
- When a security advisory means you need the patched version in, and you need to know what it breaks
- Prerequisites: a working test suite the agent can run, and a clean working tree so a revert is a clean revert

## The Prompt

```
Upgrade this project's dependencies safely, one package at a time, keeping only the upgrades that leave the test suite green.

## 1. ESTABLISH A BASELINE

Before changing anything:
- Confirm the working tree is clean. If it is not, stop and tell me.
- Detect the package manager from the lock file: package-lock.json (npm), pnpm-lock.yaml (pnpm), yarn.lock (yarn), uv.lock or poetry.lock or requirements.txt (Python), Cargo.lock (Rust), go.sum (Go).
- Find the test command from the project's own config (package.json scripts, pyproject.toml, Makefile, CI workflow). Do not guess a command that is not defined there.
- Run the test suite now and record the result. If it is already failing, stop and report which tests fail. There is no point upgrading on a red baseline.

## 2. BUILD THE WORKLIST

- Run the audit for the detected ecosystem: npm audit, pnpm audit, pip-audit, cargo audit, govulncheck.
- Run the outdated report: npm outdated, pnpm outdated, pip list --outdated, cargo outdated, go list -u -m all.
- Produce one table of candidates: package, current version, target version, patch/minor/major, and whether it appears in the audit output.
- Order the worklist: security fixes first, then patch, then minor, then major. Majors go last because they are the ones most likely to need code changes.

## 3. UPGRADE LOOP

For each package in worklist order:
1. If it is a major bump, read the release notes or changelog for the breaking changes first and summarize them before touching anything.
2. Upgrade that one package only.
3. Run the test suite.
4. If it passes, keep the change and move on.
5. If it fails, decide once: either the failure is a trivial, mechanical call-site fix covered by the breaking changes you just read, in which case make it and re-run; or it is not, in which case revert this package to its previous version, re-run to confirm green again, and record it as deferred with the reason.
6. Never batch two upgrades before a test run. If two upgrades go in together and the suite breaks, you cannot tell which one did it.

## 4. REPORT AND COMMIT

Report three lists:
- Upgraded: package, old version -> new version, and for majors the code changes that were needed
- Deferred: package, target version, the failure it caused, and what a human would need to do
- Skipped: anything you did not attempt, and why

Then commit the successful upgrades. Use one commit for the patch and minor bumps together, and a separate commit per major bump, so a bad major can be reverted on its own.

Rules:
- Never edit a lock file by hand. Let the package manager write it.
- Never widen or remove a version constraint to make an upgrade fit.
- Never disable, skip, or rewrite a test to make an upgrade pass.
- If the audit reports a vulnerability with no non-breaking fix, say so plainly instead of forcing the upgrade.
```

## Example

### Input

"Upgrade the dependencies in this project." A Node service with 34 direct dependencies, `npm test` defined in package.json, and a clean working tree.

### Output

```
Baseline: 218 tests passing, 0 failing. Package manager: npm. Test command: npm test.

## Worklist (12 candidates)

| Package        | Current | Target  | Type  | In audit |
|----------------|---------|---------|-------|----------|
| minimatch      | 3.0.4   | 3.0.5   | patch | yes      |
| pino           | 8.15.0  | 8.21.0  | minor | no       |
| zod            | 3.22.4  | 3.23.8  | minor | no       |
| express        | 4.18.2  | 5.1.0   | major | no       |
| ...            |         |         |       |          |

## Upgraded (9)

- minimatch 3.0.4 -> 3.0.5 (security, patch). 218 passing.
- pino 8.15.0 -> 8.21.0. 218 passing.
- zod 3.22.4 -> 3.23.8. 218 passing.
- ... 6 more patch/minor bumps, suite green after each.

## Deferred (2)

- express 4.18.2 -> 5.1.0. 14 tests failed: Express 5 no longer swallows
  rejected promises in route handlers, so three async handlers in
  src/routes/orders.js now surface errors the tests did not expect. That is a
  behavioural change across the error middleware, not a call-site rename.
  Reverted to 4.18.2, suite back to 218 passing. Needs a dedicated PR.
- multer 1.4.5 -> 2.0.0. Peer conflict with the current express 4 pin. Blocked
  on the express upgrade above.

## Skipped (1)

- typescript 5.4.5 -> 5.6.2. Not attempted: a compiler bump changes type
  checking for the whole repo, which belongs in its own PR.

## Commits

- chore(deps): bump 9 patch and minor dependencies
```

## Customization Tips

- **To keep majors out entirely**, add: "Only consider patch and minor upgrades. List major bumps in the report but do not attempt them." This is the safest form for an unattended run.
- **For Python projects**, add: "Prefer `uv lock --upgrade-package <name>` over editing pyproject.toml. Re-run the suite against the locked resolution, not against a fresh unpinned install."
- **For monorepos**, add: "Upgrade the package in the workspace root when it is a shared dependency, and run only the affected workspace's tests plus anything downstream of it."
- **When the test suite is slow**, add: "Run the fast unit suite after each individual upgrade and the full suite once at the end. If the full suite then fails, bisect the kept upgrades."
- **To keep it read-only**, drop step 4's commit instruction and add: "Do not commit. Leave the changes staged so I can review the diff and the lock file myself."
- **To pair it with a review**, chain this into [Dependency Audit](../code-review/dependency-audit.md) first, so you go into the upgrade loop with the license and maintenance picture already in hand.

## Cost

~$0.50-2.00 depending on number of dependencies and test suite speed

## Tags

`migration` `dependencies` `security` `maintenance` `testing` `automation`
