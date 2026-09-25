#!/bin/bash
# ======================================================
# Guardianship App — Production Server Setup Script
# Run this ONCE on the server as root: bash server-setup.sh
# Server: 109.199.99.156
# ======================================================
set -e

echo "=== [1/7] Updating system packages ==="
apt-get update -y && apt-get upgrade -y

echo "=== [2/7] Installing PHP 8.2 and required extensions ==="
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt-get update -y
apt-get install -y \
  php8.2 \
  php8.2-cli \
  php8.2-fpm \
  php8.2-mbstring \
  php8.2-pdo \
  php8.2-sqlite3 \
  php8.2-mysql \
  php8.2-bcmath \
  php8.2-json \
  php8.2-tokenizer \
  php8.2-xml \
  php8.2-ctype \
  php8.2-openssl \
  php8.2-curl \
  php8.2-zip \
  unzip curl git

echo "=== [3/7] Installing Composer ==="
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

echo "=== [4/7] Installing Nginx ==="
apt-get install -y nginx

echo "=== [5/7] Creating application directory ==="
mkdir -p /var/www/guardianship/backend
chown -R www-data:www-data /var/www/guardianship

echo "=== [6/7] Writing Nginx site config ==="
cat > /etc/nginx/sites-available/guardianship << 'NGINX'
server {
    listen 80;
    server_name 109.199.99.156;
    root /var/www/guardianship/backend/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/guardianship /etc/nginx/sites-enabled/guardianship
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "=== [7/7] Creating .env on server ==="
cat > /var/www/guardianship/backend/.env << 'ENVFILE'
APP_NAME="Guardianship App"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://109.199.99.156

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/guardianship/backend/database/database.sqlite

SESSION_DRIVER=file
SESSION_LIFETIME=120

QUEUE_CONNECTION=database
CACHE_STORE=file
BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local

MAIL_MAILER=log
ENVFILE

chmod 600 /var/www/guardianship/backend/.env
chown www-data:www-data /var/www/guardianship/backend/.env

echo ""
echo "✅ Server setup complete."
echo "   Next steps:"
echo "   1. Add your GitHub Actions secrets (DEPLOY_SSH_KEY, DEPLOY_HOST, etc.)"
echo "   2. Push to the 'production' branch to trigger the CD pipeline."
echo "   3. After first deploy, run: php artisan key:generate (on the server)"
