#!/bin/bash

# Deploy de Producción para Odoo 18.0
# Dominio: odoo.filltech-ai.com

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="odoo.filltech-ai.com"
EMAIL="admin@filltech-ai.com" # Cambia por tu email para Let's Encrypt

print_header() {
    echo "=================================================="
    echo "🚀 DEPLOY PRODUCCIÓN ODOO 18.0"
    echo "=================================================="
    echo "🌐 Dominio: $DOMAIN"
    echo "📧 Email SSL: $EMAIL"
    echo "=================================================="
}

print_status() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_server() {
    print_status "Verificando que estamos en el servidor..."
    
    # Verificar si estamos en un servidor Ubuntu
    if [[ ! -f /etc/ubuntu-release ]] && [[ ! -f /etc/lsb-release ]]; then
        print_warning "No detectado Ubuntu Server. ¿Continuar? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelado"
            exit 1
        fi
    fi
    
    print_success "Verificación de servidor completada"
}

check_domain_dns() {
    print_status "Verificando DNS del dominio $DOMAIN..."
    
    # Obtener IP pública del servidor
    SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
    print_status "IP del servidor: $SERVER_IP"
    
    # Verificar DNS
    DOMAIN_IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}' || echo "")
    
    if [[ "$DOMAIN_IP" == "$SERVER_IP" ]]; then
        print_success "DNS configurado correctamente: $DOMAIN -> $SERVER_IP"
    else
        print_warning "DNS no apunta a este servidor"
        print_warning "Dominio apunta a: $DOMAIN_IP"
        print_warning "Servidor IP: $SERVER_IP"
        print_warning "¿Continuar de todas formas? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Configura tu DNS primero. En Cloudflare:"
            echo "   Tipo: A"
            echo "   Nombre: odoo"
            echo "   Contenido: $SERVER_IP"
            echo "   Proxy: Naranja (Proxied)"
            exit 1
        fi
    fi
}

prepare_server() {
    print_status "Preparando servidor para Odoo..."
    
    # Actualizar sistema
    print_status "Actualizando sistema..."
    sudo apt update && sudo apt upgrade -y
    
    # Instalar dependencias básicas
    print_status "Instalando dependencias..."
    sudo apt install -y curl wget git nginx certbot python3-certbot-nginx
    
    # Instalar Docker si no está instalado
    if ! command -v docker &> /dev/null; then
        print_status "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi
    
    # Instalar Docker Compose si no está instalado
    if ! command -v docker-compose &> /dev/null; then
        print_status "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    print_success "Servidor preparado"
}

setup_firewall() {
    print_status "Configurando firewall..."
    
    # Habilitar UFW si no está activo
    sudo ufw --force enable
    
    # Configurar reglas básicas
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Permitir SSH, HTTP, HTTPS
    sudo ufw allow ssh
    sudo ufw allow 80
    sudo ufw allow 443
    
    # Permitir puertos específicos de Odoo (solo desde localhost)
    sudo ufw allow from 127.0.0.1 to any port 8069
    
    print_success "Firewall configurado"
}

create_production_env() {
    print_status "Creando archivo de entorno de producción..."
    
    # Generar contraseñas seguras
    DB_PASSWORD=$(openssl rand -base64 32)
    ADMIN_PASSWORD=$(openssl rand -base64 16)
    
    cat > .env.production << EOF
# ==============================================
# PRODUCCIÓN - Odoo 18.0
# ==============================================
# ⚠️  MANTENER SEGURO - NO COMMITEAR A GIT

# Domain
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# PostgreSQL
POSTGRES_DB=odoo_prod
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$DB_PASSWORD
POSTGRES_PORT=5432

# Odoo
ODOO_ADMIN_PASSWORD=$ADMIN_PASSWORD
ODOO_DB_HOST=db
ODOO_DB_PORT=5432
ODOO_DB_USER=odoo
ODOO_DB_PASSWORD=$DB_PASSWORD

# Nginx
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# SSL
SSL_EMAIL=$EMAIL

# Performance
WORKERS=4
MAX_CRON_THREADS=2
DB_MAXCONN=64

EOF

    chmod 600 .env.production
    
    print_success "Archivo .env.production creado"
    print_warning "ADMIN PASSWORD: $ADMIN_PASSWORD"
    print_warning "DB PASSWORD: $DB_PASSWORD"
    print_warning "⚠️  GUARDA ESTAS CONTRASEÑAS EN UN LUGAR SEGURO"
}

deploy_odoo() {
    print_status "Desplegando Odoo en producción..."
    
    # Detener servicios existentes
    docker-compose -f docker-compose.server.yml down 2>/dev/null || true
    
    # Limpiar contenedores antiguos
    docker system prune -af
    
    # Crear directorios necesarios
    mkdir -p ./data/odoo
    mkdir -p ./data/postgresql
    mkdir -p ./data/nginx/conf.d
    mkdir -p ./data/certbot/conf
    mkdir -p ./data/certbot/www
    
    # Crear configuración inicial de Nginx
    create_nginx_config
    
    # Iniciar servicios
    docker-compose -f docker-compose.server.yml --env-file .env.production up -d db redis
    
    print_status "Esperando a que PostgreSQL esté listo..."
    sleep 30
    
    # Iniciar Odoo
    docker-compose -f docker-compose.server.yml --env-file .env.production up -d odoo
    
    print_status "Esperando a que Odoo esté listo..."
    sleep 60
    
    # Iniciar Nginx
    docker-compose -f docker-compose.server.yml --env-file .env.production up -d nginx
    
    print_success "Odoo desplegado"
}

create_nginx_config() {
    print_status "Creando configuración de Nginx..."
    
    cat > ./nginx/conf.d/odoo.conf << EOF
# Configuración Nginx para Odoo - Producción
upstream odoo {
    server odoo:8069;
}

upstream odoochat {
    server odoo:8072;
}

# HTTP - Redirección a HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Proxy settings
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_redirect off;
    
    # File upload size
    client_max_body_size 200m;
    
    # Gzip compression
    gzip on;
    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    
    # Main Odoo location
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
    
    # Odoo chat
    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
    
    # Static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
    
    # Common static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        proxy_pass http://odoo;
    }
}
EOF

    print_success "Configuración de Nginx creada"
}

setup_ssl() {
    print_status "Configurando SSL con Let's Encrypt..."
    
    # Detener Nginx temporalmente
    docker-compose -f docker-compose.server.yml stop nginx 2>/dev/null || true
    
    # Obtener certificado SSL
    docker run --rm -v "$(pwd)/data/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/data/certbot/www:/var/www/certbot" \
        -p 80:80 certbot/certbot certonly --standalone \
        --email $EMAIL --agree-tos --no-eff-email \
        -d $DOMAIN
    
    # Reiniciar Nginx
    docker-compose -f docker-compose.server.yml --env-file .env.production up -d nginx
    
    print_success "SSL configurado"
}

setup_auto_renewal() {
    print_status "Configurando renovación automática de SSL..."
    
    # Crear script de renovación
    cat > /tmp/renew-ssl.sh << 'EOF'
#!/bin/bash
cd /opt/odoo
docker run --rm -v "$(pwd)/data/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/data/certbot/www:/var/www/certbot" \
    certbot/certbot renew --quiet
docker-compose -f docker-compose.server.yml restart nginx
EOF
    
    sudo mv /tmp/renew-ssl.sh /etc/cron.daily/renew-ssl
    sudo chmod +x /etc/cron.daily/renew-ssl
    
    print_success "Renovación automática configurada"
}

show_final_info() {
    print_status "¡Deployment completado!"
    echo
    print_success "🌐 Tu Odoo está disponible en: https://$DOMAIN"
    print_success "👤 Usuario administrador: admin"
    print_success "🔑 Contraseña admin: $ADMIN_PASSWORD"
    echo
    print_warning "📋 Próximos pasos:"
    echo "1. Accede a https://$DOMAIN"
    echo "2. Inicia sesión con admin / $ADMIN_PASSWORD"
    echo "3. Configura tu instancia de Odoo"
    echo "4. Instala los módulos que necesites"
    echo
    print_warning "🔐 Información de seguridad:"
    echo "• Contraseñas guardadas en .env.production"
    echo "• Firewall configurado"
    echo "• SSL habilitado con renovación automática"
    echo "• Solo HTTPS permitido"
    echo
    print_warning "📊 Monitoreo:"
    echo "• Logs: docker-compose -f docker-compose.server.yml logs"
    echo "• Estado: docker-compose -f docker-compose.server.yml ps"
    echo "• Reiniciar: docker-compose -f docker-compose.server.yml restart"
}

main() {
    print_header
    
    # Verificaciones previas
    check_server
    check_domain_dns
    
    # Preparar servidor
    prepare_server
    setup_firewall
    
    # Configurar aplicación
    create_production_env
    deploy_odoo
    
    # Configurar SSL
    setup_ssl
    setup_auto_renewal
    
    # Información final
    show_final_info
}

# Verificar argumentos
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Uso: $0 [help]"
        echo "Deploy de producción de Odoo 18.0 en $DOMAIN"
        echo
        echo "Requisitos:"
        echo "• Ubuntu Server 20.04+ "
        echo "• DNS configurado: $DOMAIN -> IP del servidor"
        echo "• Puertos 80, 443 abiertos"
        exit 0
        ;;
    *)
        main
        ;;
esac
