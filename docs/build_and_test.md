# Build & Test Guide

This document summarizes how to build, test, and run each component of the Go vs Java performance POC on the Apple Silicon single-machine setup.

## Prerequisites

- Docker Desktop with arm64 support
- `docker compose` CLI plugin
- Go 1.22+ (optional for local Go builds)
- JDK 17+ (for Spring Boot), JDK 21+ or container build for Quarkus native
- PostgreSQL container reachable via `docker-compose.yml` (`db:5432`)

Before running any app, ensure the database is up:

```bash
docker compose up -d db
```

All runtime containers assume the custom `poc-net` network and 1 vCPU / 1 GiB limits.

## Go – Gin

```bash
cd gin-app
go mod tidy               # optional for local builds
go test ./...             # optional unit tests
./test_with_database.sh   # builds binary, docker image, and runs smoke tests

docker build --platform linux/arm64 -t poc-gin -f gin.Dockerfile gin-app
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-gin
```

## Go – Fiber

```bash
cd fiber-app
go mod tidy
go test ./...
./test_with_database.sh

docker build --platform linux/arm64 -t poc-fiber -f fiber.Dockerfile fiber-app
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-fiber
```

## Java – Spring Boot (JVM)

```bash
cd spring-app
./mvnw clean package -DskipTests
./test_with_database.sh

docker build --platform linux/arm64 -t poc-spring-jvm -f spring-jvm.Dockerfile spring-app
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-spring-jvm
```

## Java – Quarkus Native

```bash
cd quarkus-app
./mvnw package -Dnative -DskipTests -Dquarkus.native.container-build=true
./test_with_database.sh      # rebuilds native runner when sources change

docker build --platform linux/arm64 -t poc-quarkus-native -f quarkus-native.Dockerfile quarkus-app
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-quarkus-native
```

## Load Testing

Load tests live in `load-tests/`. Set `BASE_URL` if targeting a remote host.

```bash
cd load-tests
k6 run plaintext_test.js
k6 run json_test.js
k6 run cpu_test.js
k6 run db_test.js
k6 run interaction_test.js
```

For standardized measurements (1 m ramp-up, 2 m hold, 30 s ramp-down) run each script while capturing container stats `docker stats poc-app --no-stream`.

## Report Generation

Raw k6 summaries and Docker stats snapshots are stored in `phase3-results/`. Aggregate metrics are exported to `phase3-results/performance_summary.json` and summarized in `COMPARISON_REPORT.md`. Update the report only after rebuilding images and re-running load tests to maintain consistency. 
