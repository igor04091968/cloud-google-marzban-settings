
import json
import requests
import base64
import socket
import subprocess
import logging
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlparse, parse_qs

# --- НАСТРОЙКИ ---
# URL к raw файлу с подпиской на GitHub
SUBSCRIPTION_URL = "https://raw.githubusercontent.com/ALIILAPRO/v2rayNG-Config/refs/heads/main/sub.txt"

# Путь к конфигурационному файлу Xray
XRAY_CONFIG_PATH = "/var/lib/marzban/xray_config.json"

# Сервис для перезапуска
SERVICE_TO_RESTART = "marzban"

# Настройки проверки прокси
CHECK_TIMEOUT = 3  # Секунды
MAX_PROXIES_TO_USE = 5
CHECK_HOST_PORT = ("8.8.8.8", 53) # Куда подключаться для проверки

# Настройки логирования
LOG_FILE = "/var/log/update_xray_proxies.log"

# --- КОНЕЦ НАСТРОЕК ---

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[
                        logging.FileHandler(LOG_FILE),
                        logging.StreamHandler()
                    ])

def fetch_subscription_content(url):
    """Загружает и декодирует содержимое подписки."""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        content = response.text
        # Попытка декодировать из Base64, если это необходимо
        try:
            decoded_content = base64.b64decode(content).decode('utf-8')
            return decoded_content.splitlines()
        except (ValueError, TypeError):
            return content.splitlines()
    except requests.RequestException as e:
        logging.error(f"Ошибка при загрузке подписки: {e}")
        return []

def parse_vless_link(link):
    """Парсит VLESS ссылку в словарь, совместимый с Xray."""
    try:
        parsed_url = urlparse(link)
        uuid = parsed_url.username
        address = parsed_url.hostname
        port = parsed_url.port
        
        params = parse_qs(parsed_url.query)
        
        stream_settings = {
            "network": params.get("type", ["tcp"])[0],
            "security": params.get("security", ["none"])[0],
        }

        if stream_settings["network"] == "ws":
            stream_settings["wsSettings"] = {
                "path": params.get("path", ["/"])[0],
                "headers": {"Host": params.get("host", [address])[0]}
            }
        
        if stream_settings["security"] == "tls":
             stream_settings["tlsSettings"] = {
                "serverName": params.get("sni", [address])[0]
            }


        return {
            "protocol": "vless",
            "settings": {
                "vnext": [{
                    "address": address,
                    "port": port,
                    "users": [{
                        "id": uuid,
                        "encryption": params.get("encryption", ["none"])[0]
                    }]
                }]
            },
            "streamSettings": stream_settings,
            # Уникальный тег для балансировщика
            "tag": f"proxy-auto-{address}-{port}" 
        }
    except Exception as e:
        logging.warning(f"Не удалось разобрать ссылку {link}: {e}")
        return None

def check_proxy(proxy_config):
    """Проверяет доступность прокси путем TCP-соединения."""
    try:
        address = proxy_config["settings"]["vnext"][0]["address"]
        port = proxy_config["settings"]["vnext"][0]["port"]
        
        with socket.create_connection((address, port), timeout=CHECK_TIMEOUT):
            logging.info(f"Прокси {address}:{port} доступен.")
            return proxy_config
    except (socket.timeout, socket.error, KeyError) as e:
        # logging.warning(f"Прокси {proxy_config['settings']['vnext'][0]['address']}:{proxy_config['settings']['vnext'][0]['port']} недоступен: {e}")
        return None

def update_xray_config(good_proxies):
    """Обновляет конфигурационный файл Xray с новыми прокси."""
    if not good_proxies:
        logging.warning("Нет доступных прокси для обновления. Конфиг не изменен.")
        return False

    try:
        with open(XRAY_CONFIG_PATH, 'r') as f:
            config = json.load(f)

        # Находим и удаляем старый балансировщик и его прокси
        new_outbounds = []
        for outbound in config.get("outbounds", []):
            if outbound.get("tag", "").startswith("proxy-auto-"):
                continue # Удаляем старые авто-прокси
            if outbound.get("tag") == "PROXY":
                continue # Удаляем старый балансировщик
            new_outbounds.append(outbound)
        
        config["outbounds"] = new_outbounds

        # Добавляем новые прокси
        proxy_tags = []
        for proxy in good_proxies:
            config["outbounds"].append(proxy)
            proxy_tags.append(proxy["tag"])

        # Создаем и добавляем балансировщик
        balancer = {
            "tag": "PROXY",
            "protocol": "balancer",
            "settings": {
                "selector": proxy_tags
            }
        }
        config["outbounds"].append(balancer)
        
        with open(XRAY_CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=2)
        
        logging.info(f"Конфиг успешно обновлен. Добавлено {len(good_proxies)} прокси в балансировщик.")
        return True

    except (FileNotFoundError, json.JSONDecodeError, PermissionError) as e:
        logging.error(f"Ошибка при работе с конфиг. файлом {XRAY_CONFIG_PATH}: {e}")
        return False

def restart_service():
    """Перезапускает указанный сервис."""
    try:
        subprocess.run(["systemctl", "restart", SERVICE_TO_RESTART], check=True)
        logging.info(f"Сервис {SERVICE_TO_RESTART} успешно перезапущен.")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logging.error(f"Не удалось перезапустить сервис {SERVICE_TO_RESTART}: {e}")

def main():
    logging.info("--- Запуск скрипта обновления прокси ---")
    
    if SUBSCRIPTION_URL == "YOUR_GITHUB_RAW_URL_HERE":
        logging.error("URL подписки не указан. Пожалуйста, отредактируйте скрипт.")
        return

    links = fetch_subscription_content(SUBSCRIPTION_URL)
    if not links:
        return

    logging.info(f"Загружено {len(links)} ссылок.")
    
    parsed_proxies = [parse_vless_link(link) for link in links if link.startswith("vless://")]
    parsed_proxies = [p for p in parsed_proxies if p is not None]

    # --- Начало блока дедупликации ---
    logging.info(f"Начинаю дедупликацию {len(parsed_proxies)} прокси.")
    unique_proxies = []
    seen_identifiers = set()
    for proxy in parsed_proxies:
        try:
            # Создаем уникальный идентификатор для каждого прокси
            vnext = proxy["settings"]["vnext"][0]
            identifier = f"{vnext['address']}:{vnext['port']}:{vnext['users'][0]['id']}"
            if identifier not in seen_identifiers:
                seen_identifiers.add(identifier)
                unique_proxies.append(proxy)
        except (KeyError, IndexError):
            continue # Игнорируем неправильно сформированные прокси
    
    logging.info(f"Осталось {len(unique_proxies)} уникальных прокси после дедупликации.")
    parsed_proxies = unique_proxies
    # --- Конец блока дедупликации ---

    logging.info(f"Разобрано {len(parsed_proxies)} VLESS прокси. Начинаю проверку...")

    good_proxies = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        results = executor.map(check_proxy, parsed_proxies)
        for result in results:
            if result:
                good_proxies.append(result)

    logging.info(f"Найдено {len(good_proxies)} рабочих прокси.")
    
    selected_proxies = good_proxies[:MAX_PROXIES_TO_USE]

    if update_xray_config(selected_proxies):
        restart_service()
    
    logging.info("--- Скрипт завершил работу ---")

if __name__ == "__main__":
    main()
