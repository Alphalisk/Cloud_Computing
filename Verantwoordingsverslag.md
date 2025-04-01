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






## Verantwoording Opdracht 1: Klant 2


## Verantwoording Opdracht 2: Docker

*Gemaakt door: Richard Mank*  
*Studentnummer: [12345678]*  
*Datum: 31-3-2025*

