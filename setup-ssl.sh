#!/bin/bash
# Script para configurar SSL con Let's Encrypt para odoo.filltech-ai.com

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="odoo.filltech-ai.com"
EMAIL="admin@filltech-ai.com"

echo -e "${GREEN}🔒 Configurando SSL para ${DOMAIN}${NC}"

# Verificar que el dominio resuelve correctamente
echo -e "${YELLOW}📡 Verificando resolución DNS...${NC}"
if nslookup $DOMAIN > /dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS configurado correctamente${NC}"
else
    echo -e "${RED}❌ Error: El dominio no resuelve. Verifica la configuración en Cloudflare${NC}"
    exit 1
fi

# Detener nginx temporalmente
echo -e "${YELLOW}⏸️  Deteniendo Nginx temporalmente...${NC}"
sudo systemctl stop nginx

# Obtener certificado usando standalone
echo -e "${YELLOW}📜 Obteniendo certificado SSL de Let's Encrypt...${NC}"
sudo certbot certonly \
    --standalone \
    --preferred-challenges http \
    -d $DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal

# Verificar que el certificado se obtuvo correctamente
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}✅ Certificado SSL obtenido correctamente${NC}"
else
    echo -e "${RED}❌ Error al obtener el certificado SSL${NC}"
    exit 1
fi

# Reiniciar nginx
echo -e "${YELLOW}🔄 Reiniciando Nginx...${NC}"
sudo systemctl start nginx
sudo systemctl status nginx --no-pager -l

# Configurar renovación automática
echo -e "${YELLOW}🔄 Configurando renovación automática...${NC}"
sudo crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'"; } | sudo crontab -

# Verificar certificado
echo -e "${YELLOW}🔍 Verificando certificado...${NC}"
sudo certbot certificates

echo -e "${GREEN}🎉 Configuración SSL completada!${NC}"
echo -e "${GREEN}🌐 Tu sitio ahora está disponible en: https://${DOMAIN}${NC}"

# Mostrar información del certificado
echo -e "${YELLOW}📋 Información del certificado:${NC}"
sudo openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -text -noout | grep -E "(Subject|Issuer|Not Before|Not After)"
