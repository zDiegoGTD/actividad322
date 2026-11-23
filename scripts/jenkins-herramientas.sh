#!/bin/bash
# Instala dentro del contenedor de Jenkins las herramientas que necesitan las
# etapas del pipeline: Python 3 (Build y Test) y el cliente de Docker
# (Security Test y Deploy).
set -x

docker exec -u root jenkins bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends python3 curl ca-certificates
    if ! command -v docker >/dev/null; then
        curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz \
            -o /tmp/docker.tgz
        tar xzf /tmp/docker.tgz --strip-components=1 -C /usr/local/bin docker/docker
        rm -f /tmp/docker.tgz
    fi
    chmod 666 /var/run/docker.sock || true
    python3 --version
    docker --version
"
