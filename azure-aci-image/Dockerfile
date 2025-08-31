FROM python:3.9-slim
RUN apt-get update && apt-get install -y curl socat && rm -rf /var/lib/apt/lists/*
RUN pip install marzban
RUN curl -L https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz | gunzip > /usr/local/bin/chisel && chmod +x /usr/local/bin/chisel
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]