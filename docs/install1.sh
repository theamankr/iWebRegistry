#!/bin/bash

set -e  # Exit on any error

echo "Starting automated Namingo installation..."

# Update and install required packages
echo "Installing required packages..."
apt update && apt install -y curl software-properties-common ufw debian-keyring debian-archive-keyring apt-transport-https bzip2 composer gettext git gnupg2 net-tools php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-ds php8.2-fpm php8.2-gd php8.2-gmp php8.2-gnupg php8.2-igbinary php8.2-imap php8.2-intl php8.2-mbstring php8.2-opcache php8.2-readline php8.2-redis php8.2-soap php8.2-swoole php8.2-uuid php8.2-xml pv redis unzip wget whois

# Install web server (Caddy as default)
echo "Installing Caddy webserver..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' -o caddy-stable.gpg.key
gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg caddy-stable.gpg.key
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy

# Configure timezone
echo "Configuring timezone to UTC..."
timedatectl set-timezone UTC

# Configure PHP
echo "Configuring PHP settings..."
PHP_INI_CLI="/etc/php/8.2/cli/php.ini"
PHP_INI_FPM="/etc/php/8.2/fpm/php.ini"
OPCACHE_INI="/etc/php/8.2/mods-available/opcache.ini"

sed -i "s/^;opcache.enable=.*/opcache.enable=1/" $PHP_INI_CLI $PHP_INI_FPM
sed -i "s/^;opcache.enable_cli=.*/opcache.enable_cli=1/" $PHP_INI_CLI
sed -i "s/^;opcache.jit_buffer_size=.*/opcache.jit_buffer_size=100M/" $PHP_INI_CLI $PHP_INI_FPM
sed -i "s/^;opcache.jit=.*/opcache.jit=1255/" $OPCACHE_INI

echo "session.cookie_secure = 1" >> $PHP_INI_FPM
echo "session.cookie_httponly = 1" >> $PHP_INI_FPM
echo "session.cookie_samesite = \"Strict\"" >> $PHP_INI_FPM
echo "session.cookie_domain = example.com" >> $PHP_INI_FPM

echo "memory_limit = -1" >> $PHP_INI_FPM  # Adjust for large domain installations
systemctl restart php8.2-fpm

# Install and configure MariaDB
echo "Installing and configuring MariaDB..."
curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
cat <<EOF > /etc/apt/sources.list.d/mariadb.sources
# MariaDB 10.11 repository list
Types: deb
URIs: https://mirrors.chroot.ro/mariadb/repo/10.11/ubuntu
Suites: jammy
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
EOF

apt update && apt install -y mariadb-client mariadb-server php8.2-mysql
mysql_secure_installation

# Create necessary databases
echo "Creating databases..."
mysql -u root -p <<EOF
CREATE DATABASE registry;
CREATE DATABASE registryTransaction;
CREATE DATABASE registryAudit;
EOF

# Install Adminer
echo "Installing Adminer..."
mkdir -p /usr/share/adminer
wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php

# Download and setup Namingo
echo "Downloading and setting up Namingo..."
git clone https://github.com/getnamingo/registry /opt/registry
mkdir -p /var/log/namingo
chown -R www-data:www-data /var/log/namingo

# Configure UFW Firewall
echo "Configuring UFW firewall..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 700/tcp
ufw allow 43/tcp
ufw allow 53/tcp
ufw enable

# Configure Caddy
echo "Configuring Caddy..."
cat <<EOF > /etc/caddy/Caddyfile
rdap.example.com {
    reverse_proxy localhost:7500
    tls your-email@example.com
}
EOF
systemctl reload caddy

echo "Installation complete! Please configure Namingo as per your requirements."
