#!/bin/bash

# Test GMeeting Application
echo "🧪 Testing GMeeting Application"
echo "==============================="

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

# Test function
test_service() {
    local name=$1
    local url=$2
    local timeout=${3:-5}
    
    echo -n "🔍 Testing $name... "
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

# Test database connection
test_database() {
    echo -n "🔍 Testing MySQL... "
    if docker exec gmeeting_mysql mysqladmin ping -h"localhost" --silent 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

test_redis() {
    echo -n "🔍 Testing Redis... "
    if docker exec gmeeting_redis redis-cli auth redis123 ping 2>/dev/null | grep -q PONG; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

# Main test execution
main() {
    print_status "Starting application tests..."
    echo ""
    
    local failed_tests=0
    
    # Test database services
    print_status "📊 Testing Database Services"
    test_database || ((failed_tests++))
    test_redis || ((failed_tests++))
    
    echo ""
    
    # Test application services
    print_status "🌐 Testing Application Services"
    test_service "Backend API" "http://localhost:3001/health" || ((failed_tests++))
    test_service "SFU Server" "http://localhost:3002/health" || ((failed_tests++))
    test_service "Frontend" "http://localhost:3000" || ((failed_tests++))
    
    echo ""
    
    # Test API endpoints
    print_status "🔧 Testing API Endpoints"
    test_service "Auth endpoint" "http://localhost:3001/api/auth/login" || ((failed_tests++))
    test_service "Rooms endpoint" "http://localhost:3001/api/rooms" || ((failed_tests++))
    
    echo ""
    
    # Results
    if [ $failed_tests -eq 0 ]; then
        print_status "🎉 All tests passed!"
        echo ""
        print_status "✅ Application is ready to use:"
        print_status "   Frontend:  http://localhost:3000"
        print_status "   Backend:   http://localhost:3001"
        print_status "   SFU:       http://localhost:3002"
        echo ""
        print_status "👤 Default admin account:"
        print_status "   Email:     admin@gmeeting.com"
        print_status "   Password:  admin123"
    else
        print_error "❌ $failed_tests test(s) failed"
        echo ""
        print_warning "🔧 Troubleshooting:"
        print_warning "   1. Check if all services are running:"
        print_warning "      ps aux | grep node"
        print_warning "      docker ps"
        print_warning "   2. Check service logs:"
        print_warning "      tail -f logs/backend.log"
        print_warning "      tail -f logs/sfu.log"
        print_warning "      tail -f logs/frontend.log"
        print_warning "   3. Restart services:"
        print_warning "      ./stop-dev.sh && ./start-dev.sh"
        echo ""
        return 1
    fi
}

# Run tests
main "$@"
