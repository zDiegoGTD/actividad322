#!/bin/bash
# lab.sh - orquestacion del laboratorio DevSecOps OCY1102
# Uso: bash scripts/lab.sh <fase>
#   app        levanta la aplicacion Flask en contenedor
#   metricas   levanta Prometheus y Grafana
#   elk        levanta Elasticsearch, Logstash y Kibana
#   trafico    genera peticiones para alimentar metricas y registros
#   jenkins    levanta Jenkins
#   sonar      levanta SonarQube Community
#   osv        analisis de dependencias con OSV-Scanner
#   zap        analisis dinamico con OWASP ZAP (modo linea base)
#   doxygen    genera la documentacion tecnica
#   parar-elk  detiene la pila ELK para liberar memoria

set -x
cd "$HOME/actividad322" || exit 1
FASE="$1"

case "$FASE" in

app)
    docker network create red-dso 2>/dev/null
    docker build -t appsegura .
    docker rm -f appsegura 2>/dev/null
    docker run -d --name appsegura --network red-dso -p 5000:5000 \
        -v "$HOME/actividad322/logs:/app/logs" appsegura
    sleep 5
    docker ps --filter name=appsegura
    curl -s -i http://127.0.0.1:5000/hello?name=TEST | head -12
    ;;

app-vulnerable)
    # Ejecuta la version vulnerable tal cual esta en app.py (debug=True, sin escapar)
    docker rm -f appsegura appvulnerable 2>/dev/null
    docker run -d --name appvulnerable --network host appsegura python app.py
    sleep 6
    docker ps --filter name=appvulnerable
    curl -s -i "http://127.0.0.1:5000/hello?name=TEST" | head -10
    echo "--- prueba de XSS reflejado ---"
    curl -s "http://127.0.0.1:5000/hello?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
    ;;

parar-vulnerable)
    docker rm -f appvulnerable
    ;;

metricas)
    export GF_ADMIN_PASSWORD="$(cat "$HOME/.grafana_admin_pass")"
    docker compose up -d
    sleep 8
    docker compose ps
    curl -s http://127.0.0.1:9090/api/v1/targets | head -c 300
    ;;

elk)
    sudo sysctl -w vm.max_map_count=262144
    docker compose -f docker-compose-elk.yml up -d
    sleep 20
    docker compose -f docker-compose-elk.yml ps
    ;;

trafico)
    for i in $(seq 1 40); do
        curl -s "http://127.0.0.1:5000/hello?name=usuario$i" > /dev/null
    done
    for i in $(seq 1 12); do
        curl -s "http://127.0.0.1:5000/ruta-inexistente-$i" > /dev/null
    done
    curl -s "http://127.0.0.1:5000/hello?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E" > /dev/null
    wc -l logs/app.log
    tail -5 logs/app.log
    ;;

jenkins)
    docker volume create jenkins_home
    docker rm -f jenkins 2>/dev/null
    docker run -d --name jenkins \
        --network red-dso \
        --restart unless-stopped \
        -p 8080:8080 -p 50000:50000 \
        -v jenkins_home:/var/jenkins_home \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --group-add "$(getent group docker | cut -d: -f3)" \
        jenkins/jenkins:lts
    sleep 25
    docker ps --filter name=jenkins
    ;;

sonar)
    docker rm -f sonarqube 2>/dev/null
    docker run -d --name sonarqube \
        --network red-dso \
        -p 9000:9000 \
        -v sonarqube_data:/opt/sonarqube/data \
        -v sonarqube_extensions:/opt/sonarqube/extensions \
        -v sonarqube_logs:/opt/sonarqube/logs \
        sonarqube:community
    sleep 10
    docker ps --filter name=sonarqube
    ;;

osv)
    mkdir -p reportes-seguridad
    docker run --rm -v "$(pwd)":/src:ro ghcr.io/google/osv-scanner:v2 \
        scan source -r /src --format json > reportes-seguridad/osv.report.json
    docker run --rm -v "$(pwd)":/src:ro ghcr.io/google/osv-scanner:v2 \
        scan source -r /src
    ;;

zap)
    mkdir -p reportes-seguridad
    chmod 777 reportes-seguridad
    docker run --rm -t --network host \
        -v "$(pwd)/reportes-seguridad":/zap/wrk:rw \
        ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
        -t "http://127.0.0.1:5000/hello?name=TEST" \
        -r zap-report.html -I
    ls -la reportes-seguridad/
    ;;

zap-full)
    # Analisis activo: necesario para que ZAP detecte el XSS reflejado
    mkdir -p reportes-seguridad
    chmod 777 reportes-seguridad
    docker run --rm -t --network host \
        -v "$(pwd)/reportes-seguridad":/zap/wrk:rw \
        ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py \
        -t "http://127.0.0.1:5000/hello?name=TEST" \
        -r zap-report-completo.html -I -j
    ls -la reportes-seguridad/
    ;;

doxygen)
    [ -f Doxyfile ] || doxygen -g
    sed -i 's|^PROJECT_NAME.*|PROJECT_NAME           = "Actividad322 Flask DSO"|' Doxyfile
    sed -i 's|^PROJECT_NUMBER.*|PROJECT_NUMBER         = 1.0|' Doxyfile
    sed -i 's|^PROJECT_BRIEF.*|PROJECT_BRIEF          = "Aplicacion Flask del pipeline DevSecOps OCY1102"|' Doxyfile
    sed -i 's|^OUTPUT_DIRECTORY.*|OUTPUT_DIRECTORY       = docs|' Doxyfile
    sed -i 's|^OUTPUT_LANGUAGE.*|OUTPUT_LANGUAGE        = Spanish|' Doxyfile
    sed -i 's|^INPUT  .*|INPUT                  = .|' Doxyfile
    sed -i 's|^FILE_PATTERNS .*|FILE_PATTERNS          = *.py|' Doxyfile
    sed -i 's|^RECURSIVE .*|RECURSIVE              = YES|' Doxyfile
    sed -i 's|^EXCLUDE  .*|EXCLUDE                = .venv __pycache__ reportes-seguridad docs|' Doxyfile
    sed -i 's|^OPTIMIZE_OUTPUT_JAVA.*|OPTIMIZE_OUTPUT_JAVA   = YES|' Doxyfile
    sed -i 's|^EXTRACT_ALL .*|EXTRACT_ALL            = YES|' Doxyfile
    sed -i 's|^GENERATE_LATEX.*|GENERATE_LATEX         = NO|' Doxyfile
    sed -i 's|^HAVE_DOT .*|HAVE_DOT               = YES|' Doxyfile
    sed -i 's|^CALL_GRAPH .*|CALL_GRAPH             = YES|' Doxyfile
    sed -i 's|^CALLER_GRAPH .*|CALLER_GRAPH           = YES|' Doxyfile
    doxygen Doxyfile 2>&1 | tail -15
    ls docs/html/index.html
    ;;

parar-elk)
    docker compose -f docker-compose-elk.yml down
    free -h
    ;;

*)
    echo "fase desconocida: $FASE"
    exit 1
    ;;
esac
