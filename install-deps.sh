#!/bin/bash

# Install Dependencies for All Services
echo "📦 Installing GMeeting Dependencies"
echo "==================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check Node.js version
check_node() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install Node.js 18+"
        exit 1
    fi
    
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 18 ]; then
        print_warning "Node.js version $node_version detected. Recommended: 18+"
    else
        print_status "Node.js version: $(node --version)"
    fi
}

# Install backend dependencies
install_backend() {
    if [ -d "backend" ]; then
        print_status "Installing backend dependencies..."
        cd backend
        
        if npm install; then
            print_status "✅ Backend dependencies installed"
        else
            print_error "❌ Failed to install backend dependencies"
            cd ..
            return 1
        fi
        
        cd ..
    else
        print_error "Backend directory not found"
        return 1
    fi
}

# Install SFU dependencies
install_sfu() {
    if [ -d "sfu-server" ]; then
        print_status "Installing SFU server dependencies..."
        cd sfu-server
        
        if npm install; then
            print_status "✅ SFU server dependencies installed"
        else
            print_error "❌ Failed to install SFU server dependencies"
            cd ..
            return 1
        fi
        
        cd ..
    else
        print_error "SFU server directory not found"
        return 1
    fi
}

# Install frontend dependencies
install_frontend() {
    if [ -d "frontend" ]; then
        print_status "Installing frontend dependencies..."
        cd frontend
        
        if npm install; then
            print_status "✅ Frontend dependencies installed"
        else
            print_error "❌ Failed to install frontend dependencies"
            cd ..
            return 1
        fi
        
        cd ..
    else
        print_error "Frontend directory not found"
        return 1
    fi
}

# Main execution
main() {
    print_status "Starting dependency installation..."
    echo ""
    
    check_node
    echo ""
    
    install_backend
    echo ""
    
    install_sfu
    echo ""
    
    install_frontend
    echo ""
    
    print_status "🎉 All dependencies installed successfully!"
    echo ""
    print_status "Next steps:"
    print_status "  1. Start database: ./start-db.sh"
    print_status "  2. Follow guide:   ./quick-start.sh"
    echo ""
}

# Run main function
main "$@"
