#!/bin/bash
set -e

# ===========================================
# PRODUCTION READINESS CHECKER
# ===========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_TOTAL=0

check() {
    ((CHECKS_TOTAL++))
    echo -n "  Checking $1... "
    if eval "$2" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        if [ ! -z "$3" ]; then
            echo -e "    ${YELLOW}Fix: $3${NC}"
        fi
        return 1
    fi
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

section "Environment Configuration"

check "Production environment file exists" "[ -f .env.prod ]" "Create .env.prod from template"

if [ -f .env.prod ]; then
    check "Secure database password set" "! grep -q 'YOUR_SECURE_PASSWORD_HERE' .env.prod" "Set POSTGRES_PASSWORD in .env.prod"
    check "Secure admin password set" "! grep -q 'YOUR_ADMIN_PASSWORD_HERE' .env.prod" "Set ODOO_ADMIN_PASSWORD in .env.prod"
fi

section "Docker Configuration"

check "Docker is installed" "command -v docker"
check "Docker Compose is installed" "command -v docker-compose"
check "Docker daemon is running" "docker info"

section "File Structure"

check "Production Docker Compose exists" "[ -f docker-compose.prod.yml ]"
check "Production Dockerfile target exists" "grep -q 'FROM base AS production' Dockerfile"
check "Production entrypoint exists" "[ -f entrypoint.prod.sh ]"
check "Production config exists" "[ -f config/odoo.prod.conf ]"
check "Nginx config exists" "[ -f nginx/nginx.conf ]"
check "PostgreSQL config exists" "[ -f postgresql.conf ]"

section "Scripts and Permissions"

check "Production deploy script exists" "[ -f deploy-prod.sh ]"
check "Backup script exists" "[ -f backup.sh ]"
check "Deploy script is executable" "[ -x deploy-prod.sh ]"
check "Backup script is executable" "[ -x backup.sh ]"

section "Security Configuration"

if [ -f config/odoo.prod.conf ]; then
    check "Database listing disabled" "grep -q 'list_db = False' config/odoo.prod.conf"
    check "Database filter configured" "grep -q 'db_filter' config/odoo.prod.conf"
    check "Workers configured for production" "grep -q 'workers = [1-9]' config/odoo.prod.conf"
    check "Log level set appropriately" "grep -q 'log_level = warn\|log_level = error' config/odoo.prod.conf"
fi

if [ -f nginx/nginx.conf ]; then
    check "Rate limiting configured" "grep -q 'limit_req_zone' nginx/nginx.conf"
    check "Security headers present" "grep -q 'X-Frame-Options' nginx/nginx.conf"
    check "Server tokens disabled" "grep -q 'server_tokens off' nginx/nginx.conf"
fi

section "Performance Configuration"

if [ -f docker-compose.prod.yml ]; then
    check "Memory limits set" "grep -q 'memory:' docker-compose.prod.yml"
    check "Restart policies configured" "grep -q 'unless-stopped' docker-compose.prod.yml"
    check "Health checks configured" "grep -q 'healthcheck:' docker-compose.prod.yml"
fi

section "Production Readiness Summary"

echo ""
echo "=========================================="
echo "🎯 PRODUCTION READINESS REPORT"
echo "=========================================="
echo -e "Checks passed: ${GREEN}$CHECKS_PASSED${NC} / $CHECKS_TOTAL"

PERCENTAGE=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))

if [ $PERCENTAGE -eq 100 ]; then
    echo -e "Status: ${GREEN}🚀 PRODUCTION READY${NC}"
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "Status: ${YELLOW}⚠️  MOSTLY READY (review failed checks)${NC}"
else
    echo -e "Status: ${RED}❌ NOT READY FOR PRODUCTION${NC}"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Fix any failed checks above"
echo "2. Review and update .env.prod with secure passwords"
echo "3. Configure SSL certificates for HTTPS"
echo "4. Set up monitoring and alerting"
echo "5. Configure automated backups"
echo "6. Review firewall and security settings"
echo ""

if [ $PERCENTAGE -ge 80 ]; then
    echo -e "${GREEN}Ready to deploy with:${NC}"
    echo "  ./deploy-prod.sh"
else
    echo -e "${RED}Please fix the issues above before deploying.${NC}"
fi

echo ""
