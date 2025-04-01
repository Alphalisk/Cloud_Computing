#!/bin/bash

# === Instellingen ===
CTID=$1                       # Bijv. 111
HOSTNAME="influxdb"
IP="10.24.13.${CTID}"
GW="10.24.13.1"
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
STORAGE="local-lvm"
USERNAME="wpadmin"
PUBKEY_PATH="/root/.ssh/id_rsa.pub" 

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
sudo pct exec $CTID -- bash -c "apt update && apt upgrade -y"


# Locales
sudo pct exec $CTID -- bash -c "apt install -y locales && locale-gen en_US.UTF-8"


# === 4.1 SSH-server installeren ===
sudo pct exec $CTID -- bash -c "apt install -y openssh-server"
sudo pct exec $CTID -- bash -c "systemctl enable ssh && systemctl start ssh"


# === 4.5 Firewall instellen ===
echo "🛡️  Firewall (UFW) instellen op container $CTID"
sudo pct exec $CTID -- bash -c "apt install -y ufw"
sudo pct exec $CTID -- bash -c "ufw default deny incoming"
sudo pct exec $CTID -- bash -c "ufw allow 22/tcp comment 'Allow SSH'"
sudo pct exec $CTID -- bash -c "ufw allow 8086/tcp comment 'Allow InfluxDB Web UI'"
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

sudo pct exec $CTID -- bash -c "apt install -y curl"


# Add GPG key (compat key)
sudo pct exec $CTID -- bash -c "apt install -y gnupg2"
sudo pct exec $CTID -- bash -c 'curl -s https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor | tee /usr/share/keyrings/influxdata-archive-keyring.gpg > /dev/null'

# Add repo
sudo pct exec $CTID -- bash -c 'echo "deb [signed-by=/usr/share/keyrings/influxdata-archive-keyring.gpg] https://repos.influxdata.com/ubuntu jammy stable" > /etc/apt/sources.list.d/influxdb.list'
sudo pct exec $CTID -- bash -c "apt update && apt install -y influxdb2"
sudo pct exec $CTID -- bash -c "systemctl enable influxdb && systemctl start influxdb"

# === 9. Curl test ===
echo "🌐 Curl test vanaf host naar InfluxDB Web UI op http://${IP}:8086"
curl -s -o /dev/null -w "📡 InfluxDB Web UI status: %{http_code}\n" http://${IP}:8086 # Dit moet 200 of 301 zijn.

echo "✅ Container influxdb klaar!"
