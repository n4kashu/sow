#!/bin/bash

# Check if domain parameter is provided
if [ -z "$1" ]; then
    echo "Error: Domain name is required"
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1
NGINX_CONF="/etc/nginx/conf.d/${DOMAIN}.conf"
HTML_DIR="/var/www/${DOMAIN}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Create web root directory
echo "Creating web root directory..."
mkdir -p $HTML_DIR
cp sow.html $HTML_DIR/index.html
chown -R www-data:www-data $HTML_DIR
chmod -R 755 $HTML_DIR

# Create initial Nginx configuration for HTTP
echo "Creating initial Nginx configuration..."
cat > $NGINX_CONF << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    root ${HTML_DIR};
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Test and reload Nginx
nginx -t && systemctl reload nginx

# Get SSL certificate
echo "Obtaining SSL certificate from Let's Encrypt..."
certbot --nginx \
    -d ${DOMAIN} \
    --non-interactive \
    --agree-tos \
    --email admin@${DOMAIN} \
    --redirect \
    --keep-until-expiring \
    --preferred-challenges http \
    --staple-ocsp

# Final Nginx reload
systemctl reload nginx

echo "Setup completed! Your site is available at https://${DOMAIN}"
echo "Certificates will auto-renew via certbot timer"
