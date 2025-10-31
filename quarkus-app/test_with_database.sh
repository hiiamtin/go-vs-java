#!/bin/bash

# Test script for Quarkus application with database
# Validates parity across all five endpoints

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧪 Testing Quarkus Application (Native) with Database"
echo "===================================================="

echo "⚙️  Building native executable (may trigger container build)..."
BUILD_LOG="native-build.log"

RUNNER="target/quarkus-poc-1.0.0-runner"
SHOULD_BUILD=0
if [ ! -f "$RUNNER" ]; then
    SHOULD_BUILD=1
else
    if [ -n "$(find src/main/java src/main/resources quarkus-native.Dockerfile pom.xml -newer "$RUNNER" -print -quit)" ]; then
        SHOULD_BUILD=1
    fi
fi

if [ "$SHOULD_BUILD" -eq 1 ]; then
    if ! ./mvnw package -Dnative -DskipTests -Dquarkus.native.container-build=true -Dmaven.repo.local=.m2 2>&1 | tee "$BUILD_LOG"; then
        echo "❌ Native build failed. Last 40 lines:"
        tail -n 40 "$BUILD_LOG"
        echo "See $BUILD_LOG for details."
        exit 1
    fi
else
    echo "⚡ Native runner up to date; skipping rebuild."
fi

echo "📦 Building Quarkus native runtime image..."
docker build --platform linux/arm64 -t quarkus-native-app -f quarkus-native.Dockerfile .

echo "✅ Docker build successful!"

echo "🧹 Cleaning up any existing container..."
if docker ps -a --format '{{.Names}}' | grep -Eq '^quarkus-native-app$'; then
    docker stop quarkus-native-app >/dev/null 2>&1
    docker rm quarkus-native-app >/dev/null 2>&1
    echo "✅ Existing container removed"
fi

echo "🚀 Starting Quarkus application on poc-net network..."
docker run -d \
    --name quarkus-native-app \
    --network poc-net \
    --platform linux/arm64 \
    --cpus="1.0" \
    --memory="1g" \
    -p 8080:8080 \
    quarkus-native-app

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
    docker logs quarkus-native-app
    docker stop quarkus-native-app >/dev/null 2>&1 || true
    docker rm quarkus-native-app >/dev/null 2>&1 || true
    exit 1
fi

echo ""
echo "🔍 Test 1: Plaintext Endpoint"
plaintext_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:8080/plaintext)
http_code=$(echo "$plaintext_response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
response_body=$(echo "$plaintext_response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ] && [ "$response_body" = "Hello, World!" ]; then
    echo "✅ GET /plaintext - HTTP 200 OK"
else
    echo "⚠️  GET /plaintext unexpected: HTTP $http_code, body '$response_body'"
fi

echo ""
echo "🔍 Test 2: JSON Endpoint"
json_payload='{"customerId":12345,"personalInfo":{"firstName":"John","lastName":"Smith","email":"john.smith@example.com","address":{"street":"123 Main St","city":"New York","state":"NY"}}}'
json_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$json_payload" \
    http://localhost:8080/json)

http_code=$(echo "$json_response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
response_body=$(echo "$json_response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ] && echo "$response_body" | grep -q '"status":"ok"'; then
    echo "✅ POST /json - HTTP 200 OK"
else
    echo "⚠️  POST /json unexpected: HTTP $http_code, body '$response_body'"
    echo "   --- Container logs ---"
    docker logs quarkus-native-app | tail -n 40
fi

echo ""
echo "🔍 Test 3: CPU Endpoint"
cpu_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"test_input"}' \
    http://localhost:8080/cpu)

http_code=$(echo "$cpu_response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
response_body=$(echo "$cpu_response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ] && echo "$response_body" | grep -q '"processed_name"'; then
    echo "✅ POST /cpu - HTTP 200 OK"
else
    echo "⚠️  POST /cpu unexpected: HTTP $http_code, body '$response_body'"
    echo "   --- Container logs ---"
    docker logs quarkus-native-app | tail -n 40
fi

echo ""
echo "🔍 Test 4: Database Read Endpoint"
db_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:8080/db)
http_code=$(echo "$db_response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
response_body=$(echo "$db_response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ] && echo "$response_body" | grep -q '"id":10'; then
    echo "✅ GET /db - HTTP 200 OK"
else
    echo "⚠️  GET /db unexpected: HTTP $http_code, body '$response_body'"
fi

echo ""
echo "🔍 Test 5: Realistic Transaction Endpoint"
interaction_payload='{"customerId":10,"note":"Test interaction via API","type":"CALL"}'
interaction_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$interaction_payload" \
    http://localhost:8080/interaction)

http_code=$(echo "$interaction_response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
response_body=$(echo "$interaction_response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "201" ] && echo "$response_body" | grep -q '"customer_id":10'; then
    echo "✅ POST /interaction - HTTP 201 Created"
else
    echo "⚠️  POST /interaction unexpected: HTTP $http_code, body '$response_body'"
fi

echo ""
echo "🔍 Test 6: Error Handling"
echo "   Invalid customer ID..."
invalid_customer=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"customerId":999,"note":"Test","type":"CALL"}' \
    http://localhost:8080/interaction)
if echo "$invalid_customer" | grep -q 'HTTP_CODE:404'; then
    echo "✅ Invalid customer ID returns 404"
else
    echo "⚠️  Invalid customer ID test failed"
fi

echo "   Invalid interaction type..."
invalid_type=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"customerId":10,"note":"Test","type":"INVALID"}' \
    http://localhost:8080/interaction)
if echo "$invalid_type" | grep -q 'HTTP_CODE:400'; then
    echo "✅ Invalid interaction type returns 400"
else
    echo "⚠️  Invalid interaction type test failed"
fi

echo ""
echo "🧼 Cleaning up..."
docker stop quarkus-native-app >/dev/null 2>&1 || true
docker rm quarkus-native-app >/dev/null 2>&1 || true

echo "🎉 All tests executed for Quarkus application!"
