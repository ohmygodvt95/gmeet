#!/bin/bash

# Simple Development Start Script
echo "🚀 GMeeting Development Setup"
echo "============================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if we're in the right directory
if [ ! -f ".env" ]; then
    print_error "Not in GMeeting root directory. Please cd to the project root."
    exit 1
fi

# Option to run health check first
read -p "🏥 Do you want to run health check first? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "health-check.sh" ]; then
        chmod +x health-check.sh
        ./health-check.sh
        echo ""
        read -p "Continue with setup? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_status "Setup cancelled. Fix issues and try again."
            exit 0
        fi
    else
        print_warning "health-check.sh not found, skipping..."
    fi
fi

# Step 0: Setup Permissions
echo ""
print_step "Step 0: Setting up Permissions"
echo "=============================="

if [ -f "setup-permissions.sh" ]; then
    chmod +x setup-permissions.sh
    ./setup-permissions.sh
else
    print_warning "setup-permissions.sh not found, setting basic permissions..."
    chmod +x *.sh 2>/dev/null
    mkdir -p logs
fi

# Step 1: Start Database
echo ""
print_step "Step 1: Starting Database Services"
echo "=================================="

if ! docker ps | grep -q "gmeeting_mysql"; then
    print_status "Starting database containers..."
    if [ -f "start-db.sh" ]; then
        ./start-db.sh
    else
        docker-compose -f docker-compose.db.yml up -d
        sleep 10
    fi
else
    print_status "✅ Database already running"
fi

# Step 2: Install Dependencies
echo ""
print_status "Step 2: Installing Dependencies"
echo "==============================="

install_if_needed() {
    local dir=$1
    local name=$2
    local script_dir
    script_dir=$(pwd)
    
    if [ -d "$script_dir/$dir" ] && [ -f "$script_dir/$dir/package.json" ]; then
        if [ ! -d "$script_dir/$dir/node_modules" ]; then
            print_status "Installing $name dependencies..."
            (cd "$script_dir/$dir" && npm install)
            print_status "✅ $name dependencies installed"
        else
            print_status "✅ $name dependencies already installed"
        fi
    else
        print_warning "⚠️  $name directory or package.json not found"
    fi
}

install_if_needed "backend" "Backend"
install_if_needed "sfu-server" "SFU Server"
install_if_needed "frontend" "Frontend"

# Step 3: Start Development Servers
echo ""
print_step "Step 3: Start Development Servers"
echo "================================="
echo ""

# Option for manual or automatic
read -p "🤔 How would you like to start the development servers? (manual/auto/guided): " -n 1 -r
echo
case $REPLY in
    [Aa]* )
        print_status "Starting all services automatically..."
        if [ -f "start-dev-manual.sh" ]; then
            ./start-dev-manual.sh
        else
            print_error "start-dev-manual.sh not found"
        fi
        ;;
    [Gg]* )
        print_status "Starting guided manual setup..."
        if [ -f "start-dev-manual.sh" ]; then
            ./start-dev-manual.sh
        else
            print_error "start-dev-manual.sh not found"
        fi
        ;;
    * )
        print_status "📋 Manual setup - Open 3 separate terminals and run:"
        echo ""
        print_status "🔧 Terminal 1 - Backend:"
        echo "   cd backend && npm run dev"
        echo ""
        print_status "🎬 Terminal 2 - SFU Server:"
        echo "   cd sfu-server && npm run dev"
        echo ""
        print_status "🌐 Terminal 3 - Frontend:"
        echo "   cd frontend && npm run dev"
        echo ""
        print_status "🌍 Access URLs:"
        echo "   Frontend:  http://localhost:3000"
        echo "   Backend:   http://localhost:3001"
        echo "   SFU:       http://localhost:3002"
        echo ""
        print_status "🔍 To test services: ./test-services.sh"
        print_status "🛑 To stop all: ./stop-dev.sh"
        ;;
esac
print_status "📊 Database URLs:"
echo "   MySQL:     localhost:3306"
echo "   Redis:     localhost:6379"
echo ""
print_status "🛑 To stop:"
echo "   Ctrl+C in each terminal"
echo "   ./stop-db.sh (to stop database)"
echo ""

# Option to start one service at a time
echo "💡 Quick start options:"
echo "   1. Start Backend only"
echo "   2. Start SFU only" 
echo "   3. Start Frontend only"
echo "   4. Manual (show commands only)"
echo ""

read -p "Choose option (1-4) or Enter to continue: " choice

case $choice in
    1)
        print_status "Starting Backend..."
        cd backend && npm run dev
        ;;
    2)
        print_status "Starting SFU Server..."
        cd sfu-server && npm run dev
        ;;
    3)
        print_status "Starting Frontend..."
        cd frontend && npm run dev
        ;;
    *)
        print_status "Manual mode selected. Use the commands above."
        ;;
esac
