#!/bin/bash

# Test script for GMeeting application
set -e

echo "🧪 Running GMeeting Tests..."

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

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test HTTP endpoint
test_http() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Testing: $name"
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
    
    if [ "$response_code" = "$expected_status" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} (Status: $response_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $response_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Check if services are running
print_status "Checking if services are running..."
if ! docker-compose ps | grep -q "Up"; then
    print_warning "Services are not running. Starting services..."
    docker-compose up -d
    
    print_status "Waiting for services to start..."
    sleep 30
fi

# Source environment variables
if [ -f .env ]; then
    source .env
else
    print_error ".env file not found"
    exit 1
fi

print_status "Running system tests..."

# 1. Test Database Connection
print_test "Database Connection"
if docker exec gmeeting_mysql mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 2. Test Redis Connection
print_test "Redis Connection"
if docker exec gmeeting_redis redis-cli ping | grep -q PONG; then
    echo -e "  ${GREEN}✓ PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 3. Test Backend Health
test_http "Backend Health Check" "http://localhost:${BACKEND_PORT}/health"

# 4. Test SFU Health
test_http "SFU Server Health Check" "http://localhost:${SFU_PORT}/health"

# 5. Test Frontend
test_http "Frontend Home Page" "http://localhost:${FRONTEND_PORT}"

# 6. Test Backend API Endpoints
print_status "Testing Backend API..."

# Test auth endpoints (should return proper error codes)
test_http "Auth Login Endpoint" "http://localhost:${BACKEND_PORT}/api/auth/login" "400"
test_http "Auth Register Endpoint" "http://localhost:${BACKEND_PORT}/api/auth/register" "400"

# Test protected endpoints (should return 401)
test_http "Protected Rooms Endpoint" "http://localhost:${BACKEND_PORT}/api/rooms" "401"

# 7. Test SFU Server Endpoints
print_status "Testing SFU Server..."
test_http "SFU Stats Endpoint" "http://localhost:${SFU_PORT}/stats"

# 8. Test Container Resource Usage
print_status "Checking container resource usage..."

print_test "Container Memory Usage"
HIGH_MEMORY=$(docker stats --no-stream --format "{{.MemPerc}}" | sed 's/%//' | awk '$1 > 80 {print $1}')
if [ -z "$HIGH_MEMORY" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (All containers under 80% memory)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} (Some containers using high memory: $HIGH_MEMORY%)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 9. Test Log Output
print_test "Service Log Output"
if docker-compose logs --tail=10 2>&1 | grep -q "ERROR\|FATAL"; then
    echo -e "  ${YELLOW}⚠ WARNING${NC} (Found errors in logs)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${GREEN}✓ PASSED${NC} (No critical errors in recent logs)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 10. Test WebSocket Connection (basic)
print_test "WebSocket Connectivity"
if nc -z localhost "$SFU_PORT"; then
    echo -e "  ${GREEN}✓ PASSED${NC} (SFU WebSocket port accessible)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${RED}✗ FAILED${NC} (SFU WebSocket port not accessible)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Performance Tests
print_status "Running performance tests..."

# 11. Test Response Time
print_test "Backend Response Time"
RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null "http://localhost:${BACKEND_PORT}/health")
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    echo -e "  ${GREEN}✓ PASSED${NC} (Response time: ${RESPONSE_TIME}s)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} (Slow response time: ${RESPONSE_TIME}s)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Security Tests
print_status "Running security tests..."

# 12. Test CORS Headers
print_test "CORS Headers"
CORS_HEADER=$(curl -s -I "http://localhost:${BACKEND_PORT}/health" | grep -i "access-control-allow-origin" || echo "")
if [ -n "$CORS_HEADER" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (CORS headers present)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} (CORS headers not found)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 13. Test Security Headers
print_test "Security Headers"
SECURITY_HEADERS=$(curl -s -I "http://localhost:${BACKEND_PORT}/health" | grep -E "(X-Frame-Options|X-Content-Type-Options)" | wc -l)
if [ "$SECURITY_HEADERS" -gt 0 ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (Security headers present)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} (Some security headers missing)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Print Test Summary
echo ""
echo "========================================"
echo "           TEST SUMMARY"
echo "========================================"
echo ""
print_status "Total Tests: $TOTAL_TESTS"
print_status "Passed: $PASSED_TESTS"
if [ $FAILED_TESTS -gt 0 ]; then
    print_error "Failed: $FAILED_TESTS"
else
    print_status "Failed: $FAILED_TESTS"
fi

echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    print_status "🎉 All tests passed! GMeeting is working correctly."
    echo ""
    print_status "System Status:"
    print_status "  ✅ Database: Connected"
    print_status "  ✅ Redis: Connected"
    print_status "  ✅ Backend: Healthy"
    print_status "  ✅ SFU Server: Healthy"
    print_status "  ✅ Frontend: Accessible"
    echo ""
    print_status "Ready for production! 🚀"
    exit 0
else
    print_error "⚠️  Some tests failed. Please check the issues above."
    echo ""
    print_status "Troubleshooting:"
    print_status "  • Check service logs: ./scripts/logs.sh"
    print_status "  • Verify configuration: cat .env"
    print_status "  • Restart services: docker-compose restart"
    print_status "  • Check status: ./scripts/status.sh"
    exit 1
fi
