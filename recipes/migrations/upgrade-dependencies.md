# Upgrade Dependencies

Safely upgrade all project dependencies with automated testing.

## Recipe

```bash
claude "Audit all dependencies for outdated packages and security vulnerabilities. For each outdated package: check the changelog for breaking changes, upgrade it, run tests. If tests fail, revert that upgrade. At the end, commit all successful upgrades together."
```

## Steps

1. Detect package manager (npm/pnpm/pip/cargo)
2. Run audit: `npm audit` / `pip-audit` / `cargo audit`
3. List outdated: `npm outdated` / `pip list --outdated`
4. For each outdated package:
   - Check if major version bump (breaking changes likely)
   - Upgrade the package
   - Run test suite
   - If tests pass, keep; if fail, revert
5. Commit all successful upgrades

## When to Use

- Monthly dependency maintenance
- Before a major release
- After Renovate/Dependabot PRs pile up

## Cost

~$0.50-2.00 depending on number of dependencies and test suite speed
