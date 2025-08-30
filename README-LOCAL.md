# 🚀 Odoo 18.0 - Instalación Local para Desarrollo

## ✅ Estado de la Instalación

Tu instalación local de Odoo 18.0 está **funcionando correctamente** y lista para usar.

### 🌐 URLs de Acceso

| Tipo | URL | Descripción |
|------|-----|-------------|
| **RECOMENDADO** | https://localhost:8443 | Acceso principal via HTTPS con Nginx |
| HTTP | http://localhost:8080 | Redirige automáticamente a HTTPS |
| Directo | http://localhost:8069 | Acceso directo a Odoo (sin Nginx) |

### 🔑 Credenciales de Acceso

- **Usuario**: `admin`
- **Contraseña**: `admin`
- **Base de Datos**: `odoo_local`

### 📱 Accesos Específicos

- **Login Directo**: https://localhost:8443/web/login?db=odoo_local
- **Gestor de BD**: https://localhost:8443/web/database/manager
- **Selector de BD**: https://localhost:8443/web/database/selector

## 🛠️ Herramientas Disponibles

### Scripts de Gestión

```bash
# Probar la instalación
./test-local-install.sh

# Utilidades generales
./odoo-utils.sh [comando]

# Gestión del deployment
./deploy-local.sh [comando]
```

### Comandos de Utilidades

```bash
# Ver estado de servicios
./odoo-utils.sh status

# Ver logs
./odoo-utils.sh logs

# Reiniciar servicios
./odoo-utils.sh restart

# Comandos de base de datos
./odoo-utils.sh db

# Crear respaldo
./odoo-utils.sh backup

# Ejecutar pruebas
./odoo-utils.sh test
```

### Comandos de Deployment

```bash
# Ver estado
./deploy-local.sh status

# Reiniciar servicios
./deploy-local.sh restart

# Ver logs
./deploy-local.sh logs

# Limpiar instalación (⚠️ elimina todos los datos)
./deploy-local.sh clean
```

## 🐳 Servicios Docker

| Servicio | Contenedor | Puerto | Estado |
|----------|------------|--------|---------|
| Odoo | `odoo_local_app` | 8069 | ✅ Healthy |
| PostgreSQL | `odoo_local_db` | 5433 | ✅ Healthy |
| Redis | `odoo_local_redis` | 6379 | ✅ Healthy |
| Nginx | `odoo_local_nginx` | 8080, 8443 | ✅ Running |

## 🔒 Certificados SSL

- **Tipo**: Auto-firmados para desarrollo local
- **Ubicación**: `nginx/ssl/localhost.crt` y `nginx/ssl/localhost.key`
- **Advertencia**: Tu navegador mostrará una advertencia de seguridad (es normal en desarrollo)

## 🗄️ Base de Datos

### Información
- **Nombre**: `odoo_local`
- **Usuarios**: admin, demo, portal
- **Estado**: Inicializada con módulo base

### Acceso Directo a PostgreSQL
```bash
# Conectar a la base de datos
docker exec -it odoo_local_db psql -U odoo -d odoo_local

# Listar tablas
docker exec -it odoo_local_db psql -U odoo -d odoo_local -c "\dt"

# Ver usuarios
docker exec -it odoo_local_db psql -U odoo -d odoo_local -c "SELECT login FROM res_users WHERE active = true;"
```

## 📦 Respaldos

### Crear Respaldo
```bash
./odoo-utils.sh backup
```

### Respaldo Manual
```bash
# Crear directorio
mkdir -p ./backups

# Crear respaldo
docker exec -t odoo_local_db pg_dump -U odoo -d odoo_local > ./backups/odoo_local_$(date +%Y%m%d_%H%M%S).sql
```

## 🔧 Personalización

### Archivos de Configuración
- **Odoo**: `config/odoo.local.conf`
- **Nginx**: `nginx/nginx.local.conf`
- **Environment**: `.env.local`
- **Docker Compose**: `docker-compose.local.yml`

### Directorios
- **Addons**: `addons/` (módulos personalizados)
- **Logs**: Dentro de los contenedores
- **SSL**: `nginx/ssl/`
- **Backups**: `./backups/`

## 🚨 Solución de Problemas

### Servicio no Inicia
```bash
# Verificar estado
docker ps

# Ver logs
./odoo-utils.sh logs

# Reiniciar
./odoo-utils.sh restart
```

### Error de Conexión a BD
```bash
# Verificar PostgreSQL
docker logs odoo_local_db

# Reinicializar BD (⚠️ elimina datos)
./deploy-local.sh clean
./deploy-local.sh deploy
```

### Certificados SSL
```bash
# Regenerar certificados
./generate-ssl-local.sh

# Verificar certificados
ls -la nginx/ssl/
```

## 🌟 Próximos Pasos

1. **Probar la Aplicación**: Accede a https://localhost:8443
2. **Instalar Módulos**: Usa el App Store de Odoo
3. **Personalizar**: Modifica los archivos de configuración según tus necesidades
4. **Desarrollo**: Agrega tus módulos personalizados en `addons/`
5. **Producción**: Cuando esté listo, usa los scripts de producción para el servidor

## 📞 Soporte

Si tienes problemas:
1. Ejecuta `./test-local-install.sh` para verificar el estado
2. Revisa los logs con `./odoo-utils.sh logs`
3. Verifica el estado con `./deploy-local.sh status`

---

**¡Tu instalación local de Odoo 18.0 está lista para desarrollo! 🎉**
