#!/bin/bash

# Diagnóstico Error 521 Cloudflare - Odoo
# Error: Web server is down

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="odoo.filltech-ai.com"

print_header() {
    echo "=================================================="
    echo "🚨 DIAGNÓSTICO ERROR 521 CLOUDFLARE"
    echo "=================================================="
    echo "🌐 Dominio: $DOMAIN"
    echo "❌ Error: Web server is down"
    echo "⏰ Timestamp: 2025-09-01 15:50:13 UTC"
    echo "=================================================="
}

print_status() {
    echo -e "${BLUE}[DIAGNÓSTICO]${NC} $1"
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

check_server_ip() {
    print_status "Verificando IP del servidor..."
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "unknown")
    print_status "IP actual del servidor: $SERVER_IP"
    
    # Verificar DNS
    CLOUDFLARE_IP=$(nslookup $DOMAIN 8.8.8.8 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' 2>/dev/null || echo "no-resolve")
    print_status "IP en Cloudflare: $CLOUDFLARE_IP"
    
    if [[ "$CLOUDFLARE_IP" == "no-resolve" ]]; then
        print_error "DNS no resuelve"
        return 1
    elif [[ "$SERVER_IP" == "unknown" ]]; then
        print_error "No se puede determinar IP del servidor"
        return 1
    else
        print_success "IPs identificadas correctamente"
    fi
}

check_docker_services() {
    print_status "Verificando servicios Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        return 1
    fi
    
    echo "Estado de contenedores:"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(odoo|nginx)" 2>/dev/null; then
        print_success "Contenedores encontrados"
    else
        print_error "No hay contenedores de Odoo/Nginx ejecutándose"
        return 1
    fi
}

check_ports() {
    print_status "Verificando puertos críticos..."
    
    # Puerto 80
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        print_success "Puerto 80 en uso"
        netstat -tuln | grep ":80 " | head -1
    else
        print_error "Puerto 80 no está escuchando"
    fi
    
    # Puerto 443
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        print_success "Puerto 443 en uso"
        netstat -tuln | grep ":443 " | head -1
    else
        print_error "Puerto 443 no está escuchando"
    fi
    
    # Puerto 8069 (Odoo)
    if netstat -tuln 2>/dev/null | grep -q ":8069 "; then
        print_success "Puerto 8069 (Odoo) en uso"
    else
        print_error "Puerto 8069 (Odoo) no está escuchando"
    fi
}

check_firewall() {
    print_status "Verificando configuración de firewall..."
    
    if command -v ufw &> /dev/null; then
        echo "Estado UFW:"
        sudo ufw status verbose | head -10
        
        if sudo ufw status | grep -q "80.*ALLOW"; then
            print_success "Puerto 80 permitido en firewall"
        else
            print_error "Puerto 80 bloqueado en firewall"
        fi
        
        if sudo ufw status | grep -q "443.*ALLOW"; then
            print_success "Puerto 443 permitido en firewall"
        else
            print_error "Puerto 443 bloqueado en firewall"
        fi
    else
        print_warning "UFW no está instalado"
    fi
}

check_nginx() {
    print_status "Verificando Nginx..."
    
    # Verificar contenedor Nginx
    if docker ps | grep -q nginx; then
        print_success "Contenedor Nginx ejecutándose"
        
        # Verificar configuración
        if docker exec $(docker ps -q --filter "name=nginx") nginx -t 2>/dev/null; then
            print_success "Configuración Nginx válida"
        else
            print_error "Error en configuración Nginx"
            return 1
        fi
    else
        print_error "Contenedor Nginx no está ejecutándose"
        return 1
    fi
}

check_odoo() {
    print_status "Verificando Odoo..."
    
    if docker ps | grep -q odoo; then
        print_success "Contenedor Odoo ejecutándose"
        
        # Test de conectividad interna
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8069 | grep -q "200\|30[0-9]"; then
            print_success "Odoo responde internamente"
        else
            print_warning "Odoo no responde o está iniciando"
        fi
    else
        print_error "Contenedor Odoo no está ejecutándose"
        return 1
    fi
}

test_direct_connection() {
    print_status "Probando conexión directa al servidor..."
    
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null)
    
    # Test HTTP directo
    if curl -s -o /dev/null -w "%{http_code}" -m 10 "http://$SERVER_IP" | grep -q "200\|30[0-9]"; then
        print_success "HTTP directo funciona (puerto 80)"
    else
        print_error "HTTP directo falla (puerto 80)"
    fi
    
    # Test HTTPS directo (puede fallar por SSL)
    if curl -k -s -o /dev/null -w "%{http_code}" -m 10 "https://$SERVER_IP" | grep -q "200\|30[0-9]"; then
        print_success "HTTPS directo funciona (puerto 443)"
    else
        print_warning "HTTPS directo falla (puerto 443) - posible problema SSL"
    fi
}

show_logs() {
    print_status "Últimos logs relevantes..."
    
    echo
    echo "=== LOGS NGINX ==="
    if docker ps -q --filter "name=nginx" | head -1 | xargs docker logs --tail=10 2>/dev/null; then
        :
    else
        echo "No hay logs de Nginx disponibles"
    fi
    
    echo
    echo "=== LOGS ODOO ==="
    if docker ps -q --filter "name=odoo" | head -1 | xargs docker logs --tail=10 2>/dev/null; then
        :
    else
        echo "No hay logs de Odoo disponibles"
    fi
}

suggest_fixes() {
    echo
    echo "=================================================="
    echo "🔧 POSIBLES SOLUCIONES"
    echo "=================================================="
    
    echo -e "${YELLOW}1. Verificar y reiniciar servicios:${NC}"
    echo "   cd /opt/odoo-18.0"
    echo "   docker-compose -f docker-compose.server.yml ps"
    echo "   docker-compose -f docker-compose.server.yml restart"
    echo
    
    echo -e "${YELLOW}2. Si los servicios no están ejecutándose:${NC}"
    echo "   cd /opt/odoo-18.0"
    echo "   docker-compose -f docker-compose.server.yml down"
    echo "   docker-compose -f docker-compose.server.yml --env-file .env.production up -d"
    echo
    
    echo -e "${YELLOW}3. Verificar configuración de firewall:${NC}"
    echo "   sudo ufw status"
    echo "   sudo ufw allow 80"
    echo "   sudo ufw allow 443"
    echo
    
    echo -e "${YELLOW}4. Si el problema persiste, hacer deploy completo:${NC}"
    echo "   cd /opt/odoo-18.0"
    echo "   ./deploy-production.sh"
    echo
    
    echo -e "${YELLOW}5. Temporalmente, desactivar proxy Cloudflare:${NC}"
    echo "   - Ve a Cloudflare Dashboard"
    echo "   - Busca el registro DNS 'odoo'"
    echo "   - Cambia de 'Proxied' (naranja) a 'DNS only' (gris)"
    echo "   - Espera 5 minutos y prueba"
    echo
}

main() {
    print_header
    
    echo "🔍 Ejecutando diagnóstico completo..."
    echo
    
    # Ejecutar todas las verificaciones
    check_server_ip || true
    echo
    check_docker_services || true
    echo  
    check_ports || true
    echo
    check_firewall || true
    echo
    check_nginx || true
    echo
    check_odoo || true
    echo
    test_direct_connection || true
    echo
    show_logs
    
    suggest_fixes
}

# Ejecutar diagnóstico
main
