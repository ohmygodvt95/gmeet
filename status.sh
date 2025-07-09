#!/bin/bash

# GMeeting Development Status Check Script
echo "📊 GMeeting Services Status"
echo "=========================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Function to check service status by PID and port
check_service_status() {
    local service_name=$1
    local port=$2
    local pid_file="logs/${service_name}.pid"
    
    echo "🔍 $service_name Service:"
    
    # Check PID file
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            print_status "Process running (PID: $pid)"
        else
            print_error "Process not running (stale PID file)"
            rm -f "$pid_file" 2>/dev/null
        fi
    else
        print_info "Not running (no PID file)"
    fi
    
    # Check port
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            local port_pid
            port_pid=$(lsof -ti:$port 2>/dev/null)
            print_status "Port $port is listening (PID: $port_pid)"
        else
            print_error "Port $port is not listening"
        fi
    else
        # Fallback for systems without lsof
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            print_status "Port $port is listening"
        else
            print_error "Port $port is not listening"
        fi
    fi
    
    echo ""
}

# Function to check Docker service
check_docker_service() {
    local service_name=$1
    local container_name=$2
    
    echo "🐳 $service_name:"
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker not found"
        echo ""
        return
    fi
    
    if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "$container_name"; then
        local status
        status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
        print_status "Container running (Status: $status)"
        
        # Check container health if available
        local health
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
        if [ "$health" != "" ] && [ "$health" != "<no value>" ]; then
            if [ "$health" = "healthy" ]; then
                print_status "Health check: $health"
            else
                print_warning "Health check: $health"
            fi
        fi
    else
        print_error "Container not running"
    fi
    
    echo ""
}

# Check Node.js services
echo "🚀 Node.js Services:"
echo "==================="
check_service_status "frontend" 3000
check_service_status "backend" 3001
check_service_status "sfu" 3002

# Check Docker services
echo "🐳 Docker Services:"
echo "=================="
check_docker_service "MySQL Database" "gmeeting_mysql"
check_docker_service "Redis Cache" "gmeeting_redis"

# Check overall health
echo "🌐 Health Checks:"
echo "=================="

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
    print_warning "curl not available - skipping health checks"
    echo ""
else
    # Backend health
    if curl -s --max-time 5 http://localhost:3001/health > /dev/null 2>&1; then
        print_status "Backend API is healthy (http://localhost:3001)"
    else
        print_error "Backend API is not responding"
    fi

    # SFU health  
    if curl -s --max-time 5 http://localhost:3002/health > /dev/null 2>&1; then
        print_status "SFU Server is healthy (http://localhost:3002)"
    else
        print_error "SFU Server is not responding"
    fi

    # Frontend health
    if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
        print_status "Frontend is accessible (http://localhost:3000)"
    else
        print_error "Frontend is not accessible"
    fi
fi

echo ""

# Check log files
echo "📝 Log Files:"
echo "============"
if [ -d "logs" ]; then
    for log_file in logs/*.log; do
        if [ -f "$log_file" ]; then
            size=$(du -h "$log_file" 2>/dev/null | cut -f1)
            name=$(basename "$log_file")
            print_info "$name ($size)"
        fi
    done
    if ! ls logs/*.log >/dev/null 2>&1; then
        print_info "No log files found"
    fi
else
    print_info "Logs directory not found"
fi

echo ""

# System resources
echo "💻 System Resources:"
echo "==================="
if command -v free >/dev/null 2>&1; then
    mem_usage=$(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100)}')
    print_info "Memory usage: $mem_usage"
fi

if command -v df >/dev/null 2>&1; then
    disk_usage=$(df . | tail -1 | awk '{print $5}')
    print_info "Disk usage: $disk_usage"
fi

# Load average (Linux/macOS)
if [ -f "/proc/loadavg" ]; then
    load=$(cat /proc/loadavg | awk '{print $1}')
    print_info "Load average: $load"
elif command -v uptime >/dev/null 2>&1; then
    load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    print_info "Load average: $load"
fi

echo ""
echo "📋 Quick Commands:"
echo "   ./start-dev.sh       - Start development services"
echo "   ./stop-dev.sh        - Stop development services"
echo "   ./start-db.sh        - Start database services"
echo "   ./stop-db.sh         - Stop database services"
echo "   ./test-services.sh   - Test service connectivity"
echo "   tail -f logs/*.log   - View live logs"
