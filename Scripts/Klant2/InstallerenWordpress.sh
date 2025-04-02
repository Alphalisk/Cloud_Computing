ssh wpadmin@10.24.13.200 << 'EOF'
# 📦 Vereiste pakketten installeren
sudo apt update
sudo apt install -y apache2 php php-mysql libapache2-mod-php mariadb-server unzip wget

# 🔐 MariaDB beveiligen & database/user aanmaken
sudo mysql -u root <<MYSQL
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
MYSQL

# 🌐 WordPress downloaden en uitpakken
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz

# 📁 Verplaatsen naar de juiste map
sudo mv wordpress /var/www/html/
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# ⚙️ Apache configuratie
sudo bash -c 'cat > /etc/apache2/sites-available/wordpress.conf <<CONF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/html/wordpress

    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
CONF'

# 🌐 Apache activeren
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo systemctl reload apache2
EOF
