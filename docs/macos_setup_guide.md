# Mac OS Single-Machine Setup Guide

## Overview
This guide covers the specific requirements for running the Go vs Java Performance POC on a single Mac OS machine (Apple Silicon). The setup differs from a standard multi-machine deployment due to Docker networking limitations and resource contention.

## Key Differences

### Network Configuration
- **Standard Setup:** `--net=host` (not supported on Mac OS)
- **Mac OS Setup:** Custom Docker network `poc-net`
- **Database Hostname:** `db` (container name) instead of `localhost`
- **Application Access:** Port forwarding to `localhost:8080` for load testing

### Platform Considerations
- **Architecture:** Must use `linux/arm64` images for Apple Silicon
- **Build Images:** All base images must specify arm64 platform
- **Performance:** Expect slower builds due to cross-platform compilation

### Resource Management
- **Contention:** k6 and containers compete for same resources
- **Load Reduction:** 100 virtual users instead of 200
- **Results:** Pessimistic (worse) performance, valid for relative comparison only

## Implementation Requirements

### Database Configuration
All applications must connect using:
```go
// Go Example
dsn := "host=db user=poc_user password=poc_password dbname=poc_db port=5432 sslmode=disable"
```

```java
// Java Example
spring.datasource.url=jdbc:postgresql://db:5432/poc_db
spring.datasource.username=poc_user
spring.datasource.password=poc_password
```

### Docker Network Setup
```bash
# Create custom network
docker network create poc-net

# Database container will run with name "db"
# Application containers will join poc-net network
```

### Platform Specification
All Docker commands must include:
```bash
docker build --platform linux/arm64 ...
docker run --platform linux/arm64 ...
```

## Testing Configuration

### k6 Scripts Target
All load test scripts must target:
```javascript
export const options = {
  // Target host for k6
  // Forwarded to application containers
  target: 'http://localhost:8080'
};
```

### Load Profile
Modified for single-machine execution:
```javascript
export const options = {
  stages: [
    { duration: '1m', target: 100 },    // Reduced from 200
    { duration: '2m', target: 100 },    // Hold at 100 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
};
```

## Container Execution

### Database Container
```bash
docker run -d \
  --name db \
  --network poc-net \
  --platform linux/arm64 \
  -e POSTGRES_DB=poc_db \
  -e POSTGRES_USER=poc_user \
  -e POSTGRES_PASSWORD=poc_password \
  postgres:15-alpine
```

### Application Container
```bash
docker run -d \
  -p 8080:8080 \
  --name poc-app \
  --network poc-net \
  --platform linux/arm64 \
  --cpus="1.0" \
  --memory="1g" \
  [IMAGE_NAME]
```

## Important Notes

### Performance Expectations
- **Relative Comparison:** Results are valid for comparing A vs B, C vs D
- **Absolute Values:** Do not represent production-level performance
- **Resource Contention:** k6 and applications share CPU/memory
- **Disclaimer:** Must be included in final report

### Common Pitfalls
1. **Wrong Hostname:** Using `localhost` instead of `db` for database connection
2. **Missing Network:** Forgetting `--network poc-net` flag
3. **Wrong Platform:** Not specifying `linux/arm64` causing emulation
4. **Port Conflicts:** Multiple containers trying to use port 8080

### Verification Steps
```bash
# Check network
docker network ls | grep poc-net

# Check container architecture
docker inspect [container_name] | grep Arch

# Test database connectivity
docker exec -it db psql -U poc_user -d poc_db -c "SELECT 1;"

# Test application connectivity
curl http://localhost:8080/plaintext
```

## Build Considerations

### Go Applications
```dockerfile
# Use arm64-specific base images
FROM --platform=linux/arm64 golang:alpine AS builder
# ... build stages ...
FROM --platform=linux/arm64 gcr.io/distroless/static-debian11
```

### Java Applications
```dockerfile
# Use arm64-specific base images
FROM --platform=linux/arm64 openjdk:17-slim AS builder
# ... build stages ...
FROM --platform=linux/arm64 openjdk:17-jre-slim
```

### Quarkus Native
```dockerfile
# Multi-stage with platform specification
FROM --platform=linux/arm64 quay.io/quarkus/centos-quarkus-maven:20.3.1-java11 AS build
# ... native build ...
FROM --platform=linux/arm64 registry.access.redhat.com/ubi8/ubi-minimal
```

## Monitoring

### Resource Usage
Monitor both containers and k6 during testing:
```bash
# Monitor application containers
docker stats poc-app --no-stream

# Monitor system resources (Activity Monitor or htop)
# k6 process will also be consuming resources
```

### Performance Impact
- **CPU Competition:** k6 and applications share cores
- **Memory Pressure:** All processes compete for RAM
- **I/O Contention:** Database disk access shared
- **Network Overhead:** Port forwarding adds latency

## Final Report Requirements

### Disclaimer
```markdown
> "Disclaimer: All tests were conducted on a single Mac OS machine (Apple Silicon). 
> The load generator (k6) and application containers ran concurrently, causing 
> resource contention. The following results are valid for *relative comparison* 
> only and do not represent absolute, production-level performance."
```

### Analysis Focus
- **Relative Performance:** Framework A vs Framework B
- **Efficiency:** Resource usage patterns
- **Startup Time:** Cold start comparisons
- **Memory Footprint:** Base vs load consumption

This setup provides fair comparative data while acknowledging the limitations of single-machine testing.