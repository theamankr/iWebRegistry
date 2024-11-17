#!/bin/bash

# Function to print messages in blue
print_blue() {
  echo -e "\e[34m$1\e[0m"
}

# Function to display a progress bar
progress_bar() {
  local progress=$1
  local width=50
  local completed=$((progress * width / 100))
  local remaining=$((width - completed))
  printf "\r["
  printf "%0.s#" $(seq 1 $completed)
  printf "%0.s-" $(seq 1 $remaining)
  printf "] %d%%" "$progress"
}

# Update and Install Essential Packages
print_blue "Updating and installing essential packages..."
progress_bar 5
apt update && apt upgrade -y
progress_bar 15
apt install -y curl software-properties-common ufw
progress_bar 25
add-apt-repository ppa:ondrej/php
apt install -y debian-keyring debian-archive-keyring apt-transport-https
progress_bar 35
apt update
apt install -y bzip2 composer gettext git gnupg2 net-tools php8.2 php8.2-cli php8.2-common php8.2-curl php8.2-ds php8.2-fpm php8.2-gd php8.2-gmp php8.2-gnupg php8.2-igbinary php8.2-imap php8.2-intl php8.2-mbstring php8.2-opcache php8.2-readline php8.2-redis php8.2-soap php8.2-swoole php8.2-uuid php8.2-xml pv redis unzip wget whois
progress_bar 50

# Install Apache2 web server
print_blue "Installing Apache2 web server..."
add-apt-repository ppa:ondrej/apache2
apt update
apt install -y apache2 python3-certbot-apache
progress_bar 60

# Configure Timezone to UTC
print_blue "Configuring timezone to UTC..."
timedatectl set-timezone UTC
progress_bar 65

# PHP Configuration
print_blue "Configuring PHP..."
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
progress_bar 70

# Database installation (MariaDB)
print_blue "Installing and configuring MariaDB..."
curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
echo "# MariaDB 10.11 repository" > /etc/apt/sources.list.d/mariadb.sources
echo "URIs: https://mirrors.chroot.ro/mariadb/repo/10.11/ubuntu" >> /etc/apt/sources.list.d/mariadb.sources
echo "Suites: jammy" >> /etc/apt/sources.list.d/mariadb.sources
echo "Components: main main/debug" >> /etc/apt/sources.list.d/mariadb.sources
echo "Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp" >> /etc/apt/sources.list.d/mariadb.sources
apt update
apt install -y mariadb-client mariadb-server php8.2-mysql
mysql_secure_installation
progress_bar 80

# Generate random database credentials
DB_NAME="db_$(openssl rand -hex 4)"
DB_USER="user_$(openssl rand -hex 4)"
DB_PASS="$(openssl rand -base64 12)"

# Create database and user
print_blue "Creating database and user..."
mysql -uroot -e "CREATE DATABASE $DB_NAME;"
mysql -uroot -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"
progress_bar 85

# Display database credentials and prompt user to copy them
print_blue "=========================================="
print_blue "IMPORTANT: Save the database credentials"
print_blue "Database Name: $DB_NAME"
print_blue "Database User: $DB_USER"
print_blue "Database Password: $DB_PASS"
print_blue "=========================================="
read -p "Press Enter after copying the credentials to continue..."
progress_bar 90

# Install Adminer
print_blue "Installing Adminer..."
mkdir /usr/share/adminer
wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
progress_bar 95

# Ask for confirmation to reboot the server
read -p "$(print_blue 'Do you want to reboot the server now? (yes/no): ')" confirm
if [[ $confirm == "yes" ]]; then
  print_blue "Rebooting the server..."
  reboot
else
  print_blue "Reboot canceled. You may need to reboot manually."
fi
progress_bar 100
echo
