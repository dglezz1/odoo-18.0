#!/bin/bash

# Solución Rápida Error 521 - Odoo Cloudflare
# Reinicia servicios y verifica conectividad

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[FIX]${NC} $1"
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

echo "=================================================="
echo "🚨 SOLUCIÓN RÁPIDA ERROR 521 CLOUDFLARE"
echo "=================================================="

# Paso 1: Verificar ubicación
print_status "Verificando ubicación del proyecto..."
if [[ ! -f "docker-compose.server.yml" ]]; then
    print_error "No estás en el directorio correcto"
    echo "Navega a: cd /opt/odoo-18.0"
    exit 1
fi
print_success "Ubicación correcta"

# Paso 2: Verificar Docker
print_status "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    print_status "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    print_success "Docker instalado - reinicia la sesión SSH"
    exit 1
fi
print_success "Docker disponible"

# Paso 3: Verificar Docker Compose
print_status "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado"
    print_status "Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose instalado"
fi
print_success "Docker Compose disponible"

# Paso 4: Verificar archivo .env.production
print_status "Verificando configuración de producción..."
if [[ ! -f ".env.production" ]]; then
    print_warning "Archivo .env.production no encontrado"
    print_status "Ejecuta primero: ./deploy-production.sh"
    exit 1
fi
print_success "Configuración encontrada"

# Paso 5: Detener servicios
print_status "Deteniendo servicios actuales..."
docker-compose -f docker-compose.server.yml down 2>/dev/null || true
print_success "Servicios detenidos"

# Paso 6: Limpiar contenedores
print_status "Limpiando contenedores antiguos..."
docker system prune -f 2>/dev/null || true
print_success "Limpieza completada"

# Paso 7: Verificar/crear directorios
print_status "Verificando directorios..."
mkdir -p ./data/{odoo,postgresql,nginx/conf.d,certbot/{conf,www}}
print_success "Directorios verificados"

# Paso 8: Iniciar servicios base
print_status "Iniciando PostgreSQL y Redis..."
docker-compose -f docker-compose.server.yml --env-file .env.production up -d db redis
sleep 15
print_success "Base de datos y cache iniciados"

# Paso 9: Iniciar Odoo
print_status "Iniciando Odoo..."
docker-compose -f docker-compose.server.yml --env-file .env.production up -d odoo
sleep 30
print_success "Odoo iniciado"

# Paso 10: Verificar Odoo
print_status "Verificando Odoo..."
for i in {1..12}; do
    if curl -s http://localhost:8069 >/dev/null; then
        print_success "Odoo responde correctamente"
        break
    fi
    if [[ $i -eq 12 ]]; then
        print_error "Odoo no responde después de 60 segundos"
        echo "Verifica logs: docker-compose -f docker-compose.server.yml logs odoo"
        exit 1
    fi
    echo -n "."
    sleep 5
done

# Paso 11: Configurar firewall
print_status "Configurando firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80
    sudo ufw allow 443
    print_success "Firewall configurado"
else
    print_warning "UFW no disponible - instala: sudo apt install ufw"
fi

# Paso 12: Iniciar Nginx
print_status "Iniciando Nginx..."
docker-compose -f docker-compose.server.yml --env-file .env.production up -d nginx
sleep 10
print_success "Nginx iniciado"

# Paso 13: Verificaciones finales
print_status "Verificaciones finales..."
echo
echo "=== ESTADO DE SERVICIOS ==="
docker-compose -f docker-compose.server.yml ps

echo
echo "=== TEST DE CONECTIVIDAD ==="
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
echo "IP del servidor: $SERVER_IP"

# Test puerto 80
if curl -s -o /dev/null -w "%{http_code}" -m 10 http://localhost | grep -q "200\|30[0-9]"; then
    print_success "Puerto 80 - OK"
else
    print_warning "Puerto 80 - No responde"
fi

# Test puerto 443
if curl -k -s -o /dev/null -w "%{http_code}" -m 10 https://localhost | grep -q "200\|30[0-9]"; then
    print_success "Puerto 443 - OK"
else
    print_warning "Puerto 443 - No responde (SSL puede no estar configurado)"
fi

# Test Odoo directo
if curl -s -o /dev/null -w "%{http_code}" -m 10 http://localhost:8069 | grep -q "200\|30[0-9]"; then
    print_success "Odoo (8069) - OK"
else
    print_error "Odoo (8069) - No responde"
fi

echo
echo "=================================================="
echo "🎯 PRÓXIMOS PASOS"
echo "=================================================="

print_status "1. Verificar que los servicios estén ejecutándose:"
echo "   docker-compose -f docker-compose.server.yml ps"
echo

print_status "2. Si el Error 521 persiste, verificar logs:"
echo "   docker-compose -f docker-compose.server.yml logs nginx"
echo "   docker-compose -f docker-compose.server.yml logs odoo"
echo

print_status "3. Temporalmente desactivar proxy Cloudflare:"
echo "   • Cloudflare Dashboard > DNS Records"
echo "   • Registro 'odoo' cambiar de Proxied (🟠) a DNS only (⚪)"
echo "   • Esperar 5 minutos y probar"
echo

print_status "4. Si funciona sin proxy, el problema es SSL:"
echo "   • Ejecutar: ./deploy-production.sh (configurará SSL automáticamente)"
echo

print_status "5. Reactivar proxy Cloudflare una vez solucionado"
echo

if [[ "$SERVER_IP" != "unknown" ]]; then
    print_success "Prueba acceso directo: http://$SERVER_IP"
    print_success "Una vez funcione, vuelve a activar proxy Cloudflare"
fi

echo "=================================================="
print_success "🚀 Solución rápida completada"
echo "=================================================="
