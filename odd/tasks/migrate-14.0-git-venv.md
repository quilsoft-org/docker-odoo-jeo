# Migrar imagen Odoo 14.0 a patrón git + venv (bullseye)

## Objetivo
Migrar `jeo/14.0` y `jeo/14.0.debug` del enfoque `.deb` nightly (Debian bullseye,
Python 3.9) al patrón git clone + venv + multi-stage, en **bullseye** (Python 3.9).

## Decisiones (usuario)
- Base: **bullseye (3.9)** — Python oficial de Odoo 14, pins a medida, build limpio.
  Se descartó jammy (6-7 bumps + core no oficial) y noble (sin pins 3.12).
- Odoo 14.0: **seguir la rama `14.0`** (congelada/EOL; sin commits nuevos, pero se
  mantiene el mecanismo `ODOO_RELEASE=$(date)` por consistencia con el parque).
- Forks propios SIN pin (igual que 15/16): pyafipws@py3k, aeroolib@master-fix-ods,
  currency2text, openupgradelib@master.
- AFIP: se conserva `adhoc-odoo-argentina-ce.txt` (variante CE que ya usaba 14.0).
- aeroo: ACTIVO (se instala `adhoc-aeroo_reports.txt`).

## Fixes de pins cp39 (Odoo 14 pinnea versiones sin wheel cp39)
| Pin viejo | Fix | Motivo |
|---|---|---|
| `libsass==0.17.0` | `libsass==0.20.1` | sin wheel cp39 (solo cp37) ni abi3; source build rompe con Cython 3 |
| `MarkupSafe==1.1.0` | `MarkupSafe==2.0.1` | sin wheel cp39; 2.0.1 es el tope compatible con Jinja2 2.11.x |
| `psycopg2==2.8.5` | `psycopg2==2.9.9` | 2.8.5 no soporta Python 3.9 (2.8.6 recién agregó 3.9) |

(se aplican con `sed` sobre `odoo-src/requirements.txt`, igual que en 16/17)

## Adaptaciones específicas 14.0 (bullseye)
- Base `debian:bullseye-slim` (Python 3.9 nativo). Binario `odoo-bin` (git) en vez
  de `odoo` (deb), en entrypoint y CMD.
- **bullseye está EOL** (LTS venció 31/ago/2026): los repos `debian-security` ya
  están podados. Se apunta al snapshot congelado `snapshot.debian.org` (fecha
  `20260824T000000Z`) con `Acquire::Check-Valid-Until=false` (el InRelease del
  snapshot está "expirado").
- `python3-distutils` en runtime: Debian bullseye separa `distutils` del paquete
  `python3`; sin él, `pip` (el venv) falla con `ModuleNotFoundError: distutils.cmd`.
- `libldap-2.4-2` y `libssl1.1` (bullseye), NO `libldap-2.5-0`/`libssl3` (jammy/noble).
- wkhtmltopdf: se conserva el `.deb` buster 0.12.5-1 (sha1 ea8277df...) porque bullseye
  todavía tiene `libssl1.1` + `libjpeg62-turbo` (deps del deb).
- OpenSSL SECLEVEL: bullseye NO necesita el hack `SECLEVEL=1` (openssl 1.1.1 default
  SECLEVEL=1; el 14.0 .deb anterior ya corría sin él).
- Paths canónicos `/opt/odoo/...` (se elimina la inconsistencia `/mnt/extra-addons`).

## Archivos
- `jeo/14.0/Dockerfile` — reescritura (builder/runtime, venv, CMD odoo-bin)
- `jeo/14.0/odoo.conf`, `entrypoint.sh` — corregidos
- `jeo/14.0/wait-for-psql.py` — sin cambios (ya compatible)
- `jeo/14.0/requirements/` — conservar (forks sin pin); se dedupe `pysftp` en requirements.txt
- `jeo/14.0/.dockerignore` + `.gitignore` — nuevos
- `jeo/14.0/make.sh` — `--build-arg ODOO_RELEASE`
- `jeo/14.0.debug/Dockerfile` — wdb client (tar.gz) + debugpy + res_users re-apuntado; borrar `extract_*.sh` y el daemon smtpd

## Notas
- La rama 14.0 de Odoo está congelada (EOL): el mecanismo de frescura diaria no trae
  commits nuevos, pero se mantiene por uniformidad con el resto del parque.
- Odoo 14 es EOL (~2024) y bullseye EOL (ago/2026): esta imagen es un puente, no un
  destino a largo plazo. Ver plan de migración de clientes fuera de 14.
- Snapshot.debian.org es más lento que los mirrors vivos; builds más lentos en 14.0.

## Verificación
- `docker build` de 14.0: **OK** (imagen 1.45GB, la más chica del parque).
- `odoo-bin --version` → `Odoo Server 14.0`; venv Python 3.9.2.
- Pins verificados en la imagen: libsass 0.20.1, MarkupSafe 2.0.1, psycopg2 2.9.9,
  gevent 20.9.0, greenlet 0.4.17, lxml 4.6.5, Pillow 8.1.1, reportlab 3.5.55,
  python-ldap 3.1.0, Babel 2.6.0, Werkzeug 0.16.1.
- `docker build` de 14.0.debug: **OK** (wdb + debugpy + parche res_users).
- Fixes necesarios durante la verificación: snapshot.debian.org + Check-Valid-Until,
  y `python3-distutils` en runtime (distutils).

## Registro de commits
| Commit | Contenido |
|---|---|
| `e457917` | Migrar imagen Odoo 14.0 a git + venv (Dockerfile, odoo.conf, entrypoint, make.sh, .dockerignore, .gitignore, requirements) |
| `2669537` | Migrar 14.0.debug (wdb master, debugpy, sin smtpd, sin extract scripts) |

## Estado
- Código migrado, corregido y commiteado en `master.mejoras-v14`.
- Builds verificados sin errores (14.0 = 1.45GB).
- Pendiente (decisión del usuario): push de `master.mejoras-v14` y PR/merge a `master`.
