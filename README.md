# Развертывание Marzban в Kubernetes

Этот репозиторий содержит все необходимые файлы и инструкции для развертывания панели управления прокси-серверами Marzban в кластере Kubernetes.

## Предварительные требования

Перед началом убедитесь, что у вас есть:

*   Работающий кластер Kubernetes.
*   `kubectl`, настроенный для доступа к вашему кластеру.
*   Доменное имя, направленное на IP-адрес вашего сервера, где будет работать туннель.
*   `git` и `git-lfs`, установленные на вашей локальной машине.

## Шаги развертывания

### 1. Клонирование репозитория

Склонируйте этот репозиторий на вашу локальную машину:

```bash
git clone https://github.com/igor04091968/cloud-google-marzban-settings.git
cd cloud-google-marzban-settings
```

### 2. Применение конфигураций Kubernetes

Примените все манифесты Kubernetes из директории `kubernetes` в вашем кластере. Эти команды создадут все необходимые ресурсы: namespace, deployments, services, configmaps, и persistent volume claims.

```bash
kubectl apply -f kubernetes/
```

### 3. Настройка реверс-туннеля

Для доступа к панели Marzban извне кластера используется реверс-туннель, созданный с помощью `chisel`.

На вашем внешнем сервере (например, VDS), куда указывает ваше доменное имя, запустите сервер `chisel`:

```bash
chisel server --port 8443 --reverse &
```

### 4. Настройка сервиса туннеля

Сервис `marzban-tunnel.service` предназначен для автоматического запуска и поддержания клиента `chisel` на машине, где работает ваш кластер Kubernetes (или на машине, имеющей доступ к кластеру).

Отредактируйте файл `scripts/marzban-tunnel.service`, если необходимо, указав правильный адрес вашего сервера с `chisel`.

Затем скопируйте этот файл в `/etc/systemd/system/`, включите и запустите сервис:

```bash
sudo cp scripts/marzban-tunnel.service /etc/systemd/system/
sudo systemctl enable marzban-tunnel.service
sudo systemctl start marzban-tunnel.service
```

### 5. Проверка развертывания

Убедитесь, что все поды в пространстве имен `marzban` запущены и работают:

```bash
kubectl get pods -n marzban
```

## Использование

После успешного развертывания и запуска туннеля, панель управления Marzban будет доступна по адресу:

`http://<ваш-домен>:8443`

## Скрипты

*   `scripts/update_xray_proxies.py`: Скрипт для обновления прокси в Xray.
*   `scripts/marzban-tunnel.service`: Файл сервиса systemd для автоматического запуска туннеля `chisel`.
