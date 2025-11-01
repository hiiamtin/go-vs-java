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
- Metrics: RPS, p90/p95/p99 latency (exported JSON), plus simultaneous
  `docker stats --no-stream` snapshots for CPU & memory.
- Artifacts: Raw outputs stored in `phase3-results/` and summarized in
  `phase3-results/performance_summary.json`.
- Database: PostgreSQL 15-alpine with schema/seed in `database/`.
- Environment setup: `docker-compose up -d db` then run each app with
  `docker run ... --net poc-net --cpus=1.0 --memory=1g`.

## Deliverables
- Four parity applications (Gin, Fiber, Spring JVM, Quarkus Native)
- Arm64-ready Dockerfiles and test scripts
- k6 scenarios + captured metrics (`phase3-results/`)
- `COMPARISON_REPORT.md` summarizing startup time, image size,
  throughput, latency, memory, and pros/cons

## Next Actions
1. Project manager to complete Task 14 final review of the report and methodology notes.
2. Optionally rerun k6 scenarios after any tuning changes (e.g., alternate pool sizes).
3. Consider follow-up experiments (more VUs, multi-host setup) using the existing
   scripts and Docker artifacts as a baseline.
