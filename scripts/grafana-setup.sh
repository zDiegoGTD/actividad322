#!/bin/bash
# Configura en Grafana el origen de datos de Prometheus y crea el dashboard
# con los dos paneles exigidos por la pauta.
set -e

CLAVE="$(cat "$HOME/.grafana_admin_pass")"
URL="http://127.0.0.1:3000"

echo "esperando a Grafana..."
for i in $(seq 1 40); do
    if curl -s -o /dev/null -w '%{http_code}' "$URL/api/health" | grep -q 200; then
        echo "Grafana operativo"
        break
    fi
    sleep 3
done

echo "--- origen de datos ---"
curl -s -u "admin:$CLAVE" -X POST "$URL/api/datasources" \
    -H "Content-Type: application/json" \
    -d '{"name":"Prometheus","type":"prometheus","access":"proxy","url":"http://prometheus:9090","isDefault":true}' \
    | head -c 200
echo

echo "--- dashboard ---"
curl -s -u "admin:$CLAVE" -X POST "$URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -d '{
  "dashboard": {
    "title": "Observabilidad appsegura - OCY1102",
    "uid": "ocy1102-dso",
    "tags": ["devsecops","ocy1102"],
    "timezone": "browser",
    "refresh": "10s",
    "time": {"from": "now-30m", "to": "now"},
    "panels": [
      {
        "type": "stat",
        "title": "Estado del servicio (up)",
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 0},
        "targets": [{"expr": "up{job=\"appsegura\"}", "refId": "A"}],
        "fieldConfig": {"defaults": {"mappings": [
            {"type":"value","options":{"0":{"text":"CAIDO","color":"red","index":0},"1":{"text":"ACTIVO","color":"green","index":1}}}
        ]}, "overrides": []}
      },
      {
        "type": "timeseries",
        "title": "Tasa de peticiones HTTP - rate(http_requests_total[5m])",
        "gridPos": {"h": 8, "w": 16, "x": 8, "y": 0},
        "targets": [{"expr": "rate(http_requests_total[5m])", "refId": "A", "legendFormat": "{{endpoint}} {{status}}"}]
      }
    ],
    "schemaVersion": 39,
    "version": 0
  },
  "overwrite": true
}' | head -c 300
echo
echo "listo"
