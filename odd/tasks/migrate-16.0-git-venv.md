# Migrar imagen Odoo 16.0 a patrón git + venv (jammy)

## Objetivo
Migrar `jeo/16.0` y `jeo/16.0.debug` del enfoque `.deb` nightly (Debian bullseye,
Python 3.9) al patrón git clone + venv + multi-stage, en **jammy** (Python 3.10).
`16.0.slave` queda FUERA de esta pasada (decisión del usuario).

## Decisiones (usuario)
- Base: **jammy** (3.10). Odoo 16 soporta 3.7–3.10.
- Odoo 16.0: **seguir la rama `16.0`** (HEAD móvil, sin pin de commit).
- **Forks propios SIN tocar** (no pin): `quilsoft-org/pyafipws@py3k`, `quilsoft-org/meli-sdk`.
- Parche `res_users.py`: **igual** (amplio, reemplaza todas las ocurrencias).
- aeroo: **queda comentado** (no se instala), como está hoy.
- Alcance: 16.0 + 16.0.debug (NO 16.0.slave).

## Fixes de pins jammy (Odoo 16 en 3.10 pinnea versiones sin wheel cp310)
| Pin viejo (3.10) | Fix | Motivo |
|---|---|---|
| `gevent==21.8.0` | `gevent==22.10.2` | sin wheel Linux cp310, no compila con Cython 3.x |
| `greenlet==1.1.2` | `greenlet==2.0.2` | gevent 22.10.2 exige greenlet>=2.0 |
| `MarkupSafe==1.1.1` | `MarkupSafe==2.0.1` | sin wheel cp310 (2020) |

(se aplican con `sed` sobre `odoo-src/requirements.txt`, igual que en 17.0)

## Adaptaciones específicas 16.0
- `--no-deps`/`--use-pep517` se quitan: en venv se instala CON deps.
- pyafipws cache: path cambia a `${VENV_PATH}/lib/python3.10/site-packages/pyafipws`.
- OpenSSL `SECLEVEL=1` (AFIP): instalar `openssl` en runtime (jammy no trae openssl.cnf).
- `xlsxwriter>=3.2.5` (upgrade que Odoo instala viejo).

## Archivos
- `jeo/16.0/Dockerfile` — reescritura (builder/runtime, venv, CMD odoo-bin)
- `jeo/16.0/odoo.conf`, `entrypoint.sh`, `wait-for-psql.py` — corregidos
- `jeo/16.0/requirements/` — conservar (forks sin pin); solo cambia la forma de instalar
- `jeo/16.0/.dockerignore` + `.gitignore` — nuevos
- `jeo/16.0/make.sh` — `--build-arg ODOO_RELEASE`
- `jeo/16.0.debug/Dockerfile` — wdb client (tar.gz) + debugpy + procps + res_users re-apuntado; borrar `extract_*.sh`

## Notas
- `16.0.slave` va a romper en el próximo build (parchea `server.py` en path del deb).
  Queda anotado para migrar después.

## Verificación
- `docker build` de 16.0 (sin push).

## Registro de commits
| Commit | Contenido |
|---|---|
| (pendiente) | — |
