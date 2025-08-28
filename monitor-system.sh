#!/bin/bash
# Script de monitoreo para Odoo en Ubuntu Server

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================"
echo "🔍 ESTADO DEL SISTEMA ODOO"
echo "======================================"

# Verificar servicios Docker
echo -e "\n${YELLOW}🐳 Estado de contenedores Docker:${NC}"
docker compose -f docker-compose.server.yml ps

# Verificar uso de recursos
echo -e "\n${YELLOW}📊 Uso de recursos:${NC}"
echo "CPU y Memoria:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Verificar espacio en disco
echo -e "\n${YELLOW}💾 Espacio en disco:${NC}"
df -h | grep -E "/$|/var"

# Verificar conectividad
echo -e "\n${YELLOW}🌐 Conectividad:${NC}"
if curl -s -o /dev/null -w "%{http_code}" https://odoo.filltech-ai.com | grep -q "200"; then
    echo -e "${GREEN}✅ Sitio web accesible${NC}"
else
    echo -e "${RED}❌ Sitio web no accesible${NC}"
fi

# Verificar certificado SSL
echo -e "\n${YELLOW}🔒 Estado del certificado SSL:${NC}"
if openssl s_client -connect odoo.filltech-ai.com:443 -servername odoo.filltech-ai.com < /dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
    echo -e "${GREEN}✅ Certificado SSL válido${NC}"
else
    echo -e "${RED}❌ Problema con certificado SSL${NC}"
fi

# Verificar logs de errores recientes
echo -e "\n${YELLOW}📝 Errores recientes en logs:${NC}"
if docker compose -f docker-compose.server.yml logs --tail=10 2>/dev/null | grep -i error; then
    echo -e "${RED}❌ Se encontraron errores en los logs${NC}"
else
    echo -e "${GREEN}✅ No se encontraron errores recientes${NC}"
fi

# Verificar backups
echo -e "\n${YELLOW}💾 Estado de backups:${NC}"
BACKUP_COUNT=$(find ./backups -name "backup_*.sql" -mtime -1 | wc -l)
if [ $BACKUP_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Backup reciente encontrado${NC}"
    ls -la ./backups/backup_*.sql | tail -1
else
    echo -e "${YELLOW}⚠️  No se encontraron backups recientes${NC}"
fi

echo -e "\n======================================"
echo "📈 Resumen del sistema:"
echo "======================================"

# Uptime del sistema
echo "⏱️  Tiempo activo: $(uptime -p)"

# Load average
echo "📊 Carga del sistema: $(uptime | awk -F'load average:' '{print $2}')"

# Memoria libre
echo "🧠 Memoria libre: $(free -h | awk '/^Mem:/ {print $7}')"

echo -e "\n${GREEN}✅ Monitoreo completado${NC}"
