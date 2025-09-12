# Конфигурация служб на vds1.iri1968.dpdns.org

Этот документ описывает настройку и параметры запуска для служб `socat`, `nginx` и `chisel`.

## 1. Socat (TLS-прокси)

`socat` работает как TLS-терминатор, принимая трафик на порту 443 и перенаправляя его на Nginx.

### Файл службы: `/etc/systemd/system/socat-placeholder.service`

```ini
[Unit]
Description=Socat TLS reverse proxy for Nginx Placeholder
After=network.target

[Service]
ExecStart=/usr/bin/socat OPENSSL-LISTEN:443,fork,reuseaddr,cert=/etc/letsencrypt/live/vds1.iri1968.dpdns.org/fullchain.pem,key=/etc/letsencrypt/live/vds1.iri1968.dpdns.org/privkey.pem,verify=0 TCP:127.0.0.1:8081
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
```

---

## 2. Nginx (Веб-сервер заглушки)

Nginx сконфигурирован для двух целей:
1.  Отдавать сайт-заглушку, слушая внутренний порт `127.0.0.1:8081`.
2.  Обслуживать порт `80` для обновления сертификатов Let's Encrypt.

### Основной конфигурационный файл: `/etc/nginx/nginx.conf`

Ключевое изменение в этом файле — директива `include` теперь включает все файлы из `sites-enabled`, а не только те, что с расширением `.conf`.

```nginx
# ... (пропущено для краткости) ...
http {
    # ...
    ##
    # Virtual Host Configs
    ##

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
# ... (пропущено для краткости) ...
```

### Конфигурация сайта-заглушки: `/etc/nginx/sites-available/placeholder`

```nginx
server {
    listen 127.0.0.1:8081;
    server_name vds1.iri1968.dpdns.org;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Конфигурация для Certbot: `/etc/nginx/sites-available/certbot`

```nginx
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
```

### Файл заглушки: `/var/www/html/index.html`

```html
<html><body><h1>It works! (Nginx via Socat)</h1></body></html>
```

---

## 3. Chisel (Сервер туннелей)

Chisel сервер работает в фоновом режиме и готов к приему подключений от клиентов для создания туннелей.

### Файл службы: `/etc/systemd/system/chisel-server.service`

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
