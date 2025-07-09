#!/bin/bash

# Environment Health Check for GMeeting Development
echo "🏥 GMeeting Development Environment Health Check"
echo "=============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

ERRORS=0
WARNINGS=0

# Function to increment error count
add_error() {
    ERRORS=$((ERRORS + 1))
}

# Function to increment warning count
add_warning() {
    WARNINGS=$((WARNINGS + 1))
}

print_step "System Requirements"
echo "=================="

# Check Node.js
print_step "Node.js version..."
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version)
    node_major=$(echo "$node_version" | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_major" -ge 18 ]; then
        print_status "Node.js $node_version (>= 18 required)"
    else
        print_error "Node.js $node_version (>= 18 required)"
        add_error
    fi
else
    print_error "Node.js not found"
    add_error
fi

# Check npm
print_step "npm version..."
if command -v npm >/dev/null 2>&1; then
    npm_version=$(npm --version)
    print_status "npm $npm_version"
else
    print_error "npm not found"
    add_error
fi

# Check Docker
print_step "Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker --version >/dev/null 2>&1; then
        docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_status "Docker $docker_version"
        
        # Check Docker daemon
        if docker ps >/dev/null 2>&1; then
            print_status "Docker daemon is running"
        else
            print_error "Docker daemon not accessible (try: sudo usermod -aG docker $USER)"
            add_error
        fi
    else
        print_error "Docker not working properly"
        add_error
    fi
else
    print_error "Docker not found"
    add_error
fi

# Check Docker Compose
print_step "Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    compose_version=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
    print_status "Docker Compose $compose_version"
elif docker compose version >/dev/null 2>&1; then
    compose_version=$(docker compose version --short)
    print_status "Docker Compose $compose_version (plugin)"
else
    print_error "Docker Compose not found"
    add_error
fi

echo ""
print_step "Project Structure"
echo "================"

# Check project directories
for dir in backend frontend sfu-server; do
    print_step "$dir directory..."
    if [ -d "$dir" ]; then
        print_status "$dir/ exists"
        
        # Check package.json
        if [ -f "$dir/package.json" ]; then
            print_status "$dir/package.json exists"
        else
            print_error "$dir/package.json missing"
            add_error
        fi
        
        # Check node_modules
        if [ -d "$dir/node_modules" ]; then
            print_status "$dir/node_modules/ exists"
        else
            print_warning "$dir/node_modules/ missing (run ./install-deps.sh)"
            add_warning
        fi
    else
        print_error "$dir/ directory missing"
        add_error
    fi
done

echo ""
print_step "Configuration Files"
echo "=================="

# Check .env
print_step ".env file..."
if [ -f ".env" ]; then
    print_status ".env exists"
    
    # Check key variables
    if grep -q "DB_HOST" .env && grep -q "REDIS_HOST" .env; then
        print_status ".env contains database configuration"
    else
        print_warning ".env missing database configuration"
        add_warning
    fi
else
    if [ -f ".env.example" ]; then
        print_warning ".env missing (but .env.example exists)"
        add_warning
    else
        print_error ".env and .env.example both missing"
        add_error
    fi
fi

# Check docker-compose files
for compose_file in docker-compose.db.yml docker-compose.yml; do
    print_step "$compose_file..."
    if [ -f "$compose_file" ]; then
        print_status "$compose_file exists"
    else
        print_error "$compose_file missing"
        add_error
    fi
done

echo ""
print_step "Scripts"
echo "======"

# Check scripts
for script in start-db.sh stop-db.sh start-dev.sh stop-dev.sh install-deps.sh test-services.sh; do
    print_step "$script..."
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_status "$script exists and executable"
        else
            print_warning "$script exists but not executable"
            add_warning
        fi
    else
        print_error "$script missing"
        add_error
    fi
done

echo ""
print_step "Database Services"
echo "================"

# Check if database containers are running
print_step "MySQL container..."
if docker ps | grep -q "gmeeting_mysql"; then
    print_status "MySQL container is running"
else
    print_warning "MySQL container not running (run ./start-db.sh)"
    add_warning
fi

print_step "Redis container..."
if docker ps | grep -q "gmeeting_redis"; then
    print_status "Redis container is running"
else
    print_warning "Redis container not running (run ./start-db.sh)"
    add_warning
fi

echo ""
print_step "Development Services"
echo "=================="

# Check if development services are running
print_step "Backend service..."
if curl -s http://localhost:3001/health >/dev/null 2>&1; then
    print_status "Backend is running (http://localhost:3001)"
else
    print_warning "Backend not running"
    add_warning
fi

print_step "SFU server..."
if curl -s http://localhost:3002/health >/dev/null 2>&1; then
    print_status "SFU server is running (http://localhost:3002)"
else
    print_warning "SFU server not running"
    add_warning
fi

print_step "Frontend..."
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    print_status "Frontend is running (http://localhost:3000)"
else
    print_warning "Frontend not running"
    add_warning
fi

echo ""
print_step "Port Availability"
echo "================"

# Check ports
for port in 3000 3001 3002 3306 6379; do
    print_step "Port $port..."
    if netstat -tln 2>/dev/null | grep -q ":$port "; then
        print_status "Port $port is in use"
    elif ss -tln 2>/dev/null | grep -q ":$port "; then
        print_status "Port $port is in use"
    else
        print_warning "Port $port is available"
        add_warning
    fi
done

echo ""
echo "=============================================="
print_step "Health Check Summary"
echo "=============================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_status "🎉 Perfect! Environment is ready for development"
elif [ $ERRORS -eq 0 ]; then
    print_warning "⚠️  Environment is mostly ready ($WARNINGS warnings)"
    print_warning "Consider fixing warnings for optimal experience"
else
    print_error "❌ Environment has issues ($ERRORS errors, $WARNINGS warnings)"
    print_error "Please fix errors before starting development"
fi

echo ""
print_step "Recommended Actions:"

if [ $ERRORS -gt 0 ]; then
    echo "🔧 Fix critical issues first:"
    echo "   - Install missing requirements (Node.js, Docker, etc.)"
    echo "   - Create missing configuration files"
    echo "   - Fix file permissions"
fi

if [ $WARNINGS -gt 0 ]; then
    echo "📝 Then address warnings:"
    echo "   - Run: ./install-deps.sh"
    echo "   - Run: ./start-db.sh"
    echo "   - Run: ./start-dev.sh"
fi

echo ""
echo "📚 Quick commands:"
echo "   ./setup-permissions.sh  # Fix permissions"
echo "   ./install-deps.sh       # Install dependencies"
echo "   ./start-db.sh           # Start databases"
echo "   ./test-services.sh      # Test all services"
echo "   ./start-dev.sh          # Start development"
echo ""

exit $ERRORS
