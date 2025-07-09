#!/bin/bash

# Start Database Services Only
echo "🗄️ Starting Database Services"
echo "============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "🐳 Starting MySQL and Redis containers..."
docker-compose -f docker-compose.db.yml up -d

echo "⏳ Waiting for services to be ready..."

# Wait for MySQL
echo -n "🔍 Waiting for MySQL..."
for i in {1..30}; do
    if docker exec gmeeting_mysql mysqladmin ping -h"localhost" --silent 2>/dev/null; then
        echo " ✅ Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

# Wait for Redis
echo -n "🔍 Waiting for Redis..."
for i in {1..10}; do
    if docker exec gmeeting_redis redis-cli auth redis123 ping 2>/dev/null | grep -q PONG; then
        echo " ✅ Ready!"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo "✅ Database services are ready!"
echo ""
echo "📊 Service Status:"
echo "  MySQL:  localhost:3306"
echo "  Redis:  localhost:6379"
echo ""
echo "🔗 Connection Details:"
echo "  MySQL Database: gmeeting"
echo "  MySQL User:     sail"
echo "  MySQL Password: password"
echo "  Redis Password: redis123"
echo ""
echo "📝 Next Steps:"
echo "  1. Start Backend:  cd backend && npm run dev"
echo "  2. Start SFU:      cd sfu-server && npm run dev"
echo "  3. Start Frontend: cd frontend && npm run dev"
