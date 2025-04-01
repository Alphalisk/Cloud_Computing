#!/bin/bash

# === Instellingen ===
CTID=$1                       # Bijv. 111
HOSTNAME="wp${CTID}"
IP="10.24.13.${CTID}"
GW="10.24.13.1"
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
STORAGE="local-lvm"
USERNAME="wpadmin"
PUBKEY_PATH="/home/beheerder/.ssh/id_rsa.pub" 

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
  --unprivileged 1 \
  --features nesting=1

# === 1.5 Containerconfig aanpassen voor Tailscale (TUN device) ===
echo "⚙️  Pas containerconfig aan voor TUN toegang (Tailscale compatibiliteit)"
CTCONF="/etc/pve/lxc/${CTID}.conf"

# Voeg nesting expliciet toe als backup
if ! sudo grep -q "features: nesting=1" "$CTCONF"; then
    echo "features: nesting=1" | sudo tee -a "$CTCONF" > /dev/null
fi

# Voeg toegang toe tot TUN device
if ! sudo grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" "$CTCONF"; then
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm" | sudo tee -a "$CTCONF" > /dev/null
fi

if ! sudo grep -q "lxc.mount.entry: /dev/net/tun" "$CTCONF"; then
    echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" | sudo tee -a "$CTCONF" > /dev/null
fi


# === 2. Container starten ===
sudo pct start $CTID
echo "⏳ Wachten tot container netwerk klaar is..."
sleep 10

# Test of internet werkt (optioneel, visuele check)
sudo pct exec $CTID -- ping -c 1 1.1.1.1 >/dev/null 2>&1 && echo "✅ Netwerk werkt binnen container" || echo "⚠️  Geen internet binnen container"


# === 2.1 Tailscale installeren en verbinden ===
TAILSCALE_AUTH_KEY="tskey-auth-kPrPPiyXcv11CNTRL-RetqYbsDMLeuLdpAgK4JLeRwPy1cEDakH"  # <<< Vervang dit met jouw eigen auth key
echo "🌐 Tailscale installeren en verbinden op container $CTID"

# Mirror
echo "🌍 Mirror aanpassen naar nl.archive.ubuntu.com"
sudo pct exec $CTID -- bash -c "sed -i 's|http://archive.ubuntu.com|http://nl.archive.ubuntu.com|g' /etc/apt/sources.list"
sudo pct exec $CTID -- bash -c "until apt update; do echo 'APT update faalde, opnieuw proberen...'; sleep 3; done"


# Stap 1: curl installeren (anders faalt download)
sudo pct exec $CTID -- bash -c "apt update && apt install -y curl"

# Stap 2: tailscale installeren
sudo pct exec $CTID -- bash -c "curl -fsSL https://tailscale.com/install.sh | sh"

# Stap 2.5: tailscaled starten
sudo pct exec $CTID -- bash -c "systemctl enable tailscaled && systemctl start tailscaled"

# Stap 3: tailscale activeren met auth key
sudo pct exec $CTID -- bash -c "tailscale up --authkey=${TAILSCALE_AUTH_KEY} --hostname=${HOSTNAME}"


# Optioneel: IP tonen
TAILSCALE_IP=$(sudo pct exec $CTID -- tailscale ip | head -n 1)
echo "✅ Tailscale IP van container $CTID: $TAILSCALE_IP"


# === 3. DNS fix voor Tailgate (resolv.conf workaround) ===
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.custom.conf > /dev/null
sudo pct exec $CTID -- bash -c "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"



# Locales
sudo pct exec $CTID -- bash -c "apt install -y locales && locale-gen en_US.UTF-8"

# === 4. Software installeren ===
sudo pct exec $CTID -- bash -c "apt update && apt upgrade -y"
sudo pct exec $CTID -- bash -c "apt install -y apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-xml php-mbstring unzip wget"

# === 4.1 SSH-server installeren ===
sudo pct exec $CTID -- bash -c "apt install -y openssh-server"
sudo pct exec $CTID -- bash -c "systemctl enable ssh && systemctl start ssh"


# === 4.5 Firewall instellen ===
echo "🛡️  Firewall (UFW) instellen op container $CTID"
sudo pct exec $CTID -- bash -c "apt install -y ufw"
sudo pct exec $CTID -- bash -c "ufw default deny incoming"
sudo pct exec $CTID -- bash -c "ufw allow 22/tcp comment 'Allow SSH'"
sudo pct exec $CTID -- bash -c "ufw allow 80/tcp comment 'Allow HTTP'"
sudo pct exec $CTID -- bash -c "ufw allow 443/tcp comment 'Allow HTTPS'"
sudo pct exec $CTID -- bash -c "ufw allow out to any"
sudo pct exec $CTID -- bash -c "yes | ufw enable"

# === 4.6 SSH gebruiker + key instellen ===
echo "🔑 Gebruiker '$USERNAME' aanmaken en SSH key toevoegen aan container $CTID"

sudo pct exec $CTID -- adduser --disabled-password --gecos "" $USERNAME
sudo pct exec $CTID -- mkdir -p /home/$USERNAME/.ssh
sudo bash -c "cat $PUBKEY_PATH | pct exec $CTID -- tee /home/$USERNAME/.ssh/authorized_keys > /dev/null"
sudo pct exec $CTID -- chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
sudo pct exec $CTID -- chmod 700 /home/$USERNAME/.ssh
sudo pct exec $CTID -- chmod 600 /home/$USERNAME/.ssh/authorized_keys

# ✅ SSH configuratie forceren
sudo pct exec $CTID -- sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo pct exec $CTID -- sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
sudo pct exec $CTID -- systemctl restart ssh


# === 5. MariaDB configureren ===
sudo pct exec $CTID -- bash -c "mysql -u root <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EOF"

# === 6. WordPress downloaden en installeren ===
sudo pct exec $CTID -- bash -c "cd /tmp && wget https://wordpress.org/latest.tar.gz"
sudo pct exec $CTID -- bash -c "cd /tmp && tar -xvzf latest.tar.gz"
sudo pct exec $CTID -- bash -c "mv /tmp/wordpress /var/www/html/wordpress"
sudo pct exec $CTID -- bash -c "chown -R www-data:www-data /var/www/html/wordpress && chmod -R 755 /var/www/html/wordpress"

# === 7. Apache config aanmaken ===
sudo pct exec $CTID -- bash -c "cat > /etc/apache2/sites-available/wordpress.conf <<EOL
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
sudo pct exec $CTID -- bash -c "a2ensite wordpress.conf && a2enmod rewrite && systemctl reload apache2"

# === 9. Curl test ===
echo " Curl test vanaf host naar http://${IP}/wordpress"
curl -s -o /dev/null -w "📡 HTTP status: %{http_code}\n" http://${IP}/wordpress # Dit moet 200 of 301 zijn.

echo "✅ Container $CTID klaar! Bezoek: http://${IP}/wordpress"

# === 10. Status check Tailscale ===
echo "🔍 Controleer Tailscale status:"
sudo pct exec $CTID -- tailscale status | head -n 5