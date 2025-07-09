#!/bin/bash

# Backup script for GMeeting application
set -e

echo "💾 GMeeting Backup Utility"

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

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Cannot proceed with backup."
    exit 1
fi

# Source environment variables
source .env

# Configuration
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="gmeeting_backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Parse command line arguments
BACKUP_TYPE="full"
COMPRESS=true
CLEANUP_OLD=false
RETENTION_DAYS=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --cleanup)
            CLEANUP_OLD=true
            shift
            ;;
        --retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -h|--help)
            echo "GMeeting Backup Utility"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --type TYPE           Backup type: full, database, files (default: full)"
            echo "  --no-compress         Don't compress backup files"
            echo "  --cleanup             Remove old backups based on retention policy"
            echo "  --retention DAYS      Retention period in days (default: 30)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Backup Types:"
            echo "  full                  Complete backup (database + files + config)"
            echo "  database              Database only"
            echo "  files                 Files and configuration only"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Create backup directory
mkdir -p "$BACKUP_PATH"

print_status "Starting backup: $BACKUP_NAME"
print_status "Backup type: $BACKUP_TYPE"
print_status "Backup location: $BACKUP_PATH"

# Function to backup database
backup_database() {
    print_step "Backing up MySQL database..."
    
    # Check if MySQL container is running
    if ! docker ps | grep -q gmeeting_mysql; then
        print_warning "MySQL container is not running. Starting it..."
        docker-compose up -d mysql
        sleep 10
    fi
    
    # Create database dump
    local db_file="$BACKUP_PATH/database.sql"
    docker exec gmeeting_mysql mysqldump \
        -h"$DB_HOST" \
        -u"$DB_USER" \
        -p"$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB_NAME" > "$db_file"
    
    if [ $? -eq 0 ]; then
        print_status "✅ Database backup completed: $(du -h "$db_file" | cut -f1)"
    else
        print_error "❌ Database backup failed"
        return 1
    fi
    
    # Backup Redis data if available
    if docker ps | grep -q gmeeting_redis; then
        print_step "Backing up Redis data..."
        local redis_file="$BACKUP_PATH/redis.rdb"
        docker exec gmeeting_redis redis-cli BGSAVE
        sleep 2
        docker cp gmeeting_redis:/data/dump.rdb "$redis_file" 2>/dev/null || true
        
        if [ -f "$redis_file" ]; then
            print_status "✅ Redis backup completed: $(du -h "$redis_file" | cut -f1)"
        else
            print_warning "⚠️  Redis backup not available"
        fi
    fi
}

# Function to backup files
backup_files() {
    print_step "Backing up configuration and files..."
    
    # Backup environment file
    if [ -f .env ]; then
        cp .env "$BACKUP_PATH/"
        print_status "✅ Environment file backed up"
    fi
    
    # Backup docker-compose configuration
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml "$BACKUP_PATH/"
        print_status "✅ Docker Compose configuration backed up"
    fi
    
    # Backup any uploaded files (if exists)
    if [ -d "data/uploads" ]; then
        cp -r data/uploads "$BACKUP_PATH/"
        local uploads_size=$(du -sh "$BACKUP_PATH/uploads" | cut -f1)
        print_status "✅ Upload files backed up: $uploads_size"
    fi
    
    # Backup SSL certificates (if exists)
    if [ -d "ssl" ]; then
        cp -r ssl "$BACKUP_PATH/"
        print_status "✅ SSL certificates backed up"
    fi
    
    # Backup logs (recent logs only)
    if [ -d "logs" ]; then
        mkdir -p "$BACKUP_PATH/logs"
        find logs -name "*.log" -mtime -7 -exec cp {} "$BACKUP_PATH/logs/" \; 2>/dev/null || true
        if [ -n "$(ls -A "$BACKUP_PATH/logs" 2>/dev/null)" ]; then
            print_status "✅ Recent logs backed up"
        fi
    fi
}

# Function to create metadata
create_metadata() {
    local metadata_file="$BACKUP_PATH/backup_metadata.txt"
    
    cat > "$metadata_file" << EOF
GMeeting Backup Metadata
========================

Backup Name: $BACKUP_NAME
Backup Type: $BACKUP_TYPE
Created: $(date)
Created By: $(whoami)
Hostname: $(hostname)

System Information:
- Docker Version: $(docker --version 2>/dev/null || echo "Not available")
- Docker Compose Version: $(docker-compose --version 2>/dev/null || echo "Not available")

Application Information:
- Database Host: $DB_HOST
- Database Name: $DB_NAME
- Redis Host: $REDIS_HOST

Backup Contents:
$(ls -la "$BACKUP_PATH")

File Sizes:
$(du -sh "$BACKUP_PATH"/* 2>/dev/null | sort -hr)

Total Backup Size: $(du -sh "$BACKUP_PATH" | cut -f1)
EOF

    print_status "✅ Metadata file created"
}

# Function to compress backup
compress_backup() {
    if [ "$COMPRESS" = true ]; then
        print_step "Compressing backup..."
        
        local compressed_file="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
        tar -czf "$compressed_file" -C "$BACKUP_DIR" "$BACKUP_NAME"
        
        if [ $? -eq 0 ]; then
            local original_size=$(du -sh "$BACKUP_PATH" | cut -f1)
            local compressed_size=$(du -sh "$compressed_file" | cut -f1)
            
            print_status "✅ Backup compressed successfully"
            print_status "   Original size: $original_size"
            print_status "   Compressed size: $compressed_size"
            
            # Remove uncompressed directory
            rm -rf "$BACKUP_PATH"
            print_status "📦 Final backup: $compressed_file"
        else
            print_error "❌ Compression failed"
            return 1
        fi
    else
        print_status "📁 Backup location: $BACKUP_PATH"
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    if [ "$CLEANUP_OLD" = true ]; then
        print_step "Cleaning up old backups (older than $RETENTION_DAYS days)..."
        
        local deleted_count=0
        
        # Find and delete old backup directories
        while IFS= read -r -d '' old_backup; do
            rm -rf "$old_backup"
            deleted_count=$((deleted_count + 1))
            print_status "Deleted: $(basename "$old_backup")"
        done < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "gmeeting_backup_*" -mtime +$RETENTION_DAYS -print0 2>/dev/null)
        
        # Find and delete old compressed backups
        while IFS= read -r -d '' old_backup; do
            rm -f "$old_backup"
            deleted_count=$((deleted_count + 1))
            print_status "Deleted: $(basename "$old_backup")"
        done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "gmeeting_backup_*.tar.gz" -mtime +$RETENTION_DAYS -print0 2>/dev/null)
        
        if [ $deleted_count -eq 0 ]; then
            print_status "No old backups to clean up"
        else
            print_status "✅ Cleaned up $deleted_count old backup(s)"
        fi
    fi
}

# Main backup execution
case $BACKUP_TYPE in
    "full")
        backup_database
        backup_files
        ;;
    "database")
        backup_database
        ;;
    "files")
        backup_files
        ;;
    *)
        print_error "Unknown backup type: $BACKUP_TYPE"
        exit 1
        ;;
esac

# Create metadata and compress
create_metadata
compress_backup
cleanup_old_backups

# Final summary
echo ""
print_status "🎉 Backup completed successfully!"
print_status "Backup name: $BACKUP_NAME"
print_status "Type: $BACKUP_TYPE"

if [ "$COMPRESS" = true ]; then
    local final_file="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    if [ -f "$final_file" ]; then
        print_status "Location: $final_file"
        print_status "Size: $(du -sh "$final_file" | cut -f1)"
    fi
else
    print_status "Location: $BACKUP_PATH"
    print_status "Size: $(du -sh "$BACKUP_PATH" | cut -f1)"
fi

echo ""
print_status "💡 Restore Instructions:"
print_status "  1. Extract backup: tar -xzf ${BACKUP_NAME}.tar.gz"
print_status "  2. Restore database: mysql -u\$DB_USER -p\$DB_PASSWORD \$DB_NAME < database.sql"
print_status "  3. Copy files back to application directory"
print_status "  4. Restart services: docker-compose restart"
