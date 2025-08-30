# 🚂 Odoo 18.0 - Deployment en Railway

## 📋 Configuración de Volúmenes en Railway

Railway no permite el uso de la palabra clave `VOLUME` en Dockerfiles. En su lugar, debes configurar los volúmenes a través de la interfaz web de Railway o mediante variables de entorno.

### 🗂️ Volúmenes Necesarios para Odoo

| Directorio | Propósito | Tamaño Recomendado |
|------------|-----------|-------------------|
| `/var/lib/odoo` | Datos de la aplicación | 5GB+ |
| `/var/log/odoo` | Logs de la aplicación | 1GB |
| `/mnt/extra-addons` | Módulos personalizados | 1GB |

### ⚙️ Configuración en Railway

1. **Crear Volúmenes en Railway Dashboard:**
   ```
   - Volumen 1: odoo-data -> /var/lib/odoo
   - Volumen 2: odoo-logs -> /var/log/odoo  
   - Volumen 3: odoo-addons -> /mnt/extra-addons
   ```

2. **Variables de Entorno Requeridas:**
   ```env
   # Base de Datos
   DATABASE_URL=postgresql://user:pass@host:port/dbname
   PGUSER=your_db_user
   PGPASSWORD=your_db_password
   PGDATABASE=your_db_name
   PGHOST=your_db_host
   PGPORT=5432

   # Odoo Configuration
   ODOO_RC=/etc/odoo/odoo.conf
   ADDONS_PATH=/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons

   # Railway específico
   PORT=8069
   ```

### 🐳 Dockerfiles Modificados

Los Dockerfiles han sido modificados para cumplir con las restricciones de Railway:

- ✅ **Dockerfile** - Sin declaraciones VOLUME
- ✅ **Dockerfile.dev** - Sin declaraciones VOLUME

Los volúmenes se gestionan ahora exclusivamente a través de Railway volumes.

### 🚀 Proceso de Deployment en Railway

1. **Conectar Repositorio:**
   ```bash
   # Asegúrate de que tu código esté en GitHub
   git add .
   git commit -m "Remove VOLUME declarations for Railway compatibility"
   git push origin production
   ```

2. **Configurar en Railway:**
   - Conectar el repositorio GitHub
   - Seleccionar la rama `production`
   - Configurar las variables de entorno
   - Agregar los volúmenes necesarios

3. **Base de Datos:**
   - Usar Railway PostgreSQL addon
   - O conectar a base de datos externa
   - La URL de conexión se configura automáticamente

### 📝 Archivo railway.json (Opcional)

```json
{
  "deploy": {
    "healthcheckPath": "/web/health",
    "restartPolicyType": "on-failure",
    "restartPolicyMaxRetries": 3
  }
}
```

### 🔧 Configuración de odoo.conf para Railway

```ini
[options]
; Railway configuration
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo

; Database (usar variables de entorno de Railway)
db_host = ${PGHOST}
db_port = ${PGPORT}
db_user = ${PGUSER}
db_password = ${PGPASSWORD}
db_name = ${PGDATABASE}

; Server
http_port = ${PORT}
workers = 2
max_cron_threads = 1

; Logging
logfile = /var/log/odoo/odoo.log
log_level = info

; Security
admin_passwd = ${ADMIN_PASSWORD}
```

### 🌍 Variables de Entorno para Railway

```bash
# En Railway Dashboard > Variables
DATABASE_URL=postgresql://...  # Auto-generada si usas Railway PostgreSQL
ADMIN_PASSWORD=your_secure_admin_password
ODOO_RC=/etc/odoo/odoo.conf
PORT=8069  # Railway lo asigna automáticamente

# Opcionales
WORKERS=2
DB_MAXCONN=64
LIMIT_MEMORY_HARD=2684354560
LIMIT_MEMORY_SOFT=2147483648
LIMIT_REQUEST=8192
LIMIT_TIME_CPU=60
LIMIT_TIME_REAL=120
```

### 🔍 Health Check

Railway verificará automáticamente el estado del servicio. Odoo responde en:
- `GET /web/health` - Health check endpoint
- `GET /web/database/list` - Database availability

### 📦 Deployment Commands

```bash
# Preparar para Railway
git add .
git commit -m "Railway-ready Odoo deployment"
git push origin production

# Railway detectará automáticamente el Dockerfile
# y construirá la imagen sin las declaraciones VOLUME
```

### 🚨 Solución de Problemas

**Error: "VOLUME keyword is banned"**
- ✅ Solucionado: Removidas todas las declaraciones VOLUME

**Error de conexión a BD:**
- Verificar variables de entorno `DATABASE_URL`
- Verificar que el servicio PostgreSQL esté activo

**Error de permisos:**
- Railway maneja automáticamente los permisos de volúmenes
- Los directorios se crean con los permisos correctos

### 📚 Enlaces Útiles

- [Railway Volumes Documentation](https://docs.railway.com/reference/volumes)
- [Railway Environment Variables](https://docs.railway.com/develop/variables)
- [Railway Deployment Guide](https://docs.railway.com/deploy/deployments)

---

**¡Tu proyecto Odoo está ahora compatible con Railway! 🚂✨**
