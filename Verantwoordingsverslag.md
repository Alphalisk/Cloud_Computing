# # Begeleidende Verantwoording – Cloud Computing

## 1. Inleiding

In dit verslag verantwoord ik de resultaten van mijn werkzaamheden binnen het vak **Cloud Computing** in het kader van mijn opleiding **HBO-ICT** module **Operations Engineering**.

## 2. Opdrachten van het project

De werkzaamheden van de project:
- De cloud omgeving online opzetten: Voorbereidende opdracht.
- Cloudopdracht 1: Proxmox uit werken
- Cloudopdracht 2: Docker uit werken

## Verantwoording voorbereidende opdracht

Vanuit de opleiding hebben we 3 virtuele servers toegewezen gekregen die voor onze opdracht drie echte fysieke servers simuleren.
Op deze servers moet Proxmox geinstalleerd worden, een cluster gemaakt worden en een shared storage middels CEPH gerealiseerd worden.

De volgende stappen zijn uitgevoerd:  

| Stap | Beschrijving                                                                |
|------|-----------------------------------------------------------------------------|
| 1    | Installeer Proxmox op 3 VM’s (elk met eigen naam + IP)                      |
| 2    | Update pakketten + stel repo in via SSH                                     |
| 3    | Maak van de 3 losse nodes één **cluster** met `pvecm`                       |
| 4    | Installeer **Ceph** voor gedeelde opslag                                    |
| 5    | Gereed voor de rest van de cloud opdracht                                   |


Hierbij een screenshot van het monitoren:

![alt text](.\Screenshots\VoorbereidendeOpdracht\WerkendClusterEnCeph.png)

Hierbij een screenshot van de ingestelde partities:

|Partitie |	Grootte |	Beschrijving                       |
|---------|---------|--------------------------------------|
|/dev/sda1|	1 MB	|BIOS boot (voor het opstarten)        |
|/dev/sda2|	1 GB	|EFI (voor UEFI boot systemen)         |
|/dev/sda3|	106 GB	|LVM – hierop is Proxmox geïnstalleerd |
|/dev/sda4|	215 GB	|Voor Ceph OSD gebruikt                |

![alt text](.\Screenshots\VoorbereidendeOpdracht\InzagePartities.png)

Het cluster is nu gereed voor gebruik.

## Verantwoording Opdracht 1: Proxmox

## Verantwoording Opdracht 2: Docker


*Gemaakt door: Richard Mank*  
*Studentnummer: [12345678]*  
*Datum: 31-3-2025*

