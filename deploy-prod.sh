#!/bin/bash
set -e

# ===========================================
# ODOO PRODUCTION DEPLOYMENT SCRIPT
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================================="
echo "🚀 ODOO 18.0 - PRODUCTION DEPLOYMENT"
echo "=================================================="

# Check requirements
echo "🔍 Checking requirements..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    exit 1
fi

# Check environment file
if [ ! -f ".env.prod" ]; then
    echo "❌ .env.prod file not found"
    exit 1
fi

echo "✅ Requirements check passed"

# Pull images and build
echo "🔄 Pulling latest images..."
docker-compose -f docker-compose.prod.yml pull postgres nginx || echo "⚠️ Some images couldn't be pulled"

echo "🏗️ Building Odoo application..."
docker-compose -f docker-compose.prod.yml build odoo

echo "🚀 Starting services..."
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

echo "✅ Production deployment completed!"
echo "🌐 Odoo available at: http://localhost"
echo "📋 View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "🔧 Check status: docker-compose -f docker-compose.prod.yml ps"

