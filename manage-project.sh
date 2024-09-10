# Prompt for the project name
read -p "Enter the project name: " project

# Step 1: Create a directory for the project
sudo mkdir -p /var/www/$project/public_html

# Step 2: Set correct permissions
sudo chown -R $USER:$USER /var/www/$project/public_html
sudo chmod -R 755 /var/www

# Step 3: Create a test index.php for the project
echo "<?php echo '$project'; ?>" | sudo tee /var/www/$project/public_html/index.php

# Step 4: Create Virtual Host file for the project
sudo bash -c "cat <<EOT > /etc/apache2/sites-available/$project.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $project.local
    DocumentRoot /var/www/$project/public_html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT"

# Step 5: Enable the Virtual Host
sudo a2ensite $project.conf

# Step 6: Update the hosts file to access the project via a local domain
sudo bash -c "echo '127.0.0.1    $project.local' >> /etc/hosts"

# Step 7: Restart Apache to apply changes
sudo systemctl restart apache2