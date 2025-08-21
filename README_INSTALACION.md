# Odoo 18.0 - Guías de Instalación Multiplataforma

Este repositorio contiene guías completas y scripts automatizados para instalar Odoo 18.0 en diferentes sistemas operativos.

## 📁 Archivos Disponibles

### 🍎 macOS
- **`INSTALACION_ODOO_18.md`** - Guía completa de instalación para macOS
- **`INSTALACION_RAPIDA.md`** - Guía de referencia rápida para macOS  
- **`install_odoo_macos.sh`** - Script de instalación automática para macOS
- **`odoo_sass_troubleshooting.ipynb`** - Notebook de diagnóstico SASS

### 🪟 Windows
- **`INSTALACION_ODOO_18_WINDOWS.md`** - Guía completa de instalación para Windows
- **`INSTALACION_RAPIDA_WINDOWS.md`** - Guía de referencia rápida para Windows
- **`install_odoo_windows.bat`** - Script batch de instalación automática
- **`install_odoo_windows.ps1`** - Script PowerShell de instalación avanzada
- **`verify_installation.ps1`** - Script de verificación de instalación

### 🐧 Linux (Ubuntu/Debian)
*Próximamente*

## 🚀 Instalación Rápida

### macOS
```bash
# Hacer ejecutable y ejecutar
chmod +x install_odoo_macos.sh
./install_odoo_macos.sh
```

### Windows
```powershell
# Ejecutar PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install_odoo_windows.ps1
```

O usar el script batch:
```cmd
# Ejecutar como Administrador
install_odoo_windows.bat
```

## 🎯 Características de los Scripts

### ✅ Scripts Automáticos
- Detección automática de dependencias instaladas
- Instalación de todos los prerrequisitos
- Configuración automática de PostgreSQL
- Creación de entorno virtual Python
- Instalación de dependencias Python
- Configuración inicial de Odoo
- Scripts de inicio y verificación

### 🛠️ Componentes Instalados

| Componente | macOS | Windows |
|------------|-------|---------|
| Python 3.11+ | ✅ Homebrew | ✅ winget |
| PostgreSQL 14+ | ✅ Homebrew | ✅ winget |
| Git | ✅ Homebrew | ✅ winget |
| Node.js | ✅ Homebrew | ✅ winget |
| SASS Compiler | ✅ sassc (libsass) | ✅ npm sass |
| Build Tools | ✅ Xcode Command Line | ✅ VS Build Tools |

## 📋 Requisitos del Sistema

### macOS
- macOS 10.15+ (Catalina o superior)
- 4GB RAM (8GB recomendado)
- 10GB espacio libre
- Homebrew instalado

### Windows  
- Windows 10/11 (64-bit)
- 4GB RAM (8GB recomendado)
- 10GB espacio libre
- Permisos de administrador

## 🔧 Estructura de Instalación

```
Odoo Installation Directory/
├── addons/                 # Módulos de Odoo
├── venv/                   # Entorno virtual Python  
├── odoo-bin               # Ejecutable principal
├── odoo.conf              # Archivo de configuración
├── requirements.txt       # Dependencias Python
├── odoo.log              # Archivo de logs
├── start_odoo.{sh|bat}   # Script de inicio
└── verify_installation.{sh|ps1}  # Script de verificación
```

## 🌐 Acceso Web

Después de la instalación, accede a Odoo en:
- **URL**: http://localhost:8069
- **Usuario inicial**: admin  
- **Contraseña inicial**: admin

## 📖 Documentación Detallada

### Para macOS
- Lee `INSTALACION_ODOO_18.md` para instrucciones completas
- Usa `INSTALACION_RAPIDA.md` para referencias rápidas
- Consulta `odoo_sass_troubleshooting.ipynb` para problemas de SASS

### Para Windows
- Lee `INSTALACION_ODOO_18_WINDOWS.md` para instrucciones completas  
- Usa `INSTALACION_RAPIDA_WINDOWS.md` para referencias rápidas

## 🛠️ Comandos Útiles Post-Instalación

### Iniciar Odoo
```bash
# macOS
./start_odoo.sh

# Windows  
start_odoo.bat
```

### Verificar Instalación
```bash
# macOS
./verify_installation.sh

# Windows
PowerShell -ExecutionPolicy Bypass -File verify_installation.ps1
```

### Modo Desarrollador
```bash
# macOS/Linux
python odoo-bin --config=odoo.conf --dev=reload,qweb,werkzeug,xml

# Windows
venv\Scripts\python.exe odoo-bin --config=odoo.conf --dev=reload,qweb,werkzeug,xml
```

## 🔍 Solución de Problemas

### Problemas Comunes
1. **Error de PostgreSQL**: Verificar que el servicio esté ejecutándose
2. **Error de Python**: Verificar que el entorno virtual esté activado  
3. **Error de SASS**: Verificar instalación del compilador correcto
4. **Error de permisos**: Ejecutar con permisos de administrador

### Logs de Debugging
- **Archivo de log**: `odoo.log` en el directorio de instalación
- **Logs en tiempo real**: Se muestran en la consola durante ejecución

## 🤝 Contribución

Esta documentación se basa en la instalación exitosa de Odoo 18.0 en macOS y su adaptación para Windows. 

Para reportar problemas o mejoras:
1. Verifica los logs de instalación
2. Consulta la documentación específica de tu plataforma
3. Ejecuta el script de verificación

## 📅 Historial de Versiones

- **v1.0** (21 Agosto 2025) - Instalación inicial para macOS
- **v1.1** (21 Agosto 2025) - Documentación y scripts para Windows

## 📞 Soporte

- **Documentación oficial Odoo**: https://www.odoo.com/documentation/18.0/
- **Foro de la comunidad**: https://www.odoo.com/forum/
- **GitHub Issues**: https://github.com/odoo/odoo/issues

---

**Nota**: Estos scripts y documentación han sido probados en las versiones especificadas del software. Para otros entornos, pueden ser necesarios ajustes menores.
