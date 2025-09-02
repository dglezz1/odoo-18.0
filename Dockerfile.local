FROM python:3.11-slim-bullseye

# Metadatos
LABEL maintainer="FillTech AI <admin@filltech-ai.com>"
LABEL version="18.0-local"
LABEL description="Odoo 18.0 Community - Deploy Local Optimizado"

# Variables de entorno
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    ODOO_RC=/etc/odoo/odoo.conf \
    ODOO_HOME=/opt/odoo \
    PYTHONUNBUFFERED=1 \
    ODOO_USER=odoo

# Instalar dependencias del sistema (optimizado)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dirmngr \
    fonts-noto-cjk \
    gnupg \
    libssl-dev \
    node-less \
    npm \
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
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Crear usuario odoo
RUN useradd -r -d $ODOO_HOME -s /bin/bash $ODOO_USER

# Instalar rtlcss (para soporte RTL)
RUN npm install -g rtlcss

# Crear directorios necesarios
RUN mkdir -p \
    $ODOO_HOME \
    /var/lib/odoo \
    /var/log/odoo \
    /etc/odoo \
    /mnt/extra-addons \
    && chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo /var/log/odoo /etc/odoo /mnt/extra-addons

# Descargar e instalar Odoo
WORKDIR $ODOO_HOME
RUN curl -o odoo.tar.gz -sSL https://nightly.odoo.com/18.0/nightly/src/odoo_18.0.latest.tar.gz \
    && tar -xzf odoo.tar.gz --strip-components=1 \
    && rm odoo.tar.gz

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt \
    && pip3 install --no-cache-dir -r requirements.txt

# Configuración de Odoo
COPY config/odoo.conf /etc/odoo/odoo.conf
RUN chown $ODOO_USER:$ODOO_USER /etc/odoo/odoo.conf

# Script de entrada
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Cambiar ownership de archivos Odoo
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

# Cambiar a usuario odoo
USER $ODOO_USER

# Exponer puertos
EXPOSE 8069 8071 8072

# Comando de entrada
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
