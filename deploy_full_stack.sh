#!/bin/bash

# Прекратить выполнение при любой ошибке
set -e

# ==============================================================================
# --- КОНФИГУРАЦИЯ ---

# !!! ВАЖНО: Замените на имя вашего НОВОГО, ПЕРЕСОБРАННОГО Docker-образа !!!
DOCKER_IMAGE="YOUR_DOCKERHUB_USERNAME/YOUR_IMAGE_NAME:new-chisel"

# Параметры для VDS
VDS_HOST="vds1.iri1968.dpdns.org"
VDS_USER="root"
CHISEL_SERVER_PORT="8444" # Новый порт для chisel-server

# ==============================================================================

# Проверка, что пользователь изменил плейсхолдер
if [ "$DOCKER_IMAGE" == "YOUR_DOCKERHUB_USERNAME/YOUR_IMAGE_NAME:new-chisel" ]; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!! ОШИБКА: Пожалуйста, отредактируйте этот скрипт."
  echo "!!! Замените значение переменной DOCKER_IMAGE на имя вашего образа."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

# --- Шаг 1: Настройка chisel-server на VDS ---
echo "⚙️  Настраиваю chisel-server на $VDS_HOST..."

echo "   - Завершаю старые процессы chisel-server (если есть)..."
ssh $VDS_USER@$VDS_HOST "pkill -f 'chisel server' || true"

echo "   - Запускаю новый chisel-server на порту $CHISEL_SERVER_PORT..."
ssh $VDS_USER@$VDS_HOST "nohup chisel server --port $CHISEL_SERVER_PORT --reverse > /dev/null 2>&1 &"

# Даем серверу секунду на запуск
sleep 3

echo "   - Проверяю, что сервер запущен..."
ssh $VDS_USER@$VDS_HOST "ps aux | grep '[c]hisel server --port $CHISEL_SERVER_PORT'"
echo "✅ chisel-server на VDS настроен."
echo ""


# --- Шаг 2: Развертывание в Kubernetes ---
echo "🚀 Начинаю развертывание сервиса x-ui в Kubernetes..."
echo "   Использую образ: $DOCKER_IMAGE"
echo ""

echo "📄 Создаю Kubernetes Deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-ui-deployment
  labels:
    app: x-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: x-ui
  template:
    metadata:
      labels:
        app: x-ui
    spec:
      containers:
      - name: x-ui-container
        image: $DOCKER_IMAGE
        ports:
        - containerPort: 2053
EOF
echo "✅ Deployment создан."
echo ""

echo "🌐 Создаю Kubernetes Service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: x-ui-service
spec:
  type: NodePort
  selector:
    app: x-ui
  ports:
    - protocol: TCP
      port: 2053
      targetPort: 2053
EOF
echo "✅ Service создан."
echo ""

echo "⏳ Ожидаю завершения развертывания..."
kubectl rollout status deployment/x-ui-deployment --timeout=120s
echo "✅ Развертывание успешно завершено!"
echo ""

# --- Шаг 3: Получение информации для доступа ---
echo "🔎 Получаю информацию для доступа..."
NODE_PORT=$(kubectl get service x-ui-service -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "🎉 --- УСПЕХ! --- 🎉"
echo "Ваш сервис x-ui развернут в Kubernetes, туннель к VDS настроен."
echo "   IP-адрес узла (Node IP): $NODE_IP"
echo "   Внешний порт (NodePort):  $NODE_PORT"
echo "   ➡️ Попробуйте открыть в браузере: http://$NODE_IP:$NODE_PORT"
echo "----------------------------------------------------------------------"
