#!/bin/bash
# Entrypoint para desarrollo de Odoo
set -e

# Configuración de colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[ODOO DEV]${NC} $1"
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
: ${DB_NAME:=odoo_dev}

log "Starting Odoo 18.0 Development Container"
log "Database Host: $HOST"
log "Development Mode: ENABLED"

# Activar entorno virtual
source /opt/odoo/venv/bin/activate

# Esperar a que PostgreSQL esté disponible
log "Waiting for PostgreSQL..."
python3 /opt/odoo/wait-for-psql.py --host=$HOST --port=$PORT --user=$USER --password=$PASSWORD --timeout=60

if [ $? -ne 0 ]; then
    error "PostgreSQL is not available after 60 seconds"
    exit 1
fi

log "PostgreSQL is available!"

# Crear directorio de logs si no existe
mkdir -p /opt/odoo/logs

# Función para ejecutar Odoo en modo desarrollo
run_odoo_dev() {
    log "Starting Odoo in development mode..."
    log "Features enabled: reload, qweb, werkzeug, xml"
    log "Debug mode: ON"
    
    # Construir addons-path dinámicamente
    ADDONS_PATH="/opt/odoo/odoo/addons,/opt/odoo/addons"
    if [ -d "/opt/odoo/custom_addons" ] && [ -n "$(find /opt/odoo/custom_addons -maxdepth 2 -name '__manifest__.py' 2>/dev/null)" ]; then
        ADDONS_PATH="/opt/odoo/odoo/addons,/opt/odoo/custom_addons,/opt/odoo/addons"
        log "Custom addons found, including in path"
    else
        log "No custom addons found, using default path"
    fi
    
    exec python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --addons-path="$ADDONS_PATH" \
        --dev=reload,qweb,werkzeug,xml \
        --log-level=debug \
        --logfile=/opt/odoo/logs/odoo.log \
        "$@"
}

# Función para debugging con debugpy
run_odoo_debug() {
    log "Starting Odoo with Python debugger (port 5678)..."
    
    # Construir addons-path dinámicamente
    ADDONS_PATH="/opt/odoo/odoo/addons,/opt/odoo/addons"
    if [ -d "/opt/odoo/custom_addons" ] && [ -n "$(find /opt/odoo/custom_addons -maxdepth 2 -name '__manifest__.py' 2>/dev/null)" ]; then
        ADDONS_PATH="/opt/odoo/odoo/addons,/opt/odoo/custom_addons,/opt/odoo/addons"
        log "Custom addons found, including in path"
    else
        log "No custom addons found, using default path"
    fi
    
    python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client \
        /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --addons-path="$ADDONS_PATH" \
        --dev=reload,qweb,werkzeug,xml \
        --log-level=debug \
        "$@"
}

# Función para tests
run_tests() {
    log "Running Odoo tests for modules: ${2:-all}"
    python3 /opt/odoo/odoo/odoo-bin \
        --config=/opt/odoo/config/odoo.conf \
        --data-dir=/opt/odoo/data \
        --test-enable \
        --test-tags="$2" \
        --stop-after-init \
        --database=$DB_NAME \
        --db_host=$HOST \
        --db_port=$PORT \
        --db_user=$USER \
        --db_password=$PASSWORD
}

# Función para scaffold (crear módulo)
scaffold_module() {
    if [ -z "$2" ]; then
        error "Please specify module name"
        exit 1
    fi
    
    log "Creating new module: $2"
    python3 /opt/odoo/odoo/odoo-bin scaffold "$2" /opt/odoo/custom_addons/
    
    # Cambiar permisos
    chown -R odoo:odoo "/opt/odoo/custom_addons/$2"
    log "Module $2 created in /opt/odoo/custom_addons/"
}

# Función para mostrar ayuda
show_help() {
    echo "Odoo 18.0 Development Container"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Development Commands:"
    echo "  odoo                    Start Odoo in development mode (default)"
    echo "  debug                   Start Odoo with Python debugger"
    echo "  test [MODULE_TAGS]      Run tests for specified modules/tags"
    echo "  scaffold MODULE_NAME    Create new module"
    echo "  shell                   Open Odoo shell"
    echo ""
    echo "Standard Commands:"
    echo "  init-db                 Initialize database"
    echo "  update MODULE_LIST      Update specified modules"
    echo "  install MODULE_LIST     Install specified modules"
    echo "  help                    Show this help"
    echo ""
    echo "Development Features:"
    echo "  - Auto-reload on file changes"
    echo "  - Debug logging enabled"
    echo "  - QWeb template debugging"
    echo "  - Werkzeug debugging"
    echo "  - XML debugging"
    echo ""
    echo "Examples:"
    echo "  $0 odoo"
    echo "  $0 debug"
    echo "  $0 test sale"
    echo "  $0 scaffold my_custom_module"
    echo "  $0 install sale,purchase"
}

# Procesar comando
case "$1" in
    odoo|"")
        run_odoo_dev "${@:2}"
        ;;
    debug)
        run_odoo_debug "${@:2}"
        ;;
    test|tests)
        run_tests "$@"
        ;;
    scaffold)
        scaffold_module "$@"
        ;;
    init-db)
        log "Initializing development database: $DB_NAME"
        python3 /opt/odoo/odoo/odoo-bin \
            --config=/opt/odoo/config/odoo.conf \
            --data-dir=/opt/odoo/data \
            --init=base \
            --database=$DB_NAME \
            --db_host=$HOST \
            --db_port=$PORT \
            --db_user=$USER \
            --db_password=$PASSWORD \
            --stop-after-init
        log "Development database initialized!"
        ;;
    update)
        if [ -z "$2" ]; then
            error "Please specify modules to update"
            exit 1
        fi
        log "Updating modules in development: $2"
        python3 /opt/odoo/odoo/odoo-bin \
            --config=/opt/odoo/config/odoo.conf \
            --data-dir=/opt/odoo/data \
            --update="$2" \
            --database=$DB_NAME \
            --db_host=$HOST \
            --db_port=$PORT \
            --db_user=$USER \
            --db_password=$PASSWORD \
            --stop-after-init
        ;;
    install)
        if [ -z "$2" ]; then
            error "Please specify modules to install"
            exit 1
        fi
        log "Installing modules in development: $2"
        python3 /opt/odoo/odoo/odoo-bin \
            --config=/opt/odoo/config/odoo.conf \
            --data-dir=/opt/odoo/data \
            --init="$2" \
            --database=$DB_NAME \
            --db_host=$HOST \
            --db_port=$PORT \
            --db_user=$USER \
            --db_password=$PASSWORD \
            --stop-after-init
        ;;
    shell)
        log "Opening Odoo development shell..."
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
