# 🌐 Guía de Configuración para Internet con Nginx

## 🚀 **Configuración Rápida para Producción**

### **Paso 1: Configurar variables de entorno**
```bash
# Editar archivo de configuración
cp .env.prod .env.prod.local
nano .env.prod.local

# Cambiar estos valores:
DOMAIN=tu-dominio.com                    # Tu dominio real
DB_PASSWORD=password_super_seguro         # Password seguro para BD
ADMIN_PASSWORD=admin_password_seguro      # Password del admin de Odoo
SSL_EMAIL=tu-email@dominio.com           # Email para Let's Encrypt
```

### **Paso 2: Configurar DNS**
Apuntar tu dominio al servidor:
```bash
# En tu proveedor de DNS, crear registro A:
tu-dominio.com  →  IP_DE_TU_SERVIDOR
```

### **Paso 3: Configurar SSL automáticamente**
```bash
# Generar certificados SSL de Let's Encrypt
./ssl-setup.sh tu-dominio.com tu-email@dominio.com
```

### **Paso 4: Iniciar en producción**
```bash
# Inicialización completa
./deploy-prod.sh init

# O paso a paso:
./deploy-prod.sh start    # Iniciar servicios
./deploy-prod.sh ssl      # Obtener certificados SSL reales
```

---

## 🔧 **Comandos de Gestión**

### **Estado y logs:**
```bash
./deploy-prod.sh status           # Ver estado de servicios
./deploy-prod.sh logs            # Ver todos los logs
./deploy-prod.sh logs nginx      # Ver logs de Nginx
./deploy-prod.sh logs odoo       # Ver logs de Odoo
```

### **Gestión de SSL:**
```bash
./deploy-prod.sh ssl             # Obtener certificados iniciales
./deploy-prod.sh renew-ssl       # Renovar certificados
```

### **Backups:**
```bash
./deploy-prod.sh backup          # Crear backup
./deploy-prod.sh restore archivo.sql  # Restaurar backup
```

### **Mantenimiento:**
```bash
./deploy-prod.sh restart         # Reiniciar todos los servicios
./deploy-prod.sh update          # Actualizar imágenes Docker
./deploy-prod.sh clean           # Limpiar sistema (¡cuidado!)
```

---

## 🔒 **Configuraciones de Seguridad**

### **Firewall (Ubuntu/Debian):**
```bash
# Instalar UFW
sudo ufw enable

# Permitir solo puertos necesarios
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS

# Bloquear acceso directo a bases de datos
sudo ufw deny 5432     # PostgreSQL
```

### **Configuraciones adicionales en Nginx:**
- ✅ Rate limiting para APIs y login
- ✅ Headers de seguridad (CSP, HSTS, etc.)
- ✅ Bloqueo de endpoints sensibles (`/database`, `/web/database`)
- ✅ Compresión GZIP
- ✅ Cache de archivos estáticos

### **Configuraciones de Odoo:**
- ✅ `proxy_mode = True` (para headers correctos)
- ✅ `list_db = False` (ocultar lista de bases de datos)
- ✅ Workers múltiples para mejor performance
- ✅ Límites de memoria y CPU
- ✅ Logs estructurados

---

## 📊 **Monitoreo y Performance**

### **URLs importantes:**
- **Aplicación:** https://tu-dominio.com
- **Logs Nginx:** `docker-compose -f docker-compose.prod.yml logs nginx`
- **Logs Odoo:** `docker-compose -f docker-compose.prod.yml logs odoo`

### **Métricas a monitorear:**
```bash
# Uso de recursos
docker stats

# Logs en tiempo real
./deploy-prod.sh logs -f

# Estado de certificados SSL
./deploy-prod.sh ssl-status
```

### **Cron para renovación automática SSL:**
```bash
# Agregar a crontab (crontab -e)
0 3 * * 1 /ruta/a/tu/proyecto/deploy-prod.sh renew-ssl
```

---

## 🚨 **Troubleshooting**

### **Problemas comunes:**

1. **Error 502 Bad Gateway**
   ```bash
   ./deploy-prod.sh logs nginx
   ./deploy-prod.sh logs odoo
   ```

2. **Certificados SSL inválidos**
   ```bash
   ./deploy-prod.sh ssl    # Regenerar certificados
   ```

3. **Base de datos no accesible**
   ```bash
   ./deploy-prod.sh logs db
   ```

4. **Performance lenta**
   - Aumentar workers en `config/odoo.prod.conf`
   - Verificar recursos del servidor
   - Optimizar consultas de BD

### **Logs útiles:**
```bash
# Ver los últimos errores
./deploy-prod.sh logs | grep ERROR

# Monitorear conexiones
./deploy-prod.sh logs nginx | grep "POST\|GET"

# Ver uso de memoria
docker stats --no-stream
```

---

## 🎯 **Configuración Completa en 5 Minutos**

```bash
# 1. Clonar/preparar archivos
git clone tu-repositorio
cd odoo-18.0

# 2. Configurar variables
cp .env.prod .env.prod.local
# Editar DOMAIN, DB_PASSWORD, ADMIN_PASSWORD, SSL_EMAIL

# 3. Configurar SSL y desplegar
./ssl-setup.sh tu-dominio.com tu-email@dominio.com
./deploy-prod.sh init

# 4. ¡Listo! Acceder a https://tu-dominio.com
```

**¡Tu Odoo estará accesible desde internet con HTTPS en menos de 5 minutos!** 🚀
