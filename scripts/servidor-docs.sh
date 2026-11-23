#!/bin/bash
# Publica localmente la documentacion Doxygen y los reportes de seguridad
# para poder consultarlos desde el navegador.
cd "$HOME/actividad322" || exit 1

pkill -f "http.server 8000" 2>/dev/null
sleep 1

setsid nohup python3 -m http.server 8000 --bind 127.0.0.1 > /tmp/httpserver.log 2>&1 < /dev/null &
sleep 3

curl -s -o /dev/null -w "docs:  %{http_code}\n" http://127.0.0.1:8000/docs/html/index.html
curl -s -o /dev/null -w "zap:   %{http_code}\n" http://127.0.0.1:8000/reportes-seguridad/zap-report-completo.html
