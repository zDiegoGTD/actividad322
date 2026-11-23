## @file app_seguro.py
#  @brief Servicio Flask con neutralizacion de entrada, cabeceras de
#         seguridad y metricas expuestas para Prometheus.
#  @author Diego Otarola

import logging
import os

from flask import Flask, Response, request
from markupsafe import escape
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = Flask(__name__)

os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    filename='logs/app.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
)

## Contador de peticiones HTTP expuesto como http_requests_total.
REQUESTS = Counter(
    'http_requests_total',
    'Total de peticiones HTTP atendidas',
    ['endpoint', 'method', 'status'],
)


## @brief Agrega cabeceras de seguridad y contabiliza la peticion.
#  @param resp Respuesta construida por Flask.
#  @return Respuesta con las cabeceras de seguridad aplicadas.
@app.after_request
def add_security_headers(resp):
    resp.headers['Content-Security-Policy'] = "default-src 'self'"
    resp.headers['X-Content-Type-Options'] = 'nosniff'
    resp.headers['X-Frame-Options'] = 'DENY'
    resp.headers['Referrer-Policy'] = 'no-referrer'
    REQUESTS.labels(request.path, request.method, resp.status_code).inc()
    return resp


## @brief Devuelve un saludo con la entrada neutralizada.
#  @param name Nombre recibido por la cadena de consulta. Entrada NO CONFIABLE:
#              debe escaparse siempre antes de incorporarla a la respuesta.
#  @return Cadena HTML segura.
@app.route('/hello')
def hello():
    name = request.args.get('name', 'mundo')
    app.logger.info('peticion a /hello')
    return f"Hello, {escape(name)}!"


## @brief Expone las metricas en formato Prometheus.
#  @return Respuesta con las metricas del proceso.
@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


## @brief Registra los errores 404 para su analisis en Kibana.
#  @param e Excepcion capturada por Flask.
#  @return Mensaje de error y codigo 404.
@app.errorhandler(404)
def no_encontrado(e):
    app.logger.error('ruta no encontrada: %s', request.path)
    return 'No encontrado', 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
