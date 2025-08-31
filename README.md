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

### 5. Настройка внешнего доступа (VDS и Туннель)

Доступ к панели Marzban, работающей внутри Kubernetes, организован через сложную цепочку проксирования, которая выводит сервис на ваш VDS.

**Компоненты на VDS:**

1.  **Nginx:** Принимает HTTPS трафик на порт **443**. Отвечает за SSL/TLS шифрование.
2.  **Python-скрипт:** Локальный скрипт, который слушает порт **8000** и преобразует входящие HTTP запросы в SOCKS5.
3.  **Chisel Server:** Основной сервер туннеля. Он запущен с параметром `--socks5` и слушает порт **993** для подключения клиентов.

**Схема работы на VDS:**
`Nginx (443) -> Python-скрипт (8000) -> Chisel SOCKS5 (993)`

**Команда для запуска Chisel Server на VDS:**
```bash
# Убедитесь, что chisel находится в /usr/local/bin/chisel
nohup /usr/local/bin/chisel server --port 993 --reverse --socks5 --auth cloud:2025 > /dev/null 2>&1 &
```

**Клиент Туннеля в Kubernetes:**

Клиент `chisel` запускается как под в Kubernetes (см. `kubernetes/chisel-client-deployment.yaml`). Он подключается к серверу Chisel на VDS и дает ему инструкцию `R:8000:marzban-controller.marzban.svc.cluster.local:8443`.

Эта инструкция в контексте SOCKS5-прокси означает, что трафик, пришедший через прокси, должен быть направлен на сервис `marzban-controller` в кластере. Python-скрипт на VDS как раз и является тем клиентом, который отправляет трафик в SOCKS5-прокси.

### 6. Проверка развертывания

Убедитесь, что все поды в пространстве имен `marzban` запущены и работают. Статус `Running` означает, что все в порядке.

```bash
kubectl get pods -n marzban
```
*Если какой-то из подов застрял в состоянии `ContainerCreating` или `Error`, проверьте его события с помощью команды `kubectl describe pod <имя-пода> -n marzban`.*

## Использование

После успешного развертывания и запуска туннеля, панель управления Marzban будет доступна по адресу:

`https://vds1.iri1968.dpdns.org`

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
        env MARZBAN_ADMIN_PASSWORD=\'ВАШ_ПАРОЛЬ\' \
        marzban-cli admin create --username \'ВАШ_ЛОГИН\' --sudo
    ```

После выполнения этой команды вы сможете войти в панель управления с указанными учетными данными.

## Сетевая схема взаимодействия

```mermaid
graph TD
    subgraph "Интернет"
        A[Пользователь]
    end

    subgraph "VDS-сервер (vds1.iri1968.dpdns.org)"
        Nginx[Nginx:443]
        PythonProxy[Python Script:8000]
        ChiselServer[Chisel Server SOCKS5:993]
    end

    subgraph "Kubernetes Кластер (Minikube)"
        ChiselClient[Chisel Client]
        Service[Service marzban-controller]
        Pod[Pod marzban-controller:8443]
    end

    A -- HTTPS --> Nginx
    Nginx -- HTTP --> PythonProxy
    PythonProxy -- SOCKS5 --> ChiselServer
    ChiselServer <--> ChiselClient
    ChiselClient -- Переброс порта --> Service
    Service -- > Pod
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
    env MARZBAN_ADMIN_PASSWORD=\'ВАШ_ПАРОЛЬ\' \
    marzban-cli admin create --username \'ВАШ_ЛОГИН\' --sudo
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

## Автоматическое развертывание (Cloud Shell)

В качестве альтернативы пошаговому выполнению, в репозитории есть скрипт `scripts/setup_app.sh`, который полностью автоматизирует развертывание локальной части Marzban в Minikube (шаги 2-7 из основной инструкции).

**Что делает скрипт:**
*   Запускает Minikube.
*   Создает `namespace` и `secret` для сертификата.
*   Применяет все манифесты Kubernetes.
*   Ожидает, пока все компоненты будут запущены.
*   Создает суперадминистратора с учетными данными `admin` / `04091968`.

**Использование:**

1.  **Перейдите в директорию со скриптами:**
    ```bash
    cd scripts
    ```

2.  **Сделайте скрипт исполняемым:**
    ```bash
    chmod +x setup_app.sh
    ```

3.  **Запустите скрипт:**
    ```bash
    ./setup_app.sh
    ```

**ВНИМАНИЕ:** Скрипт не настраивает удаленный VDS-сервер. Шаги по настройке Nginx и запуску `chisel server` на VDS по-прежнему необходимо выполнять вручную.
