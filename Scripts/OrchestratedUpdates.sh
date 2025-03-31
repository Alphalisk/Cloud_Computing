#!/bin/bash

# Lijst met alle node-hostnamen of IP-adressen
NODES=("pve00" "pve01" "pve02")

# Updatecommando dat op elke node uitgevoerd wordt
for NODE in "${NODES[@]}"
do
  echo "🔄 Bezig met updates op $NODE..."
  ssh root@$NODE 'apt update && apt upgrade -y && apt autoremove -y'
  echo "✅ Updates voltooid op $NODE"
  echo "------------------------------"
done
