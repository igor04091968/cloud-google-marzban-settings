# Финальная конфигурация VDS1 и клиента Chisel

Этот документ описывает финальную, рабочую конфигурацию для доступа к панели `x-ui` через туннель `chisel`, используя Nginx в качестве единой точки входа.

## Обзор архитектуры

1.  **Nginx** является единственной службой, слушающей внешние порты `80` и `443` на сервере `vds1`.
2.  **Chisel-клиент** (из Hugging Face) подключается к `vds1` на порт `443` по специальному WebSocket-пути `/chisel-ws`.
3.  **Nginx** определяет это WebSocket-соединение и проксирует его на `chisel-сервер`, работающий локально на порту `8080`.
4.  **Chisel-сервер** устанавливает туннель, открывая на `vds1` локальный порт `8000`, который ведет к панели `x-ui` в контейнере.
5.  **Обычные пользователи** (браузеры), заходящие на `https://vds1.iri1968.dpdns.org`, попадают в Nginx, который проксирует их запросы на порт `8000`, т.е. в туннель к `x-ui`.

---

## 1. Конфигурация сервера `vds1.iri1968.dpdns.org`

### 1.1. Nginx

Nginx выполняет двойную роль: маршрутизатора для WebSocket-соединений `chisel` и обратного прокси для `x-ui`.

#### Основной файл конфигурации сайта: `/etc/nginx/sites-available/00-main-proxy`

Этот файл содержит всю логику для портов 80 и 443.

```nginx
# Карта для корректного обновления соединения до WebSocket
map $http_upgrade $connection_upgrade {
    default upgrade;
    ""      close;
}

# Сервер для порта 80: обработка Let's Encrypt и редирект на HTTPS
server {
    listen 80;
    server_name vds1.iri1968.dpdns.org;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# Основной сервер для порта 443: обработка TLS и маршрутизация
server {
    listen 443 ssl http2;
    server_name vds1.iri1968.dpdns.org;

    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem;

    # Локация для WebSocket-соединений от chisel-клиента
    location /chisel-ws {
        proxy_pass http://127.0.0.1:8080; # Направляем на chisel-сервер
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_read_timeout 7d; # Длительный таймаут для постоянного соединения
    }

    # Локация по умолчанию для доступа к панели x-ui
    location / {
        proxy_pass http://127.0.0.1:8000; # Направляем на вход в туннель
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 1.2. Chisel Server

Сервер `chisel` работает как фоновая служба `systemd`, принимая подключения только с локальной машины.

#### Файл службы: `/etc/systemd/system/chisel-server.service`

```ini
[Unit]
Description=Chisel Server
After=network.target

[Service]
ExecStart=/usr/local/bin/chisel server --host 127.0.0.1 --port 8080 --reverse --auth cloud:2025
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
```

### 1.3. Отключенные службы

Служба `socat` (`socat-placeholder.service`) была **отключена** и не используется в данной конфигурации.

---

## 2. Конфигурация клиента Chisel (Hugging Face)

### 2.1. Команда запуска

Это финальная, рабочая команда для запуска `chisel` клиента внутри контейнера.

```bash
/usr/local/bin/chisel client -v --auth "cloud:2025" wss://vds1.iri1968.dpdns.org/chisel-ws R:8000:127.0.0.1:2023
```

**Ключевые моменты команды:**
*   `wss://...`: Указывает на необходимость установки защищенного WebSocket-соединения.
*   `.../chisel-ws`: Специальный путь, который Nginx использует для маршрутизации на `chisel-сервер`.
*   `R:8000:127.0.0.1:2023`: Создает обратный туннель, делая `x-ui` (порт `2023` в контейнере) доступным на сервере `vds1` по адресу `127.0.0.1:8000`.
