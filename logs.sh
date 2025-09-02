#!/bin/bash

# Script de monitoreo de logs - Odoo 18.0

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "📋 LOGS ODOO 18.0"
echo "=================================================="

if [ "$1" = "odoo" ]; then
    echo -e "${BLUE}Logs de Odoo:${NC}"
    docker-compose logs -f odoo
elif [ "$1" = "db" ]; then
    echo -e "${BLUE}Logs de PostgreSQL:${NC}"
    docker-compose logs -f postgres
else
    echo -e "${GREEN}Logs de todos los servicios:${NC}"
    docker-compose logs -f
fi
