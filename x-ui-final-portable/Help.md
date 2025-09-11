# Полная инструкция по развертыванию x-ui с использованием Hugging Face, VDS1, Nginx и Chisel

Эта инструкция описывает полный процесс развертывания x-ui панели, доступной через Hugging Face Space, с использованием VDS1 в качестве прокси и Chisel для туннелирования трафика.

## 1. Настройка VDS1 (vds1.iri1968.dpdns.org)

### 1.1. Установка Nginx

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 1.2. Настройка Nginx для проксирования

Создайте файл `/etc/nginx/sites-available/x-ui.conf` со следующим содержимым:

```nginx
server {
    listen 80;
    server_name vds1.iri1968.dpdns.org; # Замените на ваш домен

    # Перенаправление HTTP на HTTPS
    return 301 https://$host$request_uri;

    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl;
    server_name vds1.iri1968.dpdns.org; # Замените на ваш домен

    ssl_certificate /etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem; # Укажите правильный путь
    ssl_certificate_key /etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem; # Укажите правильный путь

    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Расположение по умолчанию - Nginx только для Certbot.
    # Здесь не должно быть проксирования к Chisel.
    location / {
        try_files $uri $uri/ =404;
    }
}
```
Затем включите сайт и перезапустите Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/x-ui.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 1.3. Установка Certbot и получение SSL-сертификатов (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d vds1.iri1968.dpdns.org # Замените на ваш домен и следуйте инструкциям
```

### 1.4. Настройка Chisel Server

```bash
# Установите chisel на VDS1 (если еще не установлен)
# Загрузите последнюю версию chisel с https://github.com/jpillora/chisel/releases
# Пример для v1.10.1:
CHISEL_VERSION=1.10.1
wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz
gunzip /tmp/chisel.gz
mv /tmp/chisel /usr/local/bin/chisel
chmod +x /usr/local/bin/chisel

# Запустите Chisel сервер в фоновом режиме
# Он должен слушать на порту 80. Nginx будет проксировать к нему.
# Флаг --reverse важен для обратных туннелей.
# Для mTLS серверу необходимо верифицировать сертификат клиента.
# Предполагается, что client.crt, client.key, ca.crt присутствуют на VDS1.
nohup /usr/local/bin/chisel server --port 443 --reverse --tls-cert /etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem --tls-key /etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem --tls-ca /home/igor04091968/ca.crt > /dev/null 2>&1 &
# Примечание: --tls-ca используется для проверки сертификата клиента. Предполагается, что /home/igor04091968/ca.crt является корневым CA, подписавшим client.crt.
```

## 2. Настройка Hugging Face Space

### 2.1. Подготовка Dockerfile

Создайте файл `Dockerfile` в директории `huggingface-x-ui-final/` со следующим содержимым:

```dockerfile
FROM debian:bullseye-slim

# Install necessary packages and clean up
RUN apt-get update && apt-get install -y \
    dos2unix \
    wget \
    curl \
    tar \
    bash \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Install chisel
ARG CHISEL_VERSION=1.10.1
RUN wget https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz -O /tmp/chisel.gz && \
    gunzip /tmp/chisel.gz && \
    mv /tmp/chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

# Download and extract 3x-ui
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    wget -O /usr/local/x-ui-linux-${ARCH}.tar.gz \
    "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${ARCH}.tar.gz" && \
    mkdir -p /usr/local/x-ui/ && \
    tar -zxvf /usr/local/x-ui-linux-*.tar.gz -C /usr/local/x-ui/ --strip-components=1 && \
    rm /usr/local/x-ui-linux-*.tar.gz && \
    chmod +x /usr/local/x-ui/x-ui && \
    cp /usr/local/x-ui/x-ui.sh /usr/bin/x-ui

# Create directory for chisel certs and copy them
RUN mkdir -p /etc/chisel
COPY client.crt /etc/chisel/client.crt
COPY client.key /etc/chisel/client.key
COPY ca.crt /etc/chisel/ca.crt

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh

# Make the script executable
RUN chmod +x /usr/local/bin/start.sh

# Expose the x-ui port
EXPOSE 2023

# Set the entrypoint to our startup script
RUN chmod -R 777 /usr/local/x-ui/
ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/start.sh"]
```

### 2.2. Подготовка start.sh скрипта

Создайте файл `start.sh` в директории `huggingface-x-ui-final/` со следующим содержимым:

```bash
#!/bin/bash

# Set a writable directory for the x-ui database
export XUI_DB_FOLDER=/tmp

# Function to run chisel client in a loop
run_chisel() {
  while true; do
    echo "Starting chisel client with mTLS..."
    /usr/local/bin/chisel client -v --auth "cloud:2025" --tls-cert /etc/chisel/client.crt --tls-key /etc/chisel/client.key --tls-ca /etc/chisel/ca.crt https://vds1.iri1968.dpdns.org:443 R:2023:127.0.0.1:2023
    echo "Chisel client exited. Restarting in 5 seconds..."
    sleep 5
  ne
}

# Start chisel in the background
run_chisel &

# Wait a moment for the background process to start
sleep 2

# Set x-ui port
/usr/local/x-ui/x-ui setting -port 2023

# Set webBasePath
/usr/local/x-ui/x-ui setting -webBasePath /

# Reset x-ui admin credentials
/usr/local/x-ui/x-ui setting -username prog10 -password 04091968

# Start x-ui in the foreground
echo "Starting x-ui panel..."
cd /usr/local/x-ui
./x-ui
```

### 2.3. Развертывание на Hugging Face

1.  **Создайте новый Hugging Face Space:**
    *   Перейдите на [Hugging Face Spaces](https://huggingface.co/spaces).
    *   Нажмите "Create new Space".
    *   Выберите "Docker" в качестве SDK.
    *   Укажите имя Space, например, `your-username/x-ui-tunnel`.
    *   Выберите аппаратное обеспечение (например, CPU Basic).
    *   Нажмите "Create Space".

2.  **Загрузите файлы в ваш Space:**
    *   Клонируйте ваш новый Space локально:
        ```bash
git clone https://huggingface.co/spaces/your-username/x-ui-tunnel
cd x-ui-tunnel
```
    *   Скопируйте `Dockerfile`, `start.sh`, `client.crt`, `client.key`, `ca.crt` из вашей локальной директории `cloud-google-marzban-settings-repo/huggingface-x-ui-final/` в клонированную директорию Space.
    *   Создайте файл `README.md` в корневой директории Space со следующим содержимым:
        ```markdown
---
license: mit
title: x-ui-tunnel
sdk: docker
emoji: 🚀
colorFrom: gray
colorTo: indigo
pinned: true
app_port: 2023 # This is the port that x-ui is listening on inside the Docker container
persistent_storage: true
---
# x-ui Tunnel

This Hugging Face Space runs an x-ui panel accessible via a Chisel reverse tunnel.
```
        **Примечание:** `app_port` в `README.md` должен соответствовать удаленному порту обратного туннеля, который равен `8000` в нашем `start.sh` (`R:8000:127.0.0.1:2023`). Это порт, который будет открыт Hugging Face.

3.  **Отправьте изменения в Hugging Face:**
    ```bash
git add .
git commit -m "Initial x-ui tunnel setup"
git push
```
    Hugging Face автоматически начнет сборку Docker образа и развертывание вашего Space. Вы можете отслеживать прогресс на странице вашего Space.

## 3. Дополнительные настройки и устранение неполадок

### 3.1. Настройка DNS

Убедитесь, что DNS запись для вашего домена (например, `vds1.iri1968.dpdns.org`) указывает на IP-адрес вашего VDS1.

### 3.2. Проверка и отладка

*   **Проверка Nginx:**
    ```bash
sudo nginx -t
sudo systemctl status nginx
```
*   **Проверка Chisel Server на VDS1:**
    ```bash
ps aux | grep chisel
sudo ss -tulnp | grep 80 # Проверьте, слушает ли chisel на порту 80
```
*   **Проверка Hugging Face Space logs:**
    На странице вашего Hugging Face Space перейдите во вкладку "Logs" для просмотра логов Docker контейнера. Это поможет отладить проблемы с запуском `chisel client` или `x-ui`.
*   **Проверка доступности x-ui:**
    Попробуйте получить доступ к вашей x-ui панели через домен `https://vds1.iri1968.dpdns.org`.

## 4. Настройка Git для Hugging Face

Для эффективной работы с репозиториями Hugging Face (Spaces, Models) необходимо правильно настроить Git, особенно для работы с большими файлами через Git LFS.

### 4.1. Установка и настройка Git LFS

Git Large File Storage (LFS) — это расширение Git, которое позволяет версионировать большие файлы, такие как наборы данных, модели и видео, не сохраняя их непосредственно в репозитории Git.

1.  **Установите Git LFS:**
    *   **Debian/Ubuntu:**
        ```bash
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
        sudo apt-get install git-lfs
        ```
    *   **macOS (с Homebrew):**
        ```bash
        brew install git-lfs
        ```
    *   **Windows (с Chocolatey):**
        ```bash
        choco install git-lfs
        ```
    *   **Другие ОС:** См. [официальную документацию Git LFS](https://git-lfs.com/).

2.  **Инициализируйте Git LFS для вашего пользователя:**
    ```bash
git lfs install
```
    Эту команду нужно выполнить один раз для вашей системы.

3.  **Настройте Git LFS для отслеживания больших файлов в вашем репозитории:**
    Перейдите в корневую директорию вашего репозитория Hugging Face (например, `your-username/x-ui-tunnel`) и укажите, какие типы файлов должны отслеживаться Git LFS. Например, для отслеживания всех файлов `.bin` и `.safetensors`:
    ```bash
git lfs track "*.bin"
git lfs track "*.safetensors"
# Добавьте другие типы файлов по необходимости, например:
# git lfs track "*.zip"
# git lfs track "*.tar.gz"
```
    Эти команды создадут или обновят файл `.gitattributes` в вашем репозитории. Убедитесь, что вы закоммитили этот файл:
    ```bash
git add .gitattributes
git commit -m "Add Git LFS tracking for large files"
```

### 4.2. Аутентификация с Hugging Face (использование токена)

Для взаимодействия с репозиториями Hugging Face вам потребуется токен доступа.

1.  **Получите ваш токен доступа:**
    *   Перейдите на [Hugging Face Settings -> Access Tokens](https://huggingface.co/settings/tokens).
    *   Создайте новый токен с правами "write" (для загрузки файлов) или используйте существующий. Скопируйте его.

2.  **Настройте Git для использования токена:**
    Вы можете использовать `huggingface-cli login` (если у вас установлен пакет `huggingface_hub` для Python) или настроить Git вручную.

    *   **Использование `huggingface-cli` (рекомендуется):**
        ```bash
pip install huggingface_hub
huggingface-cli login
# Введите ваш токен, когда будет предложено
```
        Это сохранит ваш токен в безопасном месте и настроит Git для его использования.

    *   **Ручная настройка Git (менее безопасно для токена):**
        Вы можете добавить токен непосредственно в URL репозитория при клонировании или настроить Git credential helper.
        Пример клонирования с токеном (не рекомендуется для постоянного использования):
        ```bash
git clone https://oauth-token-goes-here@huggingface.co/your-username/your-repo
```
        Лучше использовать `huggingface-cli login` или настроить Git credential helper.

### 4.3. Клонирование и отправка изменений

После настройки Git LFS и аутентификации вы можете работать с репозиториями Hugging Face как с обычными Git-репозиториями.

1.  **Клонирование репозитория:**
    ```bash
git clone https://huggingface.co/spaces/your-username/your-space-name
# или для моделей:
# git clone https://huggingface.co/your-username/your-model-name
```

2.  **Внесение изменений и отправка:**
    ```bash
# Внесите изменения в файлы
git add .
git commit -m "Your commit message"
git push
```
    Git LFS автоматически обработает большие файлы при `git push`.
