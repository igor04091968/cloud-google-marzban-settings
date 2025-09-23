#!/bin/bash

# Запуск фоновых сервисов
echo "Starting background services..."

echo "Starting Chisel client for remote access..."
chisel client -v --auth "cloud:2025" --keepalive 25s https://vds1.iri1968.dpdns.org/chisel-ws R:8006:localhost:2053 R:8443:localhost:2017 &

echo "Starting Tor..."
tor &

echo "Starting WARP (sing-box)..."
sing-box run -c /etc/sing-box/warp_config.json &

echo "Starting v2rayA..."
v2raya &

# Пауза, чтобы дать сервисам время на запуск
sleep 5

# Запуск основного сервиса x-ui в основном потоке
echo "Starting main service: x-ui"
cd /usr/local/x-ui && ./x-ui run