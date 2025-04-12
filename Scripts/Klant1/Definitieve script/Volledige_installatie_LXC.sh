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

# Check of er überhaupt een argument is
if [ -z "$1" ]; then
  echo "❌ Geef een CTID/IP-einde op, bijvoorbeeld: $0 161"
  exit 1
fi

# Check of het een getal is tussen 1 en 254
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ] || [ "$1" -gt 254 ]; then
  echo "❌ Ongeldig IP-nummer: $1 — kies een waarde tussen 1 en 254"
  exit 1
fi

echo "✅ Invoerde IP-nummer/VMID is geldig: $1"

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
sudo pct exec $CTID -- ping -c 1 1.1.1.1 >/dev/null 2>&1 && echo "✅ Netwerk werkt binnen container" || echo "⚠️  Geen internet binnen contaainer"


# # === 2.1 Tailscale installeren en verbinden ===

# Key
sudo pct push $CTID /tmp/tailscale.env /tmp/tailscale.env

#installatie
sudo pct exec $CTID -- bash -c '
  source /tmp/tailscale.env
  echo "nameserver 1.1.1.1" > /etc/resolv.conf
  apt update
  apt install -y curl jq
  curl -fsSL https://tailscale.com/install.sh | sh
  systemctl enable --now tailscaled
  for i in {1..10}; do
    if tailscale status &>/dev/null; then break; fi
    echo "⏳ Wachten op tailscaled backend..."; sleep 2
  done
  tailscale up --authkey "$TAILSCALE_AUTH_KEY" --hostname wp$CTID --ssh
  echo "🌐 Tailscale IP:"; tailscale ip -4 | head -n 1
  echo "🔗 DNS naam:"; tailscale status --json | jq -r ".Self.DNSName"
  '


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
echo "Dit is de lokale IP, vanwege tailscale kan met de script ./create_tailgate_container.sh een verbinding gemaakt worden."

# # === 10. Monitoring ===
echo "📈 Netdata installeren op container $CTID"
sudo pct exec $CTID -- bash -c "apt install -y curl sudo"

# Installatie via Netdata kickstart script
sudo pct exec $CTID -- bash -c "bash <(curl -SsL https://my-netdata.io/kickstart-static64.sh)"

# UFW-poort openen
sudo pct exec $CTID -- ufw allow 19999/tcp comment 'Allow Netdata web interface'