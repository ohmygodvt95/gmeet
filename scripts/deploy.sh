#!/bin/bash

# Deploy script for GMeeting application
set -e

echo "🚀 Deploying GMeeting Application..."

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

# Check if running as root in production
if [ "$EUID" -eq 0 ] && [ "$NODE_ENV" = "production" ]; then
    print_warning "Running as root in production is not recommended!"
fi

# Environment check
ENVIRONMENT=${1:-development}
print_status "Deploying to: $ENVIRONMENT"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please create it before deploying."
    exit 1
fi

# Source environment variables
source .env

# Pre-deployment checks
print_step "Running pre-deployment checks..."

# Check required environment variables
required_vars=("DB_HOST" "DB_PASSWORD" "JWT_SECRET" "REDIS_PASSWORD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable $var is not set"
        exit 1
    fi
done

# Check if ports are available
check_port() {
    local port=$1
    local service=$2
    if netstat -tuln | grep -q ":$port "; then
        print_warning "Port $port is already in use (required for $service)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

if [ "$ENVIRONMENT" = "development" ]; then
    check_port 3000 "Frontend"
    check_port 3001 "Backend"
    check_port 3002 "SFU Server"
fi

# Backup existing data (production only)
if [ "$ENVIRONMENT" = "production" ] && [ -d "data" ]; then
    print_step "Creating backup..."
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    if docker ps | grep -q mysql; then
        print_status "Backing up MySQL database..."
        docker exec gmeeting_mysql mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/database.sql"
    fi
    
    # Backup uploads/data
    if [ -d "data/uploads" ]; then
        print_status "Backing up uploads..."
        cp -r data/uploads "$BACKUP_DIR/"
    fi
    
    print_status "Backup created at: $BACKUP_DIR"
fi

# Stop existing services
print_step "Stopping existing services..."
docker-compose down || true

# Pull latest images (production only)
if [ "$ENVIRONMENT" = "production" ]; then
    print_step "Pulling latest images..."
    docker-compose pull
fi

# Build images if in development
if [ "$ENVIRONMENT" = "development" ]; then
    print_step "Building development images..."
    ./scripts/build.sh
fi

# Database initialization
print_step "Preparing database..."

# Start database services first
print_status "Starting database services..."
docker-compose up -d mysql redis

# Wait for database to be ready
print_status "Waiting for database to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec gmeeting_mysql mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; then
        print_status "Database is ready!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    print_status "Waiting for database... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_error "Database failed to start within timeout"
    exit 1
fi

# Run database migrations/initialization
print_status "Running database initialization..."
# The init.sql file is automatically executed by MySQL container

# Start all services
print_step "Starting all services..."
docker-compose up -d

# Wait for services to be ready
print_step "Verifying service health..."

check_service_health() {
    local service_name=$1
    local health_url=$2
    local max_retries=30
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -f "$health_url" >/dev/null 2>&1; then
            print_status "$service_name is healthy!"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        print_status "Checking $service_name health... ($retry_count/$max_retries)"
        sleep 2
    done
    
    print_error "$service_name failed to become healthy"
    return 1
}

# Health checks
sleep 10 # Give services time to start

if [ "$ENVIRONMENT" = "development" ]; then
    check_service_health "Backend" "http://localhost:$BACKEND_PORT/health"
    check_service_health "SFU Server" "http://localhost:$SFU_PORT/health"
    check_service_health "Frontend" "http://localhost:$FRONTEND_PORT"
fi

# Show deployment summary
print_step "Deployment Summary"
echo ""
print_status "✅ GMeeting has been deployed successfully!"
print_status "Environment: $ENVIRONMENT"
echo ""

if [ "$ENVIRONMENT" = "development" ]; then
    print_status "🌐 Application URLs:"
    print_status "   Frontend:   http://localhost:$FRONTEND_PORT"
    print_status "   Backend:    http://localhost:$BACKEND_PORT"
    print_status "   SFU Server: http://localhost:$SFU_PORT"
    echo ""
fi

print_status "📊 Service Status:"
docker-compose ps

echo ""
print_status "📝 Useful Commands:"
print_status "   View logs:        docker-compose logs -f"
print_status "   Stop services:    docker-compose down"
print_status "   Restart:          docker-compose restart"
print_status "   Service status:   ./scripts/status.sh"

if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    print_warning "🔒 Security Reminders for Production:"
    print_warning "   - Ensure firewall is properly configured"
    print_warning "   - SSL/TLS certificates are valid"
    print_warning "   - Regular security updates"
    print_warning "   - Monitor logs for suspicious activity"
fi

echo ""
print_status "🎉 Deployment completed successfully!"
