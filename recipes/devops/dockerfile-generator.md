# Multi-Stage Dockerfile Generator

> Generate production-optimized, multi-stage Dockerfiles with security hardening, caching optimization, and minimal image sizes.

## When to Use

- When containerizing an application for the first time
- When optimizing an existing Dockerfile for smaller image size and faster builds
- When a Docker image has security vulnerabilities from a bloated base image
- When build times are slow due to poor layer caching

## The Prompt

```
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
```

## Example

### Input

"Generate a Dockerfile for this Node.js/TypeScript Express API. It uses npm, compiles TypeScript with `npm run build`, and serves from the `dist/` directory. There's also a Prisma ORM that needs schema generation."

### Output

```dockerfile
# ============================================
# Stage 1: Build
# ============================================
FROM node:20.11-slim AS build

WORKDIR /app

# Install dependencies needed for Prisma and native modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency manifests first for layer caching
COPY package.json package-lock.json ./
COPY prisma ./prisma/

# Install ALL dependencies (including dev) for building
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source code and build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Remove dev dependencies after build
RUN npm prune --production

# ============================================
# Stage 2: Production
# ============================================
FROM node:20.11-slim AS production

# Install dumb-init for proper PID 1 signal handling
RUN apt-get update && \
    apt-get install -y --no-install-recommends dumb-init openssl && \
    rm -rf /var/lib/apt/lists/*

# Set production environment
ENV NODE_ENV=production

WORKDIR /app

# Create non-root user
RUN chown -R node:node /app
USER node

# Copy production dependencies and built application
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --from=build --chown=node:node /app/package.json ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r => { if (!r.ok) throw new Error(); })"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

```dockerignore
# .dockerignore
node_modules
npm-debug.log*
.git
.gitignore
.env
.env.*
!.env.example
Dockerfile
docker-compose*.yml
.dockerignore
README.md
CONTRIBUTING.md
LICENSE
.vscode
.idea
*.md
tests
__tests__
*.test.ts
*.spec.ts
coverage
.nyc_output
.eslintrc*
.prettierrc*
tsconfig.json
jest.config.*
```

**Build and run:**
```bash
# Build the image
docker build -t my-api:latest .

# Run the container
docker run -d \
  --name my-api \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -e JWT_SECRET="your-secret" \
  --restart unless-stopped \
  my-api:latest
```

**Expected image size:** ~180MB (Node.js slim + production dependencies + Prisma engine)

## Customization Tips

- **For Go applications**, use a two-stage build with `scratch` as the production image: the final image will be 5-20MB. Add `CGO_ENABLED=0` and static linking flags. Copy CA certificates from the build stage.
- **For Python applications**, add: "Use a virtual environment in the build stage and copy it to production. Use `--no-cache-dir` with pip. Consider using `python:XX-slim` and copying only the venv."
- **For monorepo builds**, add: "Use Docker BuildKit mount caches for package managers: `RUN --mount=type=cache,target=/root/.npm npm ci`. Only copy the specific package and its workspace dependencies."
- **For local development**, add: "Also generate a `docker-compose.yml` for local development with volume mounts for live reload, database services, and environment variable management."
- **For CI/CD integration**, add: "Include GitHub Actions cache integration using `docker/build-push-action` with layer caching. Add vulnerability scanning with `docker scout` or `trivy`."

## Tags

`devops` `docker` `containerization` `optimization` `security` `multi-stage`
