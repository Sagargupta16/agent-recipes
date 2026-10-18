---
name: monitoring-setup
description: >-
  Add health check endpoints, structured logging, application metrics, and alerting configuration to make an application production-observable. Use it when deploying an application to production for the first time; when on-call engineers struggle to diagnose issues due to lack of observability; when migrating to Kubernetes or a container orchestrator that needs health probes; when improving incident response time by adding proactive monitoring; when compliance requires audit logging and uptime monitoring.
---

<!-- Generated from recipes/devops/monitoring-setup.md by scripts/build-skills.sh. Edit the recipe, then rerun the script. -->

# Health Checks and Monitoring Setup

You are an SRE (Site Reliability Engineer) adding production observability to this application. Implement health checks, structured logging, application metrics, and alerting so that the team can detect, diagnose, and resolve issues quickly. Every production application needs these four pillars to be operable.

## 1. HEALTH CHECK ENDPOINTS

Implement three health check endpoints with different purposes:

### GET /health (Liveness Probe)
- Returns 200 if the process is running and can handle requests
- Should NOT check external dependencies (database, cache, APIs)
- Used by load balancers and container orchestrators to know if the process is alive
- If this fails, the process should be restarted
- Response: `{ "status": "ok" }`
- Must respond within 1 second, always

### GET /ready (Readiness Probe)
- Returns 200 if the application is ready to serve traffic
- MUST check all critical dependencies:
  - Database connection: run a simple query (`SELECT 1`)
  - Cache connection: run a PING command
  - Required external services: check connectivity (with short timeout)
  - Migrations: verify schema is up to date
- If this fails, the process should be removed from the load balancer but NOT restarted
- Response:
  ```json
  {
    "status": "ready",
    "checks": {
      "database": { "status": "up", "latency_ms": 2 },
      "redis": { "status": "up", "latency_ms": 1 },
      "migrations": { "status": "current", "version": "20250115_001" }
    }
  }
  ```
- On failure:
  ```json
  {
    "status": "not_ready",
    "checks": {
      "database": { "status": "down", "error": "Connection refused" },
      "redis": { "status": "up", "latency_ms": 1 }
    }
  }
  ```
  Return HTTP 503

### GET /health/detailed (Diagnostic - authenticated)
- Requires authentication (admin role or internal API key)
- Returns detailed system information for debugging:
  - Application version and git commit SHA
  - Uptime
  - Memory usage (heap used, heap total, RSS)
  - CPU usage
  - Active connections (database pool: used/available/max)
  - Request queue depth
  - Environment (staging/production)
  - Runtime version (Node.js, Python, etc.)
  - Dependency versions

## 2. STRUCTURED LOGGING

Replace console.log with structured logging that can be parsed by log aggregation tools (ELK, Datadog, CloudWatch).

### Log Format
Every log entry must be a JSON object with:
```json
{
  "timestamp": "2025-01-15T10:30:00.123Z",
  "level": "info",
  "message": "Request completed",
  "service": "my-api",
  "environment": "production",
  "requestId": "req-abc123",
  "traceId": "trace-xyz789",
  "duration_ms": 45,
  "method": "GET",
  "path": "/api/users",
  "statusCode": 200,
  "userId": "user-456"
}
```

### What to Log

**Always log (INFO level):**
- Every incoming HTTP request with method, path, status code, and duration
- Authentication events (login success, login failure, token refresh)
- Important business events (order placed, payment processed, user created)
- External service calls with duration and status
- Application startup and shutdown

**Log on WARNING level:**
- Slow queries (> configurable threshold, e.g., 1000ms)
- Retry attempts on external service calls
- Rate limiting triggers
- Deprecated API usage
- Cache misses on high-frequency queries

**Log on ERROR level:**
- Unhandled exceptions with full stack trace
- External service failures
- Database query failures
- Authentication/authorization failures
- Input validation failures (for security monitoring)

**Never log:**
- Passwords, tokens, API keys, or secrets
- Full credit card numbers, SSNs, or other PII
- Raw request bodies (may contain sensitive data)
- Health check requests (too noisy; exclude from request logging)

### Request Context
Implement request-scoped logging context:
- Generate a unique `requestId` for every incoming request
- Propagate `requestId` to all log entries within that request
- Accept and forward `traceId` from incoming headers (for distributed tracing)
- Include `userId` from the authenticated session in all log entries

## 3. APPLICATION METRICS

Expose metrics in Prometheus format at `/metrics` (or push to StatsD/Datadog).

### Essential Metrics

**HTTP Request Metrics:**
- `http_requests_total` (counter) - labels: method, path, status_code
- `http_request_duration_seconds` (histogram) - labels: method, path
- `http_requests_in_progress` (gauge)

**Business Metrics:**
- Custom counters for key business events (orders created, payments processed)
- Custom gauges for current state (active users, queue depth)

**Runtime Metrics:**
- `process_cpu_seconds_total` (counter)
- `process_resident_memory_bytes` (gauge)
- `nodejs_heap_size_used_bytes` (gauge) [Node.js specific]
- `nodejs_active_handles_total` (gauge) [Node.js specific]
- Event loop lag (for Node.js)

**Dependency Metrics:**
- `db_query_duration_seconds` (histogram) - labels: query_type, table
- `db_connections_active` (gauge)
- `db_connections_idle` (gauge)
- `external_request_duration_seconds` (histogram) - labels: service, endpoint
- `cache_hits_total` (counter) - labels: cache_name
- `cache_misses_total` (counter) - labels: cache_name

### Metric Naming Conventions
- Use snake_case
- Include unit in the name: `_seconds`, `_bytes`, `_total`
- Counters end with `_total`
- Use labels for dimensions (don't create separate metrics for each status code)
- Keep label cardinality low (don't use user IDs or request IDs as labels)

## 4. ALERTING RULES

Define alerting rules for critical conditions:

### Availability Alerts
- **High error rate:** > 5% of requests returning 5xx for > 2 minutes -> PAGE
- **Endpoint down:** Health check failing for > 1 minute -> PAGE
- **High latency:** p99 latency > 2 seconds for > 5 minutes -> WARN
- **Traffic anomaly:** Request rate dropped > 50% compared to same time yesterday -> WARN

### Resource Alerts
- **High memory:** Memory usage > 85% for > 5 minutes -> WARN, > 95% -> PAGE
- **High CPU:** CPU usage > 80% for > 10 minutes -> WARN
- **Database connection pool exhaustion:** Available connections < 10% -> PAGE
- **Disk space:** < 20% free -> WARN, < 10% free -> PAGE

### Business Alerts
- **Zero orders:** No new orders for > 30 minutes during business hours -> PAGE
- **Payment failures:** Payment failure rate > 10% for > 5 minutes -> PAGE
- **Authentication anomaly:** Failed login rate > 100/min from single IP -> WARN

### Alert Configuration
For each alert, provide:
- Prometheus alerting rule (or equivalent)
- Severity: PAGE (wake someone up) vs WARN (investigate during business hours)
- Runbook link placeholder
- Description with useful context for the on-call engineer

## OUTPUT FORMAT

Provide:
1. Complete health check endpoint implementation
2. Logging middleware/configuration
3. Metrics middleware/configuration
4. Alerting rules file (Prometheus format or equivalent)
5. A README section explaining how to access and use the monitoring
6. Any npm packages / pip packages needed

---

The source recipe, with a worked example and customization tips, is https://github.com/Sagargupta16/agent-recipes/blob/main/recipes/devops/monitoring-setup.md
