#!/bin/bash

# Setup Permissions for GMeeting Development
echo "🔐 Setting up permissions for GMeeting development..."
echo "=================================================="

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

# Set executable permissions for all shell scripts
print_step "Setting executable permissions for scripts..."
chmod +x *.sh 2>/dev/null || print_warning "Some shell scripts might not exist"

# Create logs directory if not exists
print_step "Creating logs directory..."
mkdir -p logs

# Set proper permissions for logs directory
print_step "Setting permissions for logs directory..."
chmod 755 logs

# Check if logs directory is writable
if [ -w logs ]; then
    print_status "✅ Logs directory is writable"
else
    print_error "❌ Logs directory is not writable"
    print_status "Trying to fix permissions..."
    chmod 775 logs
    if [ -w logs ]; then
        print_status "✅ Fixed logs directory permissions"
    else
        print_error "❌ Could not fix logs directory permissions"
        print_status "You may need to run: sudo chown -R $USER:$USER logs"
    fi
fi

# Check Node.js permissions
print_step "Checking Node.js permissions..."
if command -v node >/dev/null 2>&1; then
    node_path=$(which node)
    if [ -x "$node_path" ]; then
        print_status "✅ Node.js is executable"
    else
        print_error "❌ Node.js is not executable"
    fi
else
    print_error "❌ Node.js not found in PATH"
fi

# Check npm permissions
print_step "Checking npm permissions..."
if command -v npm >/dev/null 2>&1; then
    npm_path=$(which npm)
    if [ -x "$npm_path" ]; then
        print_status "✅ npm is executable"
    else
        print_error "❌ npm is not executable"
    fi
else
    print_error "❌ npm not found in PATH"
fi

# Check Docker permissions
print_step "Checking Docker permissions..."
if command -v docker >/dev/null 2>&1; then
    if docker ps >/dev/null 2>&1; then
        print_status "✅ Docker is accessible"
    else
        print_warning "⚠️  Docker requires sudo or user not in docker group"
        print_status "To fix: sudo usermod -aG docker $USER && newgrp docker"
    fi
else
    print_error "❌ Docker not found in PATH"
fi

# List all script permissions
print_step "Script permissions status:"
for script in *.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_status "✅ $script - executable"
        else
            print_warning "⚠️  $script - not executable"
            chmod +x "$script"
            print_status "   Fixed: $script"
        fi
    fi
done

# Check directory structure
print_step "Checking project structure..."
for dir in backend frontend sfu-server; do
    if [ -d "$dir" ]; then
        print_status "✅ $dir/ - exists"
        
        # Check package.json
        if [ -f "$dir/package.json" ]; then
            print_status "   ✅ $dir/package.json - exists"
        else
            print_warning "   ⚠️  $dir/package.json - missing"
        fi
        
        # Check node_modules
        if [ -d "$dir/node_modules" ]; then
            print_status "   ✅ $dir/node_modules/ - exists"
        else
            print_warning "   ⚠️  $dir/node_modules/ - missing (run ./install-deps.sh)"
        fi
    else
        print_error "❌ $dir/ - missing"
    fi
done

# Check .env file
print_step "Checking configuration files..."
if [ -f ".env" ]; then
    print_status "✅ .env - exists"
    if [ -r ".env" ]; then
        print_status "   ✅ .env - readable"
    else
        print_error "   ❌ .env - not readable"
    fi
else
    print_warning "⚠️  .env - missing"
    if [ -f ".env.example" ]; then
        print_status "   Creating .env from .env.example..."
        cp .env.example .env
        print_status "   ✅ Created .env file"
    else
        print_error "   ❌ .env.example also missing"
    fi
fi

# Check docker-compose files
for compose_file in docker-compose.db.yml docker-compose.yml docker-compose.prod.yml; do
    if [ -f "$compose_file" ]; then
        print_status "✅ $compose_file - exists"
    else
        print_warning "⚠️  $compose_file - missing"
    fi
done

echo ""
print_step "Permission setup completed!"
print_status "🎯 Next steps:"
print_status "   1. Run: ./install-deps.sh"
print_status "   2. Run: ./start-db.sh"
print_status "   3. Run: ./start-dev.sh"
echo ""
print_status "🔍 To check services: ./test-services.sh"
print_status "🛑 To stop development: ./stop-dev.sh"
echo ""
