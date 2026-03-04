# Performance Bottleneck Finder

> Identify performance bottlenecks, memory leaks, and optimization opportunities by analyzing code patterns, queries, and resource usage.

## When to Use

- When your application is slower than expected but profiling hasn't pinpointed the cause
- Before a load test to proactively find bottlenecks
- When reviewing performance-critical code paths (request handlers, data processing pipelines, rendering logic)
- When users report latency issues and you need to find the root cause in code
- During capacity planning when you need to understand scaling limits

## The Prompt

```
You are a performance engineer analyzing this codebase for bottlenecks. Your goal is to find code patterns that cause slowness, excessive memory usage, or poor scalability under load. Focus on real-world impact, not micro-optimizations.

Analyze the code and produce a report organized by severity of performance impact.

## 1. DATABASE & QUERY PERFORMANCE

Look for:
- **N+1 queries:** Loops that execute a query per iteration instead of batching
- **Missing indexes:** Queries that filter or sort on columns without indexes (look at WHERE clauses, ORDER BY, and JOIN conditions)
- **Unbounded queries:** SELECT without LIMIT, or queries that fetch all rows when only a subset is needed
- **Over-fetching:** SELECT * when only a few columns are needed, especially on tables with large text/blob columns
- **Missing connection pooling:** Creating new database connections per request instead of using a pool
- **Expensive aggregations:** COUNT, SUM, or GROUP BY on large tables without materialized views or caching
- **Transaction scope:** Transactions that hold locks longer than necessary (doing HTTP calls or file I/O inside a transaction)
- **Missing pagination:** Endpoints that return all records with no limit/offset or cursor-based pagination

For each finding, estimate the performance impact: how does it scale as data grows?

## 2. MEMORY & RESOURCE MANAGEMENT

Look for:
- **Memory leaks:** Event listeners added but never removed, growing Maps/Sets that are never pruned, closures that capture large objects unnecessarily, caches without eviction policies or TTLs
- **Large object allocation in hot paths:** Creating large arrays, buffers, or string concatenations inside loops or frequently-called functions
- **Stream misuse:** Loading entire files or HTTP responses into memory instead of using streaming
- **Missing resource cleanup:** Database connections, file handles, or HTTP connections not being closed/returned in finally blocks
- **Unbounded queues or buffers:** In-memory queues that grow without backpressure

## 3. CONCURRENCY & BLOCKING

Look for:
- **Blocking the event loop (Node.js):** Synchronous file I/O, CPU-heavy computation, JSON.parse on large payloads, RegExp with catastrophic backtracking
- **Blocking the main thread (Frontend):** Heavy computation during render, large synchronous localStorage operations, layout thrashing
- **Missing parallelization:** Sequential await calls that could be Promise.all / asyncio.gather / goroutines
- **Thread pool exhaustion:** More concurrent tasks than the thread pool can handle, causing queuing
- **Lock contention:** Mutexes or synchronization points that serialize work unnecessarily
- **Missing debouncing/throttling:** Event handlers (scroll, resize, input) that fire on every event without debouncing

## 4. CACHING OPPORTUNITIES

Look for:
- **Repeated expensive computations:** The same calculation done multiple times with the same inputs
- **Repeated external calls:** Fetching the same data from an API or database multiple times in one request lifecycle
- **Missing HTTP caching headers:** API responses that could be cached by clients/CDNs but lack Cache-Control, ETag, or Last-Modified headers
- **Missing application-level caching:** Frequently-read, rarely-changed data that should be in Redis/Memcached
- **Stale cache risks:** Caches without proper invalidation that could serve outdated data

## 5. NETWORK & I/O INEFFICIENCY

Look for:
- **Chatty APIs:** Multiple sequential HTTP calls to the same service that could be batched into one
- **Missing compression:** Large responses sent without gzip/brotli compression
- **Synchronous external calls in request path:** HTTP calls to third-party services without timeouts, circuit breakers, or fallbacks
- **Missing CDN usage:** Static assets served from the application server instead of a CDN
- **Payload bloat:** Sending unnecessary data in API responses (entire objects when the client needs 2 fields)
- **Missing connection keep-alive:** Opening new TCP connections for each HTTP call to the same host

## 6. ALGORITHM & DATA STRUCTURE ISSUES

Look for:
- **O(n^2) or worse in disguise:** Nested loops, repeated array includes/indexOf checks (should be a Set), repeated object key lookups on arrays (should be a Map)
- **Unnecessary sorting:** Sorting arrays that don't need to be sorted, or sorting repeatedly when once would suffice
- **String concatenation in loops:** Building strings with += instead of using join or a buffer
- **Regex compilation in loops:** Creating new RegExp objects inside loops instead of compiling once

## OUTPUT FORMAT

For each finding:

### [P0/P1/P2/P3] Short title
**Location:** `file:line`
**Pattern:** What the code does now
**Impact:** How this affects performance (quantify if possible: "O(n^2) where n = number of users", "adds ~200ms per request")
**Fix:** Specific code change or approach to fix it
**Effort:** Trivial / Small / Medium / Large

Priority levels:
- P0: Causes outages or severe degradation under normal load
- P1: Significant impact on user experience or cost at current scale
- P2: Will become a problem as the system scales 2-5x
- P3: Minor inefficiency, optimize if convenient

End with a summary table of all findings sorted by priority, and a "Top 3 Changes" section highlighting the highest-impact fixes.
```

## Example

### Input

"Analyze the performance of our Express.js API. Focus on the `src/routes/`, `src/services/`, and `src/models/` directories. We're experiencing p99 latency of 3 seconds on the /api/orders endpoint."

### Output

```
# Performance Analysis Report

## 1. DATABASE & QUERY PERFORMANCE

### [P0] N+1 query in order listing endpoint
**Location:** `src/services/orderService.js:45-62`
**Pattern:** The `getOrders` function fetches all orders, then loops through
each order to fetch its line items individually:
```js
const orders = await Order.find({ userId });
for (const order of orders) {
  order.items = await OrderItem.find({ orderId: order._id }); // N queries!
}
```
**Impact:** For a user with 50 orders, this fires 51 database queries. At p99,
users with 200+ orders hit 3+ second latency. This is the most likely cause of
the reported 3s p99.
**Fix:**
```js
const orders = await Order.aggregate([
  { $match: { userId: new ObjectId(userId) } },
  { $lookup: {
    from: 'orderitems',
    localField: '_id',
    foreignField: 'orderId',
    as: 'items'
  }},
  { $sort: { createdAt: -1 } },
  { $limit: 20 }
]);
```
**Effort:** Small (1-2 hours)

### [P1] Missing index on orders.userId
**Location:** `src/models/Order.js`
**Pattern:** The Order schema has no index on `userId`, but every query filters
by userId.
**Impact:** Full collection scan on every order lookup. With 1M orders, this
adds ~500ms.
**Fix:** Add `{ userId: 1, createdAt: -1 }` compound index.
**Effort:** Trivial

...

## Top 3 Changes
1. Fix N+1 query in orderService.js - Expected to reduce p99 from 3s to <200ms
2. Add compound index on orders(userId, createdAt) - Reduces query time by ~80%
3. Add Redis caching for product catalog - Eliminates 40% of database reads
```

## Customization Tips

- **For frontend code**, replace database sections with: "Look for unnecessary re-renders, missing React.memo/useMemo/useCallback, large component trees without virtualization, unoptimized images, layout shifts, and render-blocking resources."
- **For data pipelines**, add: "Look for data serialization/deserialization overhead, unnecessary data copies between stages, missing partitioning or parallelism, and stages that process data one record at a time instead of in batches."
- **For specific latency targets**, prepend: "The SLA for this service is p99 < 200ms. Flag anything that could push a single request above this threshold."
- **For cost optimization**, add: "Estimate the cloud cost impact of each bottleneck. Flag patterns that cause unnecessary compute, memory, or I/O spending."

## Tags

`performance` `optimization` `bottleneck` `database` `memory` `code-review`
