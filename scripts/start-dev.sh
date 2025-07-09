#!/bin/bash

# GMeeting Development Startup Script

echo "🚀 Starting GMeeting Development Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if ports are available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ Port $1 is already in use"
        return 1
    fi
}

echo "🔍 Checking ports..."
check_port 3000 || exit 1  # Frontend
check_port 3001 || exit 1  # Backend
check_port 3002 || exit 1  # SFU
check_port 3306 || exit 1  # MySQL
check_port 6379 || exit 1  # Redis

echo "✅ All ports are available"

# Start infrastructure services
echo "🗄️  Starting database and cache services..."
docker-compose up -d mysql redis

# Wait for database to be ready
echo "⏳ Waiting for database to initialize..."
sleep 15

# Check database connection
echo "🔌 Testing database connection..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec gmeeting_mysql mysql -u sail -ppassword -e "SELECT 1" gmeeting >/dev/null 2>&1; then
        echo "✅ Database is ready"
        break
    fi
    
    echo "Attempt $attempt/$max_attempts: Database not ready yet..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Database failed to start after $max_attempts attempts"
    exit 1
fi

# Function to run service in background
run_service() {
    local service_name=$1
    local service_dir=$2
    local start_command=$3
    
    echo "🚀 Starting $service_name..."
    cd $service_dir
    
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies for $service_name..."
        npm install
    fi
    
    # Kill existing process if running
    pkill -f "$start_command" 2>/dev/null || true
    
    # Start service in background
    nohup npm run dev > "../logs/${service_name}.log" 2>&1 &
    local pid=$!
    echo $pid > "../logs/${service_name}.pid"
    
    echo "✅ $service_name started (PID: $pid)"
    cd ..
}

# Create logs directory
mkdir -p logs

# Start backend
run_service "Backend" "backend" "src/server.js"

# Wait a bit for backend to start
sleep 3

# Start SFU server
run_service "SFU-Server" "sfu-server" "src/index.js"

# Wait a bit for SFU to start
sleep 3

# Start frontend
run_service "Frontend" "frontend" "nuxt dev"

echo ""
echo "🎉 GMeeting development environment is starting up!"
echo ""
echo "📍 Services:"
echo "   Frontend:  http://localhost:3000"
echo "   Backend:   http://localhost:3001"
echo "   SFU:       http://localhost:3002"
echo "   MySQL:     localhost:3306"
echo "   Redis:     localhost:6379"
echo ""
echo "📋 Useful commands:"
echo "   ./scripts/status.sh     - Check service status"
echo "   ./scripts/stop.sh       - Stop all services"
echo "   ./scripts/logs.sh       - View logs"
echo "   ./scripts/restart.sh    - Restart services"
echo ""
echo "⏳ Please wait 10-15 seconds for all services to fully start..."

# Function to check service health
check_service_health() {
    local service_name=$1
    local health_url=$2
    local max_wait=30
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if curl -s $health_url > /dev/null 2>&1; then
            echo "✅ $service_name is healthy"
            return 0
        fi
        sleep 1
        wait_time=$((wait_time + 1))
    done
    
    echo "⚠️  $service_name health check timeout"
    return 1
}

echo ""
echo "🔍 Checking service health..."
sleep 10

check_service_health "Backend" "http://localhost:3001/health"
check_service_health "SFU Server" "http://localhost:3002/health"
check_service_health "Frontend" "http://localhost:3000"

echo ""
echo "🎊 GMeeting is ready! Open http://localhost:3000 in your browser."
