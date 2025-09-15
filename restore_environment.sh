#!/bin/bash
#
# Скрипт для автоматического восстановления и настройки среды Cloud Shell.
#

# Выход при любой ошибке
set -e

# --- 1. Установка системных пакетов ---
echo "Updating package lists and installing essential tools..."
sudo apt-get update
sudo apt-get install -y \
    jq \
    htop \
    mc \
    openssl
    # Добавьте сюда любые другие нужные вам пакеты

echo "System packages installed."

# --- 2. Настройка SSH ---
echo "Setting up SSH configuration and keys..."

# Создание директории .ssh, если ее нет
mkdir -p ~/\.ssh

# Создание символической ссылки на конфиг SSH
# -s: symbolic link, -f: force (перезаписать, если уже существует)
# Проверяем, существует ли исходный файл в репозитории
if [ -f "$(pwd)/.ssh/config" ]; then
    ln -sf "$(pwd)/.ssh/config" ~/\.ssh/config
    echo "SSH config linked."
else
    echo "WARNING: .ssh/config not found in repository. Skipping."
fi


# Расшифровка приватного ключа для VDS
if [ -f "id_rsa_vds1.enc" ]; then
    echo "Decrypting VDS private key..."
    # Запрос пароля и расшифровка
    openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in id_rsa_vds1.enc -out ~/\.ssh/id_rsa_vds1
    # Установка правильных прав на ключ
    chmod 600 ~/\.ssh/id_rsa_vds1
    echo "Key id_rsa_vds1 decrypted to ~/.ssh/id_rsa_vds1"
else
    echo "WARNING: Encrypted key id_rsa_vds1.enc not found. Skipping decryption."
fi

# --- 3. Настройка других конфигурационных файлов (Dotfiles) ---
echo "Linking dotfiles..."
if [ -f "$(pwd)/.gitconfig" ]; then
    ln -sf "$(pwd)/.gitconfig" ~/\.gitconfig
    echo "Gitconfig linked."
else
    echo "WARNING: .gitconfig not found in repository. Skipping."
fi
# ln -sf "$(pwd)/.bashrc_custom" ~/.bashrc_custom # Пример для кастомного .bashrc
# echo "source ~/.bashrc_custom" >> ~/.bashrc # Добавление в основной .bashrc
echo "Dotfiles linking process complete."


# --- 4. Завершение ---
echo ""
echo "✅ Environment restoration complete!"
echo "Please run 'source ~/.bashrc' or restart the shell to apply all changes."

# --- 5. Verify x-ui Panel Access ---
echo ""
echo "--- Verifying x-ui panel access via VDS tunnel ---"
echo "This step assumes the chisel tunnel is active and the panel is running."
echo "Attempting to log in with default credentials (admin/admin)..."

# It might take a moment for the service to be ready after a fresh restore
sleep 15

# Execute curl via SSH on the VDS
CURL_RESPONSE=$(ssh -i ~/.ssh/id_rsa_vds1 -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@vds1.iri1968.dpdns.org 'curl -s -X POST -d "username=admin&password=admin" http://localhost:8449/login')

# Check if the response contains the success message
if echo "$CURL_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Verification SUCCESS: Successfully logged into x-ui panel."
    echo "The environment appears to be fully functional."
else
    echo "❌ Verification FAILED: Could not log into x-ui panel."
    echo "Response from server: $CURL_RESPONSE"
    echo "Please check the x-ui pod logs and the chisel tunnel status."
    # Exit with an error code if verification fails
    exit 1
fi