# Go vs Java Performance POC

## Project Goal
To conduct a comprehensive performance Proof of Concept (POC) comparing four key frameworks: **Go/Gin**, **Go/Fiber**, **Java/Spring Boot (JVM)**, and **Java/Quarkus (Native)**.

**[Single-Machine / Mac OS Variant]**
This plan is modified to run all components (Load Generator and Application Containers) on a **single Mac OS machine**. This will introduce **resource contention**; results will be valid for *relative comparison* (A vs B) but not as absolute, real-world performance figures.

The POC will isolate performance bottlenecks by testing **five distinct APIs** on each framework, with the primary metric being a "Realistic Transaction" test that combines database operations.

## Project Structure
```
go_vs_java/
├── AGENTS.md                    # Project planning and agent roles
├── README.md                    # This file
├── docs/                        # Shared specifications
│   ├── api_specifications.md   # Complete API endpoint definitions
│   ├── cpu_logic_spec.md       # CPU work function specification
│   └── json_payloads_spec.md    # JSON payload structures
├── database/                    # Database schema and seed data
│   ├── schema.sql               # PostgreSQL table definitions
│   └── seed_data.sql            # 100 test users
├── gin-app/                     # Go/Gin application (to be created)
├── fiber-app/                   # Go/Fiber application (to be created)
├── spring-app/                  # Java/Spring Boot application (to be created)
├── quarkus-app/                 # Java/Quarkus application (to be created)
├── load-tests/                  # k6 load test scripts (to be created)
└── docs/                        # Documentation
```

## Mac OS Single-Machine Setup

### Key Differences from Standard Setup
- **Database Hostname:** `db` (Docker container name) instead of `localhost`
- **Docker Network:** All containers run on custom `poc-net` network
- **Platform:** `linux/arm64` images for Apple Silicon compatibility
- **Load Testing:** Reduced to 100 virtual users (from 200) due to resource contention
- **Target Host:** `localhost:8080` for k6 scripts (forwarded to containers)

### Resource Considerations
- Load generator (k6) and applications run on same machine
- Results are for **relative comparison** only, not absolute performance
- System will show pessimistic (worse) performance due to contention

## Current Status
### ✅ Completed
- **Task 1: Define Shared Logic & Database** - COMPLETED
  - Database schema defined (`database/schema.sql`)
  - 100 test users created (`database/seed_data.sql`)
  - CPU logic specification defined (`docs/cpu_logic_spec.md`)
  - JSON payload specifications defined (`docs/json_payloads_spec.md`)
  - Complete API specifications defined (`docs/api_specifications.md`)
  - Project structure established

### 🚧 In Progress
- **Phase 1: Application Development** - STARTING
  - Task 2: Create Gin Application (Go_Specialist) - PENDING
  - Task 3: Create Fiber Application (Go_Specialist) - PENDING
  - Task 4: Create Spring Boot Application (Java_Specialist) - PENDING
  - Task 5: Create Quarkus Application (Java_Specialist) - PENDING

### 📋 Upcoming Phases
- **Phase 2: Containerization & Test Setup**
  - Create Dockerfiles for all four applications
  - Set up PostgreSQL database
  - Create k6 load test scripts

- **Phase 3: Execution & Reporting**
  - Build all Docker images
  - Run automated performance tests
  - Compile final comparison report

## API Endpoints
All four applications will implement the same five endpoints:

1. **`GET /plaintext`** - Returns "Hello, World!" (tests HTTP overhead)
2. **`POST /json`** - Receives complex customer object (tests JSON parsing)
3. **`POST /cpu`** - Performs 1,000 SHA-256 hash operations (tests CPU work)
4. **`GET /db`** - Queries user by ID = 10 (tests database read)
5. **`POST /interaction`** - Complete transaction: read, write, update (primary test)

## Database Setup
- **Database:** PostgreSQL
- **Tables:** `users` (100 records), `interaction_log` (empty)
- **Connection:** db:5432/poc_db/poc_user/poc_password (Docker container name)
- **Network:** Custom `poc-net` Docker network
- **Platform:** `linux/arm64` for Apple Silicon compatibility

## Performance Metrics
- **Primary:** API 5 "Realistic Transaction" (RPS, p99 latency, memory)
- **Secondary:** APIs 1-4 for bottleneck isolation
- **Additional:** Startup time, image size, idle memory usage

## Next Steps
1. **Go_Specialist:** Create Gin application implementing all 5 APIs
2. **Go_Specialist:** Create Fiber application with identical logic
3. **Java_Specialist:** Create Spring Boot application with identical logic
4. **Java_Specialist:** Create Quarkus application configured for native compilation

## Testing Strategy
- **Load Testing:** k6 with standardized profile (100 users, 2 min hold) - reduced for Mac OS
- **Resource Limits:** 1 CPU, 1GB memory per container
- **Target:** localhost:8080 (forwarded to Docker containers)
- **Disclaimer:** Results valid for relative comparison only due to resource contention
- **Test Runs:** 20 iterations per application for statistical significance
- **Environment:** Docker containers with PostgreSQL database

## Agent Roles
- **Project_Manager:** Coordination and final report assembly
- **Go_Specialist:** Gin and Fiber application development
- **Java_Specialist:** Spring Boot and Quarkus application development
- **DevOps_Engineer:** Dockerfiles and test environment setup
- **Performance_Analyst:** Test execution and data analysis

## Expected Deliverables
- Four working applications with identical business logic
- Docker images for each application (arm64 architecture)
- Comprehensive performance comparison report with Mac OS disclaimer
- Pros/cons analysis for each framework
- Results suitable for relative framework comparison only

---
*This project will provide data-driven insights into the trade-offs between Go and Java frameworks for business applications.*