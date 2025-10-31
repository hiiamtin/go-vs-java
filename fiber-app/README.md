# Fiber Application

## Overview
This is the Go/Fiber implementation of the performance POC application. It implements 5 REST API endpoints identical to the Gin application, with special attention to Fiber's Ctx reuse safety requirements.

## Key Differences from Gin
- **Framework:** Uses Fiber v2 instead of Gin
- **Ctx Reuse Safety:** Critical difference - Fiber reuses Ctx objects, requiring careful data handling
- **Performance:** Built for high throughput with low garbage collection overhead
- **Compatibility:** Identical business logic and API contracts

## Ctx Reuse Safety 🔒

**CRITICAL:** Fiber reuses Ctx objects for performance, which can cause data corruption if values are used outside the handler context.

### Safety Rules:
1. **Never return Ctx values directly** to callers
2. **Always copy strings/bytes** if using Ctx data in goroutines
3. **Never store Ctx references** in global variables
4. **Use c.BodyParser()** carefully - parse immediately, don't store reference

### Implementation in this App:
- **Database transactions:** All Ctx values parsed and used immediately within same handler
- **No goroutines:** All processing is synchronous to avoid Ctx reuse issues
- **Immediate copying:** String values copied to local variables before use
- **Safe parsing:** JSON parsing done synchronously without passing Ctx references

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
docker build --platform linux/arm64 -t fiber-app .

# Run with Docker network
docker run -d \
  -p 8080:8080 \
  --name fiber-app \
  --net poc-net \
  --platform linux/arm64 \
  --cpus="1.0" \
  --memory="1g" \
  fiber-app
```

## Dependencies
- `github.com/gofiber/fiber/v2` - HTTP framework
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

## Performance Characteristics

### Advantages over Gin:
- **Lower Memory Usage:** Ctx reuse reduces GC pressure
- **Higher Throughput:** Built on fasthttp for better performance
- **Faster JSON Parsing:** Optimized for high-speed scenarios

### Cautions:
- **Ctx Reuse Risk:** Must follow safety rules strictly
- **Memory Safety:** Developers must understand Fiber's lifecycle
- **Debugging Complexity:** Ctx reuse can make debugging harder

## Testing for Ctx Safety

The included test suite validates:
- ✅ All endpoints return correct responses
- ✅ Database transactions work properly  
- ✅ No data corruption in concurrent requests
- ✅ Error handling works correctly
- ✅ Ctx values used safely within handler scope

## Features
- ✅ Implements all 5 required endpoints
- ✅ Identical business logic to Gin implementation
- ✅ Database transactions with proper rollback
- ✅ Proper error handling
- ✅ Mac OS Docker compatibility (db hostname)
- ✅ ARM64 platform support
- ✅ Distroless final Docker image
- ✅ Ctx reuse safety implementation
- ✅ Comprehensive testing validation

**This implementation provides Fiber's performance benefits while maintaining safety through careful Ctx handling.**