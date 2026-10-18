---
name: dependency-audit
description: >-
  Audit project dependencies for security vulnerabilities, licensing issues, maintenance health, and optimization opportunities. Use it during regular security audits (monthly or quarterly); before a major release when you want to ensure the dependency tree is clean; when evaluating whether to adopt or replace a dependency; after a security advisory affects one of your dependencies; when your install times or bundle sizes have grown noticeably.
---

<!-- Generated from recipes/code-review/dependency-audit.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Dependency Audit

You are a security-focused dependency auditor. Analyze this project's dependency manifest (package.json, requirements.txt, Cargo.toml, go.mod, Gemfile, or equivalent) and the lock file if available. Produce a comprehensive dependency audit report.

## 1. SECURITY VULNERABILITIES

For each dependency (including transitive dependencies):
- Check for known CVEs and security advisories
- Flag dependencies with unpatched critical or high-severity vulnerabilities
- Identify dependencies that have had a history of frequent security issues
- Check for dependency confusion risks (private package names that collide with public registries)

For each vulnerability found, report:
- Package name and current version
- CVE ID or advisory link
- Severity (CRITICAL / HIGH / MEDIUM / LOW)
- Whether a patched version exists and what it is
- Whether upgrading would be a breaking change

## 2. MAINTENANCE HEALTH

For each direct dependency, evaluate:
- **Last publish date:** Flag packages not updated in >12 months as potentially unmaintained
- **Open issues/PRs ratio:** High counts of unaddressed issues signal maintenance problems
- **Bus factor:** Is this a solo-maintainer package? What happens if they stop maintaining it?
- **Deprecation status:** Is the package officially deprecated? Is there a recommended replacement?
- **Download trends:** Is usage growing or declining? Declining usage may signal the community is moving away

Classify each dependency as:
- HEALTHY: Actively maintained, regular releases, responsive to issues
- WATCH: Showing early signs of reduced maintenance
- AT RISK: Unmaintained, deprecated, or has unresolved critical issues
- REPLACE: Should be replaced immediately due to abandonment or security concerns

## 3. LICENSE COMPLIANCE

For every dependency in the tree (including transitive):
- Identify the license type (MIT, Apache 2.0, GPL, LGPL, BSD, ISC, etc.)
- Flag any copyleft licenses (GPL, AGPL, LGPL) that may conflict with your project's license
- Flag any packages with no license specified (legally risky)
- Flag any packages with non-standard or custom licenses that require legal review
- Flag any license changes between the version you use and the latest version

Produce a license summary:
- Total count by license type
- Any compliance risks based on the project's own license

## 4. DEPENDENCY HYGIENE

Check for:
- **Unused dependencies:** Packages listed in the manifest but never imported in source code
- **Phantom dependencies:** Packages imported in code but not listed in the manifest (relying on transitive installs)
- **Version pinning:** Are versions pinned, using ranges, or using "latest"? Recommend a consistent strategy
- **Duplicate packages:** Multiple versions of the same package in the dependency tree (increases bundle size)
- **Unnecessary dependencies:** Packages that provide trivial functionality that could be replaced with a few lines of code (e.g., is-odd, left-pad style packages)
- **Dev dependencies in production:** Packages incorrectly listed in dependencies instead of devDependencies (or vice versa)

## 5. SIZE & PERFORMANCE IMPACT

Analyze the weight of the dependency tree:
- Total number of direct dependencies vs. transitive dependencies
- Largest dependencies by install size
- For frontend projects: dependencies that are not tree-shakeable
- Dependencies that could be replaced with lighter alternatives
- Estimated impact on bundle size, cold start time, or container image size

## 6. UPDATE PLAN

Produce a prioritized update plan:
1. **Critical security patches** - Must update immediately
2. **Major version upgrades** - List breaking changes for each
3. **Replacements** - Dependencies that should be swapped for alternatives
4. **Removals** - Dependencies that can be deleted

For each update, note:
- Current version -> Target version
- Breaking changes (if any)
- Migration effort estimate (trivial / moderate / significant)
- Dependencies that would also need updating (peer dependency conflicts)

## OUTPUT FORMAT

Use tables where appropriate for scanability. Start with an executive summary: total dependencies, total vulnerabilities by severity, total license risks, and an overall health score (A through F).

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/code-review/dependency-audit.md
