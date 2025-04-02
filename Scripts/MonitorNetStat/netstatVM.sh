# purge old netdata
ssh wpadmin@10.24.13.200 << 'EOF'
sudo systemctl stop netdata || true
sudo pkill netdata || true
sudo apt purge --yes netdata netdata-core netdata-web netdata-plugins-* || true
sudo rm -rf /etc/netdata /var/lib/netdata /var/cache/netdata /opt/netdata /usr/lib/netdata /usr/sbin/netdata
sudo rm -f /etc/systemd/system/netdata.service
EOF

# clean install
ssh wpadmin@10.24.13.200 << 'EOF'
bash <(curl -SsL https://my-netdata.io/kickstart.sh)
EOF


# # Firewall (misschien nodig)
# sudo ufw allow 19999/tcp comment 'Allow Netdata'
# sudo systemctl restart netdata

# # misschien nodig...
# sudo mkdir -p /etc/netdata
# sudo nano /etc/netdata/netdata.conf
# [web]
#   bind to = 0.0.0.0
