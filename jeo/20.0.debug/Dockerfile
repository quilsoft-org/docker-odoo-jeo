FROM jobiols/odoo-jeo:20.0
LABEL maintainer="Jorge Obiols <jorge.obiols@gmail.com>"

USER root

RUN apt-get update && apt-get install -y git

# install wdb — master HEAD on purpose: Jorge owns the repo and wants the latest
RUN /odoo/venv/bin/pip install --no-cache-dir \
    https://github.com/jobiols/wdb/archive/refs/heads/master.tar.gz#subdirectory=client

# sin esto no anda el wdb
RUN /odoo/venv/bin/pip install --no-cache-dir debugpy

USER odoo
