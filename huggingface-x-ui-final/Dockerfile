FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y curl unzip gzip binutils && rm -rf /var/lib/apt/lists/*

# Установка 3x-ui
RUN curl -L -o x-ui.tar.gz "https://github.com/MHSanaei/3x-ui/releases/download/v2.8.4/x-ui-linux-amd64.tar.gz" && \
    tar -xzf x-ui.tar.gz && \
    mkdir -p /usr/local/x-ui/bin && \
    mv x-ui/x-ui /usr/local/x-ui/ && \
    mv x-ui/bin/xray-linux-amd64 /usr/local/x-ui/bin/ && \
    chmod +x /usr/local/x-ui/x-ui /usr/local/x-ui/bin/xray-linux-amd64 && \
    rm -rf x-ui x-ui.tar.gz

# Установка Chisel (НОВАЯ ВЕРСИЯ через curl)
RUN curl -L -o chisel.gz "https://github.com/jpillora/chisel/releases/download/v1.11.3/chisel_1.11.3_linux_amd64.gz" && \
    gunzip chisel.gz && \
    mv chisel /usr/local/bin/chisel && \
    chmod +x /usr/local/bin/chisel

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]