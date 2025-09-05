#!/bin/bash
#
# Скрипт для синхронизации настроек из репозитория GitHub.
# Клонирует репозиторий, если он не существует, или обновляет его, если существует.
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
echo "Настройка конфигурации и ключей SSH..."

# Создаем директорию .ssh, если ее нет
mkdir -p ~/.ssh

# Копируем шаблон конфига в ~/.ssh/config
cp -f ./ssh_config_template ~/.ssh/config

# Копируем секретные ключи SSH
echo "Копирование секретных ключей SSH..."
cp -f ./ssh_keys/id_rsa_* ~/.ssh/

# Устанавливаем безопасные права доступа
echo "Установка прав доступа для SSH..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa_*
chmod 644 ~/.ssh/*.pub

echo "Настройка SSH завершена."

echo "Синхронизация полностью завершена."
