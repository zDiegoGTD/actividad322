#!/bin/bash
# Instala el plugin de SonarQube, el analizador sonar-scanner y aplica la
# configuracion de Jenkins (credencial, servidor, herramienta y pipeline).
set -e

VERSION_SCANNER="7.0.2.4839"
JENKINS_URL="http://127.0.0.1:8080"
USUARIO="diego"
CLAVE="$(cat "$HOME/.jenkins_admin_pass")"

echo "== 1. plugins =="
docker exec jenkins jenkins-plugin-cli --plugins sonar:latest --verbose 2>&1 | tail -5

echo "== 2. analizador sonar-scanner dentro del contenedor =="
docker exec -u root jenkins bash -c "
    set -e
    if [ ! -d /opt/sonar-scanner ]; then
        apt-get install -y -qq unzip > /dev/null 2>&1 || true
        curl -sSL -o /tmp/scanner.zip \
          https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${VERSION_SCANNER}-linux-x64.zip
        unzip -q /tmp/scanner.zip -d /opt
        mv /opt/sonar-scanner-${VERSION_SCANNER}-linux-x64 /opt/sonar-scanner
        rm -f /tmp/scanner.zip
    fi
    /opt/sonar-scanner/bin/sonar-scanner --version 2>&1 | head -4
"

echo "== 3. token de SonarQube dentro del contenedor =="
docker cp "$HOME/.sonar_token" jenkins:/var/jenkins_home/sonar_token.txt
docker exec -u root jenkins chown jenkins:jenkins /var/jenkins_home/sonar_token.txt

echo "== 4. reinicio de Jenkins para cargar el plugin =="
docker restart jenkins > /dev/null
for i in $(seq 1 60); do
    estado="$(curl -s -o /dev/null -w '%{http_code}' -u "$USUARIO:$CLAVE" "$JENKINS_URL/api/json" || true)"
    [ "$estado" = "200" ] && { echo "Jenkins operativo tras $((i * 5))s"; break; }
    sleep 5
done

echo "== 5. configuracion mediante la consola de scripts =="
CRUMB="$(curl -s -u "$USUARIO:$CLAVE" "$JENKINS_URL/crumbIssuer/api/json" \
    | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)"

curl -s -u "$USUARIO:$CLAVE" -H "Jenkins-Crumb: $CRUMB" \
    --data-urlencode "script@$HOME/actividad322/scripts/jenkins-config.groovy" \
    "$JENKINS_URL/scriptText"
