#!/bin/bash
# Analisis de composicion de software con OWASP Dependency-Check.
# La primera ejecucion descarga la base de datos de la NVD y puede tardar
# bastante; si la API limita las peticiones se documenta el fallback a OSV-Scanner.
set -x
cd "$HOME/actividad322" || exit 1

mkdir -p reportes-seguridad
docker volume create dependency-check-data

docker run --rm \
    -v "$(pwd)":/src:ro \
    -v dependency-check-data:/usr/share/dependency-check/data \
    -v "$(pwd)/reportes-seguridad":/report \
    owasp/dependency-check:latest \
    --scan /src \
    --project "actividad322-flask-dso" \
    --format ALL \
    --out /report \
    --disableYarnAudit \
    --disableNodeAudit

ls -la reportes-seguridad/
