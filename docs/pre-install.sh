#!/bin/bash

# Update and Install Essential Packages
apt update && apt upgrade -y
apt install -y curl software-properties-common ufw
add-apt-repository ppa:ondrej/php
apt install -y debian-keyring debian-archive-keyring apt-transport-https
apt update
apt install -y bzip2 composer gettext git gnupg2 net-tools php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-ds php8.2-fpm php8.2-gd php8.2-gmp php8.2-gnupg php8.2-igbinary php8.2-imap php8.2-intl php8.2-mbstring php8.2-opcache php8.2-readline php8.2-redis php8.2-soap php8.2-swoole php8.2-uuid php8.2-xml pv redis unzip wget whois

# Install Apache2 web server
add-apt-repository ppa:ondrej/apache2
apt update
apt install -y apache2 python3-certbot-apache

# Configure Timezone to UTC
timedatectl set-timezone UTC

# PHP Configuration
echo "opcache.enable=1" >> /etc/php/8.2/cli/php.ini
echo "opcache.enable_cli=1" >> /etc/php/8.2/cli/php.ini
echo "opcache.jit_buffer_size=100M" >> /etc/php/8.2/cli/php.ini
echo "opcache.jit=1255" >> /etc/php/8.2/cli/php.ini
echo "session.cookie_secure = 1" >> /etc/php/8.2/cli/php.ini
echo "session.cookie_httponly = 1" >> /etc/php/8.2/cli/php.ini
echo "session.cookie_samesite = \"Strict\"" >> /etc/php/8.2/cli/php.ini
echo "session.cookie_domain = example.com" >> /etc/php/8.2/cli/php.ini
echo "memory_limit = 512M" >> /etc/php/8.2/fpm/php.ini
echo "opcache.jit=1255" >> /etc/php/8.2/mods-available/opcache.ini
echo "opcache.jit_buffer_size=100M" >> /etc/php/8.2/mods-available/opcache.ini
systemctl restart php8.2-fpm

# Database installation (MariaDB)
curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
echo "# MariaDB 10.11 repository" > /etc/apt/sources.list.d/mariadb.sources
echo "URIs: https://mirrors.chroot.ro/mariadb/repo/10.11/ubuntu" >> /etc/apt/sources.list.d/mariadb.sources
echo "Suites: jammy" >> /etc/apt/sources.list.d/mariadb.sources
echo "Components: main main/debug" >> /etc/apt/sources.list.d/mariadb.sources
echo "Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp" >> /etc/apt/sources.list.d/mariadb.sources
apt update
apt install -y mariadb-client mariadb-server php8.2-mysql
mysql_secure_installation

# Generate random database credentials
DB_NAME="db_$(openssl rand -hex 4)"
DB_USER="user_$(openssl rand -hex 4)"
DB_PASS="$(openssl rand -base64 12)"

# Create database and user
mysql -uroot -e "CREATE DATABASE $DB_NAME;"
mysql -uroot -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"

# Print database credentials
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASS"

# Install Adminer
mkdir /usr/share/adminer
wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php

# Download and Set Up Namingo
mkdir -p /opt/registry
git clone https://github.com/theamankr/iWebRegistry /opt/registry

# Create directory for Namingo logs
mkdir -p /var/log/namingo
chown -R www-data:www-data /var/log/namingo

# Configure UFW Firewall
ufw allow 80/tcp
ufw allow 80/udp
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 700/tcp
ufw allow 700/udp
ufw allow 43/tcp
ufw allow 43/udp
ufw allow 53/tcp
ufw allow 53/udp

# Enable UFW
ufw enable

# Reboot the server
reboot
