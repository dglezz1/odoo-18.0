#!/bin/bash
# Script para generar certificados SSL auto-firmados para desarrollo

CERT_DIR="nginx/ssl"
DAYS=365
COUNTRY="ES"
STATE="Madrid"
CITY="Madrid"
ORG="Odoo Development"
ORG_UNIT="IT"
COMMON_NAME="localhost"

echo "Generating SSL certificates for development..."

# Crear directorio si no existe
mkdir -p $CERT_DIR

# Generar clave privada
openssl genrsa -out $CERT_DIR/server.key 2048

# Generar certificado auto-firmado
openssl req -new -x509 -key $CERT_DIR/server.key -out $CERT_DIR/server.crt -days $DAYS -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$ORG_UNIT/CN=$COMMON_NAME"

# Establecer permisos correctos
chmod 600 $CERT_DIR/server.key
chmod 644 $CERT_DIR/server.crt

echo "SSL certificates generated successfully!"
echo "Certificate: $CERT_DIR/server.crt"
echo "Private key: $CERT_DIR/server.key"
echo ""
echo "Note: These are self-signed certificates for development only."
echo "For production, use certificates from a trusted CA."
