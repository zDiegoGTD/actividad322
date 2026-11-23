FROM python:3.12-slim

# Usuario sin privilegios: limita el impacto de una ejecucion remota de codigo
RUN adduser --disabled-password --gecos "" appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN mkdir -p logs && chown -R appuser:appuser /app

USER appuser
EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "--workers", "3", "app_seguro:app"]
