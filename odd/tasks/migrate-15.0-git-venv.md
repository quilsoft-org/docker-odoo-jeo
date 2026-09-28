# Migrar imagen Odoo 15.0 a patrón git + venv (noble)

## Objetivo
Migrar `jeo/15.0` y `jeo/15.0.debug` del enfoque `.deb` nightly (debian:bullseye,
Python 3.9) al patrón git clone + venv + multi-stage en **ubuntu:noble** (Python 3.12).

## Decisiones (usuario)
- Base: **noble (3.12)**. Motivo: Odoo 15 solo tiene pins frescos (con wheel) para
  3.12; los pins de 3.9/3.10/3.11 son de 2019-2021 sin wheel (gevent 21.8.0, etc.).
- Odoo 15.0: **seguir la rama `15.0`** (HEAD móvil, sin pin de commit).
- **Deps git SIN pinear**: `ingadhoc/pyafipws@py3k`, `OCA/openupgradelib@master`,
  `aeroolib@master-fix-ods`, `currency2text`.
- aeroo: **queda activo** (15.0 lo instala, a diferencia de 16.0).
- pyafipws cache: **agregar** (sqlite del padrón AFIP).
- SECLEVEL=1: **NO hace falta en noble** (noble no trae `system_default_sect` en
  openssl.cnf → default SECLEVEL=1, a diferencia de jammy/bullseye que fuerzan 2).
- `.debug`: wdb git client + debugpy (como las demás), **sin** daemon smtpd, parche
  `res_users.py` re-apuntado al venv.

## Nota técnica clave
Odoo 15 tiene DOS eras de pins en requirements.txt: originales (3.7–3.9, 2019-2021)
y Noble (3.12, 2024). En 3.10/3.11 cae en el "hueco" (pins Jammy de 2021 sin wheel).
Por eso noble es la única base limpia para 15.0 (cero builds de fuente).

## Archivos
- `jeo/15.0/Dockerfile` — reescritura (builder/runtime noble, venv, CMD odoo-bin)
- `jeo/15.0/odoo.conf`, `entrypoint.sh`, `wait-for-psql.py` — corregidos
- `jeo/15.0/requirements/` — conservar (3 archivos, sin pin, aeroo activo)
- `jeo/15.0/.dockerignore` + `.gitignore` — nuevos
- `jeo/15.0/make.sh` — `--build-arg ODOO_RELEASE`
- `jeo/15.0.debug/Dockerfile` — wdb client + debugpy + res_users; borrar `extract_*.sh`

## Verificación
- `docker build` de 15.0 (sin push).

## Registro de commits
| Commit | Contenido |
|---|---|
| (pendiente) | — |
