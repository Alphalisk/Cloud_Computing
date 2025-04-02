# Stap 1: Maak een nieuwe VM aan
sudo qm create 200 --name wpcrm --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --ide2 local:cloudinit --ostype l26 --scsihw virtio-scsi-pci --scsi0 local-lvm:32
sudo qm set 200 --boot c --bootdisk scsi0
sudo qm set 200 --ciuser wpadmin --cipassword securepass --ipconfig0 ip=10.24.13.200/24,gw=10.24.13.1