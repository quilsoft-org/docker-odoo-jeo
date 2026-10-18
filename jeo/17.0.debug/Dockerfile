FROM jobiols/odoo-jeo:17.0
LABEL maintainer="Jorge Obiols <jorge.obiols@gmail.com>"

USER root

# Hacer el parche para que no cheque password
RUN sed -i  "s/raise AccessDenied()/pass/" /usr/lib/python3/dist-packages/odoo/addons/base/models/res_users.py

# install wdb
RUN git clone https://github.com/jobiols/wdb.git /opt/wdb \
    && pip install --no-cache-dir --break-system-packages /opt/wdb/client \
    && rm -rf /opt/wdb

# install wdb — master HEAD on purpose: Jorge owns the repo and wants the latest
#RUN /odoo/venv/bin/pip install --no-cache-dir \
#    https://github.com/jobiols/wdb/archive/refs/heads/master.tar.gz#subdirectory=client

# sin esto no anda el wdb
#RUN /odoo/venv/bin/pip install --no-cache-dir debugpy

USER odoo
