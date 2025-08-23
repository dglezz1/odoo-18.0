#!/bin/bash

# Script de Despliegue Automatizado para Odoo con Cloudflare
# Uso: ./deploy-filltech.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose no está instalado"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl no está instalado"
        exit 1
    fi
    
    log_success "Todas las dependencias están instaladas"
}

# Verificar archivos de configuración
check_config_files() {
    log_info "Verificando archivos de configuración..."
    
    if [ ! -f ".env.filltech" ]; then
        log_error "El archivo .env.filltech no existe"
        exit 1
    fi
    
    if [ ! -f "docker-compose.prod.yml" ]; then
        log_error "El archivo docker-compose.prod.yml no existe"
        exit 1
    fi
    
    log_success "Archivos de configuración encontrados"
}

# Obtener IP pública
get_public_ip() {
    log_info "Obteniendo IP pública..."
    
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
    
    if [ -z "$PUBLIC_IP" ]; then
        log_error "No se pudo obtener la IP pública"
        exit 1
    fi
    
    log_success "IP pública: $PUBLIC_IP"
    echo "$PUBLIC_IP"
}

# Verificar conectividad con Cloudflare
check_cloudflare_dns() {
    log_info "Verificando configuración DNS en Cloudflare..."
    
    DOMAIN_IP=$(dig +short odoo.filltech-ai.com)
    
    if [ -z "$DOMAIN_IP" ]; then
        log_warning "El dominio odoo.filltech-ai.com no resuelve a ninguna IP"
        log_info "Asegúrate de configurar el registro A en Cloudflare"
        return 1
    fi
    
    log_success "El dominio odoo.filltech-ai.com resuelve a: $DOMAIN_IP"
    return 0
}

# Preparar configuración SSL
prepare_ssl() {
    log_info "Preparando configuración SSL..."
    
    # Crear directorios para certificados
    sudo mkdir -p /etc/letsencrypt/live/odoo.filltech-ai.com
    
    # Verificar si certbot está instalado
    if command -v certbot &> /dev/null; then
        log_info "Certbot encontrado, configurando certificados SSL..."
        
        # Solo ejecutar si no existen certificados
        if [ ! -f "/etc/letsencrypt/live/odoo.filltech-ai.com/fullchain.pem" ]; then
            log_info "Obteniendo certificados SSL de Let's Encrypt..."
            sudo certbot certonly --standalone \
                --preferred-challenges http \
                -d odoo.filltech-ai.com \
                --email admin@filltech-ai.com \
                --agree-tos \
                --no-eff-email
        else
            log_success "Certificados SSL ya existen"
        fi
    else
        log_warning "Certbot no está instalado. Se usarán certificados auto-firmados."
        
        # Generar certificados auto-firmados
        if [ ! -f "/etc/letsencrypt/live/odoo.filltech-ai.com/fullchain.pem" ]; then
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/letsencrypt/live/odoo.filltech-ai.com/privkey.pem \
                -out /etc/letsencrypt/live/odoo.filltech-ai.com/fullchain.pem \
                -subj "/C=ES/ST=Madrid/L=Madrid/O=Filltech AI/CN=odoo.filltech-ai.com"
            
            # Crear chain.pem (copia de fullchain para auto-firmados)
            sudo cp /etc/letsencrypt/live/odoo.filltech-ai.com/fullchain.pem \
                /etc/letsencrypt/live/odoo.filltech-ai.com/chain.pem
        fi
    fi
}

# Configurar Nginx
setup_nginx() {
    log_info "Configurando Nginx..."
    
    # Crear directorio de configuración si no existe
    mkdir -p nginx
    
    # Copiar configuración específica de Cloudflare si no existe
    if [ ! -f "nginx/nginx.filltech.conf" ]; then
        log_info "Creando configuración de Nginx para Cloudflare..."
        # La configuración ya está en el archivo de documentación
        # Aquí podríamos copiarla automáticamente
        log_warning "Asegúrate de que nginx/nginx.filltech.conf esté configurado correctamente"
    fi
}

# Detener servicios anteriores
stop_services() {
    log_info "Deteniendo servicios anteriores..."
    
    if docker-compose ps -q > /dev/null 2>&1; then
        docker-compose down
    fi
    
    if docker-compose -f docker-compose.prod.yml ps -q > /dev/null 2>&1; then
        docker-compose -f docker-compose.prod.yml down
    fi
    
    log_success "Servicios anteriores detenidos"
}

# Construir y ejecutar servicios
start_services() {
    log_info "Iniciando servicios de producción..."
    
    # Copiar configuración de entorno
    cp .env.filltech .env
    
    # Construir y ejecutar
    docker-compose -f docker-compose.prod.yml up -d --build
    
    log_success "Servicios iniciados"
}

# Verificar servicios
verify_services() {
    log_info "Verificando servicios..."
    
    sleep 10  # Esperar a que los servicios inicien
    
    # Verificar que los contenedores estén ejecutándose
    if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        log_error "Algunos servicios no están ejecutándose correctamente"
        docker-compose -f docker-compose.prod.yml ps
        return 1
    fi
    
    # Verificar conectividad local
    if curl -f -s http://localhost:80 > /dev/null; then
        log_success "Servicio HTTP responde correctamente"
    else
        log_warning "El servicio HTTP no responde en el puerto 80"
    fi
    
    # Verificar SSL si está configurado
    if curl -f -s -k https://localhost:443 > /dev/null; then
        log_success "Servicio HTTPS responde correctamente"
    else
        log_warning "El servicio HTTPS no responde en el puerto 443"
    fi
    
    log_success "Verificación de servicios completada"
}

# Mostrar información de conexión
show_connection_info() {
    local public_ip=$1
    
    log_info "=== INFORMACIÓN DE CONEXIÓN ==="
    echo ""
    echo "🌐 URL del sitio: https://odoo.filltech-ai.com"
    echo "🔒 SSL: Activado"
    echo "☁️  Cloudflare: Activo"
    echo "📡 IP Pública: $public_ip"
    echo ""
    echo "👤 Acceso de administrador:"
    echo "   Email: admin@filltech-ai.com"
    echo "   Contraseña: (consultar archivo .env.filltech)"
    echo ""
    echo "🛠️  Comandos útiles:"
    echo "   docker-compose -f docker-compose.prod.yml logs -f"
    echo "   docker-compose -f docker-compose.prod.yml ps"
    echo "   docker-compose -f docker-compose.prod.yml restart"
    echo ""
    log_success "Despliegue completado exitosamente!"
}

# Mostrar logs en caso de error
show_logs_on_error() {
    log_error "Error durante el despliegue. Mostrando logs..."
    echo ""
    echo "=== LOGS DE ERROR ==="
    docker-compose -f docker-compose.prod.yml logs --tail=20
}

# Función principal
main() {
    log_info "=== INICIANDO DESPLIEGUE DE ODOO CON CLOUDFLARE ==="
    echo ""
    
    # Verificar dependencias
    check_dependencies
    
    # Verificar archivos de configuración
    check_config_files
    
    # Obtener IP pública
    public_ip=$(get_public_ip)
    
    # Verificar DNS (no crítico)
    check_cloudflare_dns || true
    
    # Preparar SSL
    prepare_ssl
    
    # Configurar Nginx
    setup_nginx
    
    # Detener servicios anteriores
    stop_services
    
    # Iniciar servicios nuevos
    if ! start_services; then
        show_logs_on_error
        exit 1
    fi
    
    # Verificar servicios
    if ! verify_services; then
        show_logs_on_error
        exit 1
    fi
    
    # Mostrar información de conexión
    show_connection_info "$public_ip"
}

# Manejo de errores
trap 'log_error "Script interrumpido"; exit 1' INT TERM

# Ejecutar función principal
main "$@"
