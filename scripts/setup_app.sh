#!/bin/bash
#
# Скрипт для полного автоматического развертывания Marzban в Minikube.
# ВНИМАНИЕ: Этот скрипт предназначен для выполнения в среде, где уже есть доступ
# к kubectl, minikube и репозиторию проекта.
# Он НЕ настраивает удаленный VDS-сервер.

# Используем строгий режим для надежности
set -euo pipefail

# Определяем директорию, где находится сам скрипт, для корректной работы с путями
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Конфигурация ---
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="04091968"
NAMESPACE="marzban"
KUBERNETES_DIR="${SCRIPT_DIR}/../kubernetes"
# --- Конец конфигурации ---

echo "--- Запуск скрипта для развертывания Marzban в Kubernetes ---"

# --- Шаг 1: Запуск Minikube ---
echo "--> Проверка статуса Minikube..."
if ! minikube status &> /dev/null; then
    echo "--> Minikube не запущен. Запускаю..."
    minikube start
else
    echo "--> Minikube уже запущен."
fi

# --- Шаг 2: Создание пространства имен ---
echo "--> Проверка пространства имен '${NAMESPACE}'..."
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "--> Создание пространства имен '${NAMESPACE}'..."
    kubectl create namespace ${NAMESPACE}
else
    echo "--> Пространство имен '${NAMESPACE}' уже существует."
fi

# --- Шаг 3: Создание секрета для Marzban Node ---
SECRET_NAME="marzban-node-certs"
echo "--> Проверка секрета '${SECRET_NAME}'..."
if ! kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} &> /dev/null; then
    echo "--> Создание SSL-сертификата и секрета '${SECRET_NAME}'..."
    openssl req -x509 -newkey rsa:2048 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=marzban-node"
    kubectl create secret tls ${SECRET_NAME} --cert=tls.crt --key=tls.key -n ${NAMESPACE}
    rm tls.key tls.crt
    echo "--> Секрет '${SECRET_NAME}' успешно создан."
else
    echo "--> Секрет '${SECRET_NAME}' уже существует."
fi

# --- Шаг 4: Применение манифестов Kubernetes ---
echo "--> Применение всех конфигурационных файлов из директории '${KUBERNETES_DIR}'..."
kubectl apply -f ${KUBERNETES_DIR}

# --- Шаг 5: Ожидание готовности подов ---
echo "--> Ожидание полной готовности всех подов в пространстве '${NAMESPACE}'... (может занять до 5 минут)"
kubectl wait --for=condition=ready pod --all -n ${NAMESPACE} --timeout=300s
echo "--> Все поды успешно запущены и работают."

# --- Шаг 6: Создание суперадминистратора ---
echo "--> Создание суперадминистратора с логином '${ADMIN_USERNAME}'..."
CONTROLLER_POD=$(kubectl get pods -n ${NAMESPACE} -l app=marzban-controller -o jsonpath='{.items[0].metadata.name}')

# Проверяем, не создан ли уже такой пользователь
ADMIN_LIST=$(kubectl exec ${CONTROLLER_POD} -n ${NAMESPACE} -- marzban-cli admin list)
if echo "${ADMIN_LIST}" | grep -q "${ADMIN_USERNAME}"; then
    echo "--> Администратор '${ADMIN_USERNAME}' уже существует."
else
    echo -e '\n' | kubectl exec -i ${CONTROLLER_POD} -n ${NAMESPACE} -- \
    env MARZBAN_ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
    marzban-cli admin create --username "${ADMIN_USERNAME}" --sudo
    echo "--> Администратор '${ADMIN_USERNAME}' успешно создан."
fi

# --- Шаг 7: Завершение ---
echo ""
echo "--- УСПЕХ! Локальная часть Marzban полностью развернута в Minikube ---"
echo ""
echo "Не забудьте выполнить шаги по настройке Nginx и Chisel на вашем VDS-сервере,"
echo "а также запустить клиент Chisel для проброса портов, как описано в README.md."
echo ""