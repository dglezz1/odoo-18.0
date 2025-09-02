# Configuración de Subdominio en Cloudflare para Odoo

## Paso 1: Configurar DNS en Cloudflare

### 1.1 Acceder al Panel de Cloudflare
1. Ir a [cloudflare.com](https://cloudflare.com)
2. Iniciar sesión en tu cuenta
3. Seleccionar el dominio `filltech-ai.com`

### 1.2 Crear el Subdominio
1. Ir a la pestaña **DNS** → **Records**
2. Hacer clic en **Add record**
3. Configurar el registro:
   ```
   Type: A
   Name: odoo (esto creará odoo.filltech-ai.com)
   IPv4 address: TU_IP_PUBLICA
   Proxy status: ☑ Proxied (nube naranja)
   TTL: Auto
   ```

### 1.3 Obtener tu IP Pública
```bash
# Obtener IP pública
curl ifconfig.me
# o
curl ipinfo.io/ip
```

### 1.4 Configurar Certificado SSL
En Cloudflare:
1. Ir a **SSL/TLS** → **Overview**
2. Seleccionar **Full (strict)** para máxima seguridad
3. Ir a **SSL/TLS** → **Edge Certificates**
4. Activar **Always Use HTTPS**

## Paso 2: Preparar el Servidor Local

### 2.1 Configurar Router/Firewall
```bash
# Abrir puerto 80 (HTTP) y 443 (HTTPS) en tu router
# Hacer port forwarding:
# Puerto externo 80 → IP_LOCAL:80
# Puerto externo 443 → IP_LOCAL:443
```

### 2.2 Verificar Configuración de Red
```bash
# Verificar IP local
ip route get 1.1.1.1 | awk '{print $7; exit}'

# Verificar puertos abiertos
sudo netstat -tuln | grep -E ':80|:443'
```

## Paso 3: Despliegue de Producción

### 3.1 Usar el Archivo de Configuración
```bash
# Copiar el archivo de configuración
cp .env.filltech .env

# Verificar configuración
cat .env
```

### 3.2 Ejecutar Despliegue de Producción
```bash
# Detener servicios anteriores
docker-compose down

# Construir y ejecutar en producción
docker-compose -f docker-compose.prod.yml up -d --build

# Verificar servicios
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

### 3.3 Configurar SSL Automático
```bash
# Ejecutar script de SSL
chmod +x ssl-setup.sh
sudo ./ssl-setup.sh

# El script configurará automáticamente:
# - Certificados Let's Encrypt
# - Renovación automática
# - Redirección HTTPS
```

## Paso 4: Obtener Tokens de Cloudflare

### 4.1 API Token para Let's Encrypt
1. Ir a **My Profile** → **API Tokens**
2. Crear token con permisos:
   - **Zone:Zone:Read**
   - **Zone:DNS:Edit**
   - Recursos: `Include: Specific zone: filltech-ai.com`

### 4.2 Zone ID
1. En el dashboard de `filltech-ai.com`
2. En el sidebar derecho, copiar **Zone ID**

## Paso 5: Configuración Avanzada de Nginx

### 5.1 Archivo de Configuración Personalizada
```bash
# Crear configuración personalizada para el subdominio
sudo nano nginx/nginx.filltech.conf
```

### 5.2 Contenido de nginx.filltech.conf
```nginx
upstream odoo {
    server odoo:8069;
}

upstream odoochat {
    server odoo:8072;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name odoo.filltech-ai.com;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name odoo.filltech-ai.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/odoo.filltech-ai.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/odoo.filltech-ai.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/odoo.filltech-ai.com/chain.pem;

    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # Cloudflare Real IP
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 104.16.0.0/12;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    real_ip_header CF-Connecting-IP;

    # Gzip Compression
    gzip on;
    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    gzip_min_length 1000;

    client_max_body_size 200M;

    # Odoo Backend
    location / {
        proxy_pass http://odoo;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 300s;
    }

    # Odoo Chat/WebSocket
    location /websocket {
        proxy_pass http://odoochat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
    }

    # Static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Block access to sensitive files
    location ~* \.(log|conf)$ {
        deny all;
    }
}
```

## Paso 6: Script de Despliegue Automatizado

### 6.1 Script para Cloudflare
```bash
# Crear script de despliegue
nano deploy-filltech.sh
chmod +x deploy-filltech.sh
```

## Paso 7: Verificación y Monitoreo

### 7.1 Verificar Configuración
```bash
# Verificar certificados SSL
curl -I https://odoo.filltech-ai.com

# Verificar respuesta de Odoo
curl -L https://odoo.filltech-ai.com/web/database/selector

# Verificar logs
docker-compose -f docker-compose.prod.yml logs -f nginx
docker-compose -f docker-compose.prod.yml logs -f odoo
```

### 7.2 Monitoreo Continuo
```bash
# Ver estado de servicios
docker-compose -f docker-compose.prod.yml ps

# Ver uso de recursos
docker stats

# Ver logs en tiempo real
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

## Paso 8: Troubleshooting Común

### 8.1 Problemas de Conectividad
```bash
# Verificar que el puerto esté abierto
telnet tu_ip_publica 80
telnet tu_ip_publica 443

# Verificar DNS
nslookup odoo.filltech-ai.com
dig odoo.filltech-ai.com
```

### 8.2 Problemas de SSL
```bash
# Verificar certificados
openssl s_client -connect odoo.filltech-ai.com:443

# Renovar certificados manualmente
sudo certbot renew --dry-run
```

### 8.3 Problemas de Cloudflare
- Verificar que el proxy esté activado (nube naranja)
- Comprobar que SSL esté en modo "Full (strict)"
- Revisar reglas de firewall en Cloudflare
- Verificar que no haya reglas de Page Rules conflictivas

## Paso 9: Configuración de Firewall Local

### 9.1 UFW (Ubuntu/Debian)
```bash
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8069
sudo ufw allow 5432
sudo ufw enable
```

### 9.2 Firewalld (CentOS/RHEL)
```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8069/tcp
sudo firewall-cmd --reload
```

## Notas Importantes

1. **Seguridad**: Nunca commits los archivos `.env.*` al repositorio
2. **Backup**: Siempre haz backup de la base de datos antes de actualizar
3. **Monitoreo**: Configura alertas para servicios caídos
4. **Performance**: Considera usar un CDN adicional para archivos estáticos
5. **Logs**: Mantén rotación de logs para evitar llenar el disco

## Comandos de Emergencia

```bash
# Detener todo
docker-compose -f docker-compose.prod.yml down

# Reiniciar servicios
docker-compose -f docker-compose.prod.yml restart

# Ver logs de errores
docker-compose -f docker-compose.prod.yml logs --tail=50 odoo | grep ERROR

# Backup rápido de BD
docker exec $(docker-compose ps -q db) pg_dump -U odoo odoo > backup_$(date +%Y%m%d_%H%M%S).sql
```
