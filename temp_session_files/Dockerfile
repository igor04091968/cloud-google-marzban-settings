# Используем базовый образ Debian
FROM debian:bullseye-slim

# Устанавливаем переменные окружения, чтобы избежать интерактивных запросов при установке
ENV DEBIAN_FRONTEND=noninteractive

# 1. Установка всех системных зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    sqlite3 \
    jq \
    openssl \
    tor \
    tor-geoipdb \
    psmisc \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Установка 3x-ui
RUN mkdir -p /usr/local/x-ui \
    && wget -O /tmp/x-ui.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz \
    && tar -zxvf /tmp/x-ui.tar.gz -C /usr/local/x-ui/ --strip-components=1 \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui /usr/local/x-ui/bin/xray-linux-amd64

# 3. Установка sing-box (конкретная бета-версия)
RUN SINGBOX_VERSION="1.9.0-beta.11" \
    && SINGBOX_FILENAME="sing-box-1.9.0-beta.11-linux-amd64" \
    && wget -O /tmp/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/${SINGBOX_FILENAME}.tar.gz" \
    && tar -zxvf /tmp/sing-box.tar.gz -C /tmp/ \
    && install -m 755 "/tmp/${SINGBOX_FILENAME}/sing-box" /usr/local/bin/sing-box \
    && rm -rf /tmp/sing-box*

# 4. Установка Xray-core
RUN XRAY_VERSION=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | jq -r .tag_name) \
    && wget -O /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip" \
    && unzip -d /tmp/xray /tmp/xray.zip \
    && install -m 755 /tmp/xray/xray /usr/local/bin/xray \
    && install -d /usr/local/share/xray \
    && install /tmp/xray/geoip.dat /usr/local/share/xray/geoip.dat \
    && install /tmp/xray/geosite.dat /usr/local/share/xray/geosite.dat \
    && rm -rf /tmp/xray*

# 5. Установка v2rayA
RUN V2RAYA_VERSION=$(curl -s "https://api.github.com/repos/v2rayA/v2rayA/releases/latest" | jq -r .tag_name) \
    && V2RAYA_SHORT_VERSION=$(echo ${V2RAYA_VERSION} | sed 's/v//') \
    && wget -O /usr/local/bin/v2raya "https://github.com/v2rayA/v2rayA/releases/download/${V2RAYA_VERSION}/v2raya_linux_x64_${V2RAYA_SHORT_VERSION}" \
    && chmod +x /usr/local/bin/v2raya

# 6. Установка Chisel
RUN wget https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_amd64.gz -O /tmp/chisel.gz \
    && gunzip /tmp/chisel.gz \
    && mv /tmp/chisel /usr/local/bin/chisel \
    && chmod +x /usr/local/bin/chisel

# 7. Создание символической ссылки для xray в 3x-ui
RUN ln -sf /usr/local/bin/xray /usr/local/x-ui/bin/xray-linux-amd64

# 8. Копирование конфигураций и скриптов
RUN mkdir -p /etc/sing-box
COPY warp_config.json /etc/sing-box/warp_config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Открываем стандартные порты
EXPOSE 2053 2017 8086

# Запускаем наш стартовый скрипт
ENTRYPOINT ["/entrypoint.sh"]