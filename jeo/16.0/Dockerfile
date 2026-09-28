# ============================================================
# STAGE 1: builder — compila todo, después lo descartamos
# ============================================================
FROM ubuntu:jammy AS builder

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG=en_US.UTF-8
ENV ODOO_VERSION=16.0
ARG ODOO_RELEASE
ENV ODOO_RELEASE=${ODOO_RELEASE}
ENV ODOO_HOME=/odoo
ENV VENV_PATH=/odoo/venv

# Mirror apt (ARG para construir en otros lados sin editar el Dockerfile)
ARG APT_MIRROR=http://ubuntu.unc.edu.ar

RUN sed -i "s|http://archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list && \
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
        libssl-dev \
        swig && \
    rm -rf /var/lib/apt/lists/*

# Crear venv (Python 3.10 nativo de jammy)
RUN python3 -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Actualizar pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Clonar Odoo: seguimos la rama ${ODOO_VERSION} (HEAD móvil) para traer siempre
# los últimos cambios. Eliminar .git para ahorrar ~200MB.
RUN git clone --depth 1 --branch ${ODOO_VERSION} \
        https://www.github.com/odoo/odoo ${ODOO_HOME}/odoo-src && \
    rm -rf ${ODOO_HOME}/odoo-src/.git

# Odoo 16 pinnea para Python 3.10 (jammy) versiones sin wheel cp310 que no
# compilan con Cython 3.x. Subimos a las versiones que Odoo usa para 3.11+,
# que sí traen wheel cp310.
RUN sed -i 's/gevent==21.8.0/gevent==22.10.2/; s/greenlet==1.1.2/greenlet==2.0.2/; s/MarkupSafe==1.1.1/MarkupSafe==2.0.1/' \
    ${ODOO_HOME}/odoo-src/requirements.txt

# Instalar requerimientos de Odoo Core
RUN pip install --no-cache-dir -r ${ODOO_HOME}/odoo-src/requirements.txt

# Instalar dependencias extra comunes en módulos Odoo
RUN pip install --no-cache-dir \
    python-magic \
    num2words \
    odfpy \
    pdfminer.six \
    phonenumbers \
    python-ldap \
    qrcode \
    Pillow \
    reportlab \
    vobject \
    watchdog \
    xlrd \
    xlwt

# Odoo instala una versión vieja de xlsxwriter; la forzamos a una reciente
RUN pip install --no-cache-dir "xlsxwriter>=3.2.5"

# Requerimientos adicionales del usuario
COPY ./requirements /req
RUN pip install --no-cache-dir -r /req/requirements.txt && \
    pip install --no-cache-dir -r /req/odoo-argentina.txt && \
    rm -rf /req

# Instalar rtlcss y limpiar cache de npm
RUN npm install -g rtlcss && npm cache clean --force

# ============================================================
# STAGE 2: runtime — ubuntu:jammy para Python 3.10 (Odoo 16 no soporta 3.12)
# ============================================================
FROM ubuntu:jammy AS runtime

LABEL maintainer="Jorge Obiols <jorge.obiols@gmail.com>"
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG=en_US.UTF-8
ENV ODOO_VERSION=16.0
ARG ODOO_RELEASE
ENV ODOO_RELEASE=${ODOO_RELEASE}
ENV ODOO_HOME=/odoo
ENV VENV_PATH=/odoo/venv
ENV PATH="${VENV_PATH}/bin:${ODOO_HOME}/odoo-src:${PATH}"

# Mirror apt (ARG para construir en otros lados sin editar el Dockerfile)
ARG APT_MIRROR=http://ubuntu.unc.edu.ar

# Solo librerías de RUNTIME (sin *-dev, sin build-essential, sin git, sin npm)
RUN sed -i "s|http://archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        fonts-dejavu-core \
        fonts-noto-cjk \
        libssl3 \
        libpq5 \
        libldap-2.5-0 \
        libmagic1 \
        libsasl2-2 \
        node-less \
        openssl \
        python3 \
        xz-utils && \
    # Instalar wkhtmltopdf
    TARGETARCH=${TARGETARCH:-$(dpkg --print-architecture)} && \
    case ${TARGETARCH} in \
        "amd64") WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59 ;; \
        "arm64") WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc ;; \
    esac && \
    curl -o wkhtmltox.deb -sSL \
        https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${TARGETARCH}.deb && \
    echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb


# Instalar dependencias de librerías gráficas para reportes
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    libffi8 \
    shared-mime-info && \
    rm -rf /var/lib/apt/lists/*

# Instalar cliente PostgreSQL desde el repo oficial
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
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
RUN mkdir -p ${VENV_PATH}/lib/python3.10/site-packages/pyafipws/cache && \
    chmod -R 777 ${VENV_PATH}/lib/python3.10/site-packages/pyafipws

# AFIP tiene cifrado débil (DH_KEY_TOO_SMALL); bajamos SECLEVEL a 1
RUN sed -i "s/CipherString = DEFAULT:@SECLEVEL=2/CipherString = DEFAULT:@SECLEVEL=1/" /etc/ssl/openssl.cnf

COPY entrypoint.sh /
COPY odoo.conf ${ETC_DIR}/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN chmod +x /entrypoint.sh /usr/local/bin/wait-for-psql.py

EXPOSE 8069 8071 8072
USER odoo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo-bin"]
