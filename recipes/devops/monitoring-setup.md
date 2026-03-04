# Health Checks and Monitoring Setup

> Add health check endpoints, structured logging, application metrics, and alerting configuration to make an application production-observable.

## When to Use

- When deploying an application to production for the first time
- When on-call engineers struggle to diagnose issues due to lack of observability
- When migrating to Kubernetes or a container orchestrator that needs health probes
- When improving incident response time by adding proactive monitoring
- When compliance requires audit logging and uptime monitoring

## The Prompt

```
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
```

## Example

### Input

"Add monitoring to this Express.js API. It uses PostgreSQL and Redis. We use Prometheus for metrics and Grafana for dashboards."

### Output

```typescript
// src/monitoring/healthcheck.ts
import { Router, Request, Response } from 'express';
import { Pool } from 'pg';
import { Redis } from 'ioredis';

interface HealthCheckResult {
  status: 'up' | 'down';
  latency_ms?: number;
  error?: string;
}

export function createHealthRouter(db: Pool, redis: Redis): Router {
  const router = Router();
  const startTime = Date.now();

  // Liveness probe - is the process alive?
  router.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok' });
  });

  // Readiness probe - can the app serve traffic?
  router.get('/ready', async (_req: Request, res: Response) => {
    const checks: Record<string, HealthCheckResult> = {};

    // Check PostgreSQL
    const dbStart = Date.now();
    try {
      await db.query('SELECT 1');
      checks.database = { status: 'up', latency_ms: Date.now() - dbStart };
    } catch (error) {
      checks.database = {
        status: 'down',
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }

    // Check Redis
    const redisStart = Date.now();
    try {
      await redis.ping();
      checks.redis = { status: 'up', latency_ms: Date.now() - redisStart };
    } catch (error) {
      checks.redis = {
        status: 'down',
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }

    const allHealthy = Object.values(checks).every((c) => c.status === 'up');

    res.status(allHealthy ? 200 : 503).json({
      status: allHealthy ? 'ready' : 'not_ready',
      checks,
    });
  });

  // Detailed diagnostic - requires authentication
  router.get('/health/detailed', requireAdmin, async (req: Request, res: Response) => {
    const memUsage = process.memoryUsage();

    res.json({
      status: 'ok',
      version: process.env.APP_VERSION || 'unknown',
      commit: process.env.GIT_SHA || 'unknown',
      uptime_seconds: Math.floor((Date.now() - startTime) / 1000),
      environment: process.env.NODE_ENV,
      node_version: process.version,
      memory: {
        heap_used_mb: Math.round(memUsage.heapUsed / 1024 / 1024),
        heap_total_mb: Math.round(memUsage.heapTotal / 1024 / 1024),
        rss_mb: Math.round(memUsage.rss / 1024 / 1024),
      },
      database: {
        total_connections: db.totalCount,
        idle_connections: db.idleCount,
        waiting_requests: db.waitingCount,
      },
    });
  });

  return router;
}
```

```typescript
// src/monitoring/logger.ts
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level(label) {
      return { level: label };
    },
  },
  base: {
    service: process.env.SERVICE_NAME || 'my-api',
    environment: process.env.NODE_ENV || 'development',
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  // Don't pretty-print in production (JSON is machine-parseable)
  ...(process.env.NODE_ENV !== 'production' && {
    transport: { target: 'pino-pretty' },
  }),
  redact: {
    paths: ['req.headers.authorization', 'req.body.password', 'req.body.token'],
    censor: '[REDACTED]',
  },
});
```

```typescript
// src/monitoring/metrics.ts
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

export const register = new Registry();

collectDefaultMetrics({ register });

export const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status_code'],
  registers: [register],
});

export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

export const httpRequestsInProgress = new Gauge({
  name: 'http_requests_in_progress',
  help: 'Number of HTTP requests currently being processed',
  registers: [register],
});

export const dbQueryDuration = new Histogram({
  name: 'db_query_duration_seconds',
  help: 'Database query duration in seconds',
  labelNames: ['query_type'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5],
  registers: [register],
});
```

```yaml
# alerting/rules.yml
groups:
  - name: api-availability
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status_code=~"5.."}[2m]))
          / sum(rate(http_requests_total[2m])) > 0.05
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "High 5xx error rate ({{ $value | humanizePercentage }})"
          description: "More than 5% of requests are returning 5xx errors."
          runbook: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High p99 latency ({{ $value }}s)"
          description: "99th percentile latency exceeds 2 seconds."

      - alert: HealthCheckFailing
        expr: up{job="my-api"} == 0
        for: 1m
        labels:
          severity: page
        annotations:
          summary: "API health check failing"
          description: "The API has been unreachable for more than 1 minute."

  - name: api-resources
    rules:
      - alert: HighMemoryUsage
        expr: |
          process_resident_memory_bytes / 1024 / 1024 > 450
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage ({{ $value }}MB)"

      - alert: DatabaseConnectionPoolExhausted
        expr: |
          pg_pool_idle_connections / pg_pool_total_connections < 0.1
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "Database connection pool nearly exhausted"
```

**Packages needed:**
```bash
npm install pino pino-http prom-client
npm install -D pino-pretty @types/pino
```

## Customization Tips

- **For Python/FastAPI**, use: "Use structlog for structured logging, prometheus_client for metrics, and FastAPI's built-in dependency injection for health check dependencies."
- **For Kubernetes**, add: "Configure the liveness and readiness probes in the Kubernetes deployment manifest. Set appropriate `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, and `failureThreshold` values."
- **For Datadog instead of Prometheus**, add: "Use dd-trace and dogstatsd-node for metrics. Use Datadog's structured logging format. Configure Datadog monitors instead of Prometheus alerting rules."
- **For distributed tracing**, add: "Integrate OpenTelemetry with automatic instrumentation. Propagate trace context (W3C Trace Context headers) across service boundaries. Export traces to Jaeger, Zipkin, or your APM provider."
- **For Grafana dashboards**, add: "Generate a Grafana dashboard JSON that includes panels for: request rate, error rate, latency percentiles, active connections, memory usage, and top slow endpoints."

## Tags

`devops` `monitoring` `health-checks` `logging` `metrics` `alerting` `observability`
