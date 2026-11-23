#!/bin/bash
# Ejecuta un script Groovy en la consola de scripts de Jenkins.
# Uso: bash scripts/jenkins-groovy.sh <archivo.groovy>
set -e
ARCHIVO="$1"
JENKINS_URL="http://127.0.0.1:8080"
USUARIO="diego"
CLAVE="$(cat "$HOME/.jenkins_admin_pass")"
GALLETAS="$HOME/.jenkins_cookies"

CRUMB="$(curl -s -u "$USUARIO:$CLAVE" -c "$GALLETAS" \
    "$JENKINS_URL/crumbIssuer/api/json" \
    | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)"

curl -s -u "$USUARIO:$CLAVE" -b "$GALLETAS" -c "$GALLETAS" \
    -H "Jenkins-Crumb: $CRUMB" \
    --data-urlencode "script@$ARCHIVO" \
    "$JENKINS_URL/scriptText"
