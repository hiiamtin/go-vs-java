# Gin Application Build Guide

## Prerequisites
- Go 1.22+ (for local builds)
- Docker Desktop (arm64 capable)
- PostgreSQL reachable at `db:5432` when running tests

## Local Build & Test
```bash
cd gin-app
go mod tidy
go test ./...
./test_with_database.sh
```
`test_with_database.sh` compiles the app, builds the Docker image, and runs smoke tests against the shared database container.

## Docker Build
```bash
docker build --platform linux/arm64 -t poc-gin -f gin.Dockerfile gin-app
```

## Runtime
```bash
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-gin
```
