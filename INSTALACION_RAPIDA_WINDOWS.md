# Instalación Rápida de Odoo 18.0 en Windows

## 🚀 Instalación Automática (Recomendado)

### Opción 1: Script Batch (.bat)
```cmd
# Ejecutar como Administrador
install_odoo_windows.bat
```

### Opción 2: Script PowerShell (.ps1)
```powershell
# Ejecutar PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install_odoo_windows.ps1
```

## 📋 Instalación Manual Rápida

### 1. Prerrequisitos (PowerShell como Admin)
```powershell
# Instalar Python 3.11
winget install Python.Python.3.11

# Instalar Git
winget install Git.Git

# Instalar PostgreSQL 14
winget install PostgreSQL.PostgreSQL.14

# Instalar Node.js
winget install OpenJS.NodeJS

# Instalar Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# Instalar SASS
npm install -g sass
```

### 2. Configurar PostgreSQL
```cmd
# Conectar como postgres
psql -U postgres

# Crear usuario odoo
CREATE USER odoo WITH CREATEDB PASSWORD 'odoo';
\q
```

### 3. Descargar e instalar Odoo
```cmd
# Crear directorio
mkdir C:\odoo-18.0
cd C:\odoo-18.0

# Clonar repositorio
git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git .

# Crear entorno virtual
python -m venv venv

# Activar entorno
venv\Scripts\activate.bat

# Instalar dependencias
pip install -r requirements.txt
pip install psycopg2-binary
```

### 4. Configuración
```cmd
# Crear odoo.conf
echo [options] > odoo.conf
echo addons_path = addons >> odoo.conf
echo admin_passwd = admin >> odoo.conf
echo db_host = localhost >> odoo.conf
echo db_port = 5432 >> odoo.conf
echo db_user = odoo >> odoo.conf
echo db_password = odoo >> odoo.conf
```

### 5. Ejecutar Odoo
```cmd
# Activar entorno virtual
venv\Scripts\activate.bat

# Ejecutar Odoo
python odoo-bin --config=odoo.conf
```

### 6. Acceder
- URL: http://localhost:8069
- Crear base de datos
- Usuario: admin
- Contraseña: admin

## 🛠️ Comandos Útiles

```powershell
# Verificar instalación
.\verify_installation.ps1

# Iniciar Odoo
.\start_odoo.bat

# Backup base de datos
pg_dump -U odoo -h localhost odoo_demo > backup.sql

# Restaurar base de datos
psql -U odoo -h localhost -d odoo_restored < backup.sql
```

## 🔧 Solución de Problemas

### Error: Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: PostgreSQL Connection
```cmd
# Verificar servicio PostgreSQL
sc query postgresql-x64-14

# Iniciar servicio
net start postgresql-x64-14
```

### Error: Python Module Not Found
```cmd
# Reactivar entorno virtual
venv\Scripts\activate.bat

# Reinstalar dependencias
pip install -r requirements.txt --force-reinstall
```

---

**Documentación completa**: `INSTALACION_ODOO_18_WINDOWS.md`

**Scripts disponibles**:
- `install_odoo_windows.bat` - Script batch automático
- `install_odoo_windows.ps1` - Script PowerShell avanzado
- `verify_installation.ps1` - Verificación de instalación
- `start_odoo.bat` - Inicio rápido de Odoo
