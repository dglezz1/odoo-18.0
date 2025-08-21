# 🚀 Guía de Instalación Rápida - Odoo 18.0 macOS

## ⚡ Instalación en 5 Pasos

### 1. Instalar Dependencias del Sistema
```bash
# Python 3.11 y PostgreSQL
brew install python@3.11 postgresql@14

# Iniciar PostgreSQL
brew services start postgresql@14

# SASS Compiler (CRÍTICO: usar sassc, NO sass)
brew install sassc
```

### 2. Crear Entorno Virtual
```bash
cd /path/to/odoo-18.0
/opt/homebrew/opt/python@3.11/bin/python3.11 -m venv .venv
source .venv/bin/activate
```

### 3. Instalar Dependencias Python
```bash
pip install -r requirements.txt
pip install python-stdnum  # Requerido para partner_autocomplete
```

### 4. Verificar SASS Compiler
```bash
# Verificar que sassc tiene la opción -t (CRÍTICO)
sassc --help | grep -E "^\s*-t"
# Debe mostrar: -t, --style NAME
```

### 5. Ejecutar Odoo
```bash
python ./odoo-bin --addons-path="addons/" -d rd-demo
```

## 🌐 Acceso
- **URL**: http://127.0.0.1:8069
- **Usuario**: admin
- **Contraseña**: admin

## 🔥 Solución Rápida a Errores Comunes

### Error SASS: "Could not find option -t"
```bash
# Eliminar Dart Sass si existe
rm /opt/homebrew/bin/sassc
# Instalar sassc correcto
brew install sassc
```

### Puerto en uso
```bash
pkill -f "odoo-bin"
```

### Dependencia faltante
```bash
source .venv/bin/activate
pip install [paquete_faltante]
```

## ✅ Verificación Rápida
```bash
# Python correcto
python --version  # Debe ser 3.11+

# PostgreSQL corriendo
brew services list | grep postgresql

# SASS correcto
sassc --version  # sassc: 3.6.2, libsass: 3.6.6

# Odoo funcionando
curl -I http://127.0.0.1:8069  # HTTP/1.1 200 OK
```

---
**Tiempo estimado**: 15-30 minutos  
**Status**: ✅ Probado y verificado - 21/08/2025
