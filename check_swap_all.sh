#!/bin/bash

VM_IDS=(100 101 102 103 104)
CT_IDS=(20009000 20232400 20308096 20401080 20508080)

echo -e "\n======================"
echo "🔍 CHECK SWAP - VMs"
echo "======================"

for vmid in "${VM_IDS[@]}"; do
  echo -e "\n➡️ VM $vmid"

  # Vérifie si la VM est allumée
  if qm status "$vmid" | grep -q "status: running"; then

    # Teste si l’agent répond
    if qm guest cmd "$vmid" get-osinfo &>/dev/null; then
      echo "✅ QEMU Agent actif sur VM $vmid"
      qm guest exec "$vmid" -- bash -c "echo '[swapon]'; swapon --show || echo 'Aucun swap'; echo; echo '[free]'; free -h"
    else
      echo "⚠️ VM $vmid allumée mais QEMU agent inactif ou non installé"
    fi

  else
    echo "⚠️ VM $vmid éteinte"
  fi
done

echo -e "\n======================"
echo "🔍 CHECK SWAP - CTs"
echo "======================"

for ctid in "${CT_IDS[@]}"; do
  echo -e "\n➡️ CT $ctid"

  if pct status "$ctid" | grep -q "status: running"; then
    echo "✅ CT $ctid en cours d'exécution"
    pct exec "$ctid" -- bash -c "echo '[swapon]'; swapon --show || echo 'Aucun swap'; echo; echo '[free]'; free -h"
  else
    echo "⚠️ CT $ctid éteint"
  fi
done
