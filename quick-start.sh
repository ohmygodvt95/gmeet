#!/bin/bash

# GMeeting Development Quick Start Guide
echo "🎯 GMeeting Development Quick Start"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_title() {
    echo -e "${CYAN}$1${NC}"
}

print_title "🌟 Welcome to GMeeting Development!"
echo ""
print_status "This Google Meet clone uses SFU architecture for optimal performance."
print_status "Tech stack: Nuxt.js, Node.js, MediaSoup, MySQL, Redis, Docker"
echo ""

print_title "📋 Available Scripts:"
echo ""
print_step "Environment & Setup:"
echo "   ./health-check.sh        - Comprehensive environment check"
echo "   ./setup-permissions.sh   - Fix file permissions"
echo "   ./install-deps.sh        - Install all dependencies"
echo ""
print_step "Database Management:"
echo "   ./start-db.sh            - Start MySQL + Redis (Docker)"
echo "   ./stop-db.sh             - Stop database containers"
echo ""
print_step "Development:"
echo "   ./start-dev.sh           - Interactive development setup"
echo "   ./start-dev-manual.sh    - Manual development guide"
echo "   ./stop-dev.sh            - Stop all development services"
echo ""
print_step "Monitoring:"
echo "   ./test-services.sh       - Check all service status"
echo ""

print_title "🚀 Quick Start Options:"
echo ""

PS3="Please select an option: "
options=(
    "🏥 Health Check (Recommended first time)"
    "⚡ Quick Setup (Database + Dependencies)"
    "🔧 Full Setup (Health + Permissions + Database + Dev)"
    "📖 Manual Instructions"
    "❌ Exit"
)

select opt in "${options[@]}"
do
    case $opt in
        "🏥 Health Check (Recommended first time)")
            print_status "Running comprehensive health check..."
            if [ -f "health-check.sh" ]; then
                chmod +x health-check.sh
                ./health-check.sh
            else
                print_error "health-check.sh not found"
            fi
            break
            ;;
        "⚡ Quick Setup (Database + Dependencies)")
            print_status "Quick setup: starting database and installing dependencies..."
            chmod +x *.sh 2>/dev/null
            
            print_step "Starting database..."
            if [ -f "start-db.sh" ]; then
                ./start-db.sh
            fi
            
            print_step "Installing dependencies..."
            if [ -f "install-deps.sh" ]; then
                ./install-deps.sh
            fi
            
            print_step "Testing services..."
            if [ -f "test-services.sh" ]; then
                ./test-services.sh
            fi
            
            print_status "✅ Quick setup complete! Now run: ./start-dev.sh"
            break
            ;;
        "🔧 Full Setup (Health + Permissions + Database + Dev)")
            print_status "Full setup: comprehensive environment preparation..."
            chmod +x *.sh 2>/dev/null
            
            print_step "Health check..."
            if [ -f "health-check.sh" ]; then
                ./health-check.sh
            fi
            
            echo ""
            read -p "Continue with full setup? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                print_status "Setup cancelled."
                break
            fi
            
            print_step "Setting up permissions..."
            if [ -f "setup-permissions.sh" ]; then
                ./setup-permissions.sh
            fi
            
            print_step "Starting database..."
            if [ -f "start-db.sh" ]; then
                ./start-db.sh
            fi
            
            print_step "Installing dependencies..."
            if [ -f "install-deps.sh" ]; then
                ./install-deps.sh
            fi
            
            print_step "Starting development..."
            if [ -f "start-dev.sh" ]; then
                ./start-dev.sh
            fi
            break
            ;;
        "📖 Manual Instructions")
            print_title "📖 Manual Development Setup:"
            echo ""
            print_step "1. Health Check (Optional but recommended):"
            echo "   ./health-check.sh"
            echo ""
            print_step "2. Fix Permissions (If needed):"
            echo "   ./setup-permissions.sh"
            echo ""
            print_step "3. Start Database:"
            echo "   ./start-db.sh"
            echo ""
            print_step "4. Install Dependencies:"
            echo "   ./install-deps.sh"
            echo ""
            print_step "5. Start Development (Choose one):"
            echo "   ./start-dev.sh           # Interactive guide"
            echo "   ./start-dev-manual.sh    # Manual with auto option"
            echo ""
            print_step "6. Manual Development (3 separate terminals):"
            echo "   Terminal 1: cd backend && npm run dev"
            echo "   Terminal 2: cd sfu-server && npm run dev"
            echo "   Terminal 3: cd frontend && npm run dev"
            echo ""
            print_step "7. Access Application:"
            echo "   Frontend:  http://localhost:3000"
            echo "   Backend:   http://localhost:3001"
            echo "   SFU:       http://localhost:3002"
            echo ""
            print_step "8. Monitoring:"
            echo "   ./test-services.sh       # Check status"
            echo "   ./stop-dev.sh           # Stop services"
            echo "   ./stop-db.sh            # Stop database"
            echo ""
            print_title "🎯 Pro Tips:"
            echo "• Always start database first: ./start-db.sh"
            echo "• Use health-check.sh to diagnose issues"
            echo "• Check service status: ./test-services.sh"
            echo "• View logs: tail -f logs/backend.log"
            echo "• Reset environment: ./stop-dev.sh && ./stop-db.sh"
            break
            ;;
        "❌ Exit")
            print_status "👋 Happy coding! Remember to read README.md for detailed info."
            break
            ;;
        *) 
            print_error "Invalid option. Please try again."
            ;;
    esac
done

echo ""
print_title "📚 Additional Resources:"
echo "• README.md - Comprehensive documentation"
echo "• .env - Environment configuration"
echo "• Architecture documentation in README.md"
echo ""
print_status "🆘 Need help? Check README.md or run ./health-check.sh"
echo ""

# Check npm
if command -v npm &> /dev/null; then
    echo "✅ npm: $(npm --version)"
else
    echo "❌ npm not found"
    exit 1
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✅ Docker: $(docker --version)"
else
    echo "❌ Docker not found"
    exit 1
fi

echo ""
echo "🗄️ Step 1: Start Database"
echo "========================="
echo "Run this command:"
echo "  ./start-db.sh"
echo ""

if docker ps | grep -q "gmeeting_mysql"; then
    echo "✅ MySQL is running"
else
    echo "❌ MySQL not running. Please run: ./start-db.sh"
fi

if docker ps | grep -q "gmeeting_redis"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis not running. Please run: ./start-db.sh"
fi

echo ""
echo "🔧 Step 2: Install Dependencies"
echo "==============================="

# Check backend deps
if [ -d "backend/node_modules" ]; then
    echo "✅ Backend dependencies installed"
else
    echo "❌ Backend dependencies missing. Run:"
    echo "     cd backend && npm install"
fi

# Check SFU deps
if [ -d "sfu-server/node_modules" ]; then
    echo "✅ SFU dependencies installed"
else
    echo "❌ SFU dependencies missing. Run:"
    echo "     cd sfu-server && npm install"
fi

# Check frontend deps
if [ -d "frontend/node_modules" ]; then
    echo "✅ Frontend dependencies installed"
else
    echo "❌ Frontend dependencies missing. Run:"
    echo "     cd frontend && npm install"
fi

echo ""
echo "🚀 Step 3: Start Development Servers"
echo "===================================="
echo ""
echo "Open 3 separate terminals and run:"
echo ""
echo "📱 Terminal 1 - Backend:"
echo "   cd backend && npm run dev"
echo "   URL: http://localhost:3001"
echo ""
echo "🎬 Terminal 2 - SFU Server:"
echo "   cd sfu-server && npm run dev"
echo "   URL: http://localhost:3002"
echo ""
echo "🌐 Terminal 3 - Frontend:"
echo "   cd frontend && npm run dev"
echo "   URL: http://localhost:3000"
echo ""
echo "🎯 Step 4: Test Application"
echo "=========================="
echo "1. Open http://localhost:3000"
echo "2. Register a new account"
echo "3. Create a room"
echo "4. Test video calling"
echo ""
echo "🛠️ Useful Commands:"
echo "=================="
echo "  Database only:    ./start-db.sh"
echo "  Stop database:    ./stop-db.sh"
echo "  View DB logs:     docker-compose -f docker-compose.db.yml logs -f"
echo "  Test app:         ./test-app.sh"
echo ""
echo "📚 Troubleshooting:"
echo "=================="
echo "  • Check logs in each terminal"
echo "  • Ensure all ports (3000, 3001, 3002, 3306, 6379) are free"
echo "  • Restart database if connection issues"
echo "  • Check .env file configuration"
echo ""
