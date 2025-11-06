# Go vs Java Performance POC

## Project Goal
This proof of concept compares four frameworks under identical workloads:
**Go/Gin**, **Go/Fiber**, **Java/Spring Boot (JVM)**, and **Java/Quarkus (Native)**.
All components (apps, PostgreSQL, and k6 load generator) run on a single Apple
Silicon Mac, so results are strictly for *relative* comparison.

## Project Structure
```
go_vs_java/
├── AGENTS.md                    # Roles, tasks, and overall plan
├── README.md                    # You are here
├── STATUS.md                    # Live task tracker
├── COMPARISON_REPORT.md         # Final metrics & analysis
├── database/                    # Schema & seed data
├── docs/                        # API, CPU logic, payload specs
├── fiber-app/                   # Fiber implementation (Go)
├── gin-app/                     # Gin implementation (Go)
├── load-tests/                  # k6 scenarios for five APIs
├── phase3-results/              # Captured k6 outputs + docker stats
├── quarkus-app/                 # Quarkus native implementation (Java)
├── spring-app/                  # Spring Boot implementation (Java)
└── docker-compose.yml           # PostgreSQL on custom poc-net
```

## Mac OS Single-Machine Variant
- **Database hostname**: `db` (Docker container name) instead of `localhost`
- **Network**: Containers connect via custom `poc-net`
- **Images**: All Dockerfiles target `linux/arm64`
- **Load profile**: k6 capped at 100 VUs with 1 m ramp / 2 m hold / 30 s ramp-down
- **Resource limits**: Each app container constrained to 1 vCPU and 1 GiB memory
- **Disclaimer**: Throughput/latency numbers are pessimistic because the load
  generator shares the host with the services.

## Phase Summary
- **Phase 1 – Application Development** ✅
  All four services implement the shared API contract, CPU workload, and transactional logic.
- **Phase 2 – Containerization & Test Setup** ✅
  Multi-stage arm64 Dockerfiles, PostgreSQL provisioning, and k6 scripts completed.
- **Phase 3 – Execution & Reporting** ✅
  Images rebuilt, standardized load tests captured in `phase3-results/`,
  and results published in `COMPARISON_REPORT.md`. Task 14 (final review) remains.

## API Endpoints (common across all services)
1. `GET /plaintext` – baseline HTTP overhead
2. `POST /json` – large JSON payload echo (`{"status":"ok"}`)
3. `POST /cpu` – 1,000 iterations of SHA-256 hashing
4. `GET /db` – read user ID 10 from PostgreSQL
5. `POST /interaction` – transactional read/insert/update with validation

All endpoints propagate or generate `X-Correlation-ID` headers for traceability.

## Known Issues & Fixes
- **Go (Gin & Fiber)**: Default connection pool (max 2) throttled `/db` and `/interaction`.
  ➜ Enabled GORM prepared statements and set `MaxOpenConns/MaxIdleConns=50`
  with 5 m/2 m lifetime controls.
- **Spring Boot**: k6 payloads send `customerId` (camelCase) while responses are snake_case.
  ➜ Added `@JsonAlias("customerId")` so both styles bind cleanly.
- **Quarkus Native**: CPU handler blocked the event loop, collapsing throughput (~300 RPS).
  ➜ Marked `/cpu` with `@Blocking`, pushing the hashing work onto the worker pool.
- **All frameworks**: Connection pool sizing standardized (50 max / 25 min where supported)
  to keep the comparison fair before running final load tests.

## Testing & Data Capture
- Runner: `k6` with shared correlation ID helper; scripts live in `load-tests/`.
- Automation:
  - `scripts/run_phase3_load_tests.sh` executes the full suite (Gin → Fiber → Spring → Quarkus) and archives previous results.
  - `scripts/run_load_tests_{gin|fiber|spring|quarkus}.sh` target a single service via the shared helper `run_load_tests_for_app.sh`.
- Metrics: RPS, p90/p95/p99 latency (exported JSON), plus simultaneous
  `docker stats --no-stream` snapshots for CPU & memory.
- Artifacts: Raw outputs stored in `phase3-results/` and summarized in
  `phase3-results/performance_summary.json`.
- Database: PostgreSQL 15-alpine with schema/seed in `database/`.
- Environment setup: `docker-compose up -d db` then run each app with
  `docker run ... --net poc-net --cpus=1.0 --memory=1g`.

See `docs/build_and_test.md` for command-by-command instructions.

## Deliverables
- **Performance Report**: [COMPARISON_REPORT.md](COMPARISON_REPORT.md) contains the latest load-test results, latency/memory tables, and framework-specific analysis.
- Four parity applications (Gin, Fiber, Spring JVM, Quarkus Native)
- Arm64-ready Dockerfiles and test scripts
- k6 scenarios + captured metrics (`phase3-results/`)
- `COMPARISON_REPORT.md` summarizing startup time, image size,
  throughput, latency, memory, and pros/cons


## Summary Of Results

| Framework | Startup (s) | Idle Mem (MiB) | Runtime Variant |
| :--- | ---: | ---: | :--- |
| Go - Gin | 1 | 22.3 | Native |
| Go - Fiber | 2 | 17.9 | Native |
| Java - Spring JVM | 17 | 394.4 | JVM |
| Java - Quarkus Native | 1 | 10.1 | Native |
| Java - Quarkus JVM | 4 | 175.5 | JVM |

| Test | Metric | Gin | Fiber | Spring | Quarkus Native | Quarkus JVM |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: |
| Realistic Transaction | Avg RPS | 1706 | 1799 | 976 | 890 | 1475 |
|  | p99 (ms) | 148.9 | 126.3 | 227.2 | 203.3 | 179.1 |
|  | Mem (MiB) | 43.6 | 32.5 | 667.9 | 120.7 | 272.6 |
| Database I/O | Avg RPS | 5526 | 6980 | 2714 | 3052 | 4613 |
|  | p99 (ms) | 69.3 | 60.2 | 125.3 | 99.3 | 86.7 |
|  | Mem (MiB) | 42.2 | 32.6 | 636.5 | 99.1 | 237.7 |
| CPU Work | Avg RPS | 1927 | 2209 | 1424 | 386 | 1503 |
|  | p99 (ms) | 209.4 | 174.5 | 134.1 | 607.8 | 197.5 |
|  | Mem (MiB) | 39.9 | 32.5 | 624.6 | 74.0 | 219.7 |
