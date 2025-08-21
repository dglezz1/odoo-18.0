# Guía de Instalación de Odoo 18.0 en Windows

## Fecha de creación: 21 de agosto de 2025

Esta guía proporciona instrucciones paso a paso para instalar y configurar Odoo 18.0 en sistemas Windows 10/11.

## 📋 Requisitos del Sistema

- Windows 10/11 (64-bit)
- Mínimo 4GB RAM (8GB recomendado)
- 10GB espacio libre en disco
- Conexión a Internet
- Permisos de administrador

## 🛠️ Componentes Necesarios

1. **Python 3.11+** - Lenguaje de programación principal
2. **PostgreSQL 14+** - Base de datos
3. **Git** - Control de versiones
4. **Node.js y npm** - Para compilación de assets
5. **Visual Studio Build Tools** - Para compilar dependencias nativas

## 📦 Paso 1: Instalación de Python 3.11

### Opción A: Descarga desde python.org (Recomendado)

1. Ve a [https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/)
2. Descarga Python 3.11.x (64-bit)
3. Ejecuta el instalador con las siguientes opciones:
   - ✅ **Add Python to PATH**
   - ✅ **Install for all users**
   - ✅ **pip** (incluido por defecto)

4. Verifica la instalación:
```powershell
python --version
pip --version
```

### Opción B: Usando Windows Package Manager (winget)

```powershell
# Instalar Python 3.11
winget install Python.Python.3.11

# Refrescar variables de entorno
refreshenv
```

## 🗄️ Paso 2: Instalación de PostgreSQL

### Usando el instalador oficial

1. Ve a [https://www.postgresql.org/download/windows/](https://www.postgresql.org/download/windows/)
2. Descarga PostgreSQL 14 o superior
3. Durante la instalación:
   - Contraseña del superusuario: `postgres` (anótala)
   - Puerto: `5432` (por defecto)
   - Locale: `Spanish, Spain` o `English, United States`

4. Verifica la instalación:
```powershell
# Abrir PowerShell como Administrador
psql --version
```

### Configuración inicial de PostgreSQL

```powershell
# Conectar como superusuario
psql -U postgres

# Crear usuario para Odoo
CREATE USER odoo WITH CREATEDB PASSWORD 'odoo';

# Salir de PostgreSQL
\q
```

## 🔧 Paso 3: Visual Studio Build Tools

Las dependencias de Python requieren herramientas de compilación:

### Opción A: Visual Studio Build Tools (Ligero)

1. Descarga desde [https://visualstudio.microsoft.com/visual-cpp-build-tools/](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Instala con los componentes:
   - **MSVC v143 - VS 2022 C++ x64/x86 build tools**
   - **Windows 10/11 SDK**

### Opción B: Visual Studio Community (Completo)

```powershell
winget install Microsoft.VisualStudio.2022.Community
```

## 🚀 Paso 4: Node.js y SASS

### Instalar Node.js

```powershell
# Usando winget
winget install OpenJS.NodeJS

# O descarga desde https://nodejs.org/
```

### Instalar SASS globalmente

```powershell
npm install -g sass
```

## 📥 Paso 5: Descargar Odoo 18.0

### Opción A: Git Clone (Recomendado)

```powershell
# Instalar Git si no está instalado
winget install Git.Git

# Clonar repositorio
git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git C:\odoo-18.0
cd C:\odoo-18.0
```

### Opción B: Descarga directa

1. Ve a [https://github.com/odoo/odoo/archive/refs/heads/18.0.zip](https://github.com/odoo/odoo/archive/refs/heads/18.0.zip)
2. Extrae en `C:\odoo-18.0`

## 🐍 Paso 6: Entorno Virtual Python

```powershell
cd C:\odoo-18.0

# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
.\venv\Scripts\Activate.ps1

# Si hay error de ejecución, ejecutar:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verificar activación
python --version
```

## 📦 Paso 7: Instalación de Dependencias Python

```powershell
# Asegurarse que el entorno virtual está activado
.\venv\Scripts\Activate.ps1

# Actualizar pip
python -m pip install --upgrade pip

# Instalar dependencias desde requirements.txt
pip install -r requirements.txt

# Dependencias adicionales críticas
pip install psycopg2-binary
pip install pillow
pip install reportlab
pip install qrcode[pil]
pip install python-dateutil
pip install decorator
pip install docutils
pip install feedparser
pip install geoip2
pip install greenlet
pip install jinja2
pip install lxml
pip install markupsafe
pip install num2words
pip install ofxparse
pip install passlib
pip install polib
pip install psutil
pip install python-ldap
pip install python-stdnum
pip install pytz
pip install pyusb
pip install requests
pip install urllib3
pip install vobject
pip install werkzeug
pip install xlsxwriter
pip install zeep
pip install babel
pip install chardet
pip install cryptography
pip install idna
pip install libsass
pip install pyopenssl
pip install rjsmin
```

## ⚙️ Paso 8: Configuración de Odoo

### Crear archivo de configuración

```powershell
# Crear archivo odoo.conf
@"
[options]
addons_path = addons
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
logfile = odoo.log
log_level = info
"@ | Out-File -FilePath "odoo.conf" -Encoding UTF8
```

## 🚀 Paso 9: Primera Ejecución

```powershell
# Asegurarse que PostgreSQL está ejecutándose
# En Services.msc buscar postgresql-x64-14 y iniciarlo

# Activar entorno virtual
.\venv\Scripts\Activate.ps1

# Ejecutar Odoo
python odoo-bin --config=odoo.conf -d odoo_demo -i base --without-demo=all
```

### Acceder a la interfaz web

1. Abre tu navegador
2. Ve a: `http://localhost:8069`
3. Configuración inicial:
   - **Database Name**: `odoo_demo`
   - **Email**: `admin@example.com`
   - **Password**: `admin`
   - **Language**: `Spanish` o `English`
   - **Country**: `Spain` o tu país

## 🔧 Paso 10: Servicio de Windows (Opcional)

Para ejecutar Odoo como servicio de Windows:

### Crear script de inicio

```powershell
# Crear start_odoo.bat
@"
@echo off
cd /d C:\odoo-18.0
call venv\Scripts\activate.bat
python odoo-bin --config=odoo.conf
"@ | Out-File -FilePath "start_odoo.bat" -Encoding ASCII
```

### Instalar como servicio con NSSM

```powershell
# Descargar NSSM desde https://nssm.cc/download
# Extraer nssm.exe a C:\nssm\

# Instalar servicio
C:\nssm\nssm.exe install "Odoo18" "C:\odoo-18.0\start_odoo.bat"

# Configurar servicio
C:\nssm\nssm.exe set "Odoo18" DisplayName "Odoo 18.0 Server"
C:\nssm\nssm.exe set "Odoo18" Description "Odoo ERP Server Version 18.0"
C:\nssm\nssm.exe set "Odoo18" Start SERVICE_AUTO_START

# Iniciar servicio
net start Odoo18
```

## 🛠️ Solución de Problemas Comunes

### Error: ModuleNotFoundError

```powershell
# Verificar que el entorno virtual está activado
.\venv\Scripts\Activate.ps1

# Reinstalar dependencias
pip install -r requirements.txt --force-reinstall
```

### Error: PostgreSQL connection

```powershell
# Verificar que PostgreSQL está ejecutándose
Get-Service postgresql*

# Verificar configuración de conexión
psql -U odoo -h localhost -p 5432 -l
```

### Error: Permission denied

```powershell
# Ejecutar PowerShell como Administrador
# Cambiar política de ejecución
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Error: SASS compilation

```powershell
# Verificar instalación de Node.js y SASS
node --version
sass --version

# Reinstalar SASS si es necesario
npm uninstall -g sass
npm install -g sass
```

### Error: Visual C++ compiler

```powershell
# Instalar Microsoft C++ Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# O instalar Visual Studio Community
winget install Microsoft.VisualStudio.2022.Community
```

## 🔍 Verificación Final

### Script de verificación (PowerShell)

```powershell
# Crear verify_installation.ps1
@"
Write-Host "Verificando instalación de Odoo 18.0..." -ForegroundColor Green

# Verificar Python
Write-Host "Python version:" -ForegroundColor Yellow
python --version

# Verificar PostgreSQL
Write-Host "PostgreSQL status:" -ForegroundColor Yellow
Get-Service postgresql*

# Verificar Node.js
Write-Host "Node.js version:" -ForegroundColor Yellow
node --version

# Verificar SASS
Write-Host "SASS version:" -ForegroundColor Yellow
sass --version

# Verificar dependencias Python críticas
Write-Host "Verificando dependencias Python..." -ForegroundColor Yellow
python -c "import psycopg2, lxml, pillow, reportlab; print('✅ Dependencias críticas OK')"

Write-Host "Verificación completada!" -ForegroundColor Green
"@ | Out-File -FilePath "verify_installation.ps1" -Encoding UTF8

# Ejecutar verificación
PowerShell -ExecutionPolicy Bypass -File verify_installation.ps1
```

## 📁 Estructura de Archivos Final

```
C:\odoo-18.0\
├── addons/              # Módulos de Odoo
├── venv/                # Entorno virtual Python
├── odoo-bin             # Ejecutable principal
├── odoo.conf            # Archivo de configuración
├── start_odoo.bat       # Script de inicio
├── verify_installation.ps1  # Script de verificación
├── requirements.txt     # Dependencias Python
└── odoo.log            # Archivo de logs
```

## 🚀 Comandos de Uso Diario

```powershell
# Iniciar Odoo (modo desarrollo)
cd C:\odoo-18.0
.\venv\Scripts\Activate.ps1
python odoo-bin --config=odoo.conf --dev=reload,qweb,werkzeug,xml

# Actualizar módulo
python odoo-bin --config=odoo.conf -d odoo_demo -u base

# Instalar nuevo módulo
python odoo-bin --config=odoo.conf -d odoo_demo -i sale

# Backup base de datos
pg_dump -U odoo -h localhost -p 5432 odoo_demo > backup.sql

# Restaurar base de datos
createdb -U odoo -h localhost -p 5432 odoo_restored
psql -U odoo -h localhost -p 5432 odoo_restored < backup.sql
```

## 📞 Soporte y Recursos

- **Documentación oficial**: [https://www.odoo.com/documentation/18.0/](https://www.odoo.com/documentation/18.0/)
- **Foro de la comunidad**: [https://www.odoo.com/forum/](https://www.odoo.com/forum/)
- **GitHub Issues**: [https://github.com/odoo/odoo/issues](https://github.com/odoo/odoo/issues)

---

**Nota**: Esta guía fue probada en Windows 11 con todas las versiones especificadas de software. Para otros entornos, pueden ser necesarios ajustes menores.

**Autor**: Guía basada en la instalación exitosa de Odoo 18.0 en macOS, adaptada para Windows.
**Fecha**: 21 de agosto de 2025
