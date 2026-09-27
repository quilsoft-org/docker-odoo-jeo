# Migrar imagen Odoo 18.0 a patrón git + venv

## Objetivo
Migrar `jeo/18.0` del enfoque `.deb` nightly (Python del sistema) al patrón
git clone pinneado + venv + multi-stage real, espejando lo ya hecho en 19.0
(rama `master.mejoras-v19`).

## Decisiones (usuario)
- Enfoque: **git + venv** (igual que 19.0).
- Requirements: **set actual de 18.0, pinneado** (sin importar extras de 19.0:
  pandas, pika, zope.event, tools, weasyprint).
- `18.0.debug`: **incluido en esta pasada** (quitar scripts extract, alinear wdb/debugpy).

## Pins resueltos
| Dependencia | Pin |
|---|---|
| Odoo 18.0 (HEAD rama `18.0`) | `bdb5a9a8f81563a87081ec17ef99bf0fbb8d4e98` |
| adhoc-dev/aeroolib `master-fix-ods` | `d5bd0945c2aeb7ccd70e0e578b63f430ef9cc207` |
| aeroo/currency2text | `e666e17eb54f5a49f5cfb3825d8513a4d1510249` |
| ingadhoc/pyafipws `odoo18` | `2cf3b224977c1c5ac748bc386f3785ad06a42a87` |
| openupgradelib | `3.12.0` |
| coverage | `7.16.1` |
| defusedxml | `0.7.1` |
| num2words | `0.5.10` |
| genshi | `0.7.7` |

## Rama
`master.mejoras-v18` (creada desde `master` en `3564532`), aislada de `master.mejoras-v19`.

## Archivos
- `jeo/18.0/Dockerfile` — reescritura (builder/runtime, venv, CMD odoo-bin)
- `jeo/18.0/odoo.conf` — paths `/opt/odoo/custom-addons` y `/opt/odoo/data`
- `jeo/18.0/entrypoint.sh` — `sed` check_config, `odoo-bin`, banner
- `jeo/18.0/wait-for-psql.py` — espejo de 19.0
- `jeo/18.0/requirements/` — pinner + consolidar a `requirements.txt` + `adhoc-aeroo_reports.txt`; borrar `odoo-argentina-*.txt`
- `jeo/18.0/.dockerignore` — nuevo
- `jeo/18.0/.gitignore` — ya existía suelto (incluir)
- `jeo/18.0/make.sh` — `--build-arg ODOO_RELEASE`
- `jeo/18.0.debug/Dockerfile` — wdb por tar.gz, debugpy `--no-cache-dir`; borrar `extract_*.sh`

## Verificación
- `docker build` de 18.0 (sin push).

## Registro de commits
| Commit | Contenido |
|---|---|
| (pendiente) | — |
