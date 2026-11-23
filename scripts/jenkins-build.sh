#!/bin/bash
# Lanza el pipeline y muestra el estado de la ejecucion.
set -e
JENKINS_URL="http://127.0.0.1:8080"
USUARIO="diego"
CLAVE="$(cat "$HOME/.jenkins_admin_pass")"
JOB="actividad322-pipeline"
GALLETAS="$HOME/.jenkins_cookies"

CRUMB="$(curl -s -u "$USUARIO:$CLAVE" -c "$GALLETAS" \
    "$JENKINS_URL/crumbIssuer/api/json" | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)"

codigo="$(curl -s -o /dev/null -w '%{http_code}' -u "$USUARIO:$CLAVE" -b "$GALLETAS" \
    -H "Jenkins-Crumb: $CRUMB" -X POST "$JENKINS_URL/job/$JOB/build")"
echo "lanzamiento del pipeline: HTTP $codigo"

if [ "$1" = "--esperar" ]; then
    echo "esperando a que termine..."
    for i in $(seq 1 120); do
        sleep 10
        estado="$(curl -s -u "$USUARIO:$CLAVE" "$JENKINS_URL/job/$JOB/lastBuild/api/json" \
            | grep -o '"result":[^,]*' | cut -d: -f2 | tr -d '"')"
        numero="$(curl -s -u "$USUARIO:$CLAVE" "$JENKINS_URL/job/$JOB/lastBuild/api/json" \
            | grep -o '"number":[0-9]*' | head -1 | cut -d: -f2)"
        echo "  build #$numero -> ${estado:-en curso} ($((i * 10))s)"
        if [ -n "$estado" ] && [ "$estado" != "null" ]; then
            break
        fi
    done
fi
