#!/bin/bash

# Configuración de DNS en Cloudflare para Odoo 18.0
# Dominio: odoo.filltech-ai.com

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="odoo.filltech-ai.com"
ZONE="filltech-ai.com"
SUBDOMAIN="odoo"

print_header() {
    echo "=================================================="
    echo "☁️  CONFIGURACIÓN DNS CLOUDFLARE"
    echo "=================================================="
    echo "🌐 Dominio: $DOMAIN"
    echo "🔍 Zona: $ZONE"
    echo "📡 Subdominio: $SUBDOMAIN"
    echo "=================================================="
}

print_status() {
    echo -e "${BLUE}[DNS]${NC} $1"
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

get_server_ip() {
    print_status "Obteniendo IP pública del servidor..."
    
    # Intentar diferentes servicios para obtener la IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    
    if [[ -z "$SERVER_IP" ]]; then
        print_error "No se pudo obtener la IP del servidor"
        print_warning "Introduce manualmente la IP de tu servidor:"
        read -r SERVER_IP
    fi
    
    print_success "IP del servidor: $SERVER_IP"
    echo "SERVER_IP=$SERVER_IP" > .server-ip
}

check_cloudflare_credentials() {
    print_status "Verificando credenciales de Cloudflare..."
    
    if [[ -z "${CF_API_TOKEN:-}" ]] && [[ -z "${CF_API_KEY:-}" ]]; then
        print_warning "Credenciales de Cloudflare no encontradas"
        print_status "Necesitas configurar una de estas opciones:"
        echo
        echo "OPCIÓN 1 - API Token (Recomendado):"
        echo "1. Ve a https://dash.cloudflare.com/profile/api-tokens"
        echo "2. Crea un token con permisos: Zone:Zone:Read, Zone:DNS:Edit"
        echo "3. Exporta: export CF_API_TOKEN='tu_token_aqui'"
        echo
        echo "OPCIÓN 2 - API Key Global:"
        echo "1. Ve a https://dash.cloudflare.com/profile/api-tokens"
        echo "2. Copia tu Global API Key"
        echo "3. Exporta: export CF_API_KEY='tu_key' && export CF_EMAIL='tu@email.com'"
        echo
        exit 1
    fi
    
    print_success "Credenciales de Cloudflare configuradas"
}

get_zone_id() {
    print_status "Obteniendo Zone ID de Cloudflare..."
    
    if [[ -n "${CF_API_TOKEN:-}" ]]; then
        ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" | \
            jq -r '.result[0].id // empty')
    else
        ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE" \
            -H "X-Auth-Email: $CF_EMAIL" \
            -H "X-Auth-Key: $CF_API_KEY" \
            -H "Content-Type: application/json" | \
            jq -r '.result[0].id // empty')
    fi
    
    if [[ -z "$ZONE_ID" ]] || [[ "$ZONE_ID" == "null" ]]; then
        print_error "No se pudo obtener el Zone ID para $ZONE"
        print_warning "Verifica que:"
        print_warning "• El dominio $ZONE esté en tu cuenta de Cloudflare"
        print_warning "• Las credenciales sean correctas"
        print_warning "• Tengas permisos sobre la zona"
        exit 1
    fi
    
    print_success "Zone ID obtenido: $ZONE_ID"
}

create_dns_record() {
    print_status "Creando/actualizando registro DNS..."
    
    # Verificar si el registro ya existe
    if [[ -n "${CF_API_TOKEN:-}" ]]; then
        EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=A" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" | \
            jq -r '.result[0].id // empty')
    else
        EXISTING_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=A" \
            -H "X-Auth-Email: $CF_EMAIL" \
            -H "X-Auth-Key: $CF_API_KEY" \
            -H "Content-Type: application/json" | \
            jq -r '.result[0].id // empty')
    fi
    
    DNS_DATA='{
        "type": "A",
        "name": "'$SUBDOMAIN'",
        "content": "'$SERVER_IP'",
        "ttl": 300,
        "proxied": true
    }'
    
    if [[ -n "$EXISTING_RECORD" ]] && [[ "$EXISTING_RECORD" != "null" ]]; then
        print_status "Actualizando registro DNS existente..."
        
        if [[ -n "${CF_API_TOKEN:-}" ]]; then
            RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" \
                --data "$DNS_DATA")
        else
            RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_RECORD" \
                -H "X-Auth-Email: $CF_EMAIL" \
                -H "X-Auth-Key: $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "$DNS_DATA")
        fi
    else
        print_status "Creando nuevo registro DNS..."
        
        if [[ -n "${CF_API_TOKEN:-}" ]]; then
            RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" \
                --data "$DNS_DATA")
        else
            RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                -H "X-Auth-Email: $CF_EMAIL" \
                -H "X-Auth-Key: $CF_API_KEY" \
                -H "Content-Type: application/json" \
                --data "$DNS_DATA")
        fi
    fi
    
    SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')
    
    if [[ "$SUCCESS" == "true" ]]; then
        print_success "Registro DNS configurado correctamente"
        print_success "✓ $DOMAIN -> $SERVER_IP (Proxied)"
    else
        print_error "Error al configurar DNS:"
        echo "$RESPONSE" | jq -r '.errors[0].message // "Error desconocido"'
        exit 1
    fi
}

verify_dns_propagation() {
    print_status "Verificando propagación de DNS..."
    
    print_warning "Esperando propagación de DNS (puede tardar hasta 5 minutos)..."
    
    for i in {1..30}; do
        RESOLVED_IP=$(nslookup $DOMAIN 8.8.8.8 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' 2>/dev/null || echo "")
        
        if [[ -n "$RESOLVED_IP" ]]; then
            if [[ "$RESOLVED_IP" != "$SERVER_IP" ]]; then
                print_success "DNS propagado correctamente"
                print_warning "Cloudflare Proxy detectado: $DOMAIN -> $RESOLVED_IP (Proxy IP)"
                print_success "Configuración correcta - Cloudflare hará proxy a tu servidor"
                break
            else
                print_success "DNS propagado correctamente: $DOMAIN -> $RESOLVED_IP"
                break
            fi
        fi
        
        if [[ $i -eq 30 ]]; then
            print_warning "DNS aún no se ha propagado completamente"
            print_warning "Puedes continuar - la propagación seguirá en segundo plano"
        else
            sleep 10
            echo -n "."
        fi
    done
    echo
}

show_next_steps() {
    echo
    print_success "🎉 DNS configurado correctamente!"
    echo
    print_status "📋 Información de configuración:"
    echo "• Dominio: $DOMAIN"
    echo "• IP Servidor: $SERVER_IP" 
    echo "• Cloudflare Proxy: ✅ Habilitado"
    echo "• SSL: Se configurará automáticamente"
    echo
    print_warning "🚀 Próximos pasos:"
    echo "1. Ejecuta el deployment: ./deploy-production.sh"
    echo "2. El script configurará automáticamente:"
    echo "   • Docker y servicios"
    echo "   • Nginx con proxy"
    echo "   • SSL con Let's Encrypt"
    echo "   • Firewall"
    echo "3. Tu Odoo estará disponible en: https://$DOMAIN"
    echo
    print_warning "⚠️  Importante:"
    echo "• Mantén las credenciales de Cloudflare seguras"
    echo "• El SSL se configurará automáticamente con Let's Encrypt"
    echo "• Cloudflare proporcionará protección DDoS adicional"
}

main() {
    print_header
    
    # Verificar dependencias
    if ! command -v jq &> /dev/null; then
        print_status "Instalando jq..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            print_error "Instala jq manualmente: https://stedolan.github.io/jq/download/"
            exit 1
        fi
    fi
    
    get_server_ip
    check_cloudflare_credentials
    get_zone_id
    create_dns_record
    verify_dns_propagation
    show_next_steps
}

# Manejar argumentos
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Uso: $0 [help]"
        echo "Configura DNS en Cloudflare para $DOMAIN"
        echo
        echo "Requisitos:"
        echo "• Dominio $ZONE gestionado por Cloudflare"
        echo "• API Token o API Key de Cloudflare configurado"
        echo "• jq instalado (se instala automáticamente)"
        echo
        echo "Variables de entorno necesarias:"
        echo "  CF_API_TOKEN='tu_token'  (recomendado)"
        echo "  O"
        echo "  CF_API_KEY='tu_key' y CF_EMAIL='tu@email.com'"
        echo
        echo "Ejemplo:"
        echo "  export CF_API_TOKEN='tu_token_de_cloudflare'"
        echo "  $0"
        exit 0
        ;;
    *)
        main
        ;;
esac
