# Cloud_Computing
Repository voor opdrachten Cloud Computing.

Inventaris:
- Het verantwoordingsverslag voor de opdrachten wordt in het bestand *Verantwoordingsverslag.md* bijgehouden.
- De map Screenhots bevat bewijsvoering
- De map Scripts bevat bash scripts
  - modulaire scripts zijn korte scripts voor installatie specifieke onderdelen.
  - definitieve script zijn alle modulaire scripts samengevoegd tot een volledig werkend geheel. 
- De map Playbooksbevat de .yml files voor managed en control nodes onderhoud.
- Bijgeleverd zijn 2 video's buiten github:
  - Volledig_automatische_installatie_Container.mp4
  - Volledig_automatische_installatie_VM.mp4

**Netwerkconfiguratie:**
|nodenaam|IP intern    |Type node    |IP Tailscale  |
|--------|-------------|-------------|--------------|
|pve00   |10.24.13.100 |control node |100.94.185.45 |
|pve01   |10.24.13.101 |managed node |100.104.126.78|
|pve02   |10.24.13.102 |managed node |100.84.145.8  |

## Werkwijze aanmaken LXM container voor wordpress, klant 1

Met de scripts van klant 1 kunnen de containers gemaakt worden.
`Scripts\Klant1\Definitieve script\Volledige_installatie_LXC.sh`

1) Log in als root op control node (pve00)
   `ssh root@100.94.185.45` (tailgate)
2) Log in op managed node als beheerder op pve01
   `ssh beheerder@10.24.13.101`
3) trap volledige uitrolscript af (github en node hebben exact dezelfde script):
   - hier op Github: `Scripts\Klant1\Definitieve script\Volledige_installatie_LXC.sh xxx`
   - op de node pve01 `.\scripts\definitief\deployLXC.sh xxx*`  
    *xxx = te creeeren container nummer. Gebruik een uniek nieuw nummer!*
4) Doe dit zo vaak als de klant wil, eventueel met een for-loop.
    6x doen met unieke CT namen *(vb 131 t/m 136)*
5) Na uitvoering is de CT als volgt bereikbaar:
   - `<tailgate-ip>` weergeeft apache
   - `<tailgate-ip>/wordpress` weergeeft wordpress
   - `<tailgate-ip>:19999` weergeeft de netdata monitor`

## Werkwijze aanmaken VM CRM HA, klant 2

Met de scripts van klant 2 kan nu de VM gemaakt worden.
`Scripts\Klant2\Definitieve_Script\Volledige_installatieVM.sh`

1) Log in als root op control node (pve00)
   `ssh root@100.94.185.45` (tailgate)
2) Log in op managed node als beheerder op pve01 of pve02
   `ssh beheerder@10.24.13.102`
3) trap volledige uitrolscript af (github en node hebben exact dezelfde script):
   - hier op Github: `Scripts\Klant1\Definitieve script\Volledige_installatie_VM.sh xxx`
   - op de node pve01 `.\scripts\definitief\deployVM.sh xxx*`  
    *xxx = te creeeren container nummer. Gebruik een uniek nieuw nummer!*
4) Na uitvoering is de VM als volgt bereikbaar:
   - `<tailgate-ip>` weergeeft apache
   - `<tailgate-ip>/wordpress` weergeeft wordpress + CRM
   - `<tailgate-ip>:19999` weergeeft de netdata monitor`
