# Begeleidende Verantwoording – Cloud Computing

## Inleiding

In dit verslag verantwoord ik mijn werkzaamheden binnen het vak **Cloud Computing**, onderdeel van de **HBO-ICT** module **Operations Engineering**. De nadruk ligt op het inrichten, beheren en monitoren van een Proxmox-cluster inclusief geautomatiseerde uitrol van webapplicaties.

## Opdrachten van het project

De werkzaamheden van de project:
- De cloud omgeving online opzetten: Voorbereidende opdracht.
- Cloudopdracht 1: Proxmox uit werken
- Cloudopdracht 2: Docker uit werken

## Verantwoording voorbereidende opdracht

Vanuit de opleiding zijn 3 virtuele servers toegewezen die fungeren als simulatie van fysieke servers.  
Doel was het installeren van Proxmox, het opzetten van een cluster, en het realiseren van gedeelde opslag via Ceph.  

De volgende stappen zijn uitgevoerd:  

| Stap | Beschrijving                                              |
|------|-----------------------------------------------------------|
| 1    | Proxmox geïnstalleerd op 3 VM’s (elk met eigen naam + IP) |
| 2    | Pakketten geüpdatet + juiste repositories ingesteld       |
| 3    | Cluster aangemaakt met `pvecm`                            |
| 4    | Ceph geïnstalleerd voor gedeelde opslag (shared storage) |
| 5    | Cluster gereed voor verdere opdrachten (HA en applicaties)|




---

### Partitie instellingen


|Partitie |	Grootte |	Beschrijving                       |
|---------|---------|--------------------------------------|
|/dev/sda1|	1 MB	|BIOS boot (voor het opstarten)        |
|/dev/sda2|	1 GB	|EFI (voor UEFI boot systemen)         |
|/dev/sda3|	106 GB	|LVM – hierop is Proxmox geïnstalleerd |
|/dev/sda4|	215 GB	|Voor Ceph OSD gebruikt                |

Hierbij een screenshot van de ingestelde partities:

![alt text](.\Screenshots\VoorbereidendeOpdracht\InzagePartities.png)

---

### Ansible playbooks (orchestration)

Op node pve00 is Ansible geïnstalleerd als **control node**. De nodes pve01 en pve02 fungeren als **managed nodes**.

Hiervoor zijn playbooks geschreven.
De playbooks bevinden zich in de map `/Playbooks/ansible-ubuntu/`

- `initial.yml` – eenmalige setup van gebruikers en SSH
- `ongoing.yml` – voor updates en onderhoudstaken  


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

De omgeving is gereed voor verdere opdrachten (zoals het uitrollen van applicaties met WordPress en Docker).

### Afsluiting

Deze voorbereidende stappen vormen de technische basis voor het verdere cloudproject. In het volgende deel worden de applicaties voor Klant 1 en Klant 2 uitgerold met focus op LXC, VM’s en automatisering met Ansible.

---


## Verantwoording Opdracht 1: Proxmox

## Verantwoording Opdracht 2: Docker


*Gemaakt door: Richard Mank*  
*Studentnummer: [12345678]*  
*Datum: 31-3-2025*

