# Cloud_Computing
Repository voor opdrachten Cloud Computing.

Inventaris:
- Het verantwoordingsverslag voor de opdrachten wordt in het bestand *Verantwoordingsverslag.md* bijgehouden.
- De map screenhots bevat bewijsvoering
- De map Scripts bevat bash scripts
- De map Playbooks bevat de .yml files

**Netwerkconfiguratie:**
|nodenaam|IP intern    |Type node    |IP Tailscale  |
|--------|-------------|-------------|--------------|
|pve00   |10.24.13.100 |control node |100.94.185.45 |
|pve01   |10.24.13.101 |managed node |100.104.126.78|
|pve02   |10.24.13.102 |managed node |100.84.145.8  |

## Werkwijze aanmaken LXM container voor wordpress, klant 1

Met de scripts van klant 1 kunnen de containers gemaakt worden.
`Scripts\Klant1`

1) Log in als root op control node (pve00)
   `ssh root@100.94.185.45` (tailgate)
2) Log in op managed node als beheerder op pve01
   `ssh beheerder@10.24.13.101`
3) trap script ./script/deploy_wordpress_lxc6.sh <xxx> af.
   `./scripts/deploy_wordpress_lxc6.sh`  
    *xxx = te creeeren container nummer. Nu is wordpress geinstalleerd en klaar voor gebruik*
4) *Optionele stap* ivm tailscale: Zorg ervoor dat tailscale auth key in de volgende map staat; /tmp/tailscale.env
    `echo 'TAILSCALE_AUTH_KEY=tskey-auth-.....' > /tmp/tailscale.env`
5) *Optionele stap* ivm tailscale: trap ./script/create_tailgate_container.sh af, !vul de goede containernaam in.
   `./scripts/create_tailgate_container.sh`
   `<tailgate-ip>/wordpress weergeeft wordpress`  
7) Doe dit zo vaak als de klant wil, eventueel met een for-loop.
    6x doen met unieke CT namen *(vb 131 t/m 136)*
8) Koppel aan netstat monitor met monitor.sh
   `<tailgate-ip>:19999 weergeeft de monitor`

Nog te doen:
- In script koppelen aan monitor
- Script beter maken
- Script naar Ansible
- video maken van uitrol

## Werkwijze aanmaken VM CRM HA, klant 2

Met de scripts van klant 2 kan nu de VM gemaakt worden.
`Scripts\Klant2`

1) Log in als root op control node (pve00)
   `ssh root@100.94.185.45` (tailgate)
2) Log in op managed node als beheerder op pve02
   `ssh beheerder@10.24.13.102`
3) scripts uit te werken

Nog te doen:
- scripten van VM aanmaken
- In script koppelen aan monitor
- Script naar Ansible
- video maken van uitrol
- controleren van HA (cgroup?)
- video maken van HA uitval