#!/bin/bash
# Script de Despliegue Completo para Odoo 18.0 en Ubuntu Server
# Con Docker + Nginx + Cloudflare + Let's Encrypt

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
DOMAIN="odoo.filltech-ai.com"
EMAIL="admin@filltech-ai.com"
DB_PASSWORD="SecurePassword2025!"
ADMIN_PASSWORD="FillTechAdmin2025!"

# Funciones de utilidad
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Verificar permisos de root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script debe ejecutarse como root. Use: sudo $0"
    fi
}

# Verificar sistema
check_system() {
    log "Verificando sistema..."
    
    # Verificar Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "Este script está diseñado para Ubuntu Server"
    fi
    
    # Verificar memoria
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ $MEMORY_GB -lt 4 ]; then
        warning "Se recomienda al menos 4GB de RAM. Detectado: ${MEMORY_GB}GB"
    fi
    
    # Verificar espacio en disco
    DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_GB -lt 20 ]; then
        warning "Se recomienda al menos 20GB de espacio libre. Disponible: ${DISK_GB}GB"
    fi
    
    success "Verificación del sistema completada"
}

# Actualizar sistema
update_system() {
    log "Actualizando sistema..."
    apt update && apt upgrade -y
    apt install -y curl wget git nano htop ufw net-tools software-properties-common
    success "Sistema actualizado"
}

# Instalar Docker
install_docker() {
    log "Instalando Docker..."
    
    # Remover versiones anteriores
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Instalar dependencias
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Agregar clave GPG
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Agregar repositorio
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Configurar Docker
    systemctl enable docker
    systemctl start docker
    
    # Agregar usuario al grupo docker
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
    fi
    
    success "Docker instalado correctamente"
}

# Instalar Nginx
install_nginx() {
    log "Instalando Nginx..."
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    success "Nginx instalado"
}

# Configurar firewall
setup_firewall() {
    log "Configurando firewall..."
    ufw --force enable
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 'Nginx Full'
    success "Firewall configurado"
}

# Clonar repositorio de Odoo
setup_odoo() {
    log "Configurando Odoo..."
    
    # Ir al directorio home del usuario
    USER_HOME="/home/$SUDO_USER"
    if [ -n "$SUDO_USER" ]; then
        cd $USER_HOME
    else
        cd /root
    fi
    
    # Clonar o actualizar repositorio
    if [ -d "odoo-18.0" ]; then
        warning "El directorio odoo-18.0 ya existe. Actualizando..."
        cd odoo-18.0
        git pull
    else
        log "Clonando Odoo 18.0..."
        git clone https://github.com/odoo/odoo.git -b 18.0 --depth 1 odoo-18.0
        cd odoo-18.0
    fi
    
    # Cambiar propietario si es necesario
    if [ -n "$SUDO_USER" ]; then
        chown -R $SUDO_USER:$SUDO_USER ../odoo-18.0
    fi
    
    # Crear directorios
    mkdir -p {config,custom_addons,nginx/{ssl,logs},backups,scripts}
    
    success "Odoo configurado"
}

# Instalar SSL
setup_ssl() {
    log "Configurando SSL..."
    
    # Instalar certbot
    apt install -y certbot python3-certbot-nginx
    
    # Detener nginx temporalmente
    systemctl stop nginx
    
    # Obtener certificado
    log "Obteniendo certificado SSL para $DOMAIN..."
    certbot certonly \
        --standalone \
        --preferred-challenges http \
        -d $DOMAIN \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --non-interactive
    
    # Configurar renovación automática
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'") | crontab -
    
    # Reiniciar nginx
    systemctl start nginx
    
    success "SSL configurado para $DOMAIN"
}

# Configurar variables de entorno
setup_env() {
    log "Configurando variables de entorno..."
    
    cat > .env.production << EOF
# Configuración de Producción para $DOMAIN
DOMAIN=$DOMAIN
SSL_EMAIL=$EMAIL

# Database configuration
POSTGRES_DB=filltech_odoo
POSTGRES_USER=odoo_user
POSTGRES_PASSWORD=$DB_PASSWORD
PGDATA=/var/lib/postgresql/data/pgdata

# Odoo configuration
DB_HOST=db
DB_PORT=5432
DB_USER=odoo_user
DB_PASSWORD=$DB_PASSWORD
DB_NAME=filltech_odoo

# Odoo admin password
ODOO_ADMIN_PASSWORD=$ADMIN_PASSWORD

# Ports
ODOO_PORT=8069
ODOO_CHAT_PORT=8072
POSTGRES_PORT=5432
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# Environment
ODOO_ENV=production
ODOO_LOG_LEVEL=info
ODOO_WORKERS=4
ODOO_MAX_CRON_THREADS=2

# Memory limits
ODOO_LIMIT_MEMORY_HARD=2684354560
ODOO_LIMIT_MEMORY_SOFT=2147483648

# SSL Configuration
SSL_CERT_PATH=/etc/letsencrypt/live/$DOMAIN/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/$DOMAIN/privkey.pem

# Backup
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0

# Timezone
TZ=Europe/Madrid
EOF
    
    # Copiar archivo de producción como principal
    cp .env.production .env
    
    success "Variables de entorno configuradas"
}

# Desplegar servicios
deploy_services() {
    log "Desplegando servicios Docker..."
    
    # Detener servicios anteriores si existen
    docker compose -f docker-compose.server.yml down 2>/dev/null || true
    
    # Construir y ejecutar servicios
    docker compose -f docker-compose.server.yml up -d --build
    
    success "Servicios desplegados"
}

# Verificar despliegue
verify_deployment() {
    log "Verificando despliegue..."
    
    sleep 15  # Esperar a que los servicios inicien
    
    # Verificar contenedores
    if docker compose -f docker-compose.server.yml ps | grep -q "Up"; then
        success "Contenedores ejecutándose correctamente"
    else
        error "Algunos contenedores no están ejecutándose"
    fi
    
    # Verificar conectividad HTTP
    if curl -f -s http://localhost > /dev/null; then
        success "Servicio HTTP funcionando"
    else
        warning "Servicio HTTP no responde"
    fi
    
    # Verificar SSL
    if curl -f -s -k https://$DOMAIN > /dev/null; then
        success "Servicio HTTPS funcionando"
    else
        warning "Servicio HTTPS no responde"
    fi
}

# Mostrar información final
show_info() {
    echo ""
    echo "=============================================="
    echo -e "${GREEN}🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE! 🎉${NC}"
    echo "=============================================="
    echo ""
    echo -e "${BLUE}🌐 URL del sitio:${NC} https://$DOMAIN"
    echo -e "${BLUE}👤 Usuario admin:${NC} admin"
    echo -e "${BLUE}🔑 Contraseña admin:${NC} $ADMIN_PASSWORD"
    echo -e "${BLUE}📧 Email:${NC} $EMAIL"
    echo ""
    echo -e "${YELLOW}📋 Comandos útiles:${NC}"
    echo "  - Ver logs: docker compose -f docker-compose.server.yml logs -f"
    echo "  - Reiniciar: docker compose -f docker-compose.server.yml restart"
    echo "  - Detener: docker compose -f docker-compose.server.yml down"
    echo "  - Estado: docker compose -f docker-compose.server.yml ps"
    echo ""
    echo -e "${YELLOW}🔧 Archivos importantes:${NC}"
    echo "  - Configuración: ./config/odoo.conf"
    echo "  - Variables: ./.env.production"
    echo "  - Nginx: ./nginx/nginx.conf"
    echo "  - Logs Nginx: ./nginx/logs/"
    echo "  - Backups: ./backups/"
    echo ""
    echo -e "${GREEN}✅ Tu instancia de Odoo está lista para usar!${NC}"
    echo "=============================================="
}

# Función principal
main() {
    echo ""
    echo "=============================================="
    echo -e "${BLUE}🚀 INSTALADOR AUTOMÁTICO DE ODOO 18.0${NC}"
    echo -e "${BLUE}   Ubuntu Server + Docker + Nginx + SSL${NC}"
    echo "=============================================="
    echo ""
    
    check_root
    check_system
    update_system
    install_docker
    install_nginx
    setup_firewall
    setup_odoo
    setup_ssl
    setup_env
    deploy_services
    verify_deployment
    show_info
}

# Manejo de errores
trap 'echo -e "${RED}❌ Error en línea $LINENO. Abortando instalación.${NC}"; exit 1' ERR

# Ejecutar instalación
main "$@"
