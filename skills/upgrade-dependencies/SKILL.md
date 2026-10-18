---
name: upgrade-dependencies
description: >-
  Upgrade a project's dependencies one at a time, running the test suite after each bump and reverting the ones that break it. Use it during routine dependency maintenance, when a batch of updates has accumulated; before a major release, to go into it on current and patched dependencies; when Renovate or Dependabot PRs have piled up and you want them resolved locally in one sitting; when a security advisory means you need the patched version in, and you need to know what it breaks.
---

<!-- Generated from recipes/migrations/upgrade-dependencies.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Upgrade Dependencies

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

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/migrations/upgrade-dependencies.md
