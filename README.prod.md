# 🚀 Odoo 18.0 Production Deployment Guide

## 📋 Overview

This is a production-ready Odoo 18.0 deployment with:
- **Multi-stage Docker build** (development/production)
- **Nginx reverse proxy** with SSL support
- **PostgreSQL 13** optimized for production
- **Automated backups** and monitoring
- **Security hardening** and performance tuning

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │      Odoo       │    │   PostgreSQL    │
│  Reverse Proxy  │────│   Application   │────│    Database     │
│   Port 80/443   │    │    Port 8069    │    │    Port 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Configure Environment

Copy and customize the environment file:
```bash
cp .env.prod .env.prod.local
vim .env.prod.local
```

**🔒 IMPORTANT**: Change all passwords in `.env.prod.local`!

### 2. Deploy to Production

```bash
# Deploy full stack
./deploy-prod.sh

# Check service health
./deploy-prod.sh check

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 3. Access Your Installation

- **Main site**: http://localhost
- **Database manager**: http://localhost/web/database/manager
- **Admin panel**: Log in with credentials from `.env.prod.local`

## 📁 File Structure

```
odoo-18.0/
├── 📄 docker-compose.prod.yml      # Production compose file
├── 📄 Dockerfile                   # Multi-stage build
├── 📄 .env.prod                    # Environment template
├── 🗂️ config/
│   ├── 📄 odoo.prod.conf          # Odoo production config
│   └── 📄 odoo.conf               # Development config
├── 🗂️ nginx/
│   └── 📄 nginx.conf              # Nginx configuration
├── 📄 postgresql.conf             # PostgreSQL optimization
├── 📄 entrypoint.prod.sh          # Production entrypoint
├── 📄 deploy-prod.sh              # Deployment script
├── 📄 backup.sh                   # Backup automation
└── 📄 README.prod.md              # This file
```

## ⚙️ Configuration Details

### Odoo Configuration
- **Workers**: 4 (adjust based on CPU cores)
- **Memory limits**: 2GB hard / 1.6GB soft
- **Database connections**: 64 max
- **Logging**: Warn level, structured logs
- **Security**: Database filtering enabled

### PostgreSQL Tuning
- **Shared buffers**: 256MB
- **Effective cache**: 1GB
- **Work memory**: 4MB per operation
- **Autovacuum**: Optimized for Odoo workloads

### Nginx Features
- **SSL ready** (configure certificates)
- **Gzip compression** enabled
- **Rate limiting**: 10 requests/second
- **Security headers** configured
- **Static file caching**: 1 year
- **Health check**: `/nginx-health`

## 🔒 Security Checklist

- [ ] **Change default passwords** in `.env.prod.local`
- [ ] **Configure SSL certificates** for HTTPS
- [ ] **Set up firewall rules** (ports 80, 443, 22)
- [ ] **Enable fail2ban** for SSH protection
- [ ] **Configure backup encryption**
- [ ] **Set up monitoring alerts**
- [ ] **Review Nginx security headers**
- [ ] **Enable PostgreSQL SSL**

## 📊 Monitoring & Maintenance

### View System Status
```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# View resource usage
docker stats

# Check logs
docker-compose -f docker-compose.prod.yml logs -f odoo
```

### Database Maintenance
```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec postgres psql -U odoo_prod -d odoo_prod

# View database size
docker-compose -f docker-compose.prod.yml exec postgres psql -U odoo_prod -c "SELECT pg_size_pretty(pg_database_size('odoo_prod'));"
```

### Backup Management
```bash
# Create manual backup
./backup.sh

# List available backups
./backup.sh list

# Set up automated backups (crontab)
0 2 * * * /path/to/odoo-18.0/backup.sh
```

## 🔧 Troubleshooting

### Common Issues

**1. Service won't start**
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs

# Restart specific service
docker-compose -f docker-compose.prod.yml restart odoo
```

**2. Database connection issues**
```bash
# Test PostgreSQL connectivity
docker-compose -f docker-compose.prod.yml exec odoo nc -zv postgres 5432
```

**3. Performance issues**
```bash
# Check resource usage
docker stats

# Analyze slow queries
docker-compose -f docker-compose.prod.yml exec postgres tail -f /var/log/postgresql/postgresql.log
```

### Performance Tuning

**Scale workers** (edit `config/odoo.prod.conf`):
```ini
workers = 8  # 2 * CPU cores + 1
```

**Increase memory** (edit `docker-compose.prod.yml`):
```yaml
deploy:
  resources:
    limits:
      memory: 4G
```

**Optimize PostgreSQL** (edit `postgresql.conf`):
```ini
shared_buffers = 512MB  # 25% of RAM
effective_cache_size = 2GB  # 75% of RAM
```

## 🔄 Updates & Upgrades

### Update Odoo
```bash
# Pull latest code
git pull origin main

# Rebuild and deploy
./deploy-prod.sh
```

### Database Migration
```bash
# Backup before migration
./backup.sh

# Run migration
docker-compose -f docker-compose.prod.yml exec odoo odoo-bin -u all -d odoo_prod --stop-after-init
```

## 📞 Support & Documentation

- **Odoo Official Docs**: https://www.odoo.com/documentation/18.0/
- **Docker Compose**: https://docs.docker.com/compose/
- **Nginx Documentation**: https://nginx.org/en/docs/
- **PostgreSQL Tuning**: https://pgtune.leopard.in.ua/

## 🎯 Next Steps

1. **SSL Configuration**: Set up Let's Encrypt certificates
2. **Monitoring Setup**: Configure Prometheus + Grafana
3. **Email Configuration**: Set up SMTP in Odoo
4. **Custom Addons**: Add your modules to `addons/`
5. **Backup Strategy**: Configure offsite backups
6. **Load Balancing**: Add HAProxy for multiple Odoo instances

---

**🔥 Production Ready!** Your Odoo 18.0 deployment is optimized for performance, security, and scalability.
