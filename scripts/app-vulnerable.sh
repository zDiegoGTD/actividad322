#!/bin/bash
# Ejecuta la version vulnerable de la aplicacion tal como figura en app.py,
# en un entorno virtual local, para la demostracion del XSS y el analisis DAST.
set -x
cd "$HOME/actividad322" || exit 1

[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install --quiet --upgrade pip
.venv/bin/pip install --quiet "Flask>=3.1,<4.0"

pkill -f "app.py" 2>/dev/null
sleep 1

setsid nohup .venv/bin/python app.py > logs/app-vulnerable.log 2>&1 < /dev/null &
sleep 6

ss -tlnp | grep 5000
curl -s -i "http://127.0.0.1:5000/hello?name=TEST" | head -8
echo "--- XSS reflejado ---"
curl -s "http://127.0.0.1:5000/hello?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
echo
cat logs/app-vulnerable.log
