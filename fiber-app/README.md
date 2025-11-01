# Fiber Application Build Guide

## Prerequisites
- Go 1.22+ (for local builds)
- Docker Desktop with arm64 support
- PostgreSQL reachable at `db:5432`

## Local Build & Test
```bash
cd fiber-app
go mod tidy
go test ./...
./test_with_database.sh
```
The script builds the binary, docker image, and verifies all endpoints against the shared database container.

## Docker Build
```bash
docker build --platform linux/arm64 -t poc-fiber -f fiber.Dockerfile fiber-app
```

## Runtime
```bash
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-fiber
```
