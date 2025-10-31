#!/bin/bash

# Database setup script for Mac OS single-machine POC
# Creates custom Docker network and PostgreSQL container

echo "🗄️  Setting up Database for POC Testing"
echo "=========================================="

# Create custom Docker network for Mac OS compatibility
echo "🌐 Creating Docker network 'poc-net'..."
if ! docker network inspect poc-net >/dev/null 2>&1; then
    docker network create poc-net
    echo "✅ Network 'poc-net' created"
else
    echo "✅ Network 'poc-net' already exists"
fi

# Stop and remove existing database container if it exists
echo "🧹 Cleaning up existing database container..."
if docker ps -a --format 'table {{.Names}}' | grep -q "^db$"; then
    echo "🛑 Stopping existing 'db' container..."
    docker stop db >/dev/null 2>&1
    docker rm db >/dev/null 2>&1
    echo "✅ Existing container removed"
fi

# Start PostgreSQL container
echo "🚀 Starting PostgreSQL container..."
docker run -d \
    --name db \
    --restart unless-stopped \
    --network poc-net \
    --platform linux/arm64 \
    -e POSTGRES_DB=poc_db \
    -e POSTGRES_USER=poc_user \
    -e POSTGRES_PASSWORD=poc_password \
    -p 5432:5432 \
    -v "$(pwd)/database:/docker-entrypoint-initdb.d:ro" \
    postgres:15-alpine

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL container started successfully"
else
    echo "❌ Failed to start PostgreSQL container"
    exit 1
fi

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec db pg_isready -U poc_user -d poc_db >/dev/null 2>&1; then
        echo "✅ Database is ready!"
        break
    fi

    echo "   Attempt $attempt/$max_attempts..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Database failed to become ready within 60 seconds"
    docker logs db
    exit 1
fi

# Initialize database with schema and seed data
echo "📋 Initializing database schema and seed data..."
docker exec -i db psql -U poc_user -d poc_db < database/schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Schema created successfully"
else
    echo "⚠️  Schema creation failed (might already exist)"
fi

docker exec -i db psql -U poc_user -d poc_db < database/seed_data.sql

if [ $? -eq 0 ]; then
    echo "✅ Seed data loaded successfully"
else
    echo "⚠️  Seed data loading failed (might already exist)"
fi

# Verify data
echo "🔍 Verifying database setup..."
user_count=$(docker exec -i db psql -U poc_user -d poc_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')

if [ "$user_count" -gt 0 ]; then
    echo "✅ Database setup complete! Found $user_count users in database"
else
    echo "❌ Database setup incomplete - no users found"
    exit 1
fi

# Display connection info
echo ""
echo "📊 Database Connection Information"
echo "==============================="
echo "Container Name: db"
echo "Network: poc-net"
echo "Host (for containers): db"
echo "Host (for host machine): localhost"
echo "Port: 5432"
echo "Database: poc_db"
echo "User: poc_user"
echo ""
echo "🔧 Test connection:"
echo "docker exec -it db psql -U poc_user -d poc_db -c 'SELECT COUNT(*) FROM users;'"
echo ""
echo "🚀 Database is ready for POC applications!"
