#!/bin/bash

# === Instellingen === 
VMID=200
VMNAME="wpcrm"
CEPHPOOL="vm-storage"
DISK="${CEPHPOOL}:vm-${VMID}-disk-0"
CLOUDIMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMG_RAW="ubuntu.raw"
CLOUDIMG="jammy-server-cloudimg-amd64.img"
MEM=2048
CORES=2
IP="10.24.13.200/24"
GW="10.24.13.1"
USER="wpadmin"
SSH_PUBKEY_PATH="$HOME/.ssh/id_rsa.pub"  

echo "📥 Download Ubuntu Cloud Image"
wget -O $CLOUDIMG $CLOUDIMG_URL

echo "🔄 Converteer naar RAW"
qemu-img convert -f qcow2 -O raw $CLOUDIMG $IMG_RAW

echo "🧹 Verwijder bestaande disk als die bestaat (optioneel)"
rbd rm ${DISK} 2>/dev/null

echo "📤 Upload disk naar Ceph"
rbd import $IMG_RAW ${DISK}
