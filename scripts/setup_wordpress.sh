#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo"
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo -e "${RED}Error occurred in script at line ${line_number}${NC}"
    case $exit_code in
        1) echo -e "${RED}General error${NC}" ;;
        2) echo -e "${RED}Misuse of shell builtins${NC}" ;;
        126) echo -e "${RED}Command invoked cannot execute${NC}" ;;
        127) echo -e "${RED}Command not found${NC}" ;;
        *)  echo -e "${RED}Unknown error occurred${NC}" ;;
    esac
    exit $exit_code
}

# Trap errors
trap 'handle_error ${LINENO}' ERR

# Function to check command success
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 completed successfully${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Function to generate secure password
generate_secure_password() {
    local length=$1
    local password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c $length)
    echo $password
}

# Get the actual user (not root)
ACTUAL_USER=$(logname || echo $SUDO_USER)

# Main installation script
echo -e "${GREEN}Starting WordPress Installation...${NC}"

# Update system first
echo -e "${YELLOW}🔄 Updating system...${NC}"
apt update && apt upgrade -y
check_command "System update"

# Install required packages
echo -e "${YELLOW}📦 Installing LEMP stack...${NC}"
PACKAGES="nginx mysql-server php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-intl php8.1-mbstring php8.1-xml php8.1-zip php8.1-memcached"
for package in $PACKAGES; do
    apt install -y $package
done
check_command "Package installation"

# Now setup MySQL root access
echo -e "${YELLOW}🔐 Setting up MySQL root access...${NC}"
mysql_setup() {
    ROOT_PASSWORD=$(openssl rand -base64 24)
    mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    
    # Create MySQL config file for root access
    cat > /root/.my.cnf << EOF
[client]
user=root
password=$ROOT_PASSWORD
EOF
    chmod 600 /root/.my.cnf
}

# Run MySQL setup
mysql_setup
check_command "MySQL root setup"

# Directory permissions setup
echo -e "${YELLOW}📂 Setting up directory permissions...${NC}"
setup_permissions() {
    # Web root
    mkdir -p /var/www
    chmod 755 /var/www
    chown $ACTUAL_USER:www-data /var/www

    # Nginx
    mkdir -p /var/log/nginx
    chown -R www-data:www-data /var/log/nginx
    chmod -R 755 /var/log/nginx

    # PHP
    mkdir -p /var/log/php
    mkdir -p /var/lib/php/sessions
    mkdir -p /run/php
    chown -R www-data:www-data /var/log/php /var/lib/php/sessions /run/php
    chmod -R 755 /var/log/php /var/lib/php/sessions /run/php

    # Add user to www-data group
    usermod -a -G www-data $ACTUAL_USER
}

# Run permissions setup
setup_permissions
check_command "Directory permissions setup"

# Clean up any existing WordPress installation
echo -e "${YELLOW}🧹 Cleaning up existing installation...${NC}"
sudo rm -rf /var/www/wordpress
sudo mysql -e "DROP DATABASE IF EXISTS wordpress;"
sudo mysql -e "DROP USER IF EXISTS 'wordpressuser'@'localhost';"
check_command "Cleanup"

# Configure MySQL password policy
echo -e "${YELLOW}📊 Configuring MySQL password policy...${NC}"

# Try to install validate_password plugin
mysql -e "INSTALL PLUGIN validate_password SONAME 'validate_password.so';" 2>/dev/null || true

# Set password policy (will work if plugin is installed, fail silently if not)
mysql -e "SET GLOBAL validate_password_policy=LOW;" 2>/dev/null || true
mysql -e "SET GLOBAL validate_password_length=8;" 2>/dev/null || true

# Create WordPress database and user
echo -e "${YELLOW}🗄️ Setting up database...${NC}"
DB_PASSWORD=$(openssl rand -base64 24)

# Create database and user with more permissive password requirements
mysql << EOF
CREATE DATABASE IF NOT EXISTS wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER IF NOT EXISTS 'wordpressuser'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Save credentials
echo "WordPress Database Password: $DB_PASSWORD" > /home/$ACTUAL_USER/wordpress_credentials.txt
chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/wordpress_credentials.txt
chmod 600 /home/$ACTUAL_USER/wordpress_credentials.txt

# Get current user
CURRENT_USER=$(whoami)

# Download and configure WordPress with error handling
echo -e "${YELLOW}📥 Downloading WordPress...${NC}"

# Set up proper permissions for web directories
echo -e "${YELLOW}🔐 Setting up directory permissions...${NC}"
sudo mkdir -p /var/www
sudo chown -R $CURRENT_USER:$CURRENT_USER /var/www
sudo chmod -R 755 /var/www

# Ensure Nginx directories are properly set
sudo mkdir -p /var/log/nginx
sudo chown -R www-data:www-data /var/log/nginx
sudo chmod -R 755 /var/log/nginx

# Download WordPress
cd /var/www || exit 1
wget https://wordpress.org/latest.tar.gz -O wordpress.tar.gz || exit 1
tar -xzf wordpress.tar.gz || exit 1
rm wordpress.tar.gz
check_command "WordPress download and extraction"

# Set WordPress permissions
echo -e "${YELLOW}👮 Setting WordPress permissions...${NC}"
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress/ -type d -exec chmod 775 {} \;
sudo find /var/www/wordpress/ -type f -exec chmod 664 {} \;

# Add current user to www-data group
sudo usermod -a -G www-data $CURRENT_USER

# Set proper permissions for wp-content directory
sudo chmod -R 775 /var/www/wordpress/wp-content
sudo chown -R www-data:www-data /var/www/wordpress/wp-content

# Ensure PHP-FPM has proper permissions
sudo mkdir -p /var/lib/php/sessions
sudo chown -R www-data:www-data /var/lib/php/sessions
sudo chmod -R 755 /var/lib/php/sessions

check_command "Permission setup"

# Configure wp-config.php with error handling
echo -e "${YELLOW}⚙️ Configuring WordPress...${NC}"
if [ ! -f /var/www/wordpress/wp-config.php ]; then
    sudo cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
    
    # Escape special characters in DB_PASSWORD
    ESCAPED_PASSWORD=$(echo "$DB_PASSWORD" | sed 's/[\/&]/\\&/g')
    
    # Update database settings
    sudo sed -i "s/database_name_here/wordpress/" /var/www/wordpress/wp-config.php
    sudo sed -i "s/username_here/wordpressuser/" /var/www/wordpress/wp-config.php
    sudo sed -i "s/password_here/${ESCAPED_PASSWORD}/" /var/www/wordpress/wp-config.php
    
    # Add security configurations
    sudo tee -a /var/www/wordpress/wp-config.php << 'EOF'

/* Additional security settings */
define('WP_DEBUG', false);
define('DISALLOW_FILE_EDIT', true);
define('WP_AUTO_UPDATE_CORE', true);
EOF
fi
check_command "WordPress configuration"

# Ensure proper file ownership
sudo chown www-data:www-data /var/www/wordpress/wp-config.php
sudo chmod 640 /var/www/wordpress/wp-config.php

# Configure NGINX with error handling
echo -e "${YELLOW}🔧 Configuring NGINX...${NC}"
NGINX_CONF="/etc/nginx/sites-available/wordpress"
NGINX_ENABLED="/etc/nginx/sites-enabled/wordpress"

# Remove existing configurations if they exist
if [ -f "$NGINX_CONF" ]; then
    echo -e "${YELLOW}Removing existing NGINX configuration...${NC}"
    sudo rm -f "$NGINX_CONF"
fi

if [ -f "$NGINX_ENABLED" ] || [ -L "$NGINX_ENABLED" ]; then
    echo -e "${YELLOW}Removing existing symbolic link...${NC}"
    sudo rm -f "$NGINX_ENABLED"
fi

# Create NGINX configuration
sudo tee $NGINX_CONF << 'EOF'
# FastCGI cache settings
fastcgi_cache_path /tmp/nginx-cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
fastcgi_cache_valid 200 60m;

# FastCGI buffer settings
fastcgi_buffers 16 16k;
fastcgi_buffer_size 32k;
fastcgi_connect_timeout 300;
fastcgi_send_timeout 300;
fastcgi_read_timeout 300;

server {
    listen 80;
    root /var/www/wordpress;
    index index.php index.html index.htm;
    server_name _;  # Catch all domains

    # Enable GZIP compression
    gzip on;
    gzip_comp_level 6;
    gzip_min_length 1100;
    gzip_buffers 16 8k;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/js
        text/xml
        text/javascript
        application/javascript
        application/json
        application/xml
        application/rss+xml
        image/svg+xml;

    # Cache settings for static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2|svg)$ {
        expires 365d;
        add_header Cache-Control "public, no-transform";
        access_log off;
        log_not_found off;
    }

    # WordPress permalinks
    location / {
        try_files $uri $uri/ /index.php?$args;

        # Skip cache for logged-in users and important pages
        set $skip_cache 0;
        if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in") {
            set $skip_cache 1;
        }
        if ($request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
            set $skip_cache 1;
        }
    }

    # PHP handling with FastCGI cache
    location ~ \.php$ {
        try_files $uri =404;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        
        # FastCGI cache settings
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        add_header X-FastCGI-Cache $upstream_cache_status;
        
        # Buffer size settings
        fastcgi_buffer_size 32k;
        fastcgi_buffers 16 16k;
    }

    # Security settings
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* ^/wp-content/uploads/.*\.(php|pl|py|jsp|asp|htm|shtml|sh|cgi)$ {
        deny all;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Enable the site and remove default
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s "$NGINX_CONF" "$NGINX_ENABLED"
check_command "NGINX configuration"

# Test and restart services
echo -e "${YELLOW}🔍 Testing configurations...${NC}"
sudo nginx -t
check_command "NGINX configuration test"

echo -e "${YELLOW}🚀 Restarting services...${NC}"
for service in nginx php8.1-fpm mysql; do
    sudo systemctl restart $service
    sudo systemctl enable $service
    check_command "$service restart"
done

# Final checks and output
echo -e "${GREEN}✅ WordPress installation complete!${NC}"

# Handle credentials file
CREDS_FILE="/home/$ACTUAL_USER/wordpress_credentials.txt"
BACKUP_FILE="/home/$ACTUAL_USER/wordpress_credentials.txt.backup"

# Create backup of credentials
if [ -f "$CREDS_FILE" ]; then
    cp "$CREDS_FILE" "$BACKUP_FILE"
    chown $ACTUAL_USER:$ACTUAL_USER "$BACKUP_FILE"
    chmod 600 "$BACKUP_FILE"
    echo -e "${GREEN}📑 Backup of credentials created at $BACKUP_FILE${NC}"
fi

echo -e "${GREEN}📝 Database credentials are saved in $CREDS_FILE${NC}"
IP_ADDRESS=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip)
echo -e "${GREEN}🌐 You can access your WordPress site at: http://$IP_ADDRESS${NC}"
echo -e "${YELLOW}⚠️ Please complete the WordPress installation by visiting the above URL${NC}" 