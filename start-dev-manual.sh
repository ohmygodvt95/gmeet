#!/bin/bash

# Start Development Environment (Manual)
echo "🚀 Starting GMeeting Development Environment"
echo "============================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if database is running
check_database() {
    print_step "Checking database services..."
    
    if ! docker ps | grep -q "gmeeting_mysql"; then
        print_error "MySQL container is not running"
        print_status "Please run: ./start-db.sh"
        return 1
    fi
    
    if ! docker ps | grep -q "gmeeting_redis"; then
        print_error "Redis container is not running"
        print_status "Please run: ./start-db.sh"
        return 1
    fi
    
    print_status "✅ Database services are running"
    return 0
}

# Install dependencies if needed
install_deps() {
    print_step "Checking dependencies..."
    
    local SCRIPT_DIR
    SCRIPT_DIR=$(pwd)
    
    # Backend dependencies
    if [ -d "$SCRIPT_DIR/backend" ] && [ -f "$SCRIPT_DIR/backend/package.json" ]; then
        if [ ! -d "$SCRIPT_DIR/backend/node_modules" ]; then
            print_status "Installing backend dependencies..."
            (cd "$SCRIPT_DIR/backend" && npm install)
        fi
    fi
    
    # Frontend dependencies
    if [ -d "$SCRIPT_DIR/frontend" ] && [ -f "$SCRIPT_DIR/frontend/package.json" ]; then
        if [ ! -d "$SCRIPT_DIR/frontend/node_modules" ]; then
            print_status "Installing frontend dependencies..."
            (cd "$SCRIPT_DIR/frontend" && npm install)
        fi
    fi
    
    # SFU dependencies
    if [ -d "$SCRIPT_DIR/sfu-server" ] && [ -f "$SCRIPT_DIR/sfu-server/package.json" ]; then
        if [ ! -d "$SCRIPT_DIR/sfu-server/node_modules" ]; then
            print_status "Installing SFU dependencies..."
            (cd "$SCRIPT_DIR/sfu-server" && npm install)
        fi
    fi
    
    print_status "✅ Dependencies ready"
}

# Check if database is running
if ! check_database; then
    exit 1
fi

# Install dependencies
install_deps

echo ""
print_step "Starting development servers..."
echo ""

# Check Node.js version
node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$node_version" -lt 18 ]; then
    print_warning "⚠️  Node.js version $node_version detected. Recommended: 18+"
fi

echo "📝 Development Commands:"
echo "========================"
echo ""
echo "🔧 Backend (Terminal 1):"
echo "   cd backend && npm run dev"
echo "   URL: http://localhost:3001"
echo ""
echo "🎬 SFU Server (Terminal 2):"
echo "   cd sfu-server && npm run dev"
echo "   URL: http://localhost:3002"
echo ""
echo "🌐 Frontend (Terminal 3):"
echo "   cd frontend && npm run dev"
echo "   URL: http://localhost:3000"
echo ""
echo "💾 Database URLs:"
echo "   MySQL:  localhost:3306"
echo "   Redis:  localhost:6379"
echo ""
echo "🔍 Monitoring:"
echo "   Database logs: docker-compose -f docker-compose.db.yml logs -f"
echo "   Stop database: ./stop-db.sh"
echo ""

# Option to start all in background
read -p "🤔 Do you want to start all services automatically? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting all services in background..."
    
    # Save current directory
    SCRIPT_DIR=$(pwd)
    
    # Create logs directory if not exists
    mkdir -p logs || {
        print_error "Cannot create logs directory. Starting without logging to files."
        LOG_TO_FILE=false
    }
    LOG_TO_FILE=${LOG_TO_FILE:-true}
    
    # Start backend
    if [ -d "$SCRIPT_DIR/backend" ]; then
        print_status "Starting backend..."
        if [ "$LOG_TO_FILE" = true ]; then
            (cd "$SCRIPT_DIR/backend" && npm run dev > "$SCRIPT_DIR/logs/backend.log" 2>&1) &
        else
            (cd "$SCRIPT_DIR/backend" && npm run dev) &
        fi
        BACKEND_PID=$!
        echo "$BACKEND_PID" > "$SCRIPT_DIR/logs/backend.pid" 2>/dev/null || echo "Backend PID: $BACKEND_PID"
    else
        print_error "Backend directory not found at $SCRIPT_DIR/backend"
    fi
    
    # Wait a moment
    sleep 2
    
    # Start SFU
    if [ -d "$SCRIPT_DIR/sfu-server" ]; then
        print_status "Starting SFU server..."
        if [ "$LOG_TO_FILE" = true ]; then
            (cd "$SCRIPT_DIR/sfu-server" && npm run dev > "$SCRIPT_DIR/logs/sfu.log" 2>&1) &
        else
            (cd "$SCRIPT_DIR/sfu-server" && npm run dev) &
        fi
        SFU_PID=$!
        echo "$SFU_PID" > "$SCRIPT_DIR/logs/sfu.pid" 2>/dev/null || echo "SFU PID: $SFU_PID"
    else
        print_error "SFU server directory not found at $SCRIPT_DIR/sfu-server"
    fi
    
    # Wait a moment
    sleep 2
    
    # Start frontend
    if [ -d "$SCRIPT_DIR/frontend" ]; then
        print_status "Starting frontend..."
        if [ "$LOG_TO_FILE" = true ]; then
            (cd "$SCRIPT_DIR/frontend" && npm run dev > "$SCRIPT_DIR/logs/frontend.log" 2>&1) &
        else
            (cd "$SCRIPT_DIR/frontend" && npm run dev) &
        fi
        FRONTEND_PID=$!
        echo "$FRONTEND_PID" > "$SCRIPT_DIR/logs/frontend.pid" 2>/dev/null || echo "Frontend PID: $FRONTEND_PID"
    else
        print_error "Frontend directory not found at $SCRIPT_DIR/frontend"
    fi
    
    echo ""
    print_status "🎉 Services started!"
    echo ""
    print_status "📊 Service Status:"
    [ -n "$BACKEND_PID" ] && print_status "   Backend:  http://localhost:3001 (PID: $BACKEND_PID)"
    [ -n "$SFU_PID" ] && print_status "   SFU:      http://localhost:3002 (PID: $SFU_PID)"
    [ -n "$FRONTEND_PID" ] && print_status "   Frontend: http://localhost:3000 (PID: $FRONTEND_PID)"
    echo ""
    
    if [ "$LOG_TO_FILE" = true ]; then
        print_status "📝 Log files:"
        print_status "   Backend:  logs/backend.log"
        print_status "   SFU:      logs/sfu.log"
        print_status "   Frontend: logs/frontend.log"
        echo ""
        print_status "� To view logs:"
        print_status "   tail -f logs/backend.log"
        print_status "   tail -f logs/sfu.log"
        print_status "   tail -f logs/frontend.log"
    else
        print_status "📝 Services running without file logging"
    fi
    
    echo ""
    print_status "🛑 To stop all services:"
    print_status "   ./stop-dev.sh"
    
else
    print_status "Manual start selected. Use the commands above."
fi
