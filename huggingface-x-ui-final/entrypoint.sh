#!/bin/bash
set -e
# Запускаем chisel в фоне с ДВУМЯ туннелями
/usr/local/bin/chisel client --tls-skip-verify --auth "cloud:2025" https://vds1.iri1968.dpdns.org/chisel-ws R:8000:127.0.0.1:2053 R:8001:host.docker.internal:2017 &
sleep 5
# Запускаем x-ui как основной процесс
exec /usr/local/x-ui/x-ui