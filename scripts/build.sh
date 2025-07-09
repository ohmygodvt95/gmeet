#!/bin/bash

# Build script for GMeeting application
set -e

echo "🚀 Building GMeeting Application..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose could not be found. Please install docker-compose."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_status ".env file created. Please review and update the configuration."
    else
        print_error ".env.example file not found. Please create .env file manually."
        exit 1
    fi
fi

# Build images
print_status "Building Docker images..."

# Build backend
print_status "Building backend image..."
docker build -t gmeeting-backend ./backend

# Build SFU server
print_status "Building SFU server image..."
docker build -t gmeeting-sfu ./sfu-server

# Build frontend
print_status "Building frontend..."
cd frontend
if [ ! -d node_modules ]; then
    print_status "Installing frontend dependencies..."
    npm install
fi

print_status "Building frontend production bundle..."
npm run build
cd ..

# Tag images with version
VERSION=$(date +%Y%m%d-%H%M%S)
print_status "Tagging images with version: $VERSION"

docker tag gmeeting-backend gmeeting-backend:$VERSION
docker tag gmeeting-sfu gmeeting-sfu:$VERSION

docker tag gmeeting-backend gmeeting-backend:latest
docker tag gmeeting-sfu gmeeting-sfu:latest

print_status "✅ Build completed successfully!"
print_status "Images built:"
print_status "  - gmeeting-backend:latest"
print_status "  - gmeeting-sfu:latest"
print_status "  - Tagged with version: $VERSION"

echo ""
print_status "🚀 Ready to deploy! Use 'docker-compose up -d' to start the application."
