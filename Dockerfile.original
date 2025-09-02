# Usar imagen base de Python 3.11 oficial
FROM python:3.11-slim-bullseye

# Información del mantenedor
LABEL maintainer="Odoo 18.0 Docker Setup"
LABEL version="1.0"
LABEL description="Odoo 18.0 Community Edition with PostgreSQL"

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_USER=odoo \
    ODOO_HOME=/opt/odoo \
    ODOO_VERSION=18.0 \
    PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libtiff5-dev \
    libffi-dev \
    libgeoip-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    node-less \
    npm \
    postgresql-client \
    wkhtmltopdf \
    xfonts-75dpi \
    xfonts-base \
    fontconfig \
    libjpeg62-turbo \
    libxrender1 \
    xfonts-utils \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js y SASS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g sass \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario odoo
RUN useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER

# Crear directorios necesarios
RUN mkdir -p $ODOO_HOME/{addons,config,data,logs} \
    && chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

# Cambiar al usuario odoo
USER $ODOO_USER

# Establecer directorio de trabajo
WORKDIR $ODOO_HOME

# Clonar Odoo 18.0
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git odoo

# Crear entorno virtual e instalar dependencias Python
RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install wheel setuptools \
    && pip install -r odoo/requirements.txt \
    && pip install psycopg2-binary \
    && pip install gunicorn

# Copiar archivos de configuración
COPY --chown=$ODOO_USER:$ODOO_USER ./config/odoo.conf $ODOO_HOME/config/
COPY --chown=$ODOO_USER:$ODOO_USER ./scripts/entrypoint.sh $ODOO_HOME/
COPY --chown=$ODOO_USER:$ODOO_USER ./scripts/wait-for-psql.py $ODOO_HOME/

# Hacer ejecutables los scripts
USER root
RUN chmod +x $ODOO_HOME/entrypoint.sh $ODOO_HOME/wait-for-psql.py
USER $ODOO_USER

# Exponer puertos
EXPOSE 8069 8071 8072

# Comando de entrada
ENTRYPOINT ["./entrypoint.sh"]
CMD ["odoo"]
