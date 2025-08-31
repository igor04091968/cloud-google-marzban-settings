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

### 2. Создание пространства имен

Все ресурсы Marzban будут находиться в изолированном пространстве имен `marzban`. Создайте его:

```bash
kubectl create namespace marzban
```

### 3. Создание секрета для Marzban Node

Для безопасного взаимодействия между компонентами `marzban-node` требует SSL-сертификат, который должен храниться в секрете Kubernetes.

**1. Сгенерируйте самоподписанный сертификат и ключ:**
```bash
openssl req -x509 -newkey rsa:2048 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=marzban-node"
```

**2. Создайте из них секрет в Kubernetes:**
```bash
kubectl create secret tls marzban-node-certs --cert=tls.crt --key=tls.key -n marzban
```

**3. Удалите временные файлы:**
```bash
rm tls.key tls.crt
```

### 4. Применение конфигураций Kubernetes

Теперь примените все манифесты Kubernetes из директории `kubernetes`. Эти команды создадут все необходимые ресурсы: deployments, services, configmaps, и persistent volume claims.

```bash
kubectl apply -f kubernetes/
```

### 5. Настройка реверс-туннеля

Для доступа к панели Marzban извне кластера используется реверс-туннель, созданный с помощью `chisel`.

На вашем внешнем сервере (например, VDS), куда указывает ваше доменное имя, запустите сервер `chisel`:

```bash
chisel server --port 8443 --reverse &
```

### 6. Настройка сервиса туннеля

Сервис `scripts/marzban-tunnel.service` предназначен для автоматического запуска и поддержания клиента `chisel` на машине, где работает ваш кластер Kubernetes (или на машине, имеющей доступ к кластеру).

Отредактируйте файл, если необходимо, указав правильный адрес вашего сервера с `chisel`.

Затем скопируйте этот файл в `/etc/systemd/system/`, включите и запустите сервис:

```bash
sudo cp scripts/marzban-tunnel.service /etc/systemd/system/
sudo systemctl enable marzban-tunnel.service
sudo systemctl start marzban-tunnel.service
```

### 7. Проверка развертывания

Убедитесь, что все поды в пространстве имен `marzban` запущены и работают. Статус `Running` означает, что все в порядке.

```bash
kubectl get pods -n marzban
```
*Если какой-то из подов застрял в состоянии `ContainerCreating` или `Error`, проверьте его события с помощью команды `kubectl describe pod <имя-пода> -n marzban`.*

## Использование

После успешного развертывания и запуска туннеля, панель управления Marzban будет доступна по адресу:

`https://vds1.DOMAIN.org`

## Создание первого администратора

После первого развертывания в системе нет ни одного администратора. Его нужно создать вручную через командную строку.

1.  **Найдите имя пода `marzban-controller`:**

    ```bash
    kubectl get pods -n marzban -l app=marzban-controller
    ```
    Скопируйте имя пода, оно будет выглядеть примерно так: `marzban-controller-xxxxxxxxxx-xxxxx`.

2.  **Создайте нового администратора:**

    Выполните следующую команду, подставив имя вашего пода, а также желаемые `ВАШ_ЛОГИН` и `ВАШ_ПАРОЛЬ`. Флаг `--sudo` делает пользователя суперадминистратором.

    ```bash
    echo -e '\n' | kubectl exec -i <ИМЯ_ПОДА> -n marzban -- \
    env MARZBAN_ADMIN_PASSWORD='ВАШ_ПАРОЛЬ' \
    marzban-cli admin create --username 'ВАШ_ЛОГИН' --sudo
    ```

После выполнения этой команды вы сможете войти в панель управления с указанными учетными данными.

## Сетевая схема взаимодействия

```mermaid
graph TD
    subgraph "Интернет"
        A[Администратор]
        U[Пользователь Marzban]
    end

    subgraph "VDS-сервер (vds1.DOMAIN.org)"
        Nginx[Nginx:443]
        ChiselServer[Chisel Server:8443]
    end

    subgraph "Среда Google Cloud Shell"
        ChiselClient[Chisel Client]
        Kubectl[kubectl]
    end

    subgraph "Kubernetes Кластер (Minikube)"
        Service[Service marzban-controller]
        Pod[Pod marzban-controller]
        Container1[Container marzban]
        Container2[Container socat]
    end

    A -- SSH --> VDS-сервер
    A -- kubectl --> Kubectl
    U -- HTTPS --> Nginx
    Nginx -- HTTP --> ChiselServer
    ChiselServer <--> ChiselClient
    ChiselClient -- Переброс порта --> Service
    Kubectl -- Управление --> Kubernetes
    Service -- > Pod
    Pod -- > Container2
    Container2 -- > Container1
```

## Основные команды управления

### Kubernetes (`kubectl`)

*   Посмотреть все поды в пространстве `marzban`:
    ```bash
    kubectl get pods -n marzban
    ```
*   Посмотреть логи контроллера Marzban:
    ```bash
    kubectl logs -n marzban -l app=marzban-controller --tail=100
    ```
*   Применить изменения из файла конфигурации:
    ```bash
    kubectl apply -f kubernetes/marzban-configmap.yaml
    ```
*   Перезапустить сервис Marzban для применения конфигурации:
    ```bash
    kubectl rollout restart deployment marzban-controller -n marzban
    ```
*   Выполнить команду внутри пода:
    ```bash
    kubectl exec -it <ИМЯ_ПОДА> -n marzban -- <КОМАНДА>
    ```

### Marzban CLI (`marzban-cli`)

*   Создать нового администратора:
    ```bash
    echo -e '\n' | kubectl exec -i <ИМЯ_ПОДА> -n marzban -- \
    env MARZBAN_ADMIN_PASSWORD='ВАШ_ПАРОЛЬ' \
    marzban-cli admin create --username 'ВАШ_ЛОГИН' --sudo
    ```
*   Посмотреть список администраторов:
    ```bash
    kubectl exec <ИМЯ_ПОДА> -n marzban -- marzban-cli admin list
    ```
*   Удалить администратора:
    ```bash
    echo "y" | kubectl exec -i <ИМЯ_ПОДА> -n marzban -- marzban-cli admin delete --username <ЛОГИН>
    ```

### VDS Сервер

*   Перезагрузить конфигурацию Nginx:
    ```bash
    ssh root@vds1.DOMAIN.org "systemctl reload nginx"
    ```
*   Проверить статус сервиса туннеля:
    ```bash
    ssh root@vds1.DOMAIN.org "systemctl status marzban-tunnel.service"
    ```

## Скрипты

*   `scripts/update_xray_proxies.py`: Скрипт для обновления прокси в Xray.
*   `scripts/marzban-tunnel.service`: Файл сервиса systemd для автоматического запуска туннеля `chisel`.

## Быстрый старт на новом сервере

В репозитории есть универсальный скрипт `scripts/setup_app.sh`, который позволяет развернуть простое веб-приложение в Docker-контейнере на любом "чистом" сервере с ОС Debian или Ubuntu. Скрипт автоматически устанавливает все зависимости (Docker, Python) и запускает приложение.

### Использование

1.  **Подключитесь к вашему новому серверу по SSH.**

2.  **Скачайте скрипт из репозитория:**
    ```bash
    curl -o setup_app.sh https://raw.githubusercontent.com/igor04091968/cloud-google-marzban-settings/master/scripts/setup_app.sh
    ```

3.  **Сделайте скрипт исполняемым:**
    ```bash
    chmod +x setup_app.sh
    ```

4.  **Запустите скрипт с правами суперпользователя:**
    ```bash
    sudo ./setup_app.sh
    ```

После выполнения скрипта ваше приложение будет запущено и доступно на порту `8080` вашего сервера.
