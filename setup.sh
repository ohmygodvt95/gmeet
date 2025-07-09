#!/bin/bash

# GMeeting Setup Script
set -e

echo "🚀 GMeeting Initial Setup"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running on supported OS
check_os() {
    print_step "Checking operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_status "✅ Linux detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "✅ macOS detected"
    elif [[ "$OSTYPE" == "msys" ]]; then
        print_status "✅ Windows (Git Bash) detected"
    else
        print_warning "Unknown OS: $OSTYPE. Continuing anyway..."
    fi
}

# Check if required tools are installed
check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        print_status "✅ Docker found: $(docker --version)"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    else
        print_status "✅ Docker Compose found: $(docker-compose --version)"
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        missing_deps+=("node")
    else
        print_status "✅ Node.js found: $(node --version)"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        missing_deps+=("npm")
    else
        print_status "✅ npm found: $(npm --version)"
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    else
        print_status "✅ curl found"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    else
        print_status "✅ Git found: $(git --version)"
    fi
    
    # Report missing dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        print_error "Please install the missing dependencies and run this script again."
        echo ""
        print_status "Installation guides:"
        print_status "  Docker: https://docs.docker.com/get-docker/"
        print_status "  Docker Compose: https://docs.docker.com/compose/install/"
        print_status "  Node.js: https://nodejs.org/"
        exit 1
    fi
    
    print_status "✅ All dependencies are installed!"
}

# Check if Docker is running
check_docker_service() {
    print_step "Checking Docker service..."
    
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        echo ""
        print_status "To start Docker:"
        print_status "  • On Linux: sudo systemctl start docker"
        print_status "  • On macOS/Windows: Start Docker Desktop"
        exit 1
    fi
    
    print_status "✅ Docker is running"
}

# Setup environment file
setup_environment() {
    print_step "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_status "✅ Created .env file from .env.example"
        else
            print_warning ".env.example not found. Creating basic .env file..."
            cat > .env << EOF
# GMeeting Environment Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=sail
DB_PASSWORD=password
DB_NAME=gmeeting

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

BACKEND_PORT=3001
FRONTEND_PORT=3000
SFU_PORT=3002

FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:3001

TURN_SERVER_URL=stun:stun.l.google.com:19302

MEDIASOUP_WORKERS=4
ANNOUNCED_IP=127.0.0.1
EOF
            print_status "✅ Created basic .env file"
        fi
        
        print_warning "⚠️  Please review and update the .env file with your configuration!"
    else
        print_status "✅ .env file already exists"
    fi
}

# Install dependencies
install_dependencies() {
    print_step "Installing project dependencies..."
    
    # Backend dependencies
    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        print_status "Installing backend dependencies..."
        cd backend
        npm install
        cd ..
        print_status "✅ Backend dependencies installed"
    fi
    
    # Frontend dependencies
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        print_status "Installing frontend dependencies..."
        cd frontend
        npm install
        cd ..
        print_status "✅ Frontend dependencies installed"
    fi
    
    # SFU server dependencies
    if [ -d "sfu-server" ] && [ -f "sfu-server/package.json" ]; then
        print_status "Installing SFU server dependencies..."
        cd sfu-server
        npm install
        cd ..
        print_status "✅ SFU server dependencies installed"
    fi
}

# Setup database
setup_database() {
    print_step "Setting up database..."
    
    print_status "Starting MySQL and Redis containers..."
    docker-compose up -d mysql redis
    
    print_status "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec gmeeting_mysql mysqladmin ping -h"localhost" -u"sail" -p"password" --silent 2>/dev/null; then
            print_status "✅ Database is ready!"
            break
        fi
        
        print_status "Waiting for database... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Database failed to start within timeout"
        return 1
    fi
    
    print_status "✅ Database setup completed"
}

# Make scripts executable
setup_scripts() {
    print_step "Setting up scripts..."
    
    if [ -d "scripts" ]; then
        chmod +x scripts/*.sh
        print_status "✅ Made scripts executable"
    else
        print_warning "Scripts directory not found"
    fi
}

# Run initial build
initial_build() {
    print_step "Running initial build..."
    
    if [ -f "scripts/build.sh" ]; then
        ./scripts/build.sh
        print_status "✅ Initial build completed"
    else
        print_warning "Build script not found, skipping initial build"
    fi
}

# Run tests
run_tests() {
    print_step "Running initial tests..."
    
    if [ -f "scripts/test.sh" ]; then
        ./scripts/test.sh
        if [ $? -eq 0 ]; then
            print_status "✅ All tests passed!"
        else
            print_warning "⚠️  Some tests failed, but setup continues"
        fi
    else
        print_warning "Test script not found, skipping tests"
    fi
}

# Show final instructions
show_completion() {
    echo ""
    echo "========================================"
    echo "         SETUP COMPLETED! 🎉"
    echo "========================================"
    echo ""
    print_status "GMeeting has been set up successfully!"
    echo ""
    print_status "🚀 Quick Start Commands:"
    print_status "   Start development:  ./scripts/start-dev.sh"
    print_status "   View status:        ./scripts/status.sh"
    print_status "   View logs:          ./scripts/logs.sh"
    print_status "   Run tests:          ./scripts/test.sh"
    print_status "   Stop services:      ./scripts/stop.sh"
    echo ""
    print_status "🌐 Application URLs (after starting):"
    print_status "   Frontend:    http://localhost:3000"
    print_status "   Backend:     http://localhost:3001"
    print_status "   SFU Server:  http://localhost:3002"
    echo ""
    print_status "📚 Next Steps:"
    print_status "   1. Review and update .env file if needed"
    print_status "   2. Start the development environment"
    print_status "   3. Open http://localhost:3000 in your browser"
    print_status "   4. Create an account and start using GMeeting!"
    echo ""
    print_status "📖 Documentation:"
    print_status "   • README.md - Complete documentation"
    print_status "   • scripts/ - Available management scripts"
    print_status "   • docker-compose.yml - Service configuration"
    echo ""
    print_warning "⚠️  Important:"
    print_warning "   • Update JWT_SECRET in .env for production"
    print_warning "   • Configure ANNOUNCED_IP for external access"
    print_warning "   • Review security settings before deployment"
    echo ""
}

# Main execution
main() {
    echo ""
    print_status "Starting GMeeting setup process..."
    echo ""
    
    check_os
    check_dependencies
    check_docker_service
    setup_environment
    setup_scripts
    install_dependencies
    setup_database
    initial_build
    run_tests
    show_completion
}

# Handle script interruption
trap 'print_error "Setup interrupted. You can run this script again to continue."; exit 1' INT

# Run main function
main "$@"
