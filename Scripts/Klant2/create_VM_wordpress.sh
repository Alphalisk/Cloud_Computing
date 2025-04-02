# VM container maken op HA (CEPH)

## VM 200 aanmaken op HA-geschikte Ceph storage (vm-storage)
sudo qm create 200 \
  --name wpcrm \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --scsi0 vm-storage:32 \
  --ide2 vm-storage:cloudinit \
  --ostype l26

## Boot volgorde en disk instellen
sudo qm set 200 --boot c --bootdisk scsi0

## Cloud-init config (voor testomgeving)
sudo qm set 200 --ciuser wpadmin --cipassword securepass --ipconfig0 ip=10.24.13.200/24,gw=10.24.13.1

## Voeg toe aan HA
sudo ha-manager add vm:200


# SSH verbinding via certificaat