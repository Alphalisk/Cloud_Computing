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

1) Log in als root op control node (pve00)
   `ssh root@100.94.185.45` (tailgate)
2) Log in op managed node als beheerder op pve01 of pve02
   `ssh beheerder@10.24.13.101`
3) trap script ./script/deploy_wordpress_lxc4.sh <xxx> af.
   `./scripts/deploy_wordpress_lxc4.sh`  
    *xxx = te creeeren container nummer. Nu is wordpress geinstalleerd en klaar voor gebruik*
4) *Optionele stap* ivm tailscale: Zorg ervoor dat tailscale auth key in de volgende map staat; /tmp/tailscale.env
    `echo 'TAILSCALE_AUTH_KEY=tskey-auth-.....' > /tmp/tailscale.env`
5) *Optionele stap* ivm tailscale: trap ./script/create_tailgate_container.sh af.
   `./scripts/create_tailgate_container.sh`  
7) Doe dit zo vaak als de klant wil, eventueel met een for-loop.
    6x doen met unieke CT namen *(vb 130 t/m 135)*

Nog te doen:
- Koppelen aan monitor
- Script beter maken
- Script naar Ansible
- video maken van uitrol

## Werkwijze aanmaken VM CRM HA, klant 2