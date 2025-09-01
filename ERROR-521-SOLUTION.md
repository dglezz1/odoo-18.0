# 🚨 SOLUCIÓN ERROR 521 CLOUDFLARE - Odoo

## ❌ **PROBLEMA**
```
Web server is down Error code 521
Visit cloudflare.com for more information.
2025-09-01 15:50:13 UTC
```

**Error 521 significa**: Cloudflare no puede conectar con tu servidor de origen.

---

## 🔍 **DIAGNÓSTICO RÁPIDO**

### **En tu servidor, ejecuta:**

```bash
# 1. Ir al directorio del proyecto
cd /opt/odoo-18.0

# 2. Diagnóstico automático
./fix-error-521.sh

# 3. O solución rápida
./quick-fix-521.sh
```

---

## 🚨 **CAUSAS COMUNES Y SOLUCIONES**

### **1. Servicios Docker no ejecutándose**
```bash
# Verificar
docker-compose -f docker-compose.server.yml ps

# Si no hay servicios activos:
docker-compose -f docker-compose.server.yml --env-file .env.production up -d
```

### **2. Firewall bloqueando puertos**
```bash
# Verificar firewall
sudo ufw status

# Abrir puertos necesarios
sudo ufw allow 80
sudo ufw allow 443
sudo ufw reload
```

### **3. Nginx no configurado correctamente**
```bash
# Verificar Nginx
docker logs $(docker ps -q --filter "name=nginx")

# Reiniciar Nginx
docker-compose -f docker-compose.server.yml restart nginx
```

### **4. SSL no configurado**
```bash
# Si no tienes certificados SSL, el proxy de Cloudflare falla
# Ejecutar setup completo:
./deploy-production.sh
```

---

## 🔧 **SOLUCIÓN PASO A PASO**

### **PASO 1: Verificar Estado**
```bash
cd /opt/odoo-18.0

# Estado de contenedores
docker ps

# Estado de puertos
netstat -tuln | grep -E ":80|:443|:8069"

# Logs recientes
docker-compose -f docker-compose.server.yml logs --tail=20
```

### **PASO 2: Reiniciar Servicios**
```bash
# Detener todo
docker-compose -f docker-compose.server.yml down

# Limpiar
docker system prune -f

# Reiniciar en orden
docker-compose -f docker-compose.server.yml --env-file .env.production up -d db redis
sleep 15

docker-compose -f docker-compose.server.yml --env-file .env.production up -d odoo  
sleep 30

docker-compose -f docker-compose.server.yml --env-file .env.production up -d nginx
```

### **PASO 3: Verificar Conectividad**
```bash
# Test interno
curl -I http://localhost:8069
curl -I http://localhost:80
curl -I https://localhost:443

# Test externo (reemplaza IP_DEL_SERVIDOR)
curl -I http://IP_DEL_SERVIDOR
```

### **PASO 4: Configurar Firewall**
```bash
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw status verbose
```

---

## ⚡ **SOLUCIÓN RÁPIDA (1 MINUTO)**

### **Opción A: Desactivar proxy Cloudflare temporalmente**

1. **Ve a Cloudflare Dashboard**
2. **DNS Records** → Busca registro `odoo`
3. **Cambia de Proxied (🟠) a DNS only (⚪)**
4. **Espera 2-3 minutos**
5. **Prueba**: http://odoo.filltech-ai.com
6. **Si funciona**: El problema es SSL en el servidor
7. **Ejecuta**: `./deploy-production.sh` para configurar SSL
8. **Reactiva proxy** una vez solucionado

### **Opción B: Usar script automático**
```bash
cd /opt/odoo-18.0
./quick-fix-521.sh
```

---

## 🔐 **SI EL PROBLEMA ES SSL**

### **Síntoma**: Funciona con "DNS only" pero falla con "Proxied"

```bash
# 1. Generar certificados SSL
cd /opt/odoo-18.0

# 2. Detener Nginx temporalmente
docker-compose -f docker-compose.server.yml stop nginx

# 3. Generar certificado Let's Encrypt
docker run --rm -v "$(pwd)/data/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/data/certbot/www:/var/www/certbot" \
    -p 80:80 certbot/certbot certonly --standalone \
    --email admin@filltech-ai.com --agree-tos --no-eff-email \
    -d odoo.filltech-ai.com

# 4. Reiniciar Nginx
docker-compose -f docker-compose.server.yml --env-file .env.production up -d nginx

# 5. Verificar SSL
curl -I https://localhost:443

# 6. Reactivar proxy Cloudflare
```

---

## 🆘 **SI NADA FUNCIONA**

### **Deploy completo desde cero:**
```bash
cd /opt/odoo-18.0

# Limpiar todo
docker-compose -f docker-compose.server.yml down -v
docker system prune -af
docker volume prune -f

# Deploy completo
./deploy-production.sh
```

---

## ✅ **VERIFICACIÓN FINAL**

### **Cuando todo funcione:**

1. **Servicios activos**:
   ```bash
   docker-compose -f docker-compose.server.yml ps
   ```
   Debes ver: `odoo`, `nginx`, `db`, `redis` - todos "Up"

2. **Puertos escuchando**:
   ```bash
   netstat -tuln | grep -E ":80|:443"
   ```

3. **Respuesta HTTP**:
   ```bash
   curl -I http://localhost:80
   curl -I https://localhost:443
   ```

4. **Cloudflare proxy activo**:
   - Dashboard → DNS → `odoo` debe estar **Proxied (🟠)**

5. **Acceso final**:
   - ✅ https://odoo.filltech-ai.com debe cargar Odoo

---

## 📞 **COMANDOS DE EMERGENCIA**

```bash
# Ver todo de una vez
cd /opt/odoo-18.0 && \
docker ps && \
echo "--- PORTS ---" && \
netstat -tuln | grep -E ":80|:443|:8069" && \
echo "--- FIREWALL ---" && \
sudo ufw status && \
echo "--- CONNECTIVITY ---" && \
curl -I http://localhost:8069 && \
echo "--- NGINX LOGS ---" && \
docker logs $(docker ps -q --filter "name=nginx") --tail=5

# Reinicio completo rápido
docker-compose -f docker-compose.server.yml restart && \
sleep 30 && \
docker-compose -f docker-compose.server.yml ps
```

---

## 🎯 **RESULTADO ESPERADO**

Después de la solución:
- ✅ **Error 521 resuelto**
- ✅ **https://odoo.filltech-ai.com** funciona
- ✅ **Proxy Cloudflare activo** (protección DDoS)
- ✅ **SSL A+** configurado
- ✅ **Todos los servicios estables**

---

**⏱️ Tiempo estimado de solución: 5-15 minutos**

*Si sigues teniendo problemas, ejecuta `./fix-error-521.sh` para diagnóstico detallado.*
