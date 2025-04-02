echo "📈 Netdata installeren op container $CTID"
sudo pct exec $CTID -- bash -c "apt install -y curl sudo"

# Installatie via Netdata kickstart script
sudo pct exec $CTID -- bash -c "bash <(curl -SsL https://my-netdata.io/kickstart-static64.sh)"

# UFW-poort openen
sudo pct exec $CTID -- ufw allow 19999/tcp comment 'Allow Netdata web interface'