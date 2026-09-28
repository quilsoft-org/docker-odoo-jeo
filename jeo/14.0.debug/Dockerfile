FROM jobiols/odoo-jeo:14.0
LABEL maintainer="Jorge Obiols <jorge.obiols@gmail.com>"

USER root

# install wdb — master HEAD on purpose: Jorge owns the repo and wants the latest
RUN /odoo/venv/bin/pip install --no-cache-dir \
    https://github.com/jobiols/wdb/archive/refs/heads/master.tar.gz#subdirectory=client

# debugpy para debugear
RUN /odoo/venv/bin/pip install --no-cache-dir debugpy

# parche para no chequear password en debug (re-apuntado al path del venv)
RUN sed -i "s/raise AccessDenied()/pass/" /odoo/odoo-src/odoo/addons/base/models/res_users.py

USER odoo
