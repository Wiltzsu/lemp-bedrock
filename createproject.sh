#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run it with sudo."
    exit 1
fi

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Check if Composer is installed
if ! command -v composer &> /dev/null; then
    echo "Composer is not installed. Please install Composer first."
    exit 1
fi

if ! command -v php &> /dev/null; then
    echo "PHP is not installed. Please install PHP first."
    exit 1
fi

if ! command -v mysql &> /dev/null; then
    echo "MySQL is not installed. Please install MySQL first."
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Please install Nginx first."
    exit 1
fi

# Ask user for project name
read -p "Enter the project name: " PROJECT_NAME

# Check if input is not empty and doesn't contain spaces
if [[ -z "$PROJECT_NAME" || "$PROJECT_NAME" =~ [[:space:]] ]]; then
    echo -e "${YELLOW}Project name cannot be empty or contain spaces.${RESET}"
    exit 1
fi

# Define variables
PROJECT_DIR="/var/www/$PROJECT_NAME"
DB_NAME="$PROJECT_NAME"
DB_USER="root"
DB_HOST="localhost"
WP_HOME="http://$PROJECT_NAME.local"
WP_SITEURL="http://$PROJECT_NAME.local/wp"
NGINX_CONF="/etc/nginx/sites-available/$PROJECT_NAME.conf"
ETC_HOSTS="/etc/hosts"

# Prompt for MySQL root password
read -s -p "Enter the MySQL root password for your server: " MYSQL_PWD
echo ""

# Test the password
mysql -u root -p"$MYSQL_PWD" -e "SELECT 1;" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Incorrect MySQL root password. Exiting."
  exit 1
fi

# Check if the project directory already exists
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}$PROJECT_NAME already exists. Please choose another name.${RESET}"
    exit 1
fi

# Create project directory and set ownership
sudo mkdir -p "$PROJECT_DIR"
sudo chown $USER:$USER "$PROJECT_DIR"

# Create the project using Bedrock (without sudo)
composer create-project roots/bedrock "$PROJECT_DIR" || {
    echo -e "${RED}Failed to create Bedrock project. Please check your Composer installation.${RESET}"
    exit 1
}

# After Composer is done, set proper permissions for web server
sudo chown -R $USER:www-data "$PROJECT_DIR"
sudo find "$PROJECT_DIR" -type d -exec chmod 755 {} \;
sudo find "$PROJECT_DIR" -type f -exec chmod 644 {} \;

# Create the database
echo "Creating database $DB_NAME..."
mysql -u $DB_USER -p"$MYSQL_PWD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" || {
    echo -e "${RED}Failed to create database. Please check your MySQL installation and permissions.${RESET}"
    exit 1
}

# Create the Nginx configuration
echo "Creating Nginx configuration for $PROJECT_NAME..."
NGINX_CONFIG="server {
    listen 80;
    server_name ${PROJECT_NAME}.local;
    root ${PROJECT_DIR}/web;
    
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP handling (via PHP-FPM)
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # Logging
    access_log /var/log/nginx/${PROJECT_NAME}-access.log;
    error_log /var/log/nginx/${PROJECT_NAME}-error.log;
}"

echo "$NGINX_CONFIG" | sudo tee "$NGINX_CONF" > /dev/null

# Check if symlink already exists and remove it if necessary
if [ -L "/etc/nginx/sites-enabled/$PROJECT_NAME.conf" ]; then
    echo "Symlink already exists, removing old one..."
    sudo rm "/etc/nginx/sites-enabled/$PROJECT_NAME.conf"
fi

# Create the symbolic link with the correct name
echo "Creating symbolic link for Nginx..."
sudo ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/

# Add the project to /etc/hosts if it doesn't exist
echo "Adding $PROJECT_NAME.local to /etc/hosts..."
if ! grep -q "$PROJECT_NAME.local" /etc/hosts; then
    sudo bash -c "echo '127.0.0.1 $PROJECT_NAME.local' >> /etc/hosts"
fi

# Test the Nginx configuration with sudo
echo "Testing Nginx configuration..."
sudo nginx -t || {
    echo -e "${RED}Nginx configuration test failed.${RESET}"
    exit 1
}

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl restart nginx || {
    echo -e "${RED}Failed to restart Nginx.${RESET}"
    exit 1
}

echo -e "${GREEN}$PROJECT_NAME setup completed! You can access it at http://$PROJECT_NAME.local${RESET}"
