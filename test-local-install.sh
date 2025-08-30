#!/bin/bash

echo "=================================================="
echo "🧪 PRUEBAS DE LA INSTALACIÓN LOCAL DE ODOO 18.0"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local url=$1
    local description=$2
    local expected_code=$3
    
    echo -n "🔍 Probando $description... "
    
    if [[ $url == https* ]]; then
        response=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    fi
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✅ OK ($response)${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (got $response, expected $expected_code)${NC}"
        return 1
    fi
}

echo
echo "📋 Verificando estado de contenedores..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep odoo_local

echo
echo "🌐 Probando endpoints..."

# Test direct Odoo access
test_endpoint "http://localhost:8069" "Acceso directo a Odoo" "303"

# Test HTTP via Nginx (should redirect to HTTPS)
test_endpoint "http://localhost:8080" "HTTP via Nginx" "301"

# Test HTTPS via Nginx
test_endpoint "https://localhost:8443" "HTTPS via Nginx" "303"

# Test database manager
test_endpoint "https://localhost:8443/web/database/manager" "Gestor de Base de Datos" "200"

# Test database selector
test_endpoint "https://localhost:8443/web/database/selector" "Selector de Base de Datos" "200"

# Test direct database access
test_endpoint "https://localhost:8443/web?db=odoo_local" "Acceso directo a odoo_local" "303"

echo
echo "🗄️ Verificando base de datos..."
echo -n "🔍 Verificando usuarios en la base de datos... "
users=$(docker exec -it odoo_local_db psql -U odoo -d odoo_local -t -c "SELECT COUNT(*) FROM res_users WHERE active = true;" 2>/dev/null | tr -d ' \n\r')

if [ "$users" -gt "0" ]; then
    echo -e "${GREEN}✅ OK ($users usuarios activos)${NC}"
    echo "   👤 Usuarios disponibles:"
    docker exec -it odoo_local_db psql -U odoo -d odoo_local -t -c "SELECT '   - ' || login FROM res_users WHERE active = true ORDER BY login;" 2>/dev/null | sed 's/^[[:space:]]*//'
else
    echo -e "${RED}❌ FAIL (no se encontraron usuarios)${NC}"
fi

echo
echo "📊 Información de acceso:"
echo -e "${BLUE}🔗 URLs de acceso:${NC}"
echo "   • HTTP:  http://localhost:8069 (directo)"
echo "   • HTTP:  http://localhost:8080 (via Nginx, redirige a HTTPS)"
echo "   • HTTPS: https://localhost:8443 (via Nginx, recomendado)"
echo
echo -e "${BLUE}🔑 Credenciales por defecto:${NC}"
echo "   • Usuario: admin"
echo "   • Contraseña: admin (por defecto de Odoo)"
echo "   • Base de datos: odoo_local"
echo
echo -e "${BLUE}⚠️  Nota sobre SSL:${NC}"
echo "   Los certificados son auto-firmados para desarrollo."
echo "   Tu navegador mostrará una advertencia de seguridad."
echo "   Acepta el riesgo para continuar."

echo
echo -e "${GREEN}✅ Pruebas completadas${NC}"
echo "=================================================="
