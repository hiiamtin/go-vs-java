Disclaimer: All tests were conducted on a single Mac OS machine (Apple Silicon). The load generator (k6) and application containers ran concurrently, causing resource contention. The following results are valid for *relative comparison* only and do not represent absolute, production-level performance.

| Contender | Startup Time (s) | Image Size (MB) | Memory (Idle) (MiB) |
| :--- | :---: | :---: | :---: |
| Go - Gin | 1 | 34.95 | 22.32 |
| Go - Fiber | 2 | 22.90 | 17.89 |
| Java - Spring JVM | 17 | 334.80 | 394.40 |
| Java - Quarkus Native | 1 | 110.57 | 10.14 |

| **Test Type** | **Metric** | Go - Gin | Go - Fiber | Java - Spring JVM | Java - Quarkus Native | Java - Quarkus JVM |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Realistic Transaction** | **Avg. RPS** | 1706 | 1799 | 976 | 890 | 1475 |
|  | p99 Latency (ms) | 148.88 | 126.30 | 227.20 | 203.31 | 179.14 |
|  | Mem (Under Load) (MiB) | 43.60 | 32.55 | 667.90 | 120.70 | 272.60 |
| **Database I/O (Read)** | **Avg. RPS** | 5526 | 6980 | 2714 | 3052 | 4613 |
|  | p99 Latency (ms) | 69.25 | 60.15 | 125.35 | 99.30 | 86.73 |
|  | Mem (Under Load) (MiB) | 42.16 | 32.62 | 636.50 | 99.08 | 237.70 |
| **JSON Parse** | **Avg. RPS** | 5755 | 7911 | 4193 | 3411 | 4524 |
|  | p99 Latency (ms) | 67.77 | 56.02 | 119.58 | 93.16 | 82.27 |
|  | Mem (Under Load) (MiB) | 35.81 | 27.84 | 622.90 | 105.30 | 208.10 |
| **CPU Work** | **Avg. RPS** | 1927 | 2209 | 1424 | 386 | 1503 |
|  | p99 Latency (ms) | 209.42 | 174.49 | 134.11 | 607.78 | 197.50 |
|  | Mem (Under Load) (MiB) | 39.87 | 32.51 | 624.60 | 73.96 | 219.70 |
| **Plaintext** | **Avg. RPS** | 14429 | 15952 | 5826 | 6234 | 10702 |
|  | p99 Latency (ms) | 18.98 | 13.67 | 109.25 | 73.97 | 45.84 |
|  | Mem (Under Load) (MiB) | 32.75 | 21.74 | 606.10 | 81.50 | 175.50 |

> **Quarkus JVM (reference)** — Running the same load against the JVM build (`poc-quarkus-jvm`) yields: startup 4 s, idle ~175 MiB, interaction 1475 RPS (p99 179 ms), DB 4613 RPS, JSON 4524 RPS, CPU 1503 RPS (p99 197 ms), and plaintext 10,702 RPS. This highlights the native-vs-JVM CPU trade-off: JVM delivers ~4× higher CPU throughput at the cost of image size (+200 MB) and memory usage (+160 MiB idle).

**Analysis & Notes**
- **Go - Gin**
  - Pros: Instant startup, minimal idle footprint (~22 MiB), and competitive throughput (≈1.7k RPS realistic, 5.5k RPS DB) with stable JSON/plaintext numbers.
  - Cons: Transaction p99 remains ~150 ms—slower than Fiber—suggesting additional tuning (prepared statements already enabled) or more CPU headroom may be needed.
- **Go - Fiber**
  - Pros: Leads overall RPS and latency in plaintext/JSON/DB tests; realistic workload tops ~1.8k RPS with p99 ≈126 ms while keeping memory under load below Gin.
  - Cons: CPU saturation still hits 100%; benefits from additional cores or DB-side optimizations for heavier transactions.
- **Java - Spring JVM**
  - Pros: Strong database throughput (~2.7k RPS) with moderate p99 (~125 ms) thanks to mature JPA tooling; realistic flow stays near 1k RPS.
  - Cons: Startup remains slow (17 s) and memory footprint is orders of magnitude higher (≈400 MiB idle / 600 + under load).
- **Java - Quarkus Native**
  - Pros: Sub-second startup, low idle memory (~10 MiB), and solid DB/JSON throughput (~3k/3.4k RPS) with moderate transaction latency.
  - Cons: CPU-bound test still lags (≈386 RPS, p99 ≈608 ms) despite moving work off the event loop; native build pipeline adds operational overhead.

**Issue Log & Resolutions**
- **Gin & Fiber (Go)** – Initial `/db` and `/interaction` tests were connection-pool bound (default 2 idle/open connections). Resolved by enabling prepared statements and setting `MaxOpenConns/MaxIdleConns=50` with 5 m/2 m lifetimes.
- **Spring Boot (Java)** – CamelCase payloads (`customerId`) failed JSON binding once snake_case serialization was enabled. Added `@JsonAlias("customerId")` so both casings map to the DTO.
- **Quarkus Native (Java)** – `/cpu` endpoint executed on the event loop thread, limiting concurrency (~300 RPS). Annotated the handler with `@Blocking` to shift heavy hashing to the worker pool, moderately improving throughput while keeping the native profile intact.
