#!/bin/bash
# Script para generar certificados SSL self-signed para desarrollo local

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SSL LOCAL]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log "Generando certificados SSL para desarrollo local..."

# Crear directorio SSL si no existe
mkdir -p nginx/ssl

# Generar clave privada
log "Generando clave privada..."
openssl genrsa -out nginx/ssl/localhost.key 2048

# Generar certificado auto-firmado
log "Generando certificado auto-firmado..."
openssl req -new -x509 -key nginx/ssl/localhost.key -out nginx/ssl/localhost.crt -days 365 -subj "/C=ES/ST=Madrid/L=Madrid/O=Odoo Local/OU=Development/CN=localhost/subjectAltName=DNS.1=localhost,DNS.2=odoo.local,IP.1=127.0.0.1"

# Configurar permisos
chmod 600 nginx/ssl/localhost.key
chmod 644 nginx/ssl/localhost.crt

success "Certificados SSL generados para desarrollo local"
success "Clave privada: nginx/ssl/localhost.key"
success "Certificado: nginx/ssl/localhost.crt"

echo ""
echo -e "${YELLOW}⚠️  Nota: Estos son certificados auto-firmados para desarrollo.${NC}"
echo -e "${YELLOW}   Tu navegador mostrará una advertencia de seguridad.${NC}"
echo -e "${YELLOW}   Acepta el riesgo para continuar en desarrollo local.${NC}"
