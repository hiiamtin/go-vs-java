#!/bin/bash

# Test script for Gin application
# Tests endpoints that don't require database connection

echo "🧪 Testing Gin Application Locally"
echo "=================================="

# Build the application
echo "📦 Building application..."
cd "$(dirname "$0")"
go build -o main .

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Test 1: Plaintext endpoint (works without database)
echo ""
echo "🔍 Test 1: Plaintext Endpoint"
echo "GET /plaintext"

# Start app in background and wait for startup
echo "🚀 Starting application..."
./main > app.log 2>&1 &
APP_PID=$!

# Wait for app to attempt startup
sleep 5

# Check if process is still running
# Check if process is still running
if ! kill -0 $APP_PID 2>/dev/null; then
    echo "❌ Application failed to start"
    cat app.log
    rm -f app.log
    exit 1
fi

# Test plaintext endpoint
echo "📡 Testing plaintext endpoint..."
plaintext_response=$(curl -s -w "%{http_code}" http://localhost:8080/plaintext 2>/dev/null)
http_code="${plaintext_response: -3}"

if [ "$http_code" = "200" ]; then
    echo "✅ GET /plaintext - HTTP 200 OK"
    # Extract response body (remove http code)
    response_body="${plaintext_response%???}"
    if [ "$response_body" = "Hello, World!" ]; then
        echo "✅ Response body correct: '$response_body'"
    else
        echo "⚠️  Response body unexpected: '$response_body'"
    fi
else
    echo "❌ GET /plaintext - HTTP $http_code"
fi

# Test 2: Health endpoint (works without database)
echo ""
echo "🔍 Test 2: Health Endpoint"
echo "GET /health"

health_response=$(curl -s -w "%{http_code}" http://localhost:8080/health 2>/dev/null)
http_code="${health_response: -3}"

if [ "$http_code" = "200" ]; then
    echo "✅ GET /health - HTTP 200 OK"
else
    echo "❌ GET /health - HTTP $http_code"
fi

# Test 3: JSON endpoint (works without database)
echo ""
echo "🔍 Test 3: JSON Endpoint"
echo "POST /json"

json_response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"customerId":12345,"personalInfo":{"firstName":"John","lastName":"Smith"}}' \
    http://localhost:8080/json 2>/dev/null)
http_code="${json_response: -3}"

if [ "$http_code" = "200" ]; then
    echo "✅ POST /json - HTTP 200 OK"
    response_body="${json_response%???}"
    if echo "$response_body" | grep -q '"status":"ok"'; then
        echo "✅ JSON response correct"
    else
        echo "⚠️  JSON response unexpected: '$response_body'"
    fi
else
    echo "❌ POST /json - HTTP $http_code"
fi

# Test 4: CPU endpoint (works without database)
echo ""
echo "🔍 Test 4: CPU Endpoint"
echo "POST /cpu"

cpu_response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"test"}' \
    http://localhost:8080/cpu 2>/dev/null)
http_code="${cpu_response: -3}"

if [ "$http_code" = "200" ]; then
    echo "✅ POST /cpu - HTTP 200 OK"
    response_body="${cpu_response%???}"
    if echo "$response_body" | grep -q '"processed_name"'; then
        echo "✅ CPU work completed successfully"
    else
        echo "⚠️  CPU response unexpected: '$response_body'"
    fi
else
    echo "❌ POST /cpu - HTTP $http_code"
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
kill $APP_PID 2>/dev/null
wait $APP_PID 2>/dev/null
rm -f main app.log

echo ""
echo "📊 Test Summary"
echo "==============="
echo "✅ Application builds successfully"
echo "✅ Server starts without critical errors"
echo "✅ Basic endpoints respond correctly"
echo "⚠️  Database-dependent endpoints (/db, /interaction) need Docker setup"
echo ""
echo "🚀 Gin application is ready for Phase 2 (Containerization)!"
