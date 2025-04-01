#!/bin/bash
# setup_tailscale.sh

set -e

if [[ -z "${1:-}" ]]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

VM_HOSTNAME="$1"

# Auth key moet vooraf worden geset in dit bestand
source /tmp/tailscale.env

if [[ -z "${TAILSCALE_AUTH_KEY}" ]]; then
    echo "❌ Missing TAILSCALE_AUTH_KEY in environment."
    exit 1
fi

# Install jq (voor JSON parsing van tailscale status)
sudo apt update
sudo apt install -y jq

# Install Tailscale als nog niet aanwezig
if command -v tailscale &>/dev/null; then
    echo "✅ Tailscale is al geïnstalleerd. Skipping install."
else
    echo "⬇️ Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Connect
if tailscale status &>/dev/null; then
    echo "✅ Already connected to Tailnet."
else
    echo "🔌 Connecting to Tailscale..."
    sudo tailscale up --authkey "${TAILSCALE_AUTH_KEY}" --hostname "${VM_HOSTNAME}" --ssh
fi

# Output
echo
echo "📡 Tailscale status:"
sudo tailscale status
echo
echo "🌐 Tailscale IP:"
sudo tailscale ip -4 | head -n 1
echo
TAILNET_DOMAIN=$(tailscale status --json | jq -r '.Self.DNSName')
echo "🔗 Access your VM at: http://${TAILNET_DOMAIN}:8086"
