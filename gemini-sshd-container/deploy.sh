#!/bin/bash

# Скрипт для автоматического развертывания SSHD-контейнера Gemini и создания обратного туннеля.
# Выход при любой ошибке
set -e

# --- Конфигурация ---
# Эти переменные можно изменить при необходимости
VDS_ADDRESS="root@vds1.iri1968.dpdns.org"
VDS_TUNNEL_PORT="2223"
LOCAL_CONTAINER_PORT="2224"
DOCKER_IMAGE_NAME="gemini-sshd"
DOCKER_CONTAINER_NAME="sshd-container"

# --- Скрипт ---

# Проверка наличия аргумента с путем к приватному ключу
if [ -z "$1" ]; then
  echo "Ошибка: Укажите путь к приватному ключу для доступа к VDS."
  echo "Пример использования: $0 /путь/к/вашему/id_rsa_vds1"
  exit 1
fi
VDS_PRIVATE_KEY=$1

if [ ! -f "$VDS_PRIVATE_KEY" ]; then
    echo "Ошибка: Файл приватного ключа не найден по пути: $VDS_PRIVATE_KEY"
    exit 1
fi


SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR"

echo "--- Шаг 1: Сборка Docker-образа '$DOCKER_IMAGE_NAME' ---"
docker build -t "$DOCKER_IMAGE_NAME" .

echo "--- Шаг 2: Остановка и удаление старого контейнера (если существует) ---"
docker stop "$DOCKER_CONTAINER_NAME" 2>/dev/null || true
docker rm "$DOCKER_CONTAINER_NAME" 2>/dev/null || true

echo "--- Шаг 3: Запуск нового контейнера '$DOCKER_CONTAINER_NAME' ---"
docker run -d -p "127.0.0.1:$LOCAL_CONTAINER_PORT:22" --name "$DOCKER_CONTAINER_NAME" "$DOCKER_IMAGE_NAME"

echo "--- Шаг 4: Установка обратного SSH-туннеля ---"
# На всякий случай останавливаем старый процесс туннеля, если он есть
pkill -f "ssh -N -f -R $VDS_TUNNEL_PORT:localhost:$LOCAL_CONTAINER_PORT" || true
sleep 2

# Запускаем новый туннель в фоновом режиме
ssh -N -f -R "$VDS_TUNNEL_PORT:localhost:$LOCAL_CONTAINER_PORT" -i "$VDS_PRIVATE_KEY" -o "StrictHostKeyChecking=no" "$VDS_ADDRESS"


echo "---"
echo "### Развертывание завершено! ###"
echo "- Контейнер '$DOCKER_CONTAINER_NAME' запущен."
echo "- Обратный туннель активен."
echo "- Сервер VDS слушает порт $VDS_TUNNEL_PORT для подключений к Gemini."
