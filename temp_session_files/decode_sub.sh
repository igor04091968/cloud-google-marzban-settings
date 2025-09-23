#!/bin/bash

# Скрипт для декодирования и вывода информации из ссылок-подписок V2Ray

# --- Проверка зависимостей ---
for cmd in curl jq base64 sed awk grep; do
  if ! command -v $cmd &> /dev/null; then
    echo "Ошибка: Требуемая команда '$cmd' не установлена." >&2
    exit 1
  fi
done

# --- Проверка входных данных ---
if [[ -z "$1" ]]; then
  echo "Использование: $0 <URL_подписки>"
  exit 1
fi

SUB_URL="$1"
echo "Получение и декодирование серверов из: $SUB_URL"
echo "=================================================="

# --- Скачивание и обработка ---
# Используем process substitution, чтобы избежать проблем с переменными в цикле while-read
while IFS= read -r line; do
  # Пропускаем пустые строки
  if [[ -z "$line" ]]; then
    continue
  fi

  # --- VMess ---
  if [[ $line == vmess://* ]]; then
    JSON_DATA=$(echo "${line#vmess://}" | base64 --decode 2>/dev/null)
    if [[ -n "$JSON_DATA" ]]; then
      ps=$(echo "$JSON_DATA" | jq -r .ps)
      add=$(echo "$JSON_DATA" | jq -r .add)
      port=$(echo "$JSON_DATA" | jq -r .port)
      id=$(echo "$JSON_DATA" | jq -r .id)
      net=$(echo "$JSON_DATA" | jq -r .net)
      tls=$(echo "$JSON_DATA" | jq -r .tls)
      echo -e "\e[1;32mПротокол: VMess\e[0m"
      echo -e "  \e[1;37mИмя:\e[0m $ps"
      echo -e "  \e[1;37mАдрес:\e[0m $add:$port"
      echo -e "  \e[1;37mUUID:\e[0m $id"
      echo -e "  \e[1;37mСеть:\e[0m $net, \e[1;37mTLS:\e[0m $tls"
      echo "--------------------------------------------------"
    fi
  # --- VLESS / Trojan ---
  elif [[ $line == vless://* ]] || [[ $line == trojan://* ]]; then
    protocol=$(echo "$line" | awk -F '://' '{print $1}')
    # Убираем префикс протокола
    data_part=$(echo "${line#*://}")
    
    # Отделяем имя (после #)
    name_part=$(echo "$data_part" | awk -F '#' '{print $2}')
    main_part=$(echo "$data_part" | awk -F '#' '{print $1}')
    
    # Отделяем информацию о пользователе и адрес
    user_info=$(echo "$main_part" | awk -F '@' '{print $1}')
    address_info=$(echo "$main_part" | awk -F '@' '{print $2}' | awk -F '?' '{print $1}')
    
    # Отделяем параметры запроса
    query_params=$(echo "$main_part" | awk -F '?' '{print $2}')

    echo -e "\e[1;32mПротокол: ${protocol^}\e[0m" # С большой буквы
    echo -e "  \e[1;37mИмя:\e[0m ${name_part}"
    echo -e "  \e[1;37mАдрес:\e[0m ${address_info}"
    echo -e "  \e[1;37mUser/Pass:\e[0m ${user_info}"
    # Выводим параметры для наглядности
    if [[ -n "$query_params" ]]; then
        echo -e "  \e[1;37mПараметры:\e[0m"
        echo "    $query_params" | sed 's/&/\n    /g'
    fi
    echo "--------------------------------------------------"
  fi
done < <(curl -sL "$SUB_URL")

echo "Декодирование завершено."
