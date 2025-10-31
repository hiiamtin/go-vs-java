# Project Goal

To conduct a comprehensive performance Proof of Concept (POC) comparing four key frameworks: **Go/Gin**, **Go/Fiber**, **Java/Spring Boot (JVM)**, and **Java/Quarkus (Native)**.

**[Single-Machine / Mac OS Variant]**
This plan is modified to run all components (Load Generator and Application Containers) on a **single Mac OS machine**. This will introduce **resource contention**; results will be valid for *relative comparison* (A vs B) but not as absolute, real-world performance figures.

The POC will isolate performance bottlenecks by testing **five distinct APIs** on each framework.
1.  **Plaintext:** (Baseline HTTP Overhead)
2.  **JSON Parsing:** (Deserialization/Serialization)
3.  **CPU Hard Work:** (Raw Processing)
4.  **Database I/O:** (Simple Read)
5.  **Realistic Transaction:** (Primary Metric: Read + Write + Update)


The final deliverable is a markdown report (`COMPARISON_REPORT.md`) detailing Throughput (RPS), Latency (p90/p99), and Resource Usage (CPU/Memory) for **each of the five tests**, along with startup time, image size, and a "Pros & Cons" analysis.

---

## Agents

### 1. Project_Manager
* **Role:** Coordinator
* **Expertise:** Oversees the project, defines final specifications, reviews code for logical consistency, and assembles the final report.
* **Goal:** Ensure the POC is fair, all logic is equivalent, and the final report is accurate.

### 2. Go_Specialist
* **Role:** Go Developer
* **Expertise:** Proficient in Go, Gin, Fiber, Docker, and database drivers/ORMs (e.g., `pgx`, `GORM`).
* **Status:** ✅ Both applications completed with GORM migration and correlation ID middleware
* **Goal:** Create two lightweight, high-performance Go applications implementing the five test APIs.

### 3. Java_Specialist
* **Role:** Java Developer
* **Expertise:** Proficient in Java, Spring Boot (Web), Quarkus, JPA/Hibernate, and GraalVM Native Image compilation.
* **Goal:** Create two Java applications (Spring JVM and Quarkus Native) that mirror the Go applications' logic.

### 4. DevOps_Engineer
* **Role:** DevOps & QA Specialist
* **Expertise:** Docker, Dockerfiles (multi-stage), k6 (load testing), shell scripting, and database provisioning (e.g., PostgreSQL in Docker).
* **Goal:** Create a fair, reproducible, and automated testing environment.

### 5. Performance_Analyst
* **Role:** Data Analyst & Technical Writer
* **Expertise:** Analyzing test data and writing technical reports.
* **Goal:** Execute the tests and compile all collected data into a final, easy-to-read report.

---

## Tasks

### Phase 1: Application Development

**Task 1: Define Shared Logic & Database (Go_Specialist & Java_Specialist)** ✅ COMPLETED
* **CPU Logic:** Define a function `perform_cpu_work(input string) string`. This function must take a string, loop 1,000 times, and perform a SHA-256 hash on it in each loop. This *exact* logic must be replicated in both Go and Java. **Git committed with equivalent Go/Java implementations.**
* **Database Schema:** Define two PostgreSQL tables:
    1.  `users (id SERIAL PRIMARY KEY, name VARCHAR, email VARCHAR, last_contact_date TIMESTAMP)`
    2.  `interaction_log (id SERIAL PRIMARY KEY, customer_id INT, note TEXT, type VARCHAR, created_at TIMESTAMP)`
    * Pre-populate `users` with 100 rows of test data.
* **JSON Payloads:**
    1.  `LargeJSON`: A complex customer object with 50+ fields for the JSON test.
    2.  `InteractionJSON`: A simple object for API 5: `{"customerId": 123, "note": "...", "type": "CALL"}`.

**Task 2: Create Gin Application (Go_Specialist)**
* Create a Go project using `Gin` and `GORM` (or `pgx` for transactions).
* **Status:** ✅ COMPLETED - Migrated to GORM ORM with global correlation ID middleware
* Implement five endpoints:
    1.  `GET /plaintext`: Returns "Hello, World!" (Content-Type: text/plain).
    2.  `POST /json`: Receives the `LargeJSON`, binds it to a struct, returns `{"status": "ok"}`.
    3.  `POST /cpu`: Receives `{"name": "string"}`, calls `perform_cpu_work(name)`, returns `{"processed_name": "..."}`.
    4.  `GET /db`: Queries for `SELECT * FROM users WHERE id = 10` and returns the user JSON.
    5.  **`POST /interaction` (Main Test):**
        * Receives `InteractionJSON`.
        * Starts a DB Transaction.
        * Reads from `users` (e.g., `SELECT...WHERE id = customerId`).
        * Writes to `interaction_log` (e.g., `INSERT...`).
        * Updates `users` (e.g., `UPDATE users SET last_contact_date = NOW()...`).
        * Commits the Transaction.
        * Returns the newly created `interaction_log` object as JSON.
* **Mac OS Note:** The database connection string must be configured to connect to the hostname **`db`** (the name of the Docker container in Task 8), not `localhost`.

**Task 3: Create Fiber Application (Go_Specialist)**
* Create a Go project using `Fiber` and `GORM` (or `pgx`).
* **Status:** ✅ COMPLETED - Migrated to GORM ORM with global correlation ID middleware
* Implement the **exact same five endpoints** and logic as the Gin application (Task 2).
* **Critical Note:** Ensure Ctx reuse is handled safely, especially for any values passed to transaction logic.
* **Status:** ✅ COMPLETED - Ctx reuse safety implemented and tested
* **Mac OS Note:** The database connection string must be configured to connect to the hostname **`db`**, not `localhost`.
* **Status:** ✅ READY FOR IMPLEMENTATION - Reference Go applications available
* **Status:** ✅ COMPLETED - Database connectivity with proper Docker hostname configured

**Task 4: Create Spring Boot (JVM) Application (Java_Specialist)**
* Create a Spring Boot project (WebMVC, Spring Data JPA).
* Implement the **exact same five endpoints** and logic.
    * API 1-4: Standard `@GetMapping`/`@PostMapping`.
    * API 5 (`POST /interaction`): Use the `@Transactional` annotation on the service method to manage the transaction (Read, Write, Update).
* **Mac OS Note:** The `application.properties` (or `.yml`) must have its JDBC URL set to connect to the hostname **`db`**, not `localhost`. (e.g., `jdbc:postgresql://db:5432/postgres`)

**Task 5: Create Quarkus (Native) Application (Java_Specialist)**
* Create a Quarkus project (RESTEasy/JAX-RS, Hibernate/Panache).
* Implement the **exact same five endpoints** and logic.
    * API 5 (`POST /interaction`): Use the `@Transactional` annotation, similar to Spring.
* This project **must** be configured for native compilation with GraalVM.
* **Mac OS Note:** The `application.properties` must have its JDBC URL set to connect to the hostname **`db`**, not `localhost`.
* **Status:** ✅ READY FOR IMPLEMENTATION - Reference Go applications available

---

### Phase 2: Containerization & Test Setup

**Task 6: Create Go Dockerfiles (DevOps_Engineer)**
* Create `gin.Dockerfile` and `fiber.Dockerfile` using multi-stage builds.
* **Status:** ✅ COMPLETED - Both Dockerfiles created with arm64 optimization and correlation ID middleware
* **Mac OS Note:** Ensure the base build images (e.g., `golang:alpine`) are for the `linux/arm64` platform to avoid slow `amd64` emulation on Apple Silicon.

**Task 7: Create Java Dockerfiles (DevOps_Engineer)**
* Create `spring-jvm.Dockerfile` (base: `openjdk:17-slim`).
* Create `quarkus-native.Dockerfile` (using the multi-stage native build process).
* **Mac OS Note:** Ensure the base build images (e.g., `openjdk:17-slim`) are for the `linux/arm64` platform.

**Task 8: Provision Database (DevOps_Engineer)**
* **Crucial Step:** Docker on Mac does not support `--net=host`. A custom network is required. (`poc-net`)
* Create a `docker-compose.yml` or script to run a PostgreSQL container. (ensuring `arm64` architecture)
* Initialize it with the schema (`users`, `interaction_log`) and test data from Task 1.

**Task 9: Create Load Test Scripts (DevOps_Engineer)**
* Create **five separate `k6` scripts**:
    1.  `plaintext_test.js`: `GET /plaintext`.
    2.  `json_test.js`: `POST /json` (with `LargeJSON`).
    3.  `cpu_test.js`: `POST /cpu`.
    4.  `db_test.js`: `GET /db`.
    5.  `interaction_test.js`: `POST /interaction` (with `InteractionJSON`).
* **Mac OS Note 1:** All k6 scripts must target the host's `localhost`, which forwards to the container:
    `http://localhost:8080/...`
* **Mac OS Note 2 (Performance):** Due to resource contention, the load profile should be reduced to prevent `k6` from becoming a bottleneck.
        * **Modify:** Change `target: 200` (virtual users) to a lower number, e.g., **`target: 100`**.
* All scripts should use the same standardized load profile (e.g., 1 min ramp-up, 2 min hold at 200 users, 30s ramp-down).

---

### Phase 3: Execution & Reporting

**Task 10: Build All Images (Project_Manager)**
* Oversee `Go_Specialist` and `Java_Specialist` to build their Docker images.
* **Mac OS Note:** After building, verify all images are for the `arm64` architecture (e.g., using `docker inspect [image_name] | grep Arch`).
* Record the final size of each image.

**Task 11: Run Automated Tests (Performance_Analyst)**
* **Critical Warning:** The test operator must note that running `k6` and `Docker` on the same machine *will* cause resource contention. The absolute RPS/Latency numbers will be "pessimistic" (worse than reality).
* Start the PostgreSQL container (Task 8).
* **Loop (20 test runs total):**
    * **For each** of the 4 contenders (Gin, Fiber, Spring, Quarkus):
        1.  Record the system time (Start Time).
        2.  Run the container **on the `poc-net` network**:
            ```bash
            docker run -d -p 8080:8080 --net poc-net --cpus="1.0" --memory="1g" \
              --platform linux/arm64 \
              --name poc-app [IMAGE_NAME]
            ```
        3.  Wait for the app to be healthy. Record the time taken (Startup Time).
        4.  Run `docker stats poc-app --no-stream` to get `Memory (Idle)`.
        5.  **For each** of the 5 test scripts (`plaintext_test.js`, `json_test.js`, `cpu_test.js`, `db_test.js`, `interaction_test.js`):
            * Execute the `k6 run [script_name.js]` (from a separate machine).
            * While k6 is running, run `docker stats poc-app --no-stream` to capture "Under Load" CPU and Memory for *that specific test*.
            * Save the full k6 output (RPS, Latency p90, p99) for this test.
        6.  Stop and remove the container: `docker stop poc-app && docker rm poc-app`.

**Task 12: Compile Final Report (Performance_Analyst)**
* Create a new file: `COMPARISON_REPORT.md`.
* **Go Applications Status:** Both Gin and Fiber applications completed with enterprise features:
  - GORM ORM for type-safe database operations
  - Global correlation ID middleware for request tracing
  - Comprehensive Docker builds with arm64 support
  - Production-ready error handling and observability
* The report must contain a summary data table with the following structure:

| Contender | Startup Time (s) | Image Size (MB) | Memory (Idle) |
| :--- | :---: | :---: | :---: |
| Go - Gin | | | |
| Go - Fiber | | | |
| Java - Spring JVM | | | |
| Java - Quarkus Native | | | |

<br>

| **Test Type** | **Metric** | **Go - Gin** | **Go - Fiber** | **Java - Spring JVM** | **Java - Quarkus Native** |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Realistic Transaction** | Avg. RPS | | | | |
| (Primary Metric) | p99 Latency (ms) | | | | |
| | Mem (Under Load) | | | | |
| **Database I/O (Read)** | Avg. RPS | | | | |
| | p99 Latency (ms) | | | | |
| | Mem (Under Load) | | | | |
| **JSON Parse** | Avg. RPS | | | | |
| | p99 Latency (ms) | | | | |
| | Mem (Under Load) | | | | |
| **CPU Work** | Avg. RPS | | | | |
| | p99 Latency (ms) | | | | |
| | Mem (Under Load) | | | | |
| **Plaintext** | Avg. RPS | | | | |
| | p99 Latency (ms) | | | | |
| | Mem (Under Load) | | | | |

* Below the tables, add the "Analysis & Notes" section.
* **Crucially:** Add a disclaimer at the top of the report:
    > "Disclaimer: All tests were conducted on a single Mac OS machine (Apple Silicon). The load generator (k6) and application containers ran concurrently, causing resource contention. The following results are valid for *relative comparison* only and do not represent absolute, production-level performance."

**Task 13: Write Analysis and Notes (Project_Manager & Performance_Analyst)**
* Add the "Analysis and Notes" section (Pros/Cons for each of the 4 frameworks), exactly as defined in the previous version.

**Task 14: Final Review (Project_Manager)**
* Review `COMPARISON_REPORT.md` for accuracy and completeness, ensuring the "Single Machine Disclaimer" is prominent.
* Declare the POC complete.

---

## Version Control Strategy:
```bash
# Example branching strategy for specialists
git checkout -b feature/gin-application
git checkout -b feature/spring-boot-application
git checkout -b feature/fiber-application
git checkout -b feature/quarkus-application

# Regular commits as endpoints are implemented
git add .
git commit -m "Implement /plaintext and /json endpoints"
git commit -m "Implement /cpu and /db endpoints"
git commit -m "Implement /interaction transaction endpoint"
```
