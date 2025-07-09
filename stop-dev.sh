#!/bin/bash

# Stop Development Services
echo "🛑 Stopping Development Services"
echo "================================"

# Function to kill process by PID file
kill_service() {
    local service_name=$1
    local pid_file="logs/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "🔪 Stopping $service_name (PID: $pid)..."
            kill "$pid"
            rm "$pid_file"
            echo "✅ $service_name stopped"
        else
            echo "⚠️  $service_name process not found"
            rm "$pid_file"
        fi
    else
        echo "ℹ️  No PID file for $service_name"
    fi
}

# Stop services
kill_service "backend"
kill_service "sfu"
kill_service "frontend"

# Also try to kill by port
echo ""
echo "🔍 Checking for remaining processes..."

# Kill processes on specific ports
for port in 3000 3001 3002; do
    pid=$(lsof -ti:$port 2>/dev/null)
    if [ -n "$pid" ]; then
        echo "🔪 Killing process on port $port (PID: $pid)..."
        kill -9 "$pid" 2>/dev/null
    fi
done

echo ""
echo "✅ Development services stopped!"
echo ""
echo "💡 Database is still running. To stop:"
echo "   ./stop-db.sh"
