#!/bin/bash

# Railway Deployment Script for Odoo 18.0
# Este script prepara el proyecto para deployment en Railway

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo "=================================================="
    echo "🚂 RAILWAY DEPLOYMENT - ODOO 18.0"
    echo "=================================================="
}

print_status() {
    echo -e "${BLUE}[RAILWAY]${NC} $1"
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

check_git_status() {
    print_status "Verificando estado de Git..."
    
    if ! git status >/dev/null 2>&1; then
        print_error "Este directorio no es un repositorio Git"
        exit 1
    fi
    
    # Verificar si hay cambios sin commit
    if ! git diff-index --quiet HEAD --; then
        print_warning "Hay cambios sin commit. Considera hacer commit antes del deployment."
        echo "Archivos modificados:"
        git status --porcelain
        echo
    fi
    
    print_success "Estado de Git verificado"
}

validate_dockerfiles() {
    print_status "Validando Dockerfiles para Railway..."
    
    # Verificar que no hay declaraciones VOLUME
    if grep -r "^VOLUME" Dockerfile* 2>/dev/null; then
        print_error "Encontradas declaraciones VOLUME en Dockerfiles - Railway las prohíbe"
        exit 1
    fi
    
    print_success "Dockerfiles validados - sin declaraciones VOLUME"
}

check_required_files() {
    print_status "Verificando archivos requeridos..."
    
    required_files=(
        "Dockerfile"
        "requirements.txt"
        "config/odoo.railway.conf"
        "railway.json"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Archivo requerido no encontrado: $file"
            exit 1
        fi
        print_success "✓ $file"
    done
}

create_railway_env_template() {
    print_status "Creando template de variables de entorno para Railway..."
    
    cat > .env.railway.template << EOF
# ==============================================
# RAILWAY ENVIRONMENT VARIABLES - TEMPLATE
# ==============================================
# Copia estas variables a tu proyecto en Railway
# Dashboard > Variables

# === REQUERIDAS ===
# Railway PostgreSQL (auto-generadas si usas Railway PostgreSQL)
DATABASE_URL=postgresql://user:password@host:port/database
PGHOST=hostname
PGPORT=5432
PGUSER=username
PGPASSWORD=password
PGDATABASE=database_name

# Odoo Admin
ADMIN_PASSWORD=your_secure_admin_password_here

# === OPCIONALES ===
# Performance
WORKERS=2
MAX_CRON_THREADS=1
DB_MAXCONN=64
LIMIT_MEMORY_HARD=2684354560
LIMIT_MEMORY_SOFT=2147483648
LIMIT_REQUEST=8192
LIMIT_TIME_CPU=60
LIMIT_TIME_REAL=120

# Redis (para sesiones - opcional)
REDIS_HOST=hostname
REDIS_PORT=6379
REDIS_PASSWORD=password

# Email (opcional)
EMAIL_FROM=noreply@yourdomain.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_SSL=True

# Domain (opcional)
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
EOF

    print_success "Template de variables creado: .env.railway.template"
}

update_gitignore() {
    print_status "Actualizando .gitignore para Railway..."
    
    if ! grep -q ".env.railway" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# Railway environment files" >> .gitignore
        echo ".env.railway" >> .gitignore
        echo ".env.railway.*" >> .gitignore
        print_success ".gitignore actualizado"
    else
        print_success ".gitignore ya está configurado"
    fi
}

show_deployment_instructions() {
    print_status "Instrucciones de deployment en Railway:"
    echo
    echo -e "${BLUE}1. Preparar repositorio:${NC}"
    echo "   git add ."
    echo "   git commit -m 'Railway deployment ready'"
    echo "   git push origin production"
    echo
    echo -e "${BLUE}2. En Railway Dashboard:${NC}"
    echo "   • Crear nuevo proyecto"
    echo "   • Conectar repositorio GitHub"
    echo "   • Seleccionar rama 'production'"
    echo "   • Railway detectará automáticamente el Dockerfile"
    echo
    echo -e "${BLUE}3. Configurar Variables de Entorno:${NC}"
    echo "   • Copiar variables desde .env.railway.template"
    echo "   • Configurar en Railway Dashboard > Variables"
    echo "   • ⚠️  ADMIN_PASSWORD es REQUERIDO"
    echo
    echo -e "${BLUE}4. Agregar PostgreSQL:${NC}"
    echo "   • Railway Dashboard > Add Service > PostgreSQL"
    echo "   • Las variables DATABASE_URL, PGHOST, etc. se generan automáticamente"
    echo
    echo -e "${BLUE}5. Configurar Volúmenes (opcional):${NC}"
    echo "   • /var/lib/odoo (datos de aplicación)"
    echo "   • /var/log/odoo (logs)"
    echo "   • /mnt/extra-addons (módulos personalizados)"
    echo
    echo -e "${BLUE}6. Deploy:${NC}"
    echo "   • Railway iniciará el deployment automáticamente"
    echo "   • Verificar logs en Railway Dashboard"
    echo "   • Tu app estará disponible en: https://your-app-name.railway.app"
    echo
    echo -e "${YELLOW}📋 Archivos importantes para Railway:${NC}"
    echo "   • Dockerfile (sin declaraciones VOLUME)"
    echo "   • railway.json (configuración de deployment)"
    echo "   • config/odoo.railway.conf (configuración de Odoo)"
    echo "   • .env.railway.template (template de variables)"
    echo
}

main() {
    print_header
    
    check_git_status
    validate_dockerfiles
    check_required_files
    create_railway_env_template
    update_gitignore
    
    print_success "Proyecto preparado para Railway deployment"
    
    show_deployment_instructions
    
    echo "=================================================="
    echo -e "${GREEN}🚀 ¡Listo para Railway! 🚂${NC}"
    echo "=================================================="
}

# Script execution
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Uso: $0 [help]"
        echo "Prepara el proyecto Odoo para deployment en Railway"
        ;;
    *)
        main
        ;;
esac
