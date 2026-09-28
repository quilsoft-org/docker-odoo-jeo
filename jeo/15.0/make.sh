#!/usr/bin/env bash
sd build --rm=true --build-arg ODOO_RELEASE=$(date -u +%Y%m%d) -t jobiols/odoo-jeo:15.0 ./
result=$?
if [ "$result" -eq 0 ]; then
    sd push jobiols/odoo-jeo:15.0
else
    echo "Falló la creación de la imagen"
fi
exit $result
