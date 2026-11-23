#!/bin/bash
# Muestra la consola de una ejecucion del pipeline.
# Uso: bash scripts/jenkins-log.sh [numero_de_build] [lineas]
NUM="${1:-lastBuild}"
LINEAS="${2:-40}"
curl -s -u "diego:$(cat "$HOME/.jenkins_admin_pass")" \
    "http://127.0.0.1:8080/job/actividad322-pipeline/$NUM/consoleText" | tail -n "$LINEAS"
