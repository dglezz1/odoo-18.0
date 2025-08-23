#!/bin/bash

# Script de gestión para Odoo en producción
# Uso: ./deploy-prod.sh [comando]

set -e

COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.prod"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[ODOO PROD]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[ODOO PROD]${NC} $1"
}

error() {
    echo -e "${RED}[ODOO PROD]${NC} $1"
}

# Verificar que existe el archivo .env.prod
check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        error "Archivo $ENV_FILE no encontrado!"
        error "Copia .env.prod y configura tus variables de entorno"
        exit 1
    fi
}

# Verificar configuración de dominio
check_domain() {
    source "$ENV_FILE"
    if [ "$DOMAIN" = "tu-dominio.com" ]; then
        error "¡Debes configurar tu DOMAIN en $ENV_FILE!"
        exit 1
    fi
}

# Generar certificados SSL iniciales (self-signed para primera configuración)
init_ssl() {
    log "Generando certificados SSL temporales..."
    
    mkdir -p nginx/ssl/live/$DOMAIN
    
    if [ ! -f "nginx/ssl/live/$DOMAIN/fullchain.pem" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/live/$DOMAIN/privkey.pem \
            -out nginx/ssl/live/$DOMAIN/fullchain.pem \
            -subj "/C=MX/ST=Mexico/L=Mexico/O=Odoo/CN=$DOMAIN"
        
        log "Certificados temporales generados"
        warn "Recuerda obtener certificados reales con: ./deploy-prod.sh ssl"
    fi
}

# Obtener certificados Let's Encrypt
get_ssl() {
    log "Obteniendo certificados SSL de Let's Encrypt..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm certbot
    
    log "Certificados SSL obtenidos exitosamente"
    log "Reiniciando Nginx para aplicar nuevos certificados..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" restart nginx
}

# Renovar certificados SSL
renew_ssl() {
    log "Renovando certificados SSL..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm certbot renew
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" restart nginx
    
    log "Certificados SSL renovados"
}

# Inicializar el sistema
init() {
    log "Inicializando Odoo para producción..."
    
    check_env
    check_domain
    init_ssl
    
    log "Iniciando servicios..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    log "Esperando que los servicios estén listos..."
    sleep 10
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=20
    
    log "✅ Odoo está ejecutándose en producción!"
    log "🌐 Accede a: https://$DOMAIN"
    warn "⚠️  Configura certificados SSL reales: ./deploy-prod.sh ssl"
}

# Iniciar servicios
start() {
    log "Iniciando servicios de producción..."
    check_env
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    log "Servicios iniciados"
}

# Detener servicios
stop() {
    log "Deteniendo servicios..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
    
    log "Servicios detenidos"
}

# Reiniciar servicios
restart() {
    log "Reiniciando servicios..."
    
    stop
    sleep 3
    start
    
    log "Servicios reiniciados"
}

# Ver logs
logs() {
    SERVICE=${2:-}
    if [ -n "$SERVICE" ]; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$SERVICE"
    else
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
    fi
}

# Estado de servicios
status() {
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
}

# Backup de base de datos
backup() {
    log "Creando backup de base de datos..."
    
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec db pg_dump -U odoo postgres > "backups/$BACKUP_FILE"
    
    log "Backup creado: backups/$BACKUP_FILE"
}

# Restaurar base de datos
restore() {
    BACKUP_FILE=$2
    
    if [ -z "$BACKUP_FILE" ]; then
        error "Uso: ./deploy-prod.sh restore <archivo_backup>"
        exit 1
    fi
    
    if [ ! -f "backups/$BACKUP_FILE" ]; then
        error "Archivo de backup no encontrado: backups/$BACKUP_FILE"
        exit 1
    fi
    
    warn "⚠️  ADVERTENCIA: Esto sobrescribirá la base de datos actual"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Restaurando base de datos desde $BACKUP_FILE..."
        
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec db psql -U odoo -c "DROP DATABASE IF EXISTS postgres;"
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec db psql -U odoo -c "CREATE DATABASE postgres;"
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T db psql -U odoo postgres < "backups/$BACKUP_FILE"
        
        log "Base de datos restaurada exitosamente"
    else
        log "Operación cancelada"
    fi
}

# Actualizar servicios
update() {
    log "Actualizando servicios..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
    restart
    
    log "Servicios actualizados"
}

# Limpiar sistema
clean() {
    warn "⚠️  Esto eliminará volúmenes y datos"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Limpiando sistema..."
        
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v
        docker system prune -f
        
        log "Sistema limpiado"
    else
        log "Operación cancelada"
    fi
}

# Mostrar ayuda
show_help() {
    echo -e "${BLUE}Gestión de Odoo en Producción${NC}"
    echo
    echo "Uso: $0 [COMANDO]"
    echo
    echo "Comandos disponibles:"
    echo "  init         - Inicializar Odoo para producción"
    echo "  start        - Iniciar servicios"
    echo "  stop         - Detener servicios"
    echo "  restart      - Reiniciar servicios"
    echo "  status       - Ver estado de servicios"
    echo "  logs [srv]   - Ver logs (opcionalmente de un servicio específico)"
    echo "  ssl          - Obtener certificados SSL de Let's Encrypt"
    echo "  renew-ssl    - Renovar certificados SSL"
    echo "  backup       - Crear backup de base de datos"
    echo "  restore FILE - Restaurar backup de base de datos"
    echo "  update       - Actualizar servicios"
    echo "  clean        - Limpiar sistema (¡elimina datos!)"
    echo "  help         - Mostrar esta ayuda"
    echo
    echo "Ejemplos:"
    echo "  $0 init                    # Configuración inicial"
    echo "  $0 logs odoo              # Ver logs de Odoo"
    echo "  $0 backup                 # Crear backup"
    echo "  $0 restore backup.sql     # Restaurar backup"
}

# Crear directorio de backups
mkdir -p backups

# Procesar comandos
case "${1:-help}" in
    init)
        init
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$@"
        ;;
    ssl)
        get_ssl
        ;;
    renew-ssl)
        renew_ssl
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$@"
        ;;
    update)
        update
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Comando desconocido: $1"
        echo
        show_help
        exit 1
        ;;
esac
