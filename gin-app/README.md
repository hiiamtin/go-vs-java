# Gin Application

## Overview
This is the Go/Gin implementation of the performance POC application. It implements 5 REST API endpoints for benchmarking against other frameworks.

## Endpoints

### API 1: Plaintext
```
GET /plaintext
```
Returns "Hello, World!" as plain text.

### API 2: JSON Parsing
```
POST /json
```
Accepts LargeJSON complex object, returns `{"status": "ok"}`

### API 3: CPU Work
```
POST /cpu
```
Accepts `{"name": "string"}`, performs 1000 SHA-256 hash iterations, returns hash result.

### API 4: Database Read
```
GET /db
```
Queries for user with ID=10, returns user JSON.

### API 5: Realistic Transaction
```
POST /interaction
```
Complete database transaction: read user, insert interaction log, update user's last contact date.

## Database Configuration
- **Host:** `db` (Docker container name for Mac OS setup)
- **Database:** `poc_db`
- **User:** `poc_user`
- **Password:** `poc_password`
- **Port:** 5432

## Build and Run

### Local Development
```bash
# Build
go build -o main .

# Run (requires PostgreSQL database)
./main
```

### Docker Build
```bash
# Build for arm64 (Apple Silicon)
docker build --platform linux/arm64 -t gin-app .

# Run with Docker network
docker run -d \
  -p 8080:8080 \
  --name gin-app \
  --net poc-net \
  --platform linux/arm64 \
  --cpus="1.0" \
  --memory="1g" \
  gin-app
```

## Dependencies
- `github.com/gin-gonic/gin` - HTTP framework
- `github.com/lib/pq` - PostgreSQL driver

## Testing
```bash
# Test plaintext
curl http://localhost:8080/plaintext

# Test health
curl http://localhost:8080/health

# Test CPU work
curl -X POST -H "Content-Type: application/json" \
  -d '{"name":"test"}' \
  http://localhost:8080/cpu
```

## Features
- ✅ Implements all 5 required endpoints
- ✅ Database transactions for API 5
- ✅ Proper error handling
- ✅ Mac OS Docker compatibility (db hostname)
- ✅ ARM64 platform support
- ✅ Distroless final Docker image