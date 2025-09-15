#!/bin/bash
#
# Скрипт для синхронизации настроек из репозитория GitHub.
# Клонирует репозиторий, если он не существует, или обновляет его, если существует.
#
# ВАЖНО: Для работы требуется SSH-ключ, настроенный для доступа к GitHub.
#

# --- Конфигурация ---
REPO_URL="git@github.com:igor04091968/cloud-google-marzban-settings.git"
DEST_DIR="cloud-google-marzban-settings"
BRANCH="master"

# --- Логика ---
echo "Запуск синхронизации настроек..."

if [ -d "$DEST_DIR" ]; then
  echo "Директория '$DEST_DIR' уже существует. Загружаю последние изменения..."
  cd "$DEST_DIR" || exit
  git pull origin "$BRANCH"
else
  echo "Директория '$DEST_DIR' не найдена. Клонирую репозиторий..."
  git clone "$REPO_URL" "$DEST_DIR"
  cd "$DEST_DIR" || exit
fi

echo "Синхронизация репозитория завершена."

# --- Настройка SSH ---
echo "Настройка конфигурации SSH..."

# Создаем директорию .ssh, если ее нет
mkdir -p ~/.ssh

# Копируем шаблон конфига в ~/.ssh/config
cp -f ./ssh_config_template ~/.ssh/config

# Устанавливаем безопасные права доступа
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

echo "Настройка SSH завершена."

echo "Синхронизация полностью завершена."