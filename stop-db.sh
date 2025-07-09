#!/bin/bash

# Stop Database Services
echo "🛑 Stopping Database Services"
echo "============================="

echo "🐳 Stopping containers..."
docker-compose -f docker-compose.db.yml down

echo "✅ Database services stopped!"
echo ""
echo "💡 To remove data volumes (reset database):"
echo "   docker-compose -f docker-compose.db.yml down -v"
