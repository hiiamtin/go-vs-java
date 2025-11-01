# Performance Comparison Charts

The following Mermaid bar charts visualize the latest load-test results captured in `COMPARISON_REPORT.md`. Each chart focuses on the primary metrics for the “Realistic Transaction” workload (the end-to-end scenario that combines read/write/update operations).

## Average Throughput (RPS)

```mermaid
bar
    title Realistic Transaction - Average RPS (Higher is Better)
    x-axis Framework
    y-axis Avg RPS
    dataset Go - Gin: 1706
    dataset Go - Fiber: 1799
    dataset Java - Spring JVM: 976
    dataset Java - Quarkus Native: 890
    dataset Java - Quarkus JVM: 1475
```

## p99 Latency & Memory (Under Load)

```mermaid
bar
    title Realistic Transaction - p99 Latency (ms) & Memory (MiB)
    x-axis Framework
    y-axis Value
    dataset p99 Latency (ms): 148.9, 126.3, 227.2, 203.3, 179.1
    dataset Memory (MiB): 43.6, 32.6, 667.9, 120.7, 272.6
    labels Go - Gin, Go - Fiber, Java - Spring JVM, Java - Quarkus Native, Java - Quarkus JVM
```

> **Note:** Mermaid stacked bars require a consistent set of labels. The second chart overlays latency and memory within the same framework to highlight the trade-offs between responsiveness and resource consumption.

To regenerate these numbers, run `scripts/run_phase3_load_tests.sh` (or the per-app variants) and update `COMPARISON_REPORT.md` accordingly. Then adjust the datasets above with the latest values.
