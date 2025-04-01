#!/bin/bash

# === Instellingen ===
CTID=$1                       # Bijv. 102
HOSTNAME="wp${CTID}"
IP="10.24.13.${CTID}"
GW="10.24.13.1"
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
STORAGE="local-lvm"

echo "📦 Container $CTID aanmaken op IP $IP"

# === 1. Container aanmaken ===
sudo pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --cores 1 \
  --memory 1024 \
  --swap 512 \
  --net0 name=eth0,bridge=vmbr0,ip=${IP}/24,gw=$GW,rate=50 \
  --rootfs ${STORAGE}:30 \
  --ostype ubuntu \
  --unprivileged 1

# === 2. Container starten ===
sudo pct start $CTID
sleep 5

# === 3. DNS fix voor Tailgate (resolv.conf workaround) ===
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.custom.conf > /dev/null
sudo pct exec $CTID -- bash -c "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"

# === 4. Software installeren ===
pct exec $CTID -- bash -c "apt update && apt upgrade -y"
pct exec $CTID -- bash -c "apt install -y apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-xml php-mbstring unzip wget"

# === 5. MariaDB configureren ===
pct exec $CTID -- bash -c "mysql -u root <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EOF"

# === 6. WordPress downloaden en installeren ===
pct exec $CTID -- bash -c "cd /tmp && wget https://wordpress.org/latest.tar.gz"
pct exec $CTID -- bash -c "cd /tmp && tar -xvzf latest.tar.gz"
pct exec $CTID -- bash -c "mv /tmp/wordpress /var/www/html/wordpress"
pct exec $CTID -- bash -c "chown -R www-data:www-data /var/www/html/wordpress && chmod -R 755 /var/www/html/wordpress"

# === 7. Apache config aanmaken ===
pct exec $CTID -- bash -c "cat > /etc/apache2/sites-available/wordpress.conf <<EOL
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/html/wordpress
    ServerName ${HOSTNAME}.local

    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL"

# === 8. Apache activeren ===
pct exec $CTID -- bash -c "a2ensite wordpress.conf && a2enmod rewrite && systemctl reload apache2"

echo "✅ Container $CTID klaar! Bezoek: http://${IP}/wordpress"
