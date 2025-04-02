# zeker weten dat DNS goed staat
ssh wpadmin@10.24.13.200 "echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"

# WP-CLI installeren
ssh wpadmin@10.24.13.200 << 'EOF'
cd ~
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --info
EOF

# Maak wp-config.php direct aan via WP-CLI
ssh wpadmin@10.24.13.200 << 'EOF'
cd /var/www/html/wordpress
sudo -u www-data wp config create \
  --dbname=wordpress \
  --dbuser=wpuser \
  --dbpass=wppass \
  --dbhost=localhost \
  --skip-check \
  --force
EOF

# WordPress core installatie (vanaf host)
ssh wpadmin@10.24.13.200 << 'EOF'
cd /var/www/html/wordpress
sudo -u www-data wp core install \
  --url="http://10.24.13.200/wordpress" \
  --title="WPCRM Site" \
  --admin_user=admin \
  --admin_password=adminpass123 \
  --admin_email=admin@example.com
EOF


# CRM installeren
ssh wpadmin@10.24.13.200 << 'EOF'
cd /var/www/html/wordpress
wp plugin install zero-bs-crm --activate
EOF
