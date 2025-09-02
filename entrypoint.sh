#!/bin/bash
set -e

# Variables de entorno por defecto
: ${HOST:=postgres}
: ${PORT:=5432}
: ${USER:=odoo}
: ${PASSWORD:=odoo}
: ${DATABASE:=odoo}

# Función para esperar PostgreSQL
wait_for_postgres() {
    echo "Esperando PostgreSQL en $HOST:$PORT..."
    while ! nc -z $HOST $PORT; do
        sleep 1
    done
    echo "PostgreSQL está listo!"
}

# Esperar a que PostgreSQL esté disponible
wait_for_postgres

# Configurar la base de datos si no existe
if [ "$1" = 'odoo' ]; then
    echo "Iniciando Odoo..."
    exec python3 /opt/odoo/odoo-bin \
        --database=$DATABASE \
        --db_host=$HOST \
        --db_port=$PORT \
        --db_user=$USER \
        --db_password=$PASSWORD \
        --addons-path=/opt/odoo/addons \
        --data-dir=/var/lib/odoo \
        --logfile=/var/log/odoo/odoo.log \
        --log-level=info \
        --init=base \
        --workers=0 \
        --without-demo=False
fi

# Ejecutar cualquier otro comando
exec "$@"
