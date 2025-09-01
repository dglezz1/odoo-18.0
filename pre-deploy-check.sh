#!/bin/bash

# Pre-deployment Check para Odoo 18.0 Production
# Verifica que todo esté listo antes del deploy

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="odoo.filltech-ai.com"

print_header() {
    echo "=================================================="
    echo "🔍 PRE-DEPLOYMENT CHECK - ODOO 18.0"
    echo "=================================================="
    echo "🌐 Dominio: $DOMAIN"
    echo "📦 Verificando preparativos para producción..."
    echo "=================================================="
}

print_check() {
    echo -n -e "${BLUE}[CHECK]${NC} $1... "
}

print_success() {
    echo -e "${GREEN}✅ OK${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}"
    echo -e "${YELLOW}       $1${NC}"
}

print_error() {
    echo -e "${RED}❌ FAIL${NC}"
    echo -e "${RED}       $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_files() {
    print_check "Archivos necesarios"
    
    required_files=(
        "deploy-production.sh"
        "setup-cloudflare-dns.sh" 
        "docker-compose.server.yml"
        "Dockerfile"
        "requirements.txt"
        "config/odoo.conf"
        "nginx/nginx.conf"
    )
    
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        print_success
    else
        print_error "Archivos faltantes: ${missing_files[*]}"
        return 1
    fi
}

check_docker_files() {
    print_check "Dockerfiles sin VOLUME"
    
    if grep -r "^VOLUME" Dockerfile* 2>/dev/null; then
        print_error "Encontradas declaraciones VOLUME - Railway las prohíbe"
        return 1
    else
        print_success
    fi
}

check_git_status() {
    print_check "Estado de Git"
    
    if ! git status >/dev/null 2>&1; then
        print_error "No es un repositorio Git"
        return 1
    fi
    
    if ! git diff-index --quiet HEAD --; then
        print_warning "Hay cambios sin commit"
        echo "         Considera hacer commit antes del deploy"
    fi
    
    print_success
}

check_cloudflare_setup() {
    print_check "Configuración de Cloudflare"
    
    if [[ -z "${CF_API_TOKEN:-}" ]] && [[ -z "${CF_API_KEY:-}" ]]; then
        print_warning "Credenciales de Cloudflare no configuradas"
        echo "         Necesitarás configurar CF_API_TOKEN antes del deploy DNS"
    else
        print_success
    fi
}

check_dependencies() {
    print_check "Dependencias del sistema"
    
    missing_deps=()
    
    # Verificar comandos necesarios
    commands=("curl" "git" "jq")
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_success
    else
        print_warning "Dependencias faltantes: ${missing_deps[*]}"
        echo "         Se instalarán automáticamente durante el deploy"
    fi
}

check_ports() {
    print_check "Puertos necesarios"
    
    # Verificar que no hay servicios usando los puertos críticos
    ports_in_use=()
    
    critical_ports=(80 443)
    
    for port in "${critical_ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            ports_in_use+=("$port")
        fi
    done
    
    if [[ ${#ports_in_use[@]} -eq 0 ]]; then
        print_success
    else
        print_warning "Puertos en uso: ${ports_in_use[*]}"
        echo "         El deploy los liberará automáticamente"
    fi
}

check_dns() {
    print_check "Resolución DNS actual"
    
    resolved_ip=$(nslookup $DOMAIN 8.8.8.8 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}' 2>/dev/null || echo "")
    current_ip=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    
    if [[ -z "$resolved_ip" ]]; then
        print_warning "DNS no resuelve aún"
        echo "         Ejecuta ./setup-cloudflare-dns.sh primero"
    elif [[ "$resolved_ip" == "$current_ip" ]]; then
        print_success
        echo "         $DOMAIN -> $resolved_ip (directo)"
    else
        print_success  
        echo "         $DOMAIN -> $resolved_ip (via Cloudflare proxy)"
    fi
}

check_server_specs() {
    print_check "Especificaciones del servidor"
    
    # RAM
    ram_gb=$(free -g | awk 'NR==2{printf "%.1f", $2}')
    if (( $(echo "$ram_gb < 2" | bc -l) )); then
        print_warning "RAM baja: ${ram_gb}GB (mínimo 4GB recomendado)"
    fi
    
    # Disco
    disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
    if [[ $disk_gb -lt 20 ]]; then
        print_warning "Espacio en disco bajo: ${disk_gb}GB disponible"
    fi
    
    # CPU
    cpu_cores=$(nproc)
    if [[ $cpu_cores -lt 2 ]]; then
        print_warning "Pocos núcleos CPU: $cpu_cores (mínimo 2 recomendado)"
    fi
    
    print_success
    echo "         RAM: ${ram_gb}GB | Disco: ${disk_gb}GB libre | CPU: ${cpu_cores} cores"
}

show_deployment_plan() {
    echo
    echo "=================================================="
    echo "📋 PLAN DE DEPLOYMENT"
    echo "=================================================="
    
    echo -e "${BLUE}1. Configurar DNS:${NC}"
    echo "   export CF_API_TOKEN='tu_token'"
    echo "   ./setup-cloudflare-dns.sh"
    echo
    
    echo -e "${BLUE}2. Deploy en servidor:${NC}"
    echo "   # Transferir archivos al servidor"
    echo "   scp -r . user@server:/opt/odoo-18.0/"
    echo "   "
    echo "   # En el servidor"
    echo "   ssh user@server"
    echo "   cd /opt/odoo-18.0"
    echo "   ./deploy-production.sh"
    echo
    
    echo -e "${BLUE}3. Verificar deployment:${NC}"
    echo "   https://$DOMAIN"
    echo "   Usuario: admin"
    echo "   Contraseña: (generada por el script)"
    echo
}

show_checklist() {
    echo "=================================================="
    echo "✅ CHECKLIST PRE-DEPLOYMENT"
    echo "=================================================="
    
    echo "[ ] Servidor Ubuntu preparado"
    echo "[ ] Acceso SSH al servidor"  
    echo "[ ] Dominio $DOMAIN configurado en Cloudflare"
    echo "[ ] API Token de Cloudflare obtenido"
    echo "[ ] Puertos 80, 443, 22 abiertos"
    echo "[ ] Archivos del proyecto en el servidor"
    echo "[ ] Variables CF_API_TOKEN exportadas"
    echo
    
    echo -e "${GREEN}¡Una vez completado el checklist, ejecuta:${NC}"
    echo -e "${YELLOW}./deploy-production.sh${NC}"
}

main() {
    print_header
    
    echo "🔍 Ejecutando verificaciones..."
    echo
    
    checks_passed=0
    total_checks=7
    
    check_files && ((checks_passed++)) || true
    check_docker_files && ((checks_passed++)) || true
    check_git_status && ((checks_passed++)) || true
    check_cloudflare_setup && ((checks_passed++)) || true
    check_dependencies && ((checks_passed++)) || true
    check_ports && ((checks_passed++)) || true
    check_dns && ((checks_passed++)) || true
    
    if command -v free &> /dev/null && command -v df &> /dev/null; then
        check_server_specs
    else
        print_info "Ejecuta en el servidor para verificar specs completas"
    fi
    
    echo
    echo "=================================================="
    
    if [[ $checks_passed -eq $total_checks ]]; then
        echo -e "${GREEN}🎉 LISTO PARA DEPLOYMENT${NC}"
        echo -e "${GREEN}$checks_passed/$total_checks verificaciones pasadas${NC}"
    else
        echo -e "${YELLOW}⚠️  ADVERTENCIAS ENCONTRADAS${NC}"
        echo -e "${YELLOW}$checks_passed/$total_checks verificaciones pasadas${NC}"
        echo -e "${YELLOW}Puedes continuar, pero revisa las advertencias${NC}"
    fi
    
    show_deployment_plan
    show_checklist
}

# Manejo de argumentos
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Uso: $0 [help]"
        echo "Verifica que todo esté listo para el deploy de producción"
        echo
        echo "Este script verifica:"
        echo "• Archivos necesarios presentes"
        echo "• Estado de Git"
        echo "• Configuración de Cloudflare"
        echo "• Dependencias del sistema"
        echo "• Estado de puertos"
        echo "• Resolución DNS"
        echo "• Especificaciones del servidor"
        exit 0
        ;;
    *)
        main
        ;;
esac
