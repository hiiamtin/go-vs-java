#!/bin/bash

# Test script for Quarkus JVM application with database
# Validates parity across all five endpoints

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="poc-quarkus-jvm"
IMAGE_NAME="poc-quarkus-jvm"
JVM_IMAGE_TAG="poc-quarkus-jvm"

echo "🧪 Testing Quarkus Application (JVM) with Database"
echo "================================================"

echo "⚙️  Building JVM runner..."
if ! ./mvnw package -DskipTests 2>&1 | tee build-jvm.log; then
    echo "❌ JVM build failed. Last 40 lines:"
    tail -n 40 build-jvm.log
    exit 1
fi

if [ ! -f target/quarkus-app/quarkus-run.jar ]; then
    echo "❌ Missing quarkus-run.jar after build"
    exit 1
fi

echo "📦 Building Quarkus JVM Docker image..."
docker build --platform linux/arm64 -t "$IMAGE_NAME" -f quarkus-jvm.Dockerfile .

echo "✅ Docker build successful!"

echo "🧹 Cleaning up any existing container..."
if docker ps -a --format '{{.Names}}' | grep -Eq "^${APP_NAME}$"; then
    docker stop "$APP_NAME" >/dev/null 2>&1
    docker rm "$APP_NAME" >/dev/null 2>&1
    echo "✅ Existing container removed"
fi

echo "🚀 Starting Quarkus JVM application on poc-net network..."
docker run -d \
    --name "$APP_NAME" \
    --network poc-net \
    --platform linux/arm64 \
    --cpus="1.0" \
    --memory="1g" \
    -p 8080:8080 \
    "$IMAGE_NAME"

echo "⏳ Waiting for application to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
        echo "✅ Application is ready!"
        break
    fi
    echo "   Attempt $attempt/$max_attempts..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Application failed to become ready within 60 seconds"
    docker logs "$APP_NAME"
    docker stop "$APP_NAME" >/dev/null 2>&1 || true
    docker rm "$APP_NAME" >/dev/null 2>&1 || true
    exit 1
fi

run_test() {
    local name="$1"
    local method="$2"
    local url="$3"
    local payload="$4"
    local expected_http="$5"
    local expect_substring="$6"

    echo ""
    echo "🔍 Test: $name"
    if [ -n "$payload" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$payload" "$url")
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X "$method" "$url")
    fi
    http_code=$(echo "$response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')

    if [ "$http_code" = "$expected_http" ] && echo "$body" | grep -q "$expect_substring"; then
        echo "✅ $name - HTTP $expected_http"
    else
        echo "⚠️  $name unexpected: HTTP $http_code, body '$body'"
        echo "   --- Container logs ---"
        docker logs "$APP_NAME" | tail -n 40
    fi
}

run_test "Plaintext Endpoint" "GET" "http://localhost:8080/plaintext" "" "200" "Hello, World!"
run_test "JSON Endpoint" "POST" "http://localhost:8080/json" '{"customerId":12345,"personalInfo":{"firstName":"John","lastName":"Smith","email":"john.smith@example.com","address":{"street":"123 Main St","city":"New York","state":"NY"}}}' "200" '"status":"ok"'
run_test "CPU Endpoint" "POST" "http://localhost:8080/cpu" '{"name":"test_input"}' "200" '"processed_name"'
run_test "Database Read" "GET" "http://localhost:8080/db" "" "200" '"id":10'
run_test "Realistic Transaction" "POST" "http://localhost:8080/interaction" '{"customerId":10,"note":"Test interaction via API","type":"CALL"}' "201" '"customer_id":10'
run_test "Invalid customer" "POST" "http://localhost:8080/interaction" '{"customerId":999,"note":"Test","type":"CALL"}' "404" ''
run_test "Invalid interaction type" "POST" "http://localhost:8080/interaction" '{"customerId":10,"note":"Test","type":"INVALID"}' "400" ''

echo ""
echo "🧼 Cleaning up..."
docker stop "$APP_NAME" >/dev/null 2>&1 || true
docker rm "$APP_NAME" >/dev/null 2>&1 || true

echo "🎉 All tests executed for Quarkus JVM application!"
