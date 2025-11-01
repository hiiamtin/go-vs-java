# Performance Comparison Charts

The ASCII bar charts below visualize the latest results from `COMPARISON_REPORT.md`. Each chart focuses on the “Realistic Transaction” workload so you can compare throughput, latency, and memory at a glance. All bars are scaled to the largest value in their group.

## Average Throughput (Realistic Transaction)

| Framework | Avg RPS | Relative |
| --- | ---: | :--- |
| Go - Gin | 1706 | ███████████████████ |
| Go - Fiber | 1799 | ████████████████████ |
| Java - Spring JVM | 976 | ██████████ |
| Java - Quarkus Native | 890 | █████████ |
| Java - Quarkus JVM | 1475 | ███████████████ |

## p99 Latency (Lower is Better)

| Framework | p99 (ms) | Relative |
| --- | ---: | :--- |
| Go - Gin | 148.9 | ██████████████ |
| Go - Fiber | 126.3 | ████████████ |
| Java - Spring JVM | 227.2 | ████████████████████ |
| Java - Quarkus Native | 203.3 | ██████████████████ |
| Java - Quarkus JVM | 179.1 | ████████████████ |

## Memory Under Load (Realistic Transaction)

| Framework | Mem (MiB) | Relative |
| --- | ---: | :--- |
| Go - Gin | 43.6 | █ |
| Go - Fiber | 32.6 | █ |
| Java - Spring JVM | 667.9 | ████████████████████ |
| Java - Quarkus Native | 120.7 | ████ |
| Java - Quarkus JVM | 272.6 | ████████ |

> Tip: rerun `scripts/run_phase3_load_tests.sh` (or the per-app variants) and refresh the numbers above when new benchmarking data is collected.
