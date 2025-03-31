#!/bin/bash

# Variabelen
USERNAME="beheerder"
SSHPUBKEY=$(cat ~/.ssh/id_rsa.pub)
SSHPORT=6123
PASSWORD_HASH=$(openssl passwd -6 "beheerderwachtwoord")
NTP_SERVICE="systemd-timesyncd"

# Script
echo " Update en upgrade APT"
apt update && apt upgrade -y

echo " NTP service starten (indien aanwezig)"
systemctl start $NTP_SERVICE || echo " NTP service niet beschikbaar"

echo " Sudo-groep controleren"
getent group sudo > /dev/null || groupadd sudo

echo " Gebruiker '$USERNAME' aanmaken met sudo-rechten"
id "$USERNAME" &>/dev/null || useradd -m -s /bin/bash -G sudo "$USERNAME"
echo "$USERNAME:$PASSWORD_HASH" | chpasswd --encrypted

echo " SSH-sleutel kopiëren naar gebruiker"
mkdir -p /home/$USERNAME/.ssh
echo "$SSHPUBKEY" > /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

echo " SSH toegang voor root uitschakelen"
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

echo " SSH-poort aanpassen naar $SSHPORT"
sed -i "s/^#Port 22/Port $SSHPORT/" /etc/ssh/sshd_config

echo " UFW installeren en configureren"
apt install ufw -y
ufw allow $SSHPORT/tcp
ufw limit $SSHPORT/tcp
ufw default deny incoming
ufw --force enable

echo "Opruimen ongebruikte packages"
apt autoremove -y

echo " SSH herstarten en reboot uitvoeren"
systemctl restart ssh
reboot
