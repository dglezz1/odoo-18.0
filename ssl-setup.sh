#!/bin/bash

# Script para configurar SSL automáticamente con Let's Encrypt
# Uso: ./ssl-setup.sh tu-dominio.com tu-email@dominio.com

set -e

DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Uso: $0 <dominio> <email>"
    echo "Ejemplo: $0 mi-odoo.com admin@mi-odoo.com"
    exit 1
fi

echo "🔒 Configurando SSL para $DOMAIN..."

# Crear directorio para webroot
mkdir -p nginx/certbot-webroot

# Crear configuración temporal de Nginx para validación
cat > nginx/nginx.temp.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://\$server_name\$request_uri;
        }
    }
}
EOF

# Iniciar Nginx temporal para validación
docker run -d --name nginx-temp \
    -p 80:80 \
    -v $(pwd)/nginx/nginx.temp.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/nginx/certbot-webroot:/var/www/certbot \
    nginx:alpine

echo "📋 Obteniendo certificados SSL..."

# Obtener certificados
docker run --rm -it \
    -v $(pwd)/nginx/ssl:/etc/letsencrypt \
    -v $(pwd)/nginx/certbot-webroot:/var/www/certbot \
    certbot/certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --force-renewal \
    --email $EMAIL \
    -d $DOMAIN \
    --agree-tos \
    --no-eff-email

# Detener Nginx temporal
docker stop nginx-temp && docker rm nginx-temp

# Actualizar variables de entorno
sed -i.bak "s/DOMAIN=.*/DOMAIN=$DOMAIN/" .env.prod
sed -i.bak "s/SSL_EMAIL=.*/SSL_EMAIL=$EMAIL/" .env.prod

echo "✅ Certificados SSL configurados exitosamente!"
echo "🚀 Ahora puedes iniciar el sistema de producción:"
echo "   ./deploy-prod.sh init"
