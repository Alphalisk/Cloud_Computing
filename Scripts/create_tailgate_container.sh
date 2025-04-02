CTID=131 # Vul hier de naam van de container in!

# Key
sudo pct push $CTID /tmp/tailscale.env /tmp/tailscale.env

# DNS fix
sudo pct exec $CTID -- bash -c "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"

# Voeg TUN device toe aan containerconfig
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" | sudo tee -a /etc/pve/lxc/${CTID}.conf > /dev/null
echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" | sudo tee -a /etc/pve/lxc/${CTID}.conf > /dev/null


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