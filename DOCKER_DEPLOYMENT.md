# Guía de Despliegue Docker de Odoo 18.0

## 🐳 Arquitectura Docker

Esta configuración Docker incluye:
- **Odoo 18.0** - Aplicación principal
- **PostgreSQL 14** - Base de datos
- **Nginx** - Reverse proxy con SSL
- **Redis** - Cache de sesiones (opcional)

## 🚀 Instalación y Despliegue

### 1. Requisitos Previos

```bash
# Verificar Docker
docker --version
docker-compose --version

# En macOS con Homebrew
brew install docker
brew install docker-compose

# En Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io docker-compose
```

### 2. Instalación Rápida

```bash
# Hacer ejecutable el script de gestión
chmod +x docker-manage.sh

# Configurar entorno
cp .env.example .env
# Editar .env con tu configuración

# Construir e iniciar
./docker-manage.sh build
./docker-manage.sh start
```

### 3. Acceso a la Aplicación

- **HTTPS**: https://localhost
- **HTTP**: http://localhost
- **Directo**: http://localhost:8069

**Credenciales por defecto:**
- Usuario: `admin`
- Contraseña: `admin`

## 📋 Comandos de Gestión

### Servicios Básicos

```bash
# Iniciar servicios
./docker-manage.sh start

# Detener servicios
./docker-manage.sh stop

# Reiniciar servicios
./docker-manage.sh restart

# Ver estado
./docker-manage.sh status

# Ver logs
./docker-manage.sh logs
./docker-manage.sh logs odoo
```

### Gestión de Base de Datos

```bash
# Inicializar base de datos
./docker-manage.sh init-db

# Hacer backup
./docker-manage.sh backup

# Restaurar backup
./docker-manage.sh restore /path/to/backup.sql

# Abrir shell de Odoo
./docker-manage.sh shell
```

### Gestión de Módulos

```bash
# Instalar módulos
./docker-manage.sh install sale,purchase,stock

# Actualizar módulos
./docker-manage.sh update base,web

# Ejecutar comando personalizado
./docker-manage.sh exec python3 /opt/odoo/odoo/odoo-bin --help
```

## ⚙️ Configuración Personalizada

### Variables de Entorno (.env)

```bash
# Database
POSTGRES_USER=odoo
POSTGRES_PASSWORD=secure_password
DB_NAME=production_db

# Odoo
ODOO_ADMIN_PASSWORD=super_secure_password
ODOO_WORKERS=4
ODOO_LOG_LEVEL=info

# Ports
ODOO_PORT=8069
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# SSL
SSL_CERT_PATH=./nginx/ssl/server.crt
SSL_KEY_PATH=./nginx/ssl/server.key
```

### Personalizar docker-compose.yml

```yaml
# Agregar volúmenes personalizados
volumes:
  - ./custom_addons:/opt/odoo/addons
  - ./custom_config:/opt/odoo/config

# Cambiar límites de recursos
deploy:
  resources:
    limits:
      memory: 2G
      cpus: "1.0"
```

## 🔒 Configuración SSL/HTTPS

### Certificados Auto-firmados (Desarrollo)

```bash
# Generar certificados SSL
./docker-manage.sh ssl
```

### Certificados de Producción

```bash
# Usar Let's Encrypt con Certbot
docker run -it --rm \
  -v $PWD/nginx/ssl:/etc/letsencrypt \
  certbot/certbot certonly --standalone \
  -d your-domain.com
```

## 🔧 Configuración de Producción

### 1. Optimización de Performance

```bash
# En .env
ODOO_WORKERS=8  # 2 × CPU cores + 1
ODOO_MAX_CRON_THREADS=2
ODOO_LIMIT_MEMORY_HARD=4294967296  # 4GB
ODOO_LIMIT_MEMORY_SOFT=3221225472  # 3GB
```

### 2. Monitoreo y Logs

```yaml
# Agregar a docker-compose.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 3. Backup Automático

```bash
# Crear cron job
0 2 * * * /path/to/odoo/docker-manage.sh backup
```

## 🛡️ Seguridad

### 1. Cambiar Credenciales

```bash
# En .env
POSTGRES_PASSWORD=strong_random_password
ODOO_ADMIN_PASSWORD=another_strong_password
```

### 2. Firewall

```bash
# Permitir solo puertos necesarios
ufw allow 80
ufw allow 443
ufw deny 8069  # Bloquear acceso directo
```

### 3. Nginx Security Headers

Ya incluidos en `nginx/nginx.conf`:
- HSTS
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection

## 🔍 Troubleshooting

### Problemas Comunes

1. **Puerto ya en uso**:
```bash
# Verificar puertos
sudo lsof -i :8069
sudo lsof -i :80

# Cambiar puertos en .env
ODOO_PORT=8070
```

2. **Error de permisos**:
```bash
# Corregir permisos
sudo chown -R $USER:$USER .
chmod +x docker-manage.sh
```

3. **Base de datos no conecta**:
```bash
# Verificar logs
./docker-manage.sh logs db
./docker-manage.sh logs odoo
```

4. **SSL no funciona**:
```bash
# Regenerar certificados
rm -rf nginx/ssl/*
./docker-manage.sh ssl
./docker-manage.sh restart
```

### Logs y Debugging

```bash
# Ver todos los logs
./docker-manage.sh logs

# Logs específicos
./docker-manage.sh logs odoo
./docker-manage.sh logs db
./docker-manage.sh logs nginx

# Entrar al contenedor
./docker-manage.sh exec bash

# Verificar configuración
./docker-manage.sh exec cat /opt/odoo/config/odoo.conf
```

## 📦 Estructura de Archivos Docker

```
odoo-18.0/
├── Dockerfile              # Imagen de Odoo
├── docker-compose.yml      # Orquestación de servicios
├── docker-manage.sh        # Script de gestión
├── .env.example           # Variables de entorno ejemplo
├── .dockerignore          # Archivos a ignorar
├── generate_ssl.sh        # Generador de SSL
├── config/
│   └── odoo.conf         # Configuración de Odoo
├── scripts/
│   ├── entrypoint.sh     # Script de entrada
│   └── wait-for-psql.py  # Espera por PostgreSQL
└── nginx/
    ├── nginx.conf        # Configuración de Nginx
    └── ssl/              # Certificados SSL
```

## 🚀 Despliegue en Producción

### 1. Servidor de Producción

```bash
# Clonar repositorio
git clone https://github.com/your-repo/odoo-docker.git
cd odoo-docker

# Configurar producción
cp .env.example .env
# Editar .env con configuración de producción

# Construir e iniciar
./docker-manage.sh build
./docker-manage.sh start
```

### 2. Docker Swarm (Multi-nodo)

```bash
# Inicializar swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml odoo
```

### 3. Kubernetes

```yaml
# Crear manifiestos K8s
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/odoo.yaml
kubectl apply -f k8s/nginx.yaml
```

---

**Para más información, consulta:**
- `README_INSTALACION.md` - Instalación nativa
- `INSTALACION_ODOO_18.md` - Guía completa macOS
- `INSTALACION_ODOO_18_WINDOWS.md` - Guía completa Windows
