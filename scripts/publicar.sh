#!/bin/bash
# Sincroniza los cambios locales con el repositorio y los publica.
# Uso: bash scripts/publicar.sh "mensaje del commit"
set -e
cd "$HOME/actividad322" || exit 1

ORIGEN="/mnt/c/Users/deint/Downloads/OCY1102-Evaluacion3/proyecto"
for f in Jenkinsfile app.py app_seguro.py Dockerfile requirements.txt \
         requirements-demo-sca.txt sonar-project.properties prometheus.yml \
         docker-compose.yml docker-compose-elk.yml logstash.conf hola.py test_app.py; do
    [ -f "$ORIGEN/$f" ] && cp "$ORIGEN/$f" .
done
cp -r "$ORIGEN/scripts/." scripts/ 2>/dev/null || true

git add -A
git commit -m "${1:-chore: actualizacion del proyecto}" || echo "sin cambios que confirmar"
git push origin actividad322

git log --oneline -3
