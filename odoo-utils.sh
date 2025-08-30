#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "=================================================="
    echo "🛠️  UTILIDADES ODOO 18.0 LOCAL"
    echo "=================================================="
    echo
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos disponibles:"
    echo "  test      - Ejecutar pruebas de la instalación"
    echo "  open      - Abrir URLs en el navegador"
    echo "  logs      - Ver logs de los servicios"
    echo "  status    - Estado de los servicios"
    echo "  restart   - Reiniciar servicios"
    echo "  db        - Comandos de base de datos"
    echo "  backup    - Crear respaldo de la base de datos"
    echo "  restore   - Restaurar respaldo de base de datos"
    echo "  clean     - Limpiar instalación"
    echo "  help      - Mostrar esta ayuda"
    echo
}

open_urls() {
    echo -e "${BLUE}🌐 Abriendo URLs en el navegador...${NC}"
    echo
    echo "✅ Login directo: https://localhost:8443/web/login?db=odoo_local"
    echo "✅ Gestor BD: https://localhost:8443/web/database/manager" 
    echo "✅ Selector BD: https://localhost:8443/web/database/selector"
    echo
    echo -e "${YELLOW}💡 Credenciales:${NC}"
    echo "   Usuario: admin"
    echo "   Contraseña: admin"
    echo "   Base de datos: odoo_local"
}

show_logs() {
    echo -e "${BLUE}📜 Logs de servicios:${NC}"
    echo
    echo "=== ODOO APP ==="
    docker logs odoo_local_app --tail=10
    echo
    echo "=== NGINX ==="
    docker logs odoo_local_nginx --tail=5
    echo
    echo "=== POSTGRESQL ==="
    docker logs odoo_local_db --tail=5
}

db_commands() {
    echo -e "${BLUE}🗄️  Comandos de Base de Datos:${NC}"
    echo
    echo "1. Listar bases de datos:"
    docker exec -it odoo_local_db psql -U odoo -l
    echo
    echo "2. Usuarios activos en odoo_local:"
    docker exec -it odoo_local_db psql -U odoo -d odoo_local -c "SELECT login, create_date FROM res_users WHERE active = true ORDER BY create_date;"
}

create_backup() {
    BACKUP_DIR="./backups"
    BACKUP_FILE="$BACKUP_DIR/odoo_local_$(date +%Y%m%d_%H%M%S).sql"
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${BLUE}💾 Creando respaldo...${NC}"
    docker exec -t odoo_local_db pg_dump -U odoo -d odoo_local > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "${GREEN}✅ Respaldo creado: $BACKUP_FILE${NC}"
        ls -lh "$BACKUP_FILE"
    else
        echo -e "${RED}❌ Error al crear el respaldo${NC}"
    fi
}

case "$1" in
    "test")
        ./test-local-install.sh
        ;;
    "open")
        open_urls
        ;;
    "logs")
        show_logs
        ;;
    "status")
        ./deploy-local.sh status
        ;;
    "restart")
        echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"
        docker restart odoo_local_app odoo_local_nginx
        sleep 5
        ./deploy-local.sh status
        ;;
    "db")
        db_commands
        ;;
    "backup")
        create_backup
        ;;
    "clean")
        echo -e "${RED}⚠️  Esto eliminará toda la instalación local${NC}"
        ./deploy-local.sh clean
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        show_help
        exit 1
        ;;
esac
