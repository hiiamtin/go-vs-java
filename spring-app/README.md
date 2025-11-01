# Spring Boot Application Build Guide

## Prerequisites
- JDK 17+
- Maven (wrapper provided)
- Docker Desktop (arm64)
- PostgreSQL reachable at `db:5432`

## Local Build & Test
```bash
cd spring-app
./mvnw clean package -DskipTests
./test_with_database.sh
```
`test_with_database.sh` rebuilds the JAR, builds the Docker image, and runs smoke tests against the database container.

## Docker Build
```bash
docker build --platform linux/arm64 -t poc-spring-jvm -f spring-jvm.Dockerfile spring-app
```

## Runtime
```bash
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-spring-jvm
```
