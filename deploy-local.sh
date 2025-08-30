#!/bin/bash
# Script de Deploy LOCAL para Odoo 18.0 - Pruebas y Desarrollo

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Variables
PROJECT_NAME="odoo-local"
COMPOSE_FILE="docker-compose.local.yml"
ENV_FILE=".env.local"

log() {
    echo -e "${BLUE}[ODOO LOCAL]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

header() {
    echo -e "${PURPLE}================================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================================${NC}"
}

# Verificar Docker
check_docker() {
    log "Verificando Docker..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker no está instalado. Instálalo desde: https://docker.com"
    fi
    
    if ! docker ps &> /dev/null; then
        error "Docker no está ejecutándose. Inicia Docker Desktop."
    fi
    
    success "Docker está funcionando correctamente"
}

# Verificar archivos de configuración
check_config() {
    log "Verificando archivos de configuración..."
    
    local required_files=(
        "$ENV_FILE"
        "$COMPOSE_FILE"
        "config/odoo.local.conf"
        "nginx/nginx.local.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Archivo requerido no encontrado: $file"
        fi
    done
    
    success "Archivos de configuración encontrados"
}

# Crear directorios necesarios
create_directories() {
    log "Creando directorios necesarios..."
    
    local dirs=(
        "custom_addons"
        "backups"
        "logs"
        "nginx/ssl"
        "nginx/logs"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    success "Directorios creados"
}

# Generar certificados SSL
generate_ssl() {
    log "Generando certificados SSL para desarrollo local..."
    
    if [[ -f "nginx/ssl/localhost.crt" && -f "nginx/ssl/localhost.key" ]]; then
        warning "Los certificados SSL ya existen"
        return 0
    fi
    
    chmod +x generate-ssl-local.sh
    ./generate-ssl-local.sh
    
    success "Certificados SSL generados"
}

# Limpiar contenedores anteriores
cleanup() {
    log "Limpiando contenedores anteriores..."
    
    # Detener y remover contenedores anteriores
    docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    
    # Limpiar volúmenes huérfanos (opcional)
    docker volume prune -f 2>/dev/null || true
    
    success "Limpieza completada"
}

# Construir y ejecutar servicios
start_services() {
    log "Iniciando servicios de Odoo local..."
    
    # Copiar variables de entorno
    cp "$ENV_FILE" .env
    
    # Construir e iniciar servicios
    docker compose -f "$COMPOSE_FILE" up -d --build
    
    success "Servicios iniciados"
}

# Esperar a que los servicios estén listos
wait_for_services() {
    log "Esperando a que los servicios estén listos..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker compose -f "$COMPOSE_FILE" ps --filter "status=running" | grep -q "odoo_local_app"; then
            if curl -s -f http://localhost:8069/web/health > /dev/null 2>&1; then
                success "Servicios están listos"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    error "Los servicios no iniciaron correctamente después de $max_attempts intentos"
}

# Verificar estado de los servicios
check_services() {
    log "Verificando estado de los servicios..."
    
    echo ""
    docker compose -f "$COMPOSE_FILE" ps
    echo ""
    
    # Verificar conectividad
    local services=(
        "http://localhost:8069"
        "http://localhost:8080"
        "https://localhost:8443"
    )
    
    for service in "${services[@]}"; do
        if curl -s -f -k "$service" > /dev/null; then
            success "✅ $service - OK"
        else
            warning "⚠️  $service - No responde"
        fi
    done
}

# Mostrar información de acceso
show_access_info() {
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
    
    header "🎉 DEPLOY LOCAL COMPLETADO EXITOSAMENTE"
    
    echo ""
    echo -e "${GREEN}🌐 URLs de Acceso:${NC}"
    echo "   HTTP Directo:    http://localhost:8069"
    echo "   HTTP via Nginx:  http://localhost:8080"
    echo "   HTTPS via Nginx: https://localhost:8443"
    echo ""
    echo -e "${GREEN}👤 Credenciales de Acceso:${NC}"
    echo "   Usuario:     admin"
    echo "   Contraseña:  admin123"
    echo "   Email:       admin@odoo.local"
    echo ""
    echo -e "${GREEN}🛢️  Base de Datos:${NC}"
    echo "   Host:        localhost:5432"
    echo "   Database:    odoo_local"
    echo "   Usuario:     odoo"
    echo "   Contraseña:  odoo123"
    echo ""
    echo -e "${GREEN}🔧 Gestión de la Instancia:${NC}"
    echo "   Master Password: master123"
    echo "   Database Manager: http://localhost:8069/web/database/manager"
    echo ""
    echo -e "${YELLOW}📋 Comandos útiles:${NC}"
    echo "   Ver logs:        docker compose -f $COMPOSE_FILE logs -f"
    echo "   Reiniciar:       docker compose -f $COMPOSE_FILE restart"
    echo "   Detener:         docker compose -f $COMPOSE_FILE down"
    echo "   Ver estado:      docker compose -f $COMPOSE_FILE ps"
    echo "   Shell Odoo:      docker compose -f $COMPOSE_FILE exec odoo bash"
    echo "   Shell DB:        docker compose -f $COMPOSE_FILE exec db psql -U odoo -d odoo_local"
    echo ""
    echo -e "${YELLOW}📁 Directorios importantes:${NC}"
    echo "   Addons custom:   ./custom_addons/"
    echo "   Configuración:   ./config/odoo.local.conf"
    echo "   Logs:           ./logs/"
    echo "   Backups:        ./backups/"
    echo "   SSL certs:      ./nginx/ssl/"
    echo ""
    echo -e "${YELLOW}⚠️  Notas importantes:${NC}"
    echo "   - Los certificados SSL son auto-firmados (para desarrollo)"
    echo "   - El navegador mostrará advertencia de seguridad en HTTPS"
    echo "   - Los datos se persisten en volúmenes Docker"
    echo "   - Esta configuración es SOLO para desarrollo/pruebas"
    echo ""
    
    if [[ "$public_ip" != "N/A" ]]; then
        echo -e "${BLUE}🌍 Acceso desde red local (si el firewall lo permite):${NC}"
        echo "   http://$public_ip:8069"
        echo "   http://$public_ip:8080"
        echo "   https://$public_ip:8443"
        echo ""
    fi
    
    success "¡Odoo está listo para usar!"
    header "Disfruta desarrollando con Odoo 18.0 🚀"
}

# Mostrar logs recientes
show_logs() {
    log "Mostrando logs recientes..."
    echo ""
    docker compose -f "$COMPOSE_FILE" logs --tail=20
}

# Función principal de deploy
deploy() {
    header "🚀 DEPLOY LOCAL DE ODOO 18.0 PARA DESARROLLO"
    
    check_docker
    check_config
    create_directories
    generate_ssl
    cleanup
    start_services
    wait_for_services
    check_services
    show_access_info
}

# Crear backup de la base de datos
backup() {
    log "Creando backup de la base de datos local..."
    
    local backup_file="backups/backup_local_$(date +%Y%m%d_%H%M%S).sql"
    
    docker compose -f "$COMPOSE_FILE" exec db pg_dump -U odoo odoo_local > "$backup_file"
    
    success "Backup creado: $backup_file"
}

# Restaurar backup
restore() {
    if [[ -z "$2" ]]; then
        error "Uso: $0 restore <archivo_backup.sql>"
    fi
    
    local backup_file="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Archivo de backup no encontrado: $backup_file"
    fi
    
    log "Restaurando backup: $backup_file"
    
    # Recrear base de datos
    docker compose -f "$COMPOSE_FILE" exec db dropdb -U odoo odoo_local || true
    docker compose -f "$COMPOSE_FILE" exec db createdb -U odoo odoo_local
    
    # Restaurar datos
    docker compose -f "$COMPOSE_FILE" exec -T db psql -U odoo -d odoo_local < "$backup_file"
    
    success "Backup restaurado exitosamente"
}

# Menu principal
case "${1:-deploy}" in
    deploy|start)
        deploy
        ;;
    stop)
        log "Deteniendo servicios..."
        docker compose -f "$COMPOSE_FILE" down
        success "Servicios detenidos"
        ;;
    restart)
        log "Reiniciando servicios..."
        docker compose -f "$COMPOSE_FILE" restart
        success "Servicios reiniciados"
        ;;
    logs)
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;
    status)
        log "Estado de los servicios:"
        docker compose -f "$COMPOSE_FILE" ps
        check_services
        ;;
    shell)
        log "Abriendo shell en el contenedor de Odoo..."
        docker compose -f "$COMPOSE_FILE" exec odoo bash
        ;;
    db-shell)
        log "Abriendo shell de PostgreSQL..."
        docker compose -f "$COMPOSE_FILE" exec db psql -U odoo -d odoo_local
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$@"
        ;;
    clean)
        warning "Esto eliminará TODOS los datos locales. ¿Continuar? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            log "Limpiando completamente el entorno local..."
            docker compose -f "$COMPOSE_FILE" down -v
            docker system prune -f
            rm -rf logs/* backups/* nginx/ssl/*
            success "Entorno local limpiado completamente"
        else
            log "Operación cancelada"
        fi
        ;;
    ssl)
        generate_ssl
        ;;
    update)
        log "Actualizando imágenes..."
        docker compose -f "$COMPOSE_FILE" pull
        docker compose -f "$COMPOSE_FILE" up -d
        success "Imágenes actualizadas"
        ;;
    help|--help|-h)
        echo "Deploy Local de Odoo 18.0 - Comandos disponibles:"
        echo ""
        echo "  deploy/start - Iniciar deploy completo (por defecto)"
        echo "  stop         - Detener todos los servicios"
        echo "  restart      - Reiniciar servicios"
        echo "  status       - Ver estado de servicios"
        echo "  logs         - Ver logs en tiempo real"
        echo "  shell        - Abrir shell en contenedor Odoo"
        echo "  db-shell     - Abrir shell de PostgreSQL"
        echo "  backup       - Crear backup de la BD"
        echo "  restore      - Restaurar backup (requiere archivo)"
        echo "  ssl          - Regenerar certificados SSL"
        echo "  update       - Actualizar imágenes Docker"
        echo "  clean        - Limpiar completamente el entorno"
        echo "  help         - Mostrar esta ayuda"
        echo ""
        echo "Ejemplos:"
        echo "  $0 deploy"
        echo "  $0 logs"
        echo "  $0 backup"
        echo "  $0 restore backups/backup_local_20250828_120000.sql"
        ;;
    *)
        error "Comando no reconocido: $1. Usa '$0 help' para ver comandos disponibles."
        ;;
esac
