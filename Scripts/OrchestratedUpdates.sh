#!/bin/bash
for node in pve00 pve01 pve02
do
  echo "Updating $node"
  ssh root@$node 'apt update && apt upgrade -y'
done