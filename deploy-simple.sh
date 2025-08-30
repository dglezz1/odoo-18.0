#!/bin/bash
# Deploy Simple Local - Solo Docker Compose básico sin healthchecks complicados

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[ODOO SIMPLE]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Limpiar todo anterior
log "Limpiando contenedores anteriores..."
docker compose -f docker-compose.local.yml down -v 2>/dev/null || true

# Iniciar servicios
log "Iniciando servicios básicos..."
docker compose -f docker-compose.local.yml up -d

log "Esperando 30 segundos para que los servicios inicien..."
sleep 30

# Verificar estado
log "Estado de contenedores:"
docker compose -f docker-compose.local.yml ps

# Verificar conectividad
log "Verificando conectividad..."
if curl -s -f http://localhost:8069/web/database/manager > /dev/null 2>&1; then
    success "¡Odoo está funcionando!"
    echo ""
    echo "🌐 Accede a: http://localhost:8069"
    echo "🛢️ Gestor de BD: http://localhost:8069/web/database/manager"
    echo "👤 Para crear BD usa: admin@odoo.local / admin123"
    echo "🔑 Master password: master123"
elif curl -s http://localhost:8069 | grep -q "500\|error" 2>/dev/null; then
    echo "⚠️ Odoo responde pero hay errores. Revisa los logs:"
    echo "docker compose -f docker-compose.local.yml logs odoo"
else
    echo "❌ Odoo no responde. Revisa los logs:"
    echo "docker compose -f docker-compose.local.yml logs odoo"
fi
