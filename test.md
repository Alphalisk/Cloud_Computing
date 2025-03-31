Richard, je verslag ziet er al **heel sterk** uit! 💪  
Je laat duidelijk zien **wat je hebt gedaan, waarom, én hoe**, en dat is precies wat een begeleidend verantwoordingsverslag moet doen.

Toch zijn er een paar dingen die we net iets **duidelijker, netter of consistenter** kunnen maken qua formulering, structuur en spelling. Hieronder geef ik je:

---

## ✅ Algemene feedback

| Onderdeel                 | Feedback                                                                 |
|---------------------------|--------------------------------------------------------------------------|
| ✔️ Structuur               | Goed opgebouwd: inleiding → overzicht → technische uitvoering             |
| ✔️ Technische inhoud       | Sterk, klopt met de opdrachten en je voortgang                           |
| ✏️ Taalgebruik             | Hier en daar wat kromme zinnen of spelfouten (bijv. “uit werken”)         |
| 📐 Opmaak / lay-out       | Prima, maar sommige koppen kunnen helderder of op één lijn staan         |
| ❗ GitHub link ontbreekt  | Je verwijst naar een GitHub map, maar link ontbreekt                     |
| ✍️ Afsluiting ontbreekt   | Een korte reflectie of slotzin zou het net afronden                      |

---

## ✨ Voorstel: herschreven (en verbeterde) versie

Ik geef je hieronder een verbeterde versie van jouw tekst. Alles blijft inhoudelijk van jou — alleen netter verwoord en geordend:

---

# 💡 Begeleidende Verantwoording – Cloud Computing

### 1. Inleiding  
In dit verslag verantwoord ik mijn werkzaamheden binnen het vak *Cloud Computing*, onderdeel van de HBO-ICT module *Operations Engineering*. De nadruk ligt op het inrichten, beheren en monitoren van een Proxmox-cluster inclusief geautomatiseerde uitrol van webapplicaties.

---

### 2. Projectopdrachten  
De werkzaamheden zijn verdeeld over drie deelopdrachten:

1. **Voorbereidende opdracht**: Opzetten van een cloudomgeving  
2. **Cloudopdracht 1**: Implementatie van een Proxmox-cluster  
3. **Cloudopdracht 2**: Werken met Docker

---

### 3. Verantwoording voorbereidend werk

Vanuit de opleiding zijn 3 virtuele servers toegewezen die fungeren als simulatie van fysieke servers.  
Doel was het installeren van Proxmox, het opzetten van een cluster, en het realiseren van gedeelde opslag via **Ceph**.

#### ✔️ Uitgevoerde stappen:

| Stap | Beschrijving                                              |
|------|-----------------------------------------------------------|
| 1    | Proxmox geïnstalleerd op 3 VM’s (elk met eigen naam + IP) |
| 2    | Pakketten geüpdatet + juiste repositories ingesteld       |
| 3    | Cluster aangemaakt met `pvecm`                            |
| 4    | Ceph geïnstalleerd voor gedeelde opslag (shared storage) |
| 5    | Cluster gereed voor verdere opdrachten (HA en applicaties)|

---

### 4. Partitie-instellingen

| Partitie     | Grootte | Beschrijving                                  |
|--------------|--------|-----------------------------------------------|
| `/dev/sda1`  | 1 MB   | BIOS boot-partitie                            |
| `/dev/sda2`  | 1 GB   | EFI partitie voor UEFI-boot                   |
| `/dev/sda3`  | 106 GB | LVM – gebruikt voor installatie van Proxmox   |
| `/dev/sda4`  | 215 GB | Toegekend aan Ceph OSD voor gedeelde opslag   |

🖼️ *[Screenshot hier invoegen]*

---

### 5. Ansible Playbooks (orchestration)

Op node `pve00` is Ansible geïnstalleerd als **control node**. De nodes `pve01` en `pve02` fungeren als **managed nodes**.

#### 🛠️ Gebruikte playbooks:
- `initial.yml` – eenmalige setup van gebruikers en SSH
- `ongoing.yml` – voor updates en onderhoudstaken

📂 De playbooks bevinden zich in de map `/Playbooks/ansible-ubuntu/`

📁 In de map `/vars/` is onder andere `default.yml` aanwezig met variabelen zoals:

```yaml
create_user: beheerder
ssh_port: 6123
copy_local_key: "{{ lookup('file', lookup('env','HOME') + '/.ssh/id_rsa.pub') }}"
```

> Hiermee wordt de gebruiker `beheerder` met sudo-rechten aangemaakt op alle nodes, wordt poort 6123 gebruikt voor SSH en wordt authenticatie geregeld via sleutels (geen wachtwoorden).

#### 📦 Updates via Ansible

Updates worden uitgevoerd met het playbook `ongoing.yml`:

```bash
ansible-playbook --ask-vault-pass ongoing.yml
```

✅ Hiermee zijn updates geautomatiseerd uitgevoerd op alle nodes – een concrete invulling van "updates via orchestration".

🖼️ *[Resultaatscreenshot hier invoegen]*

---

### 6. Ceph & High Availability

Ceph is op alle nodes geïnstalleerd voor gedeelde, fouttolerante opslag. Hierdoor ondersteunt het Proxmox-cluster **High Availability (HA)**:

> Bij uitval van een node worden virtuele machines automatisch opnieuw opgestart op een andere node.  
> De data blijft beschikbaar dankzij Ceph-replicatie over meerdere nodes.

🖼️ *[Screenshot monitoring / Ceph status hier invoegen]*

---

### 7. Status

Op dit moment is het cluster volledig operationeel, voorzien van:
- Proxmox-cluster met 3 nodes
- Geconfigureerde shared storage via Ceph
- Werkende HA-configuratie
- Updates en beheer via Ansible

De omgeving is gereed voor verdere opdrachten (zoals het uitrollen van applicaties met WordPress en Docker).

---

### ✍️ Afsluiting

Deze voorbereidende stappen vormen de technische basis voor het verdere cloudproject. In het volgende deel worden de applicaties voor Klant 1 en Klant 2 uitgerold met focus op LXC, VM’s en automatisering met Ansible.

---

**Student**: Richard Mank  
**Studentnummer**: [12345678]  
**Datum**: 31-03-2025

---

Wil je dat ik dit omzet naar een kant-en-klaar **Markdown-bestand** voor op GitHub of in je portfolio? Of wil je het als Word/PDF-template? 😄