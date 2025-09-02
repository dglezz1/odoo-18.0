#!/bin/bash

# Deploy Local Simple - Odoo 18.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "=================================================="
echo "🚀 ODOO 18.0 - DEPLOY LOCAL"
echo "=================================================="

# Verificar Docker
print_status "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose no está instalado"
    exit 1
fi
print_success "Docker está disponible"

# Limpiar contenedores previos
print_status "Limpiando deployment anterior..."
docker-compose down -v 2>/dev/null || true
docker system prune -f
print_success "Limpieza completada"

# Construir imagen
print_status "Construyendo imagen Odoo..."
docker-compose build --no-cache
print_success "Imagen construida"

# Iniciar servicios
print_status "Iniciando servicios..."
docker-compose up -d
print_success "Servicios iniciados"

# Esperar a que PostgreSQL esté listo
print_status "Esperando PostgreSQL..."
sleep 20

# Verificar servicios
print_status "Verificando servicios..."
docker-compose ps

echo
echo "=================================================="
echo "🎉 DEPLOY COMPLETADO"
echo "=================================================="

# Información de acceso
echo -e "${GREEN}✅ Odoo disponible en:${NC}"
echo "   🌐 http://localhost:8069"
echo "   👤 Usuario: admin"
echo "   🔑 Contraseña: admin"
echo "   🗄️ Base de datos: odoo"
echo

echo -e "${BLUE}📋 Comandos útiles:${NC}"
echo "   Ver logs: docker-compose logs -f"
echo "   Parar: docker-compose down"
echo "   Reiniciar: docker-compose restart"
echo "   Estado: docker-compose ps"

echo
print_success "¡Odoo 18.0 está listo!"
