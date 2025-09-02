#!/bin/bash
set -e

# Función de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Odoo Production..."

# Variables de entorno por defecto
export ODOO_DB_HOST="${ODOO_DB_HOST:-postgres}"
export ODOO_DB_PORT="${ODOO_DB_PORT:-5432}"
export ODOO_DB_USER="${ODOO_DB_USER:-odoo_prod}"
export ODOO_DB_PASSWORD="${ODOO_DB_PASSWORD:-}"
export ODOO_DB_NAME="${ODOO_DB_NAME:-odoo_prod}"
export ODOO_ADMIN_PASSWORD="${ODOO_ADMIN_PASSWORD:-admin123}"

# Función para esperar PostgreSQL
wait_for_postgres() {
    log "Waiting for PostgreSQL at $ODOO_DB_HOST:$ODOO_DB_PORT..."
    while ! nc -z $ODOO_DB_HOST $ODOO_DB_PORT; do
        sleep 2
    done
    log "PostgreSQL is ready!"
}

# Función para crear archivo de configuración dinámico
create_config() {
    log "Creating dynamic Odoo configuration..."
    cat > /tmp/odoo.conf << EOL
[options]
addons_path = /opt/odoo/addons,/opt/odoo/custom-addons
data_dir = /var/lib/odoo
admin_passwd = ${ODOO_ADMIN_PASSWORD}

db_host = ${ODOO_DB_HOST}
db_port = ${ODOO_DB_PORT}
db_user = ${ODOO_DB_USER}
db_password = ${ODOO_DB_PASSWORD}
db_name = ${ODOO_DB_NAME}
db_maxconn = 64
db_template = template0

workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 300

list_db = False
db_filter = ^${ODOO_DB_NAME}$

log_level = warn
log_handler = :INFO

proxy_mode = True
xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8069
EOL
    log "Configuration created with DB: ${ODOO_DB_NAME}, User: ${ODOO_DB_USER}"
}

log "Checking database connection..."
wait_for_postgres
create_config

log "Starting Odoo server with dynamic config..."
exec "$@" -c /tmp/odoo.conf
