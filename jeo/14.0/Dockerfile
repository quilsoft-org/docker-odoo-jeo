# ============================================================
# STAGE 1: builder — compila todo, después lo descartamos
# ============================================================
FROM debian:bullseye-slim AS builder

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG=C.UTF-8
ENV ODOO_VERSION=14.0
ARG ODOO_RELEASE
ENV ODOO_RELEASE=${ODOO_RELEASE}
ENV ODOO_HOME=/odoo
ENV VENV_PATH=/odoo/venv

# bullseye está EOL (LTS venció ago/2026): apuntamos al snapshot congelado de Debian.
ARG DEBIAN_SNAPSHOT=20260824T000000Z

RUN sed -i \
    -e "s|deb http://deb.debian.org/debian |deb http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} |" \
    -e "s|deb http://deb.debian.org/debian-security |deb http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} |" \
    /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-valid-until && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        npm \
        python3-dev \
        python3-pip \
        python3-venv \
        build-essential \
        gcc \
        libpq-dev \
        libldap2-dev \
        libsasl2-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Crear venv (Python 3.9 nativo de bullseye)
RUN python3 -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Actualizar pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Clonar Odoo: seguimos la rama ${ODOO_VERSION}. Rama 14.0 congelada (EOL).
# Eliminar .git para ahorrar ~200MB.
RUN git clone --depth 1 --branch ${ODOO_VERSION} \
        https://www.github.com/odoo/odoo ${ODOO_HOME}/odoo-src && \
    rm -rf ${ODOO_HOME}/odoo-src/.git

# Odoo 14 pinnea para Python 3.9 (bullseye) versiones sin wheel cp39:
# - libsass 0.17.0 (solo cp37, source build rompe con Cython 3)
# - MarkupSafe 1.1.0 (sin wheel cp39; 2.0.1 es el tope compatible con Jinja2 2.11)
# - psycopg2 2.8.5 (no soporta Python 3.9)
RUN sed -i \
    's/libsass==0.17.0/libsass==0.20.1/; s/MarkupSafe==1.1.0/MarkupSafe==2.0.1/; s/psycopg2==2.8.5/psycopg2==2.9.9/' \
    ${ODOO_HOME}/odoo-src/requirements.txt

# Instalar requerimientos de Odoo Core
RUN pip install --no-cache-dir -r ${ODOO_HOME}/odoo-src/requirements.txt

# Dependencias extra comunes en módulos Odoo (las que el .deb traía por apt)
RUN pip install --no-cache-dir \
    python-magic \
    num2words \
    odfpy \
    pdfminer.six \
    phonenumbers \
    python-slugify \
    python-ldap \
    qrcode \
    Pillow \
    reportlab \
    vobject \
    watchdog \
    xlrd \
    xlwt

# Requerimientos adicionales del usuario
COPY ./requirements /req
RUN pip install --no-cache-dir git+https://github.com/OCA/openupgradelib/@master && \
    pip install --no-cache-dir -r /req/adhoc-odoo-argentina-ce.txt && \
    pip install --no-cache-dir -r /req/requirements.txt && \
    pip install --no-cache-dir -r /req/adhoc-aeroo_reports.txt && \
    rm -rf /req

# Instalar rtlcss y limpiar cache de npm
RUN npm install -g rtlcss && npm cache clean --force

# ============================================================
# STAGE 2: runtime — debian:bullseye-slim para Python 3.9 (Odoo 14)
# ============================================================
FROM debian:bullseye-slim AS runtime

LABEL maintainer="Jorge Obiols <jorge.obiols@gmail.com>"
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG=C.UTF-8
ENV ODOO_VERSION=14.0
ARG ODOO_RELEASE
ENV ODOO_RELEASE=${ODOO_RELEASE}
ENV ODOO_HOME=/odoo
ENV VENV_PATH=/odoo/venv
ENV PATH="${VENV_PATH}/bin:${ODOO_HOME}/odoo-src:${PATH}"

# bullseye está EOL (LTS venció ago/2026): apuntamos al snapshot congelado de Debian.
ARG DEBIAN_SNAPSHOT=20260824T000000Z

# Solo librerías de RUNTIME (sin *-dev, sin build-essential, sin git, sin npm)
RUN sed -i \
    -e "s|deb http://deb.debian.org/debian |deb http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} |" \
    -e "s|deb http://deb.debian.org/debian-security |deb http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} |" \
    /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-valid-until && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        fonts-dejavu-core \
        fonts-noto-cjk \
        libssl1.1 \
        libpq5 \
        libldap-2.4-2 \
        libmagic1 \
        libsasl2-2 \
        node-less \
        openssl \
        python3 \
        python3-distutils \
        xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Librerías gráficas para reportes
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    shared-mime-info && \
    rm -rf /var/lib/apt/lists/*

# Instalar cliente PostgreSQL desde el repo oficial
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg && \
    apt-get update && \
    apt-get install --no-install-recommends -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Crear usuario odoo
RUN addgroup --gid 1100 odoo && \
    adduser --system --uid 1100 --gid 1100 \
            --shell /bin/bash --home ${ODOO_HOME} --gecos "ODOO" odoo

# Copiar artefactos compilados desde el builder
COPY --from=builder --chown=odoo:odoo ${VENV_PATH}            ${VENV_PATH}
COPY --from=builder --chown=odoo:odoo ${ODOO_HOME}/odoo-src   ${ODOO_HOME}/odoo-src
COPY --from=builder /usr/local/lib/node_modules   /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/rtlcss         /usr/local/bin/rtlcss

# Configurar directorios y permisos
ENV ETC_DIR=/opt/odoo/etc
ENV DATA_DIR=/opt/odoo/data
ENV LOG_DIR=/var/log/odoo
ENV BKP_DIR=/var/odoo/backups
ENV ADDONS_DIR=/opt/odoo/custom-addons
ENV ODOO_RC=${ETC_DIR}/odoo.conf

RUN mkdir -p ${ETC_DIR} ${DATA_DIR} ${ADDONS_DIR} ${BKP_DIR} ${LOG_DIR} /var/odoo && \
    chown -R odoo:odoo ${DATA_DIR} ${ADDONS_DIR} ${BKP_DIR} ${LOG_DIR} /var/odoo

# Cache para pyafipws (base sqlite que se refresca desde padron AFIP)
RUN mkdir -p ${VENV_PATH}/lib/python3.9/site-packages/pyafipws/cache && \
    chmod -R 777 ${VENV_PATH}/lib/python3.9/site-packages/pyafipws

COPY entrypoint.sh /
COPY odoo.conf ${ETC_DIR}/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /entrypoint.sh /usr/local/bin/wait-for-psql.py

EXPOSE 8069 8071 8072
USER odoo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo-bin"]
