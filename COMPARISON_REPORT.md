Disclaimer: All tests were conducted on a single Mac OS machine (Apple Silicon). The load generator (k6) and application containers ran concurrently, causing resource contention. The following results are valid for *relative comparison* only and do not represent absolute, production-level performance.

| Contender | Startup Time (s) | Image Size (MB) | Memory (Idle) (MiB) |
| :--- | :---: | :---: | :---: |
| Go - Gin | 0.33 | 34.95 | 3.79 |
| Go - Fiber | 0.64 | 22.90 | 18.07 |
| Java - Spring JVM | 12.03 | 334.80 | 394.80 |
| Java - Quarkus Native | 1.07 | 110.57 | 10.11 |

| **Test Type** | **Metric** | Go - Gin | Go - Fiber | Java - Spring JVM | Java - Quarkus Native |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Realistic Transaction** | **Avg. RPS** | 480 | 526 | 824 | 873 |
|  | p99 Latency (ms) | 580.24 | 521.76 | 378.63 | 210.31 |
|  | Mem (Under Load) (MiB) | 33.33 | 41.40 | 623.30 | 106.40 |
| **Database I/O (Read)** | **Avg. RPS** | 657 | 683 | 2276 | 2848 |
|  | p99 Latency (ms) | 493.89 | 497.16 | 129.91 | 101.51 |
|  | Mem (Under Load) (MiB) | 32.55 | 40.06 | 598.10 | 91.22 |
| **JSON Parse** | **Avg. RPS** | 5595 | 7690 | 4172 | 3335 |
|  | p99 Latency (ms) | 68.15 | 57.16 | 115.42 | 94.45 |
|  | Mem (Under Load) (MiB) | 15.07 | 28.80 | 586.50 | 87.43 |
| **CPU Work** | **Avg. RPS** | 1949 | 2163 | 1327 | 314 |
|  | p99 Latency (ms) | 204.49 | 178.42 | 185.17 | 794.74 |
|  | Mem (Under Load) (MiB) | 22.75 | 30.07 | 588.00 | 85.84 |
| **Plaintext** | **Avg. RPS** | 13639 | 15944 | 5435 | 6194 |
|  | p99 Latency (ms) | 19.16 | 16.11 | 114.48 | 74.10 |
|  | Mem (Under Load) (MiB) | 15.51 | 22.09 | 565.40 | 58.98 |

**Analysis & Notes**
- **Go - Gin**
  - Pros: Fastest cold start, lowest idle memory footprint, strong plaintext/JSON throughput with minimal resource usage.
  - Cons: Transaction and database throughput trail other contenders; p99 latency under mixed load spikes above 500 ms.
- **Go - Fiber**
  - Pros: Highest Go throughput across all lightweight tests, especially plaintext and JSON; maintains low latency relative to Gin.
  - Cons: Still limited by ORM/database stack for heavier workloads; memory usage rises under load compared with Gin.
- **Java - Spring JVM**
  - Pros: Leads database-heavy and transactional scenarios, leveraging mature JPA stack; stable p99 latency versus Go services.
  - Cons: Slowest startup and largest image; idle and under-load memory usage orders of magnitude higher.
- **Java - Quarkus Native**
  - Pros: Best overall throughput on transaction and database tests with modest memory; near-native startup time.
  - Cons: CPU-intensive workload performance lags markedly (low RPS, high p99); requires GraalVM/native build pipeline upkeep.

**Issue Log & Resolutions**
- **Gin & Fiber (Go)** – Initial `/db` and `/interaction` tests were connection-pool bound (default 2 idle/open connections). Resolved by enabling prepared statements and setting `MaxOpenConns/MaxIdleConns=50` with 5 m/2 m lifetimes.
- **Spring Boot (Java)** – CamelCase payloads (`customerId`) failed JSON binding once snake_case serialization was enabled. Added `@JsonAlias("customerId")` so both casings map to the DTO.
- **Quarkus Native (Java)** – `/cpu` endpoint executed on the event loop thread, limiting concurrency (~300 RPS). Annotated the handler with `@Blocking` to shift heavy hashing to the worker pool, recovering throughput.
