#!/bin/bash
set -e

# Configuración de colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[ODOO DOCKER]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Configuración por defecto
: ${HOST:=db}
: ${PORT:=5432}
: ${USER:=odoo}
: ${PASSWORD:=odoo}
: ${DB_NAME:=odoo_prod}

log "Starting Odoo 18.0 Docker Container"
log "Database Host: $HOST"
log "Database Port: $PORT"
log "Database User: $USER"

# Activar entorno virtual
source /opt/odoo/venv/bin/activate

# Esperar a que PostgreSQL esté disponible
log "Waiting for PostgreSQL to be available..."
python3 /opt/odoo/wait-for-psql.py --host=$HOST --port=$PORT --user=$USER --password=$PASSWORD --timeout=60

if [ $? -ne 0 ]; then
    error "PostgreSQL is not available after 60 seconds"
    exit 1
fi

log "PostgreSQL is available!"

# Función para ejecutar Odoo
run_odoo() {
    log "Starting Odoo server..."
    exec python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --logfile=/opt/odoo/logs/odoo.log \
        "$@"
}

# Función para inicializar la base de datos
init_db() {
    log "Initializing database: $DB_NAME"
    python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --init=base \
        --database=$DB_NAME \
        --db_host=$HOST \
        --db_port=$PORT \
        --db_user=$USER \
        --db_password=$PASSWORD \
        --without-demo=all \
        --stop-after-init
    
    log "Database initialized successfully!"
}

# Función para actualizar módulos
update_modules() {
    log "Updating modules: $2"
    python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --update=$2 \
        --database=$DB_NAME \
        --db_host=$HOST \
        --db_port=$PORT \
        --db_user=$USER \
        --db_password=$PASSWORD \
        --stop-after-init
    
    log "Modules updated successfully!"
}

# Función para instalar módulos
install_modules() {
    log "Installing modules: $2"
    python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --init=$2 \
        --database=$DB_NAME \
        --db_host=$HOST \
        --db_port=$PORT \
        --db_user=$USER \
        --db_password=$PASSWORD \
        --stop-after-init
    
    log "Modules installed successfully!"
}

# Función para hacer backup
backup_db() {
    log "Creating database backup..."
    BACKUP_FILE="/opt/odoo/data/backups/backup_$(date +%Y%m%d_%H%M%S).sql"
    mkdir -p /opt/odoo/data/backups
    
    PGPASSWORD=$PASSWORD pg_dump -h $HOST -p $PORT -U $USER -d $DB_NAME > $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        log "Backup created: $BACKUP_FILE"
    else
        error "Backup failed"
        exit 1
    fi
}

# Función para restaurar backup
restore_db() {
    if [ -z "$2" ]; then
        error "Please specify backup file path"
        exit 1
    fi
    
    log "Restoring database from: $2"
    PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USER -d $DB_NAME < $2
    
    if [ $? -eq 0 ]; then
        log "Database restored successfully!"
    else
        error "Database restore failed"
        exit 1
    fi
}

# Función para mostrar ayuda
show_help() {
    echo "Odoo 18.0 Docker Container"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  odoo                    Start Odoo server (default)"
    echo "  init-db                 Initialize database"
    echo "  update MODULE_LIST      Update specified modules"
    echo "  install MODULE_LIST     Install specified modules"
    echo "  backup                  Create database backup"
    echo "  restore BACKUP_FILE     Restore database from backup"
    echo "  shell                   Open Odoo shell"
    echo "  help                    Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  HOST        Database host (default: db)"
    echo "  PORT        Database port (default: 5432)"
    echo "  USER        Database user (default: odoo)"
    echo "  PASSWORD    Database password (default: odoo)"
    echo "  DB_NAME     Database name (default: odoo_prod)"
    echo ""
    echo "Examples:"
    echo "  $0 odoo"
    echo "  $0 init-db"
    echo "  $0 install sale,purchase,stock"
    echo "  $0 update base,web"
    echo "  $0 backup"
    echo "  $0 shell"
}

# Crear directorio de logs si no existe
mkdir -p /opt/odoo/logs

# Procesar comando
case "$1" in
    odoo|"")
        run_odoo "${@:2}"
        ;;
    init-db)
        init_db
        ;;
    update)
        if [ -z "$2" ]; then
            error "Please specify modules to update"
            exit 1
        fi
        update_modules "$@"
        ;;
    install)
        if [ -z "$2" ]; then
            error "Please specify modules to install"
            exit 1
        fi
        install_modules "$@"
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db "$@"
        ;;
    shell)
        log "Opening Odoo shell..."
        python3 /opt/odoo/odoo/odoo-bin \
            --config=/opt/odoo/config/odoo.conf \
            --data-dir=/opt/odoo/data \
            --database=$DB_NAME \
            --db_host=$HOST \
            --db_port=$PORT \
            --db_user=$USER \
            --db_password=$PASSWORD \
            shell
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
