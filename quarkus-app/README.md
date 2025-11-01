# Quarkus Native Application Build Guide

## Prerequisites
- JDK 21 (or use provided Maven wrapper with container build)
- Docker Desktop (arm64)
- PostgreSQL reachable at `db:5432`

## Local Build & Test
```bash
cd quarkus-app
./mvnw clean package -DskipTests            # optional JVM build
./mvnw package -Dnative -DskipTests \
  -Dquarkus.native.container-build=true     # build native runner via Mandrel
./test_with_database.sh
```
`test_with_database.sh` will rebuild the native runner when sources change, build the docker image, and run smoke tests.

## Docker Build
> Requires the native runner (`target/quarkus-poc-1.0.0-runner`) from the step above.
```bash
docker build --platform linux/arm64 -t poc-quarkus-native -f quarkus-native.Dockerfile quarkus-app
```

## Runtime
```bash
docker run -d --name poc-app \
  --net poc-net --cpus=1.0 --memory=1g \
  --platform linux/arm64 -p 8080:8080 poc-quarkus-native
```
