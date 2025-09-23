#!/bin/bash

# Финальная версия скрипта v5, с исправленной версией sing-box

# --- ПАРАМЕТРЫ ---
TEST_URL="https://www.google.com"
LOCAL_PORT=10808
TIMEOUT=10
SERVER_LIMIT=10
WORKING_SERVERS_FILE="working_servers.txt"

# --- Проверка зависимостей ---
for cmd in curl jq base64 xray awk sed printf; do
  if ! command -v $cmd &> /dev/null; then
    echo "Ошибка: Требуемая команда '$cmd' не установлена." >&2
    exit 1
  fi
done

# --- Проверка входных данных ---
if [[ -z "$1" ]]; then
  echo "Использование: $0 <URL_подписки> [лимит_серверов]"
  exit 1
fi

SUB_URL="$1"
SERVER_LIMIT=${2:-10}

rm -f "$WORKING_SERVERS_FILE"

echo "Получение и тестирование первых $SERVER_LIMIT серверов из: $SUB_URL"
echo "Рабочие серверы будут сохранены в $WORKING_SERVERS_FILE"

# --- Функции ---

url_decode() {
    printf '%b' "${1//%/\\x}"
}

create_vmess_config() {
  local config_json="$1"
  local temp_config_file="$2"
  local address=$(echo "$config_json" | jq -r .add)
  local port=$(echo "$config_json" | jq -r .port)
  local uuid=$(echo "$config_json" | jq -r .id)
  local security=$(echo "$config_json" | jq -r .scy)
  local network=$(echo "$config_json" | jq -r .net)
  local tls_sec=$(echo "$config_json" | jq -r .tls)
  local host=$(echo "$config_json" | jq -r .host)
  local path=$(echo "$config_json" | jq -r .path)

cat > "$temp_config_file" <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{"port": $LOCAL_PORT, "listen": "127.0.0.1", "protocol": "socks", "settings": {"auth": "noauth", "udp": true}}],
  "outbounds": [{
      "protocol": "vmess",
      "settings": {"vnext": [{"address": "$address", "port": $port, "users": [{"id": "$uuid", "security": "$security", "alterId": 0}]}]},
      "streamSettings": {
        "network": "$network", "security": "$tls_sec",
        "wsSettings": {"path": "$path", "headers": {"Host": "$host"}}
      },
      "tag": "proxy"
  }]
}
EOF
}

create_vless_config() {
    local line="$1"
    local temp_config_file="$2"

    local data_part=$(echo "${line#vless://}")
    local user_info=$(echo "$data_part" | awk -F'@' '{print $1}')
    local address_part=$(echo "$data_part" | awk -F'@' '{print $2}')
    local address=$(echo "$address_part" | awk -F':' '{print $1}')
    local port=$(echo "$address_part" | awk -F'[:?]' '{print $2}')
    local query=$(echo "$address_part" | awk -F'?' '{print $2}' | awk -F'#' '{print $1}')

    declare -A params
    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            params["$key"]=$(url_decode "$value")
        fi
    done < <(echo "$query" | sed 's/&/\n/g')

    local type=${params[type]:-tcp}
    local security=${params[security]:-none}
    local sni=${params[sni]:-}
    local fp=${params[fp]:-}
    local path=${params[path]:-/}
    local host=${params[host]:-}
    local flow=${params[flow]:-}
    local pbk=${params[pbk]:-}
    local sid=${params[sid]:-}

    local jq_filter=' 
    {
        log: {loglevel: "warning"},
        inbounds: [{port: $LOCAL_PORT, listen: "127.0.0.1", protocol: "socks", settings: {auth: "noauth", udp: true}}],
        outbounds: [{
            protocol: "vless",
            settings: {vnext: [{address: $address, port: $port, users: [{id: $uuid, flow: $flow, encryption: "none"}]}]},
            streamSettings: {
                network: $network,
                security: $security,
                realitySettings: (if $security == "reality" then {fingerprint: $fp, serverName: $sni, publicKey: $pbk, shortId: $sid} else null end),
                tlsSettings: (if $security == "tls" then {serverName: $sni, fingerprint: $fp} else null end),
                wsSettings: (if $network == "ws" then {path: $path, headers: {Host: $host}} else null end)
            },
            tag: "proxy"
        }]
    }'

    jq -n \
      --argjson LOCAL_PORT "$LOCAL_PORT" \
      --argjson port "${port:-443}" \
      --arg address "$address" \
      --arg uuid "$user_info" \
      --arg network "$network" \
      --arg security "$security" \
      --arg sni "$sni" \
      --arg fp "$fp" \
      --arg path "$path" \
      --arg host "$host" \
      --arg flow "$flow" \
      --arg pbk "$pbk" \
      --arg sid "$sid" \
      "$jq_filter" > "$temp_config_file"
}

# --- Основной цикл ---

counter=0
curl -sL "$SUB_URL" | grep -E '^(vmess|vless)://' | head -n "$SERVER_LIMIT" | while IFS= read -r line; do
  counter=$((counter+1))
  echo -n "[$counter/$SERVER_LIMIT] Тестирование... "

  TEMP_CONFIG="/tmp/xray_config.json"

  if [[ $line == vmess://* ]]; then
    config_data=$(echo "${line#vmess://}" | base64 --decode 2>/dev/null)
    if [[ -z "$config_data" ]]; then echo -e "\e[1;33mПРОПУСК (ошибка декодирования)\e[0m"; continue; fi
    create_vmess_config "$config_data" "$TEMP_CONFIG"
    server_name=$(echo "$config_data" | jq -r .ps)
    echo -n "(VMess: $server_name) ... "
  elif [[ $line == vless://* ]]; then
    name=$(url_decode "$(echo "$line" | awk -F'#' '{print $2}')")
    create_vless_config "$line" "$TEMP_CONFIG"
    echo -n "(VLESS: $name) ... "
  else
    echo -e "\e[1;33mПРОПУСК\e[0m"
    continue
  fi

  xray -c "$TEMP_CONFIG" &> /dev/null &
XRAY_PID=$!
sleep 2

curl_output=$(curl -s --head --proxy socks5h://127.0.0.1:$LOCAL_PORT "$TEST_URL" -m $TIMEOUT)
curl_exit_code=$?

kill $XRAY_PID &>/dev/null
wait $XRAY_PID 2>/dev/null

if [ $curl_exit_code -eq 0 ]; then
  echo -e "\e[1;32mРАБОТАЕТ\e[0m"
  echo "$line" >> "$WORKING_SERVERS_FILE"
else
  echo -e "\e[1;31mНЕ РАБОТАЕТ\e[0m"
fi
done

echo "=================================================="
echo "Проверка завершена. Рабочие серверы сохранены в $WORKING_SERVERS_FILE"
