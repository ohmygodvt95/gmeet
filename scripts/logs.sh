#!/bin/bash

# Logs viewer script for GMeeting application
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_service() {
    echo -e "${GREEN}[SERVICE: $1]${NC}"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Check if docker-compose is running
if ! docker-compose ps | grep -q "Up"; then
    print_error "No services are currently running. Start services first with:"
    echo "  docker-compose up -d"
    exit 1
fi

# Parse command line arguments
SERVICE=""
FOLLOW=false
TAIL_LINES=50

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            TAIL_LINES="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            echo "GMeeting Logs Viewer"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --service SERVICE   Show logs for specific service (backend, frontend, sfu, mysql, redis)"
            echo "  -f, --follow           Follow log output (like tail -f)"
            echo "  -n, --lines NUMBER     Number of lines to show (default: 50)"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Show logs for all services"
            echo "  $0 -s backend          # Show backend logs only"
            echo "  $0 -f                  # Follow all logs"
            echo "  $0 -s backend -f       # Follow backend logs"
            echo "  $0 -n 100              # Show last 100 lines"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Service name mapping
declare -A SERVICE_MAP
SERVICE_MAP["backend"]="gmeeting_backend"
SERVICE_MAP["frontend"]="gmeeting_frontend"
SERVICE_MAP["sfu"]="gmeeting_sfu"
SERVICE_MAP["mysql"]="gmeeting_mysql"
SERVICE_MAP["redis"]="gmeeting_redis"

# Function to show logs for a specific service
show_service_logs() {
    local service_name=$1
    local container_name=${SERVICE_MAP[$service_name]}
    
    if [ -z "$container_name" ]; then
        print_error "Unknown service: $service_name"
        echo "Available services: ${!SERVICE_MAP[@]}"
        return 1
    fi
    
    print_service "$service_name"
    
    if [ "$FOLLOW" = true ]; then
        docker logs -f --tail "$TAIL_LINES" "$container_name"
    else
        docker logs --tail "$TAIL_LINES" "$container_name"
    fi
}

# Function to show all logs
show_all_logs() {
    if [ "$FOLLOW" = true ]; then
        print_header "Following All Service Logs"
        print_info "Press Ctrl+C to stop"
        echo ""
        docker-compose logs -f --tail="$TAIL_LINES"
    else
        print_header "GMeeting Service Logs (Last $TAIL_LINES lines)"
        echo ""
        
        for service in "${!SERVICE_MAP[@]}"; do
            if docker ps --format "table {{.Names}}" | grep -q "${SERVICE_MAP[$service]}"; then
                print_service "$service"
                docker logs --tail 10 "${SERVICE_MAP[$service]}" 2>&1 | sed 's/^/  /'
                echo ""
            fi
        done
    fi
}

# Function to show service status
show_status() {
    print_header "Service Status"
    docker-compose ps
    echo ""
    
    print_header "Resource Usage"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Main execution
clear
print_header "GMeeting Logs Viewer"

if [ -n "$SERVICE" ]; then
    show_service_logs "$SERVICE"
else
    show_all_logs
fi

# If not following logs, show additional info
if [ "$FOLLOW" = false ]; then
    echo ""
    show_status
    
    echo ""
    print_info "💡 Tips:"
    print_info "  • Use -f to follow logs in real-time"
    print_info "  • Use -s <service> to view specific service logs"
    print_info "  • Use -n <number> to change number of lines shown"
    print_info "  • Run '$0 -h' for more options"
fi
