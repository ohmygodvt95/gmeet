#!/bin/bash

# Test script for GMeeting application
echo "🧪 Testing GMeeting Application"
echo "================================"

# Check if we're in the correct directory
if [ ! -f "docker-compose.db.yml" ]; then
    echo "❌ Not in GMeeting root directory. Please run from project root."
    exit 1
fi

# Function to check if service is running
check_service() {
    local service_name=$1
    local port=$2
    
    echo -n "🔍 Checking $service_name on port $port... "
    
    if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ Failed"
        return 1
    fi
}

# Function to check database connection
check_database() {
    echo -n "🔍 Checking MySQL database... "
    
    if docker exec gmeeting_mysql mysqladmin ping -h"localhost" --silent > /dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ Failed"
        return 1
    fi
}

# Function to check Redis
check_redis() {
    echo -n "🔍 Checking Redis... "
    
    if docker exec gmeeting_redis redis-cli ping > /dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ Failed"
        return 1
    fi
}

echo "📋 Starting basic tests..."
echo ""

# Check if Docker is running
echo -n "🐳 Checking Docker... "
if docker ps > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Docker is not running"
    exit 1
fi

# Check if containers are running
echo ""
echo "📦 Checking containers..."
REQUIRED_CONTAINERS=("gmeeting_mysql" "gmeeting_redis" "gmeeting_backend" "gmeeting_frontend" "gmeeting_sfu")

for container in "${REQUIRED_CONTAINERS[@]}"; do
    echo -n "🔍 Checking $container... "
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        echo "✅ Running"
    else
        echo "❌ Not running"
        echo "💡 Try running: docker-compose up -d"
        exit 1
    fi
done

# Wait a moment for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check database and Redis
echo ""
echo "💾 Checking data services..."
check_database
check_redis

# Check application services
echo ""
echo "🌐 Checking application services..."
check_service "Backend API" "3001"
check_service "SFU Server" "3002"
check_service "Frontend" "3000"

# Additional tests
echo ""
echo "🔧 Running additional tests..."

# Test API endpoints
echo -n "🔍 Testing API registration endpoint... "
if curl -s -X POST "http://localhost:3001/api/auth/register" \
   -H "Content-Type: application/json" \
   -d '{"username":"test","email":"test@test.com","password":"test123","fullName":"Test User"}' \
   > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

echo -n "🔍 Testing API login endpoint... "
if curl -s -X POST "http://localhost:3001/api/auth/login" \
   -H "Content-Type: application/json" \
   -d '{"email":"admin@gmeeting.com","password":"admin123"}' \
   > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Test frontend pages
echo -n "🔍 Testing frontend index page... "
if curl -s "http://localhost:3000" > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
fi

# Show container logs if there are issues
echo ""
echo "📝 Recent logs:"
echo "Backend logs:"
docker logs gmeeting_backend --tail 5 2>/dev/null || echo "❌ Cannot get backend logs"

echo ""
echo "SFU logs:"
docker logs gmeeting_sfu --tail 5 2>/dev/null || echo "❌ Cannot get SFU logs"

echo ""
echo "🎉 Test completed!"
echo ""
echo "📖 Next steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Register a new account or login with:"
echo "   Email: admin@gmeeting.com"
echo "   Password: admin123"
echo "3. Create a room and test video calling"
echo ""
echo "🔗 Service URLs:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:3001"
echo "   SFU:      http://localhost:3002"
echo ""
echo "📊 To monitor services:"
echo "   docker-compose logs -f"
echo "   ./scripts/status.sh"
echo "   ./scripts/logs.sh"
