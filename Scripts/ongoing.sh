#!/bin/bash

# Configuratie
USERNAME="beheerder"           # Gebruiker waarmee je inlogt
SSH_PORT=6123                  # De aangepaste SSH-poort
NODES=("pve01" "pve02")  

for NODE in "${NODES[@]}"
do
  echo "Verbinden met $NODE..."

  ssh -p $SSH_PORT $USERNAME@$NODE bash <<'EOF'
echo "Updating package cache"
sudo apt update

echo "⬆Upgrading all packages"
sudo apt upgrade -y

echo "Ensuring NTP service is running"
sudo systemctl start systemd-timesyncd || echo "NTP service not beschikbaar"

echo "UFW status controleren"
UFW_STATUS=$(sudo ufw status | grep -i inactive)
if [[ ! -z "$UFW_STATUS" ]]; then
  echo "UFW staat uit — wordt ingeschakeld"
  sudo ufw --force enable
else
  echo "ℹUFW is al actief"
fi

echo "Verwijderen van overbodige pakketten"
sudo apt autoremove -y

echo "Controleren of reboot nodig is..."
if [ -f /var/run/reboot-required ]; then
  echo "Reboot vereist — systeem wordt opnieuw opgestart"
  sudo reboot
else
  echo "Geen reboot nodig"
fi
EOF

  echo "Onderhoud voltooid op $NODE"
  echo "--------------------------------------"

done
