# Odoo 18.0 - Deploy Local

Docker deployment simplificado para Odoo 18.0 en local.

## 🚀 Deploy Rápido

```bash
./deploy.sh
```

## 📋 Comandos

### Iniciar servicios
```bash
docker-compose up -d
```

### Ver logs
```bash
./logs.sh           # Todos los logs
./logs.sh odoo      # Solo Odoo
./logs.sh db        # Solo PostgreSQL
```

### Parar servicios
```bash
docker-compose down
```

## 🌐 Acceso

- URL: http://localhost:8069
- Usuario: admin
- Contraseña: admin
- Base de datos: odoo

## 📁 Estructura

```
├── Dockerfile          # Imagen Odoo optimizada
├── docker-compose.yml  # Servicios (Odoo + PostgreSQL)
├── .env               # Variables de entorno
├── config/            # Configuración Odoo
├── addons/            # Addons oficiales
├── custom_addons/     # Addons personalizados
├── deploy.sh          # Script de deploy
└── logs.sh           # Script de logs
```

## 🛠️ Desarrollo

### Construir imagen
```bash
docker-compose build --no-cache
```

### Reiniciar servicios
```bash
docker-compose restart
```

### Estado de servicios
```bash
docker-compose ps
```

---

**Nota:** Este es un setup para desarrollo local. Para producción usar configuraciones específicas.