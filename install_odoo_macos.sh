#!/bin/bash

# ================================================================================
# Script de Instalación Automatizada - Odoo 18.0 para macOS
# Creado: 21 de Agosto de 2025
# Testado en: macOS Apple Silicon
# ================================================================================

set -e  # Salir en caso de error

echo "🚀 Iniciando instalación de Odoo 18.0..."
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes de estado
show_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    show_error "Este script está diseñado para macOS"
    exit 1
fi

# Verificar que Homebrew está instalado
if ! command -v brew &> /dev/null; then
    show_error "Homebrew no está instalado. Instálalo desde https://brew.sh/"
    exit 1
fi

show_status "Verificando directorio de Odoo..."
ODOO_DIR="$PWD"
if [[ ! -f "odoo-bin" ]]; then
    show_error "No se encontró odoo-bin. Ejecuta este script desde el directorio de Odoo."
    exit 1
fi

show_success "Directorio de Odoo encontrado: $ODOO_DIR"

# 1. Instalar Python 3.11
show_status "Instalando Python 3.11..."
if brew list python@3.11 &>/dev/null; then
    show_success "Python 3.11 ya está instalado"
else
    brew install python@3.11
    show_success "Python 3.11 instalado"
fi

# 2. Instalar PostgreSQL
show_status "Instalando PostgreSQL 14..."
if brew list postgresql@14 &>/dev/null; then
    show_success "PostgreSQL 14 ya está instalado"
else
    brew install postgresql@14
    show_success "PostgreSQL 14 instalado"
fi

# Iniciar PostgreSQL
show_status "Iniciando servicio de PostgreSQL..."
brew services start postgresql@14
show_success "PostgreSQL iniciado"

# 3. Instalar SASS Compiler (CRÍTICO: sassc, no sass)
show_status "Instalando sassc (libsass)..."
if brew list sassc &>/dev/null; then
    show_success "sassc ya está instalado"
else
    # Eliminar cualquier symlink incorrecto
    if [[ -L "/opt/homebrew/bin/sassc" ]]; then
        show_warning "Eliminando symlink incorrecto de sassc..."
        rm /opt/homebrew/bin/sassc
    fi
    
    brew install sassc
    show_success "sassc (libsass) instalado"
fi

# Verificar que sassc tiene la opción -t
if sassc --help | grep -q "^\s*-t"; then
    show_success "sassc tiene la opción -t requerida por Odoo"
else
    show_error "sassc no tiene la opción -t. Reinstalando..."
    brew uninstall sassc
    brew install sassc
fi

# 4. Crear entorno virtual
show_status "Creando entorno virtual Python..."
PYTHON_EXEC="/opt/homebrew/opt/python@3.11/bin/python3.11"
VENV_DIR="$ODOO_DIR/.venv"

if [[ -d "$VENV_DIR" ]]; then
    show_warning "Entorno virtual ya existe. Recreando..."
    rm -rf "$VENV_DIR"
fi

$PYTHON_EXEC -m venv "$VENV_DIR"
show_success "Entorno virtual creado en $VENV_DIR"

# Activar entorno virtual
source "$VENV_DIR/bin/activate"
show_success "Entorno virtual activado"

# 5. Instalar dependencias Python
show_status "Instalando dependencias Python..."
if [[ -f "requirements.txt" ]]; then
    pip install --upgrade pip
    pip install -r requirements.txt
    show_success "Dependencias desde requirements.txt instaladas"
else
    show_warning "No se encontró requirements.txt. Instalando dependencias básicas..."
    pip install babel lxml lxml_html_clean reportlab polib decorator
    pip install zeep rjsmin pyOpenSSL docutils qrcode geoip2 python-stdnum
fi

# Instalar paquete específico requerido
pip install python-stdnum
show_success "python-stdnum instalado (requerido para partner_autocomplete)"

# 6. Configurar alias Python (opcional)
show_status "Configurando alias Python..."
ZSHRC="$HOME/.zshrc"
if ! grep -q 'alias python3="/opt/homebrew/bin/python3.11"' "$ZSHRC" 2>/dev/null; then
    echo 'alias python3="/opt/homebrew/bin/python3.11"' >> "$ZSHRC"
    echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "$ZSHRC"
    show_success "Alias Python agregados a $ZSHRC"
else
    show_success "Alias Python ya configurados"
fi

# 7. Verificaciones finales
show_status "Ejecutando verificaciones finales..."

echo "----------------------------------------"
echo "🔍 VERIFICACIÓN DE COMPONENTES"
echo "----------------------------------------"

# Verificar Python
PYTHON_VERSION=$($PYTHON_EXEC --version)
echo "✅ Python: $PYTHON_VERSION"

# Verificar PostgreSQL
if brew services list | grep -q "postgresql@14.*started"; then
    echo "✅ PostgreSQL: Corriendo"
else
    echo "❌ PostgreSQL: No está corriendo"
fi

# Verificar sassc
SASSC_VERSION=$(sassc --version | head -1)
echo "✅ SASS: $SASSC_VERSION"

# Verificar opción -t en sassc
if sassc --help | grep -q "^\s*-t"; then
    echo "✅ sassc opción -t: Disponible"
else
    echo "❌ sassc opción -t: NO disponible"
fi

# Verificar paquetes Python críticos
echo "✅ Entorno virtual: Creado y activado"
if python -c "import babel, lxml, reportlab, qrcode, geoip2, stdnum" 2>/dev/null; then
    echo "✅ Paquetes Python: Todos instalados"
else
    echo "❌ Paquetes Python: Algunos faltan"
fi

echo "----------------------------------------"
echo "🎉 INSTALACIÓN COMPLETADA"
echo "----------------------------------------"

echo ""
echo "📝 COMANDOS PARA EJECUTAR ODOO:"
echo ""
echo "# Activar entorno virtual:"
echo "source $VENV_DIR/bin/activate"
echo ""
echo "# Ejecutar Odoo (modo normal):"
echo "python ./odoo-bin --addons-path=\"addons/\" -d rd-demo"
echo ""
echo "# Ejecutar Odoo (modo desarrollo):"
echo "python ./odoo-bin --addons-path=\"addons/\" -d rd-demo --dev=all"
echo ""
echo "🌐 Interfaz web: http://127.0.0.1:8069"
echo "👤 Usuario: admin"
echo "🔐 Contraseña: admin"
echo ""

show_success "¡Instalación de Odoo 18.0 completada exitosamente!"
show_status "Documentación disponible en:"
show_status "  - INSTALACION_ODOO_18.md (guía completa)"
show_status "  - INSTALACION_RAPIDA.md (referencia rápida)"
show_status "  - odoo_sass_troubleshooting.ipynb (troubleshooting técnico)"

echo ""
echo "=================================================="
echo "🚀 ¡Listo para usar Odoo 18.0!"
echo "=================================================="
