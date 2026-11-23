#!/bin/bash
# Aplica la configuracion de Jenkins una vez que el servicio responde.
set -e
JENKINS_URL="http://127.0.0.1:8080"
USUARIO="diego"
CLAVE="$(cat "$HOME/.jenkins_admin_pass")"

echo "esperando a Jenkins..."
for i in $(seq 1 90); do
    estado="$(curl -s -o /dev/null -w '%{http_code}' -u "$USUARIO:$CLAVE" "$JENKINS_URL/api/json" || true)"
    if [ "$estado" = "200" ]; then
        echo "Jenkins responde tras $((i * 5))s"
        break
    fi
    sleep 5
done

if [ "$estado" != "200" ]; then
    echo "ERROR: Jenkins no responde (ultimo codigo: $estado)"
    docker logs jenkins 2>&1 | tail -10
    exit 1
fi

GALLETAS="$(mktemp)"

CRUMB="$(curl -s -u "$USUARIO:$CLAVE" -c "$GALLETAS" \
    "$JENKINS_URL/crumbIssuer/api/json" \
    | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)"
echo "crumb obtenido: ${#CRUMB} caracteres"

curl -s -u "$USUARIO:$CLAVE" -b "$GALLETAS" -c "$GALLETAS" \
    -H "Jenkins-Crumb: $CRUMB" \
    --data-urlencode "script@$HOME/actividad322/scripts/jenkins-config.groovy" \
    "$JENKINS_URL/scriptText"

rm -f "$GALLETAS"
