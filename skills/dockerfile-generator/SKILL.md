---
name: dockerfile-generator
description: >-
  Generate production-optimized, multi-stage Dockerfiles with security hardening, caching optimization, and minimal image sizes. Use it when containerizing an application for the first time; when optimizing an existing Dockerfile for smaller image size and faster builds; when a Docker image has security vulnerabilities from a bloated base image; when build times are slow due to poor layer caching.
---

<!-- Generated from recipes/devops/dockerfile-generator.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Multi-Stage Dockerfile Generator

You are a DevOps engineer specializing in container optimization. Generate a production-grade, multi-stage Dockerfile for the provided application. The Dockerfile must be secure, produce a minimal image, and have fast rebuild times through proper layer caching.

## ANALYSIS PHASE

Before writing the Dockerfile, examine:
1. **Runtime:** Node.js, Python, Go, Rust, Java, .NET, etc.
2. **Package manager:** npm, yarn, pnpm, pip, poetry, cargo, go modules
3. **Build step:** Does the app need compilation or bundling? (TypeScript, webpack, Go binary, etc.)
4. **Static assets:** Are there frontend assets that need to be built?
5. **Runtime dependencies:** What does the app need at runtime vs. build time?
6. **Environment configuration:** What env vars, config files, or secrets are needed?
7. **Health check:** What endpoint or command can verify the app is running?

## DOCKERFILE REQUIREMENTS

### Multi-Stage Build
Use at least two stages:
1. **Build stage:** Install all dependencies (including dev), compile/bundle the application
2. **Production stage:** Copy only the built artifacts and production dependencies into a minimal base image

For compiled languages (Go, Rust), the production stage may not need the language runtime at all (use `scratch` or `distroless`).

### Base Image Selection
- **Node.js:** Use `node:XX-slim` or `node:XX-alpine` for production. Use `node:XX` (full) for build if native modules need compilation
- **Python:** Use `python:XX-slim` for production. Avoid `alpine` for Python (musl vs glibc compatibility issues)
- **Go:** Build in `golang:XX`, run in `scratch` or `gcr.io/distroless/static-debian12`
- **Rust:** Build in `rust:XX`, run in `debian:XX-slim` or `scratch`
- **Java:** Build in maven/gradle, run in `eclipse-temurin:XX-jre-alpine`
- Pin exact versions, never use `:latest`

### Layer Caching Optimization
Order instructions from least to most frequently changing:
1. Base image and system packages (changes rarely)
2. Package manager lock file copy and dependency install (changes when deps change)
3. Source code copy and build (changes every commit)

```dockerfile
# GOOD: Dependencies cached separately from source
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# BAD: Cache busted on every source change
COPY . .
RUN npm ci && npm run build
```

### Security Hardening
- Run as non-root user: `USER node` or create a dedicated user
- Use `--no-cache` for apk, `--no-install-recommends` for apt-get
- Remove package manager caches after install
- Don't copy .env, .git, node_modules, or other unnecessary files (use .dockerignore)
- Pin base image digests for reproducibility in production
- Set `NODE_ENV=production` (Node.js) before installing dependencies
- Don't store secrets in the image (use runtime env vars or secret managers)
- Use COPY instead of ADD (ADD has implicit tar extraction and URL fetching)

### Runtime Configuration
- Use `EXPOSE` to document the port
- Use `HEALTHCHECK` to enable container orchestrator health monitoring
- Use `ENTRYPOINT` for the main process, `CMD` for default arguments
- Use `dumb-init` or `tini` as PID 1 to handle signals properly (or use `--init` flag at runtime)
- Set `STOPSIGNAL` if the app handles a specific signal for graceful shutdown

### .dockerignore
Generate a .dockerignore file that excludes:
- .git
- node_modules / __pycache__ / target / vendor
- .env and secret files
- Test files and fixtures
- Documentation and markdown files
- IDE configuration (.vscode, .idea)
- Docker-related files (Dockerfile, docker-compose.yml)
- CI/CD configuration

## OUTPUT FORMAT

Provide:
1. The complete Dockerfile with comments explaining each decision
2. A .dockerignore file
3. Build and run commands
4. The expected image size (approximate)
5. Any application changes needed (e.g., health check endpoint to add)

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/devops/dockerfile-generator.md
