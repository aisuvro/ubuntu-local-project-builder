#!/bin/bash

# Prompt for the project name
read -p "Enter the project name (e.g., wgzl): " project_name

# Paths
project_dir="/var/www/$project_name/public_html"
ssl_cert_dir="/etc/ssl"
ssl_key="$ssl_cert_dir/private/selfsigned.key"
ssl_cert="$ssl_cert_dir/certs/selfsigned.crt"
conf_file="/etc/apache2/sites-available/$project_name-ssl.conf"

# Ensure the project directory exists
if [ ! -d "$project_dir" ]; then
    echo "Project directory $project_dir does not exist."
    exit 1
fi

# Install OpenSSL and Apache if not installed
sudo apt update
sudo apt install -y openssl apache2

# Generate SSL certificate and key
sudo openssl req -newkey rsa:2048 -nodes -keyout "$ssl_key" -x509 -days 365 -out "$ssl_cert" -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"

# Enable SSL module and default SSL site
sudo a2enmod ssl
sudo a2ensite default-ssl

# Create a new SSL virtual host configuration
sudo bash -c "cat > $conf_file <<EOL
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot $project_dir
    ServerName localhost

    SSLEngine on
    SSLCertificateFile $ssl_cert
    SSLCertificateKeyFile $ssl_key

    <Directory $project_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
</IfModule>
EOL"

# Enable the new SSL site configuration
sudo a2ensite "$project_name-ssl.conf"
sudo systemctl restart apache2

# Update /etc/hosts if needed
if ! grep -q "$project_name" /etc/hosts; then
    sudo bash -c "echo '127.0.0.1 $project_name.local' >> /etc/hosts"
fi

echo "Setup complete. Access your site via https://$project_name.local"
