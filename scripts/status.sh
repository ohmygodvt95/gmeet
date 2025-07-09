#!/bin/bash

# GMeeting Status Check Script

echo "📊 GMeeting Services Status"
echo "=========================="

# Function to check service status
check_service_status() {
    local service_name=$1
    local port=$2
    local pid_file="logs/${service_name}.pid"
    
    echo "🔍 $service_name:"
    
    # Check PID file
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo "   ✅ Process running (PID: $pid)"
        else
            echo "   ❌ Process not running (stale PID file)"
            rm -f "$pid_file"
        fi
    else
        echo "   ❌ Not running (no PID file)"
    fi
    
    # Check port
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "   ✅ Port $port is listening"
    else
        echo "   ❌ Port $port is not listening"
    fi
    
    echo ""
}

# Function to check Docker service
check_docker_service() {
    local service_name=$1
    local container_name=$2
    
    echo "🐳 $service_name:"
    
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
        echo "   ✅ Container running (Status: $status)"
    else
        echo "   ❌ Container not running"
    fi
    
    echo ""
}

# Check Node.js services
check_service_status "Frontend" 3000
check_service_status "Backend" 3001
check_service_status "SFU-Server" 3002

# Check Docker services
check_docker_service "MySQL" "gmeeting_mysql"
check_docker_service "Redis" "gmeeting_redis"

# Check overall health
echo "🌐 Health Checks:"
echo "=================="

# Backend health
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ Backend API is healthy"
else
    echo "❌ Backend API is not responding"
fi

# SFU health  
if curl -s http://localhost:3002/health > /dev/null 2>&1; then
    echo "✅ SFU Server is healthy"
else
    echo "❌ SFU Server is not responding"
fi

# Frontend health
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend is not accessible"
fi

echo ""
echo "📋 Quick Commands:"
echo "   ./scripts/start-dev.sh  - Start all services"
echo "   ./scripts/stop.sh       - Stop all services"
echo "   ./scripts/logs.sh       - View logs"
echo "   ./scripts/restart.sh    - Restart services"
