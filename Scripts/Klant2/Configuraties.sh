# 🌐 2. 🛠️ DNS fixen naar 1.1.1.1
ssh wpadmin@10.24.13.200 "echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"


# 🔐 1. 🔥 UFW Firewall instellen
ssh wpadmin@10.24.13.200 << 'EOF'
sudo apt update
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22 comment 'Allow SSH'
sudo ufw allow 80 comment 'Allow HTTP'
sudo ufw allow 443 comment 'Allow HTTPS'
sudo ufw --force enable
sudo ufw status verbose
EOF

# 🔄 3. ✅ Update & upgrade uitvoeren
ssh wpadmin@10.24.13.200 << 'EOF'
sudo apt update && sudo apt upgrade -y
EOF