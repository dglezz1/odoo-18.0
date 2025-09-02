#!/bin/bash
set -e

# ===========================================
# ODOO PRODUCTION BACKUP SCRIPT
# ===========================================

BACKUP_DIR="/opt/odoo-backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

create_backup_dir() {
    mkdir -p "$BACKUP_DIR/$DATE"
    if [ $? -ne 0 ]; then
        error "Failed to create backup directory"
    fi
}

backup_database() {
    log "Backing up PostgreSQL database..."
    
    docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump \
        -U odoo_prod \
        -h localhost \
        --verbose \
        --clean \
        --no-owner \
        --no-privileges \
        odoo_prod > "$BACKUP_DIR/$DATE/database.sql"
    
    if [ $? -eq 0 ]; then
        success "Database backup completed"
        
        # Compress database backup
        gzip "$BACKUP_DIR/$DATE/database.sql"
        success "Database backup compressed"
    else
        error "Database backup failed"
    fi
}

backup_filestore() {
    log "Backing up Odoo filestore..."
    
    docker run --rm \
        -v odoo-180_odoo_data:/data:ro \
        -v "$BACKUP_DIR/$DATE":/backup \
        alpine tar czf /backup/filestore.tar.gz -C /data .
    
    if [ $? -eq 0 ]; then
        success "Filestore backup completed"
    else
        error "Filestore backup failed"
    fi
}

backup_config() {
    log "Backing up configuration files..."
    
    tar czf "$BACKUP_DIR/$DATE/config.tar.gz" \
        config/ \
        nginx/ \
        postgresql.conf \
        docker-compose.prod.yml \
        .env.prod
    
    if [ $? -eq 0 ]; then
        success "Configuration backup completed"
    else
        warning "Configuration backup failed"
    fi
}

create_manifest() {
    log "Creating backup manifest..."
    
    cat > "$BACKUP_DIR/$DATE/manifest.json" << EOF
{
    "backup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "backup_type": "full",
    "odoo_version": "18.0",
    "files": {
        "database": "database.sql.gz",
        "filestore": "filestore.tar.gz",
        "config": "config.tar.gz"
    },
    "sizes": {
        "database_mb": $(du -m "$BACKUP_DIR/$DATE/database.sql.gz" | cut -f1),
        "filestore_mb": $(du -m "$BACKUP_DIR/$DATE/filestore.tar.gz" | cut -f1),
        "config_mb": $(du -m "$BACKUP_DIR/$DATE/config.tar.gz" | cut -f1)
    }
}
EOF
    
    success "Backup manifest created"
}

cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_DIR" -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
    
    success "Old backups cleaned up"
}

verify_backup() {
    log "Verifying backup integrity..."
    
    # Verify database backup
    if gzip -t "$BACKUP_DIR/$DATE/database.sql.gz"; then
        success "Database backup verification passed"
    else
        error "Database backup verification failed"
    fi
    
    # Verify filestore backup
    if tar -tzf "$BACKUP_DIR/$DATE/filestore.tar.gz" > /dev/null; then
        success "Filestore backup verification passed"
    else
        error "Filestore backup verification failed"
    fi
    
    # Calculate total backup size
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR/$DATE" | cut -f1)
    success "Backup verification completed - Total size: $TOTAL_SIZE"
}

send_notification() {
    # Placeholder for notification system (email, Slack, etc.)
    log "Backup completed successfully at $BACKUP_DIR/$DATE"
    
    # Example: Send email notification (uncomment and configure)
    # echo "Odoo backup completed successfully on $(hostname)" | \
    # mail -s "Odoo Backup Success - $DATE" admin@yourdomain.com
}

main() {
    log "Starting Odoo production backup..."
    
    create_backup_dir
    backup_database
    backup_filestore
    backup_config
    create_manifest
    verify_backup
    cleanup_old_backups
    send_notification
    
    success "Backup process completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "restore")
        if [ -z "$2" ]; then
            error "Please specify backup date (YYYYMMDD_HHMMSS)"
        fi
        log "Restore functionality not implemented yet"
        ;;
    "list")
        log "Available backups:"
        ls -la "$BACKUP_DIR" | grep "^d" | grep "20"
        ;;
    *)
        main
        ;;
esac
