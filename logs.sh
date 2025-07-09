#!/bin/bash

# GMeeting Logs Viewer Script
echo "📝 GMeeting Development Logs"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

show_usage() {
    echo "Usage: $0 [OPTIONS] [SERVICE]"
    echo ""
    echo "Services:"
    echo "  backend    - Backend server logs"
    echo "  frontend   - Frontend server logs"
    echo "  sfu        - SFU server logs"
    echo "  mysql      - MySQL database logs"
    echo "  redis      - Redis logs"
    echo ""
    echo "Options:"
    echo "  -f, --follow    Follow log output (like tail -f)"
    echo "  -n, --lines N   Show last N lines (default: 50)"
    echo "  -l, --list      List available log files"
    echo "  -c, --clear     Clear log files"
    echo "  -a, --all       Show all logs together"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 backend              # Show backend logs"
    echo "  $0 -f frontend          # Follow frontend logs"
    echo "  $0 -n 100 sfu          # Show last 100 lines of SFU logs"
    echo "  $0 -a                   # Show all logs"
    echo "  $0 --clear backend      # Clear backend logs"
}

list_logs() {
    echo "📂 Available log files:"
    echo ""
    
    # Node.js service logs
    for service in backend frontend sfu; do
        if [ -f "logs/${service}.log" ]; then
            size=$(du -h "logs/${service}.log" 2>/dev/null | cut -f1)
            lines=$(wc -l < "logs/${service}.log" 2>/dev/null)
            echo "  ${service}.log - $size ($lines lines)"
        else
            echo "  ${service}.log - Not found"
        fi
    done
    
    echo ""
    echo "🐳 Docker container logs:"
    if command -v docker >/dev/null 2>&1; then
        if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "gmeeting_mysql"; then
            echo "  MySQL  - docker logs gmeeting_mysql"
        else
            echo "  MySQL  - Container not running"
        fi
        
        if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "gmeeting_redis"; then
            echo "  Redis  - docker logs gmeeting_redis"
        else
            echo "  Redis  - Container not running"
        fi
    else
        echo "  Docker not available"
    fi
}

clear_logs() {
    local service=$1
    
    if [ "$service" = "all" ]; then
        print_status "Clearing all log files..."
        rm -f logs/*.log
        rm -f logs/*.pid
        print_status "All logs cleared"
    elif [ -n "$service" ]; then
        if [ -f "logs/${service}.log" ]; then
            print_status "Clearing ${service} logs..."
            true > "logs/${service}.log"
            print_status "${service} logs cleared"
        else
            print_error "Log file logs/${service}.log not found"
        fi
    else
        print_error "Please specify a service or 'all'"
    fi
}

show_docker_logs() {
    local service=$1
    local follow=$2
    local lines=$3
    
    local container_name=""
    case $service in
        mysql)
            container_name="gmeeting_mysql"
            ;;
        redis)
            container_name="gmeeting_redis"
            ;;
        *)
            print_error "Unknown Docker service: $service"
            return 1
            ;;
    esac
    
    if ! docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "$container_name"; then
        print_error "$service container is not running"
        return 1
    fi
    
    echo "📋 $service logs:"
    echo "================"
    
    if [ "$follow" = true ]; then
        docker logs -f --tail "$lines" "$container_name"
    else
        docker logs --tail "$lines" "$container_name"
    fi
}

show_service_logs() {
    local service=$1
    local follow=$2
    local lines=$3
    
    local log_file="logs/${service}.log"
    
    if [ ! -f "$log_file" ]; then
        print_error "Log file $log_file not found"
        print_status "Service might not be running or hasn't generated logs yet"
        return 1
    fi
    
    echo "📋 $service logs:"
    echo "================"
    
    if [ "$follow" = true ]; then
        tail -f -n "$lines" "$log_file"
    else
        tail -n "$lines" "$log_file"
    fi
}

show_all_logs() {
    local follow=$1
    local lines=$2
    
    echo "📋 All Service Logs:"
    echo "==================="
    
    for service in backend frontend sfu; do
        if [ -f "logs/${service}.log" ]; then
            echo ""
            echo "--- $service ---"
            tail -n "$lines" "logs/${service}.log"
        fi
    done
    
    if [ "$follow" = true ]; then
        echo ""
        print_status "Following all logs (Ctrl+C to stop)..."
        tail -f logs/*.log 2>/dev/null
    fi
}

# Default values
FOLLOW=false
LINES=50
SERVICE=""
ACTION="show"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -c|--clear)
            ACTION="clear"
            shift
            ;;
        -a|--all)
            SERVICE="all"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

# Execute action
case $ACTION in
    list)
        list_logs
        ;;
    clear)
        clear_logs "$SERVICE"
        ;;
    show)
        if [ -z "$SERVICE" ]; then
            print_error "Please specify a service"
            echo ""
            show_usage
            exit 1
        fi
        
        case $SERVICE in
            all)
                show_all_logs "$FOLLOW" "$LINES"
                ;;
            mysql|redis)
                show_docker_logs "$SERVICE" "$FOLLOW" "$LINES"
                ;;
            backend|frontend|sfu)
                show_service_logs "$SERVICE" "$FOLLOW" "$LINES"
                ;;
            *)
                print_error "Unknown service: $SERVICE"
                echo ""
                show_usage
                exit 1
                ;;
        esac
        ;;
esac
