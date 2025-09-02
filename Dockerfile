FROM python:3.11-slim-bullseye AS base

# Metadatos
LABEL maintainer="FillTech AI <admin@filltech-ai.com>"
LABEL version="18.0-production"
LABEL description="Odoo 18.0 Community - Production Ready"

# Variables de entorno
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    ODOO_RC=/etc/odoo/odoo.conf \
    ODOO_HOME=/opt/odoo \
    PYTHONUNBUFFERED=1 \
    ODOO_USER=odoo

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dirmngr \
    fonts-noto-cjk \
    gnupg \
    libssl-dev \
    libpq-dev \
    libldap2-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt-dev \
    netcat \
    node-less \
    npm \
    python3-dev \
    python3-num2words \
    python3-pdfminer \
    python3-pip \
    python3-phonenumbers \
    python3-pyldap \
    python3-qrcode \
    python3-renderpm \
    python3-setuptools \
    python3-slugify \
    python3-vobject \
    python3-watchdog \
    python3-xlrd \
    python3-xlwt \
    xz-utils \
    wkhtmltopdf \
    build-essential \
    gcc \
    g++ \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario odoo
RUN useradd -r -d $ODOO_HOME -s /bin/bash $ODOO_USER

# Instalar rtlcss
RUN npm install -g rtlcss

# ========== DEVELOPMENT STAGE ==========
FROM base AS development

# Crear directorios para desarrollo
RUN mkdir -p \
    $ODOO_HOME \
    /var/lib/odoo \
    /var/log/odoo \
    /etc/odoo \
    /opt/odoo/custom-addons \
    && chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo /var/log/odoo /etc/odoo /opt/odoo/custom-addons

WORKDIR $ODOO_HOME
COPY . .
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

# Instalar dependencias Python
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# ========== PRODUCTION STAGE ==========
FROM base AS production

# Crear directorios para producción
RUN mkdir -p \
    $ODOO_HOME \
    /var/lib/odoo \
    /var/log/odoo \
    /var/run/odoo \
    /etc/odoo \
    /opt/odoo/custom-addons \
    && chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo /var/log/odoo /var/run/odoo /etc/odoo /opt/odoo/custom-addons

WORKDIR $ODOO_HOME

# Copiar solo archivos necesarios para producción
COPY --chown=$ODOO_USER:$ODOO_USER odoo ./odoo
COPY --chown=$ODOO_USER:$ODOO_USER addons ./addons
COPY --chown=$ODOO_USER:$ODOO_USER odoo-bin ./odoo-bin
COPY --chown=$ODOO_USER:$ODOO_USER requirements.txt ./requirements.txt

# Instalar dependencias Python
RUN pip3 install --no-cache-dir -r requirements.txt \
    && pip3 install --no-cache-dir gunicorn

# Configuración de producción
COPY config/odoo.prod.conf /etc/odoo/odoo.conf
RUN chown $ODOO_USER:$ODOO_USER /etc/odoo/odoo.conf

# Script de entrada para producción
COPY entrypoint.prod.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Limpiar herramientas de desarrollo
RUN apt-get remove -y \
    build-essential \
    gcc \
    g++ \
    python3-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Cambiar a usuario no-root
USER $ODOO_USER

# Exponer puerto
EXPOSE 8069

# Configurar volúmenes
VOLUME ["/var/lib/odoo", "/var/log/odoo", "/opt/odoo/custom-addons"]

# Punto de entrada y comando
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/odoo/odoo-bin"]
USER $ODOO_USER

# Exponer puertos
EXPOSE 8069 8071 8072
