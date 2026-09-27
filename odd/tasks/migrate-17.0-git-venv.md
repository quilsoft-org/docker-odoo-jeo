# Migrar imagen Odoo 17.0 a patrón git + venv (jammy)

## Objetivo
Migrar `jeo/17.0` del enfoque `.deb` nightly (Python del sistema) al patrón
git clone + venv + multi-stage real, espejando 18.0/19.0 pero quedándonos en
`ubuntu:jammy` (Python 3.10 — Odoo 17 NO soporta 3.12).

## Decisiones (usuario)
- Base: **jammy** (no noble) — Python 3.10 nativo.
- Odoo 17.0: **seguir la rama `17.0`** (HEAD móvil, sin pin de commit).
- Requirements: set actual instalado **pinneado**; app-deps sin pin (pygithub,
  openpyxl, OdooRPC) también **pinneados**.
- `odoo-argentina-ce.txt`: **actualizar al requirements oficial** de
  `ingadhoc/odoo-argentina-ce` (rama 17.0): pyOpenSSL, M2Crypto, httplib2>=0.7,
  pysimplesoap~=1.8.22, git+https://github.com/reingart/pyafipws.
- `17.0.debug`: alinear con 18/19 → wdb **client** + debugpy, sin server.

## Pins resueltos
| Dependencia | Pin |
|---|---|
| aeroolib `master-fix-ods` | `d5bd0945c2aeb7ccd70e0e578b63f430ef9cc207` |
| currency2text | `e666e17eb54f5a49f5cfb3825d8513a4d1510249` |
| ingadhoc/pyafipws `py3k` | `227b57d69659e81a229da235f051071d446ce4f1` |
| OCA/openupgradelib `master` | `48ed86f40c3d09d2681e459831fb1cdd7d829521` |
| pysimplesoap | `a330d9c4af1b007fe1436f979ff0b9f66613136e` (ya estaba) |
| pygithub | `2.10.0` |
| openpyxl | `3.1.5` |
| OdooRPC | `0.10.1` |
| coverage | `7.16.1` |
| httplib2 | `0.20.4` (ya estaba) |
| gTTS / pandas / SQLAlchemy | `2.5.1` / `2.1.2` / `2.0.32` (ya estaban) |
| genshi | `0.7.7` (ya estaba) |

## Rama
`master.mejoras-v17` (desde `master`).

## Archivos
- `jeo/17.0/Dockerfile` — reescritura (builder/runtime, venv, CMD odoo-bin)
- `jeo/17.0/odoo.conf` — paths `/opt/odoo/custom-addons` y `/opt/odoo/data`
- `jeo/17.0/entrypoint.sh` — `sed` check_config, `odoo-bin`, banner
- `jeo/17.0/wait-for-psql.py` — espejo de 18/19
- `jeo/17.0/requirements/` — pinner (git deps + app deps + coverage); actualizar ce
- `jeo/17.0/.dockerignore` + `.gitignore` — nuevos
- `jeo/17.0/make.sh` — `--build-arg ODOO_RELEASE`
- `jeo/17.0.debug/Dockerfile` — wdb client (tar.gz) + debugpy; borrar `extract_*.sh`

## Notas / pendientes a confirmar
- `odoo-argentina-ee.txt` queda **stale sin tocar** (enterprise se arma de cero después).
- El purge de nodejs/npm (CVE-2023-42282) del Dockerfile viejo **no se conserva**:
  el patrón 18/19 usa `node-less` (que trae nodejs transitivamente) + rtlcss.

## Verificación
- `docker build` de 17.0 (sin push).

## Registro de commits
| Commit | Contenido |
|---|---|
| `fbc4a72` | Migrar imagen Odoo 17.0 a git + venv (Dockerfile, odoo.conf, entrypoint, wait-for-psql, requirements, .dockerignore, .gitignore, make.sh) |
| `c6d8af0` | Quitar scripts extract y alinear 17.0.debug con 18/19 |

## Estado
- Código migrado y commiteado en `master.mejoras-v17`.
- Pendiente: verificación real con `docker build` (sin push).
