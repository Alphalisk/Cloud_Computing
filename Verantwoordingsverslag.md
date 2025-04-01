# Begeleidende Verantwoording – Cloud Computing

## Inleiding

In dit verslag verantwoord ik mijn werkzaamheden binnen het vak **Cloud Computing**, onderdeel van de **HBO-ICT** module **Operations Engineering**. De nadruk ligt op het inrichten, beheren en monitoren van een Proxmox-cluster inclusief geautomatiseerde uitrol van webapplicaties.

## Opdrachten van het project

De werkzaamheden van de project:
- De Cloud omgeving online opzetten: Voorbereidende opdracht.
- Cloudopdracht 1, klant 1
- Cloudopdracht 1, klant 2
- Cloudopdracht 2

## Verantwoording voorbereidende opdracht

Vanuit de opleiding zijn 3 virtuele servers toegewezen die fungeren als simulatie van fysieke servers.  
Doel was het installeren van Proxmox, het opzetten van een cluster, en het realiseren van gedeelde opslag via Ceph.  

De volgende stappen zijn uitgevoerd:  

| Stap | Beschrijving                                              |
|------|-----------------------------------------------------------|
| 1    | Proxmox geïnstalleerd op 3 VM’s (elk met eigen naam + IP) |
| 2    | Pakketten geüpdatet + juiste repositories ingesteld       |
| 3    | Cluster aangemaakt met `pvecm`                            |
| 4    | Ceph geïnstalleerd voor gedeelde opslag (shared storage)  |
| 5    | Cluster gereed voor verdere opdrachten                    |


### Proxmox netwerk instellingen

|nodenaam|IP intern    |Type node    |IP Tailscale  |
|--------|-------------|-------------|--------------|
|pve00   |10.24.13.100 |control node |100.94.185.45 |
|pve01   |10.24.13.101 |managed node |100.104.126.78|
|pve02   |10.24.13.102 |managed node |100.84.145.8  |

---

### Partitie instellingen per node


|Partitie |	Grootte |	Beschrijving                       |
|---------|---------|--------------------------------------|
|/dev/sda1|	1 MB	|BIOS boot (voor het opstarten)        |
|/dev/sda2|	1 GB	|EFI (voor UEFI boot systemen)         |
|/dev/sda3|	106 GB	|LVM – hierop is Proxmox geïnstalleerd |
|/dev/sda4|	215 GB	|Voor Ceph OSD gebruikt                |

Hierbij een screenshot van de ingestelde partities:

![alt text](.\Screenshots\VoorbereidendeOpdracht\InzagePartities.png)

---

### SSH Certificaat

Om er voor te zorgen dat het mogelijk is meerdere nodes te beheren vanuit een control node, Is het de bedoeling om te kunnen inloggen zonder wachtwoord.  
Daarvoor in de plaats wordt er ingelogd met certificaten en sleutels.

Stap 1: Remote Laptop met certificaat via root koppelen aan control unit:  
```bash
ssh-keygen
ssh-copy-id root@100.94.185.45
```

Stap 2: Control unit met certificaat via beheerder koppelen aan managed units:  
```bash
adduser bob # (op alle nodes)
usermod -aG sudo bob # om beheerder te maken, dit op alle nodes. Later via playbook automatisch.
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_bob # Op de control node. Hier komt de private key en de te verdelen public key.
ssh-copy-id bob@10.24.13.101 # Kopieren van public key naar andere servers
ssh-copy-id bob@10.24.13.102 # Kopieren van public key naar andere servers
```


### Ansible playbooks (orchestration)

Op node pve00 is Ansible geïnstalleerd als **control node**. De nodes pve01 en pve02 fungeren als **managed nodes**.

Hiervoor zijn playbooks geschreven.
De playbooks bevinden zich in de map `/Playbooks/ansible-ubuntu/`

- `initial.yml` – eenmalige setup van gebruikers en SSH
- `ongoing.yml` – voor updates en onderhoudstaken  

> Met `initial.yml` wordt root op de managed units uitgeschakeld! Vanaf nu kan alleen nog maar worden ingelogd met de beheerder account!  

In de map `/vars/` is `default.yml` aanwezig met de volgende variabelen:

```yaml
create_user: beheerder
ssh_port: 6123
copy_local_key: "{{ lookup('file', lookup('env','HOME') + '/.ssh/id_rsa.pub') }}"
```

> Hiermee wordt de gebruiker `beheerder` met sudo-rechten aangemaakt op alle nodes, wordt poort 6123 gebruikt voor SSH en wordt authenticatie geregeld via sleutels (geen wachtwoorden).


#### Updates via Ansible

Updates worden uitgevoerd met het playbook `ongoing.yml`:

```bash
ansible-playbook --ask-vault-pass ongoing.yml
```

Hiermee zijn updates geautomatiseerd uitgevoerd op alle nodes – een concrete invulling van "updates via orchestration".

Resultaat:
![alt text](Screenshots\VoorbereidendeOpdracht\PlaybookOngoing.png)

---

### 6. Ceph & High Availability

Ceph is op alle nodes geïnstalleerd voor gedeelde, fouttolerante opslag. Hierdoor ondersteunt het Proxmox-cluster **High Availability (HA)**:

> Bij uitval van een node worden virtuele machines automatisch opnieuw opgestart op een andere node.  
> De data blijft beschikbaar dankzij Ceph-replicatie over meerdere nodes.

Hierbij een screenshot van het monitoren:

![alt text](.\Screenshots\VoorbereidendeOpdracht\WerkendClusterEnCeph.png)

---

### 7. Status

Op dit moment is het cluster volledig operationeel, voorzien van:
- Proxmox-cluster met 3 nodes
- Geconfigureerde shared storage via Ceph
- Werkende HA-configuratie
- Updates en beheer via Ansible


## Verantwoording Opdracht 1: Klant 1

### Opdracht:
**Klant 1: WordPress voor trainingsdoeleinden**  
De eerste klant wil verschillende WordPress-websites afnemen voor trainingsdoeleinden.
De focus ligt op het zo goedkoop mogelijk aanbieden van deze websites.
Hierop is de klant aangeboden dat de applicaties in container (LXC) wordt aangeboden.

### Fase 1, Rechtstreeks met CLI en Bash een container maken:

#### stap 1: download de container template (LXC)
Een LXC container wordt niet opgebouwd vanuit een ISO zoals een VM, maar vanuit een root filesystem (.tar.zst). 

```bash
root@pve00:~# pveam update && pveam available
root@pve00:~# pveam available | grep ubuntu-22.04
system          ubuntu-22.04-standard_22.04-1_amd64.tar.zst
root@pve00:~# pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```

![alt text](Screenshots\Opdracht1\TemplateDownloaden.png)

![alt text](Screenshots\Opdracht1\TemplateDownloaden2.png)

#### Stap 2: Maak een enkele container aan.

De container heeft volgens de beoordelingsmatrix de volgende eisen:

| Eigenschap       | Waarde                        |
|------------------|-------------------------------|
| CPU              | 1 core                        |
| RAM              | 1024 MB (1 GB)                |
| Disk             | 30 GB                         |
| Network limit    | 50 MB/s                       |
| Poorten open     | 80 (HTTP), 443 (HTTPS)        |
| Firewall         | Alleen toegang tot webdiensten|

De gebruikte Bash code om dit aan te maken,
Dit is gedaan vanuit control unit pve00 met ssh naar managed unit pve01:

```bash
root@pve00:~# ssh -p 6123 beheerder@pve01 'sudo pct create 101 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname wp1 \
  --cores 1 \
  --memory 1024 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,rate=50 \
  --ostype ubuntu \
  --password wordpress \
  --unprivileged 1'
```

Screenshot:

![alt text](Screenshots\Opdracht1\ContainerCLI.png)

### Stap 3: Firewall instellen

Op de managed node stel ik de firewall voor container CT 101 in:

![alt text](Screenshots\Opdracht1\FirewallInstellen.png)

### Stap 4: Testen of het werkt

Hierbij start de container:

```bash
beheerder@pve01:~$ sudo pct start 101
beheerder@pve01:~$ sudo pct exec 101 -- bash
root@wp1:/# 
```

![alt text](Screenshots\Opdracht1\ContainerStarten.png)

### Stap 5: Wordpress installeren

Op de container moeten nu de applicatie Wordpress geinstalleerd worden.
Daarbij kwam het probleem dat het niet mogelijk was om online te komen met sudo apt update.
Er waren 2 fouten.
De tailgate DNS 100.100.100.100 werd gebruikt -> die is omgezet naar 1.1.1.1
net0 was verkeerd ingesteld.

```conf
arch: amd64
cores: 1
hostname: wp1
memory: 1024
net0: name=eth0,bridge=vmbr0,ip=10.24.13.101/24,gw=10.24.13.1,rate=50
ostype: ubuntu
rootfs: local-lvm:vm-101-disk-0,size=30G
swap: 512
unprivileged: 1
```

#### Installatie stappen: 

1) update en upgrade

```bash
sudo apt update
sudo apt upgrade -y
```

![alt text](Screenshots\Opdracht1\CTupdate&upgrade.png)

2) Installeren van Apache, PHP en MariaDB:  

```bash
apt install apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-xml php-mbstring unzip wget -y
```

Apache test:
![alt text](Screenshots\Opdracht1\Apachewerkend.png)

3) MariaDB aanmaken:

```bash
mysql_secure_installation
mysql -u root
```

```sql
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Aanmaken Database:
![alt text](Screenshots\Opdracht1\MariaDBwerkend.png)

Controleren of databse en user ingesteld zijn (database wordpress, user wpuser):
![alt text](Screenshots\Opdracht1\MariaDBenuser.png)


4) Wordpress installeren

In de container CLI:
```bash
cd /tmp
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# Dit moet op de host! niet de container
wget https://wordpress.org/latest.tar.gz
sudo pct push 101 latest.tar.gz /tmp/latest.tar.gz # pushen naar container.

# Dan in de container:
tar -xvzf latest.tar.gz
sudo mv wordpress /var/www/html/wordpress
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Apache configureren
sudo nano /etc/apache2/sites-available/wordpress.conf
sudo a2ensite wordpress.conf
sudo a2enmod rewrite
sudo systemctl reload apache2
```

De website heeft een ping, en geeft een standaard website als response.
![alt text](Screenshots\Opdracht1\WordpressPingEnCurl.png)

# Firewall instellen

```bash
beheerder@pve01:~$ echo $CTID
111
beheerder@pve01:~$ sudo pct exec $CTID -- bash -c "ufw default deny incoming"
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
beheerder@pve01:~$ sudo pct exec $CTID -- bash -c "ufw allow 80/tcp comment 'Allow HTTP'"
Rules updated
Rules updated (v6)
beheerder@pve01:~$ sudo pct exec $CTID -- bash -c "ufw allow 443/tcp comment 'Allow HTTPS'"
Rules updated
Rules updated (v6)
beheerder@pve01:~$ sudo pct exec $CTID -- bash -c "ufw allow out to any"
Rules updated
Rules updated (v6)
beheerder@pve01:~$ sudo pct exec $CTID -- bash -c "yes | ufw enable"
Firewall is active and enabled on system startup
yes: standard output: Broken pipe
beheerder@pve01:~$ 
```

### Fase 2, CLI commando's omzetten naar Bash-script voor automatisch aanmaken container:

## Verantwoording Opdracht 1: Klant 2


## Verantwoording Opdracht 2: Docker

*Gemaakt door: Richard Mank*  
*Studentnummer: [12345678]*  
*Datum: 31-3-2025*

