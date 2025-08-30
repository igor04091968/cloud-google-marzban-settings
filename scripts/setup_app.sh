#!/bin/bash
# Используем строгий режим для надежности
set -euo pipefail

echo "--- Запуск универсального скрипта для установки и запуска стартапа ---"

# --- Шаг 1: Проверка прав суперпользователя ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ОШИБКА: Этот скрипт требует прав суперпользователя. Пожалуйста, запустите его с помощью sudo."
    exit 1
fi

# --- Шаг 2: Установка системных зависимостей (для Debian/Ubuntu) ---
echo "--> Обновление списка пакетов..."
apt-get update

echo "--> Установка базовых зависимостей (python, pip, curl)..."
apt-get install -y python3 python3-pip curl ca-certificates gnupg lsb-release

# --- Шаг 3: Установка Docker ---
if ! command -v docker &> /dev/null
then
    echo "--> Docker не найден. Устанавливаю Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "--> Docker уже установлен."
fi

# --- Шаг 4: Создание файлов приложения ---
APP_DIR="/opt/my-startup"
echo "--> Создание директории для приложения в $APP_DIR..."
mkdir -p $APP_DIR
cd $APP_DIR

echo "--> Создание файла requirements.txt..."
cat <<EOF > requirements.txt
Flask
gunicorn
EOF

echo "--> Создание файла app.py..."
cat <<EOF > app.py
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Мой стартап работает!\n'

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
EOF

echo "--> Создание файла Dockerfile..."
cat <<EOF > Dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . . 
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
EOF

echo "--> Файлы приложения успешно созданы в $APP_DIR"

# --- Шаг 5: Сборка и запуск Docker-контейнера ---
echo "--> Сборка Docker-образа 'my-startup-app'..."
docker build -t my-startup-app .

# Проверяем, не запущен ли уже контейнер с таким именем
if [ "$(docker ps -q -f name=^/startup-container$)" ]; then
    echo "--> Контейнер 'startup-container' уже запущен. Перезапускаю..."
    docker stop startup-container
    docker rm startup-container
elif [ "$(docker ps -aq -f status=exited -f name=^/startup-container$)" ]; then
    echo "--> Найден остановленный контейнер 'startup-container'. Удаляю его..."
    docker rm startup-container
fi

echo "--> Запуск контейнера 'startup-container' на порту 8080..."
docker run -d -p 8080:8080 --name startup-container my-startup-app

# --- Шаг 6: Завершение ---
echo ""
echo "--- УСПЕХ! Ваше приложение запущено в Docker-контейнере ---"
echo ""
echo "Вы можете проверить его работу, выполнив в терминале этого сервера:"
echo "curl http://localhost:8080"
echo ""
echo "Посмотреть логи приложения:"
echo "docker logs startup-container"
echo ""
echo "Остановить приложение:"
echo "docker stop startup-container"
echo ""
