#!/bin/bash

# === Instellingen Basis ===
VMID=$1 # Dit aanpassen
VMNAME="wpcrm" 
CEPHPOOL="vm-storage"
DISK="vm-${VMID}-disk-0"
CLOUDIMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUDIMG="jammy-server-cloudimg-amd64.img"
IMG_RAW="ubuntu.raw"
IMG_RESIZED="ubuntu-20G.raw"
MEM=4096
CORES=2
IP="10.24.13.${VMID}/24"
GW="10.24.13.1"
USER="wpadmin"
SSH_PUBKEY_PATH="$HOME/.ssh/id_rsa.pub"

# === Instellingen Tailscale ===
VM_IP="10.24.13.${VMID}"
SSH_USER=$USER
TAILSCALE_ENV="/tmp/tailscale.env"
VM_HOSTNAME=$VMNAME

# Check of er überhaupt een argument is
if [ -z "$1" ]; then
  echo "❌ Geef een VMID/IP-einde op, bijvoorbeeld: $0 161"
  exit 1
fi

# Check of het een getal is tussen 1 en 254
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ] || [ "$1" -gt 254 ]; then
  echo "❌ Ongeldig IP-nummer: $1 — kies een waarde tussen 1 en 254"
  exit 1
fi

echo "✅ Invoerde IP-nummer/VMID is geldig: $1"

# resetten SSH key bij per ongeluk dubbel gebruik
ssh-keygen -f "/home/beheerder/.ssh/known_hosts" -R "$VM_IP"

# === Basis installatie VM met Ubuntu ===
echo "📥 Download Ubuntu Cloud Image"
sudo wget -O $CLOUDIMG $CLOUDIMG_URL

echo "🔄 Converteer naar RAW"
sudo qemu-img convert -f qcow2 -O raw $CLOUDIMG $IMG_RAW

echo "📏 Vergroot RAW image naar 20G"
sudo qemu-img resize $IMG_RAW 20G

echo "📤 Upload RAW disk naar Ceph"
sudo rbd rm ${CEPHPOOL}/$DISK 2>/dev/null
sudo rbd import $IMG_RAW $DISK --dest-pool $CEPHPOOL

echo "🖥️ Maak VM aan"
sudo qm create $VMID \
  --name $VMNAME \
  --memory $MEM \
  --cores $CORES \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --ide2 ${CEPHPOOL}:cloudinit \
  --ostype l26 \
  --agent enabled=1

echo "💾 Koppel disk en stel boot in"
sudo qm set $VMID --scsi0 ${CEPHPOOL}:$DISK
sudo qm set $VMID --boot c --bootdisk scsi0

echo "⚙️ Configureer cloud-init"
sudo qm set $VMID \
  --ciuser $USER \
  --ipconfig0 ip=$IP,gw=$GW \
  --sshkey $SSH_PUBKEY_PATH

## Voeg toe aan HA
sudo ha-manager add vm:$VMID

# 4. Start de VM
echo "🟢 Start VM $VMID..."
sudo qm start $VMID

# 5. Wacht tot SSH beschikbaar is
echo "⏳ Wachten tot SSH werkt op $IP..."
until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes $USER@${IP%/*} 'echo SSH OK' 2>/dev/null; do
  sleep 3
done

# 6. DNS fix
echo "🌐 DNS instellen op 1.1.1.1"
ssh $USER@${IP%/*} "echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"

# 7. UFW firewall configureren
echo "🛡️ Firewall instellen"
ssh $USER@${IP%/*} << 'EOF'
sudo apt update
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw allow 22 comment 'Allow SSH'
sudo ufw allow 80 comment 'Allow HTTP'
sudo ufw allow 443 comment 'Allow HTTPS'
sudo ufw --force enable
sudo ufw status verbose
EOF

# 8. Update & upgrade uitvoeren
# Hij gaat de eerste keer mis door een blokkade
ssh $USER@${IP%/*} "echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"
ssh $USER@${IP%/*} "sudo kill -9 \$(pgrep apt-get)"
ssh $USER@${IP%/*} "sudo dpkg --configure -a"
ssh $USER@${IP%/*} "echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"

echo "🔄 System update uitvoeren"
ssh $USER@${IP%/*} << 'EOF'
sudo apt update && sudo apt upgrade -y
EOF

# herstarten
sudo qm reboot ${VMID} # Deze veranderen!

# Wacht tot SSH beschikbaar is
echo "⏳ Wachten tot SSH werkt op $IP..."
until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes $USER@${IP%/*} 'echo SSH OK' 2>/dev/null; do
  sleep 3
done

echo "✅ VM $VMID is volledig klaar en geconfigureerd op $IP"

# === installatie Tailscale ===
# 🔑 SSH toegang check
echo "📤 Kopieer Tailscale config naar VM..."
scp $TAILSCALE_ENV ${SSH_USER}@${VM_IP}:/tmp/tailscale.env

# 🚀 Installatie + setup in de VM
ssh ${SSH_USER}@${VM_IP} << 'EOF'
set -e

# 🧪 DNS fix
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# 📦 Installatie Tailscale
source /tmp/tailscale.env
sudo apt update
sudo apt install -y curl jq
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled

# ⏳ Wachten op backend
for i in {1..10}; do
  if tailscale status &>/dev/null; then break; fi
  echo "⏳ Wachten op tailscaled backend..."; sleep 2
done

# 🔐 Verbinden
sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --hostname wpcrm --ssh --accept-dns=false

# ✅ Status tonen
echo "🌐 Tailscale IP:"; tailscale ip -4 | head -n 1
echo "🔗 DNS naam:"; tailscale status --json | jq -r ".Self.DNSName"
EOF

# === installatie monitor ===
# clean install
echo "Toevoegen monitor netdata"
until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o BatchMode=yes $USER@${IP%/*} 'echo SSH OK' 2>/dev/null; do
  sleep 3
done
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
bash <(curl -SsL https://my-netdata.io/kickstart.sh)
sudo ufw allow 19999/tcp comment 'Allow Netdata'
sudo systemctl restart netdata
sudo mkdir -p /etc/netdata
sudo sed -i 's/^  bind to = localhost/  bind to = 0.0.0.0/' /etc/netdata/netdata.conf
sudo systemctl restart netdata
EOF


# === installateren wordpress, mariaDB en Apache ===
echo "Installeren wordpress, mariaDB en Apache"
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
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

# === installeren CRM ===
echo "Installeren CRM"
# WP-CLI installeren
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf
cd ~
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --info
EOF

# Maak wp-config.php direct aan via WP-CLI
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
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
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
cd /var/www/html/wordpress
sudo -u www-data wp core install \
  --url="http://10.24.13.200/wordpress" \
  --title="WPCRM Site" \
  --admin_user=admin \
  --admin_password=adminpass123 \
  --admin_email=admin@example.com
EOF

# CRM installeren
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
cd /var/www/html/wordpress
wp plugin install zero-bs-crm --activate
EOF

# Eindgegevens tonen
ssh ${SSH_USER}@${VM_IP} << 'EOF'
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
# ✅ Status tonen
echo "🌐 Tailscale IP:"; tailscale ip -4 | head -n 1
echo "🔗 DNS naam:"; tailscale status --json | jq -r ".Self.DNSName"
EOF