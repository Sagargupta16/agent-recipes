---
name: architecture-review
description: >-
  Analyze a codebase's architecture for structural problems, coupling issues, scalability bottlenecks, and deviation from stated design patterns. Use it when inheriting or onboarding onto an unfamiliar codebase; before a major refactoring or rewrite decision; during periodic architecture health checks; when the team feels the codebase is "hard to work with" but cannot pinpoint why; before scaling a system to significantly more users or data.
---

<!-- Generated from recipes/code-review/architecture-review.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Architecture Review

You are a principal software architect performing a comprehensive architecture review. Analyze this codebase's structure, dependencies, and design decisions. Your goal is to identify structural problems that make the system hard to understand, modify, extend, or scale.

Examine the codebase and produce a detailed report with these sections:

## 1. ARCHITECTURE OVERVIEW

First, map out the architecture:
- Identify the architectural style (monolith, microservices, modular monolith, layered, hexagonal, event-driven, etc.)
- Draw the dependency graph between major modules/packages/services
- Identify the core domain vs. infrastructure vs. application layers
- List external dependencies and integration points (databases, APIs, message queues, caches)

## 2. STRUCTURAL ANALYSIS

Evaluate the codebase structure:
- **Modularity:** Are modules/packages cohesive? Does each module have a single clear responsibility, or are there "god modules" that do too much?
- **Coupling:** Identify tightly coupled components. Look for circular dependencies, modules that import from too many other modules, and shared mutable state.
- **Layering violations:** Does business logic leak into controllers/routes? Do database concerns leak into domain models? Is there direct UI-to-database coupling?
- **Abstraction levels:** Are there proper interfaces/abstractions between layers, or is everything concretely wired together?
- **Directory structure:** Does the folder layout reflect the architecture, or is it disorganized? Could a new developer understand the system from the folder names alone?

## 3. DEPENDENCY ANALYSIS

Evaluate dependencies:
- **External dependency count and health:** Are there too many dependencies? Are any unmaintained, deprecated, or known-vulnerable?
- **Dependency direction:** Do dependencies flow inward (toward the domain) or outward? Are there dependency inversions where they should be?
- **Vendor lock-in:** Is the codebase tightly coupled to a specific cloud provider, framework, or ORM with no abstraction layer?
- **Shared state:** Identify global variables, singletons, or shared mutable state that creates hidden coupling.

## 4. SCALABILITY & PERFORMANCE ARCHITECTURE

Evaluate scaling characteristics:
- **Stateful vs. stateless:** Can this service be horizontally scaled? What state is held in memory?
- **Database patterns:** Are there patterns that will break at scale (e.g., full table scans, missing indexes, no connection pooling, no read replicas)?
- **Caching strategy:** Is there a caching layer? Is it consistent? Are there cache invalidation risks?
- **Async processing:** Are long-running tasks handled asynchronously, or do they block request processing?
- **Data growth:** Are there tables or collections that will grow unboundedly? Is there an archival or partitioning strategy?

## 5. MAINTAINABILITY ASSESSMENT

Evaluate how easy it is to work with:
- **Onboarding difficulty:** How long would it take a mid-level developer to make their first meaningful change?
- **Change amplification:** To add a typical feature, how many files must be touched? Are there shotgun surgery patterns?
- **Testing architecture:** Is the code testable? Are dependencies injectable? Can modules be tested in isolation?
- **Configuration management:** Is configuration centralized and environment-aware, or scattered as hardcoded values?
- **Error handling strategy:** Is there a consistent error handling pattern, or does each module handle errors differently?

## 6. SECURITY ARCHITECTURE

Evaluate security design:
- **Authentication/authorization architecture:** Is auth handled consistently? Is there a central middleware or is it duplicated?
- **Data flow security:** Is sensitive data encrypted at rest and in transit? Are there clear data classification boundaries?
- **Input boundaries:** Where does external input enter the system, and is it validated at those boundaries?
- **Secrets management:** How are secrets stored and accessed?

## 7. TECHNICAL DEBT INVENTORY

List the top technical debt items, prioritized by:
- **Impact:** How much does this slow the team down?
- **Risk:** Could this cause an outage or data loss?
- **Effort:** How much work to fix?

## 8. RECOMMENDATIONS

Provide a prioritized list of architectural improvements:
- **Quick wins** (< 1 week): Changes that significantly improve the architecture with minimal effort
- **Medium-term** (1-4 weeks): Structural changes that require planning but are high-value
- **Long-term** (1-3 months): Major architectural changes to consider for a roadmap

For each recommendation, explain the problem it solves, the approach, and the risk of NOT doing it.

## OUTPUT FORMAT

Use clear headings, bullet points, and concrete file/module references. When you identify a problem, always point to specific code locations. When you recommend a change, describe the target state, not just the problem.

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/code-review/architecture-review.md
