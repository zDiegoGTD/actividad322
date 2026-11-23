#!/bin/bash
# Prepara SonarQube: espera a que el servicio este operativo, cambia la
# contrasena inicial y genera el token de analisis para Jenkins.
# El token no se muestra por pantalla: queda en ~/.sonar_token
set -e

NUEVA="$(cat "$HOME/.sonar_admin_pass")"
URL="http://127.0.0.1:9000"

echo "esperando a que SonarQube este operativo..."
for i in $(seq 1 60); do
    estado="$(curl -s "$URL/api/system/status" | grep -o '"status":"[A-Z]*"' | cut -d'"' -f4 || true)"
    if [ "$estado" = "UP" ]; then
        echo "SonarQube operativo tras $((i * 5))s"
        break
    fi
    sleep 5
done

if [ "$estado" != "UP" ]; then
    echo "ERROR: SonarQube no quedo operativo"
    exit 1
fi

# Cambio de la contrasena inicial (admin/admin)
codigo="$(curl -s -o /dev/null -w '%{http_code}' -u "admin:admin" -X POST \
    "$URL/api/users/change_password" \
    --data-urlencode "login=admin" \
    --data-urlencode "previousPassword=admin" \
    --data-urlencode "password=$NUEVA")"
echo "cambio de contrasena inicial: HTTP $codigo"

# Generacion del token de analisis
curl -s -u "admin:$NUEVA" -X POST "$URL/api/user_tokens/revoke" \
    --data-urlencode "name=jenkins-dso" > /dev/null || true

curl -s -u "admin:$NUEVA" -X POST "$URL/api/user_tokens/generate" \
    --data-urlencode "name=jenkins-dso" \
    | grep -o '"token":"[^"]*"' | cut -d'"' -f4 > "$HOME/.sonar_token"
chmod 600 "$HOME/.sonar_token"

if [ -s "$HOME/.sonar_token" ]; then
    echo "token de analisis generado y guardado en ~/.sonar_token"
else
    echo "ERROR: no se pudo generar el token"
    exit 1
fi

cp "$HOME/.sonar_token" /mnt/c/Users/deint/AppData/Local/Temp/claude/45a0b889dbe5ba4c/a0d24618-f1ef-4865-9bc4-e02419e05269/scratchpad/secretos/sonar-token.txt
echo "listo"
