#!/bin/bash

echo "🔨 Construyendo Odoo sin caché..."
docker-compose build --no-cache

echo "🚀 Iniciando servicios..."
docker-compose up -d

echo "📊 Estado de servicios:"
docker-compose ps
