# 🚀 Guía Completa de Deploy de Producción - Odoo 18.0

## 🌐 Dominio: odoo.filltech-ai.com

Esta guía te llevará paso a paso para desplegar Odoo 18.0 en producción con tu dominio personalizado.

---

## 📋 Requisitos Previos

### 🖥️ Servidor
- **Ubuntu Server 20.04+** (recomendado)
- **2 CPU cores mínimo** (4+ recomendado)
- **4GB RAM mínimo** (8GB+ recomendado)
- **40GB disco mínimo** (100GB+ recomendado)
- **Acceso root/sudo**

### 🌐 Dominio y DNS
- **Dominio**: `filltech-ai.com` gestionado por Cloudflare
- **Subdominio**: `odoo.filltech-ai.com`
- **API Token de Cloudflare** (o API Key + Email)

### 🔐 Accesos
- **SSH** al servidor
- **Puertos abiertos**: 22 (SSH), 80 (HTTP), 443 (HTTPS)

---

## 🚀 Paso 1: Preparar el Servidor

### 1.1 Conectar al Servidor
```bash
ssh root@tu-servidor-ip
# o
ssh ubuntu@tu-servidor-ip
```

### 1.2 Actualizar Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.3 Crear Usuario para Odoo (opcional pero recomendado)
```bash
sudo adduser odoo-admin
sudo usermod -aG sudo odoo-admin
sudo usermod -aG docker odoo-admin
```

### 1.4 Clonar el Repositorio
```bash
cd /opt
sudo git clone https://github.com/dglezz1/odoo-18.0.git
sudo chown -R $USER:$USER /opt/odoo-18.0
cd /opt/odoo-18.0
```

---

## ☁️ Paso 2: Configurar DNS en Cloudflare

### 2.1 Obtener API Token de Cloudflare
1. Ve a https://dash.cloudflare.com/profile/api-tokens
2. Clic en "Create Token"
3. Selecciona "Custom token"
4. Configuración:
   - **Token name**: Odoo DNS Manager
   - **Permissions**:
     - Zone:Zone:Read
     - Zone:DNS:Edit
   - **Zone Resources**:
     - Include:Zone:filltech-ai.com

### 2.2 Configurar Variables de Entorno
```bash
export CF_API_TOKEN='tu_token_de_cloudflare_aqui'
```

### 2.3 Ejecutar Configuración de DNS
```bash
./setup-cloudflare-dns.sh
```

Este script:
- ✅ Detecta la IP de tu servidor
- ✅ Configura el registro DNS `odoo.filltech-ai.com`
- ✅ Habilita el proxy de Cloudflare
- ✅ Verifica la propagación

---

## 🐳 Paso 3: Deploy de Producción

### 3.1 Ejecutar Deploy Automatizado
```bash
./deploy-production.sh
```

### 3.2 ¿Qué hace este script?

#### 🔧 Preparación del Servidor:
- ✅ Instala Docker y Docker Compose
- ✅ Configura el firewall (UFW)
- ✅ Crea directorios necesarios
- ✅ Genera contraseñas seguras

#### 🐳 Deploy de Servicios:
- ✅ PostgreSQL 14 (base de datos)
- ✅ Redis (cache y sesiones)
- ✅ Odoo 18.0 (aplicación)
- ✅ Nginx (proxy reverso)

#### 🔐 Configuración SSL:
- ✅ Certificados Let's Encrypt
- ✅ Renovación automática
- ✅ Headers de seguridad

#### 🛡️ Seguridad:
- ✅ Firewall configurado
- ✅ Solo HTTPS permitido
- ✅ Contraseñas generadas automáticamente

---

## 🎯 Paso 4: Verificación y Configuración

### 4.1 Verificar Servicios
```bash
cd /opt/odoo-18.0
docker-compose -f docker-compose.server.yml ps
```

### 4.2 Ver Logs (si hay problemas)
```bash
# Logs generales
docker-compose -f docker-compose.server.yml logs

# Logs específicos
docker-compose -f docker-compose.server.yml logs odoo
docker-compose -f docker-compose.server.yml logs nginx
docker-compose -f docker-compose.server.yml logs db
```

### 4.3 Acceder a Odoo
1. **URL**: https://odoo.filltech-ai.com
2. **Usuario**: `admin`
3. **Contraseña**: *La que generó el script (guardada en .env.production)*

### 4.4 Configuración Inicial de Odoo
1. **Seleccionar idioma**: Español (España) o el que prefieras
2. **Configurar empresa**:
   - Nombre: FillTech AI
   - País: España (o el tuyo)
   - Moneda: EUR (o la tuya)
3. **Instalar aplicaciones** según tus necesidades

---

## 🔧 Comandos de Gestión

### 📊 Estado de Servicios
```bash
cd /opt/odoo-18.0
docker-compose -f docker-compose.server.yml ps
```

### 🔄 Reiniciar Servicios
```bash
# Todos los servicios
docker-compose -f docker-compose.server.yml restart

# Servicio específico
docker-compose -f docker-compose.server.yml restart odoo
docker-compose -f docker-compose.server.yml restart nginx
```

### 📜 Ver Logs
```bash
# Logs en tiempo real
docker-compose -f docker-compose.server.yml logs -f

# Últimas líneas
docker-compose -f docker-compose.server.yml logs --tail=50
```

### 🛑 Detener Servicios
```bash
docker-compose -f docker-compose.server.yml down
```

### ▶️ Iniciar Servicios
```bash
docker-compose -f docker-compose.server.yml --env-file .env.production up -d
```

---

## 💾 Backups y Mantenimiento

### 🗄️ Backup de Base de Datos
```bash
# Crear directorio de backups
mkdir -p /opt/odoo-backups

# Backup manual
docker exec -t $(docker-compose -f docker-compose.server.yml ps -q db) pg_dump -U odoo odoo_prod > /opt/odoo-backups/odoo_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup automatizado (añadir a cron)
echo "0 2 * * * cd /opt/odoo-18.0 && docker exec -t \$(docker-compose -f docker-compose.server.yml ps -q db) pg_dump -U odoo odoo_prod > /opt/odoo-backups/odoo_backup_\$(date +\%Y\%m\%d_\%H\%M\%S).sql" | crontab -
```

### 🔄 Actualizar Odoo
```bash
cd /opt/odoo-18.0
git pull origin production
docker-compose -f docker-compose.server.yml down
docker-compose -f docker-compose.server.yml build --no-cache
docker-compose -f docker-compose.server.yml --env-file .env.production up -d
```

---

## 🚨 Solución de Problemas

### ❌ Problema: "No se puede acceder al sitio"
**Causas posibles**:
1. DNS no propagado
2. Firewall bloqueando puertos
3. Nginx no iniciado

**Soluciones**:
```bash
# Verificar DNS
nslookup odoo.filltech-ai.com

# Verificar puertos
sudo ufw status
sudo netstat -tlnp | grep :443

# Reiniciar Nginx
docker-compose -f docker-compose.server.yml restart nginx
```

### ❌ Problema: "Error 502 Bad Gateway"
**Causa**: Odoo no responde

**Solución**:
```bash
# Verificar estado de Odoo
docker-compose -f docker-compose.server.yml logs odoo

# Reiniciar Odoo
docker-compose -f docker-compose.server.yml restart odoo

# Esperar 30-60 segundos para que inicie
```

### ❌ Problema: "Database connection error"
**Causa**: PostgreSQL no disponible

**Solución**:
```bash
# Verificar PostgreSQL
docker-compose -f docker-compose.server.yml logs db

# Reiniciar PostgreSQL
docker-compose -f docker-compose.server.yml restart db
```

### ❌ Problema: "SSL Certificate error"
**Causa**: Let's Encrypt fallido

**Solución**:
```bash
# Verificar certificado
docker-compose -f docker-compose.server.yml logs nginx

# Regenerar certificado (detener nginx primero)
docker-compose -f docker-compose.server.yml stop nginx
docker run --rm -v "$(pwd)/data/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/data/certbot/www:/var/www/certbot" \
    -p 80:80 certbot/certbot certonly --standalone \
    --email admin@filltech-ai.com --agree-tos --no-eff-email \
    -d odoo.filltech-ai.com
docker-compose -f docker-compose.server.yml start nginx
```

---

## 📞 Soporte

### 📊 Información del Sistema
```bash
# Información de Docker
docker --version
docker-compose --version

# Uso de recursos
df -h
free -h
htop
```

### 📝 Logs Importantes
- **Odoo**: `docker-compose logs odoo`
- **Nginx**: `docker-compose logs nginx`  
- **PostgreSQL**: `docker-compose logs db`
- **Sistema**: `sudo journalctl -u docker`

---

## ✅ Checklist de Verificación

- [ ] DNS configurado en Cloudflare
- [ ] Servidor preparado (Docker, firewall)
- [ ] Servicios desplegados
- [ ] SSL configurado y funcionando
- [ ] Odoo accesible en https://odoo.filltech-ai.com
- [ ] Login exitoso con credenciales de admin
- [ ] Backup automatizado configurado
- [ ] Renovación SSL automática

---

**🎉 ¡Tu Odoo 18.0 está listo en producción! 🚀**

**URL**: https://odoo.filltech-ai.com  
**Gestiona tu negocio desde cualquier lugar con la potencia de Odoo y la seguridad de tu propia infraestructura.**
