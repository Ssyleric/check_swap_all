# `check_swap_all.sh` — Audit du swap sur VMs & CTs Proxmox (PVE)

🔍 **Objectif**  
Lister, en un seul passage, l’état du **swap** et de la **mémoire** pour un ensemble de **VMs** et de **containers LXC** sur un hôte **Proxmox VE**.  
- Pour les **VMs** : utilise le **QEMU Guest Agent** afin d’exécuter des commandes invité (`swapon --show`, `free -h`).  
- Pour les **CTs** : exécute directement via `pct exec` les mêmes commandes.

---

## 🧩 Fonctionnement (résumé)
1. Définit deux tableaux d’identifiants : `VM_IDS=(...)` et `CT_IDS=(...)`.  
2. Pour chaque **VM** :  
   - Vérifie que la VM est **allumée** (`qm status <id>`).  
   - Tente une commande via **QEMU Agent** (`qm guest cmd <id> get-osinfo`).  
   - Si OK, exécute sur l’invité :  
     ```bash
     echo '[swapon]'; swapon --show || echo 'Aucun swap'; echo; echo '[free]'; free -h
     ```
   - Sinon, signale que l’agent est **inactif/non installé**.  
3. Pour chaque **CT** :  
   - Vérifie que le CT est **running** (`pct status <id>`).  
   - Exécute les mêmes commandes avec `pct exec`.

---

## ✅ Prérequis
- Hôte **Proxmox VE** avec accès **root** (pas de `sudo` en PVE).  
- **QEMU Guest Agent** **installé & actif** dans les **VMs** (sinon seules les CTs seront auditées).  
  - **Linux (Debian/Ubuntu)** dans la VM :  
    ```bash
    apt update && apt install -y qemu-guest-agent
    systemctl enable --now qemu-guest-agent
    ```
  - **Côté PVE (optionnel)** : assurez-vous que **Options ▸ QEMU Agent = Activé** dans la conf de la VM.  
- Les containers LXC doivent avoir **bash**, `swapon`, `free` disponibles (paquets `procps`, `util-linux` selon distro).

---

## 📦 Installation
1. Copier le script dans votre dépôt de scripts, ex. `/home/scripts` :  
   ```bash
   install -m 0755 check_swap_all.sh /home/scripts/check_swap_all.sh
   ```
2. **Adapter les listes** d’IDs en tête de script :  
   ```bash
   VM_IDS=(100 101 102 103 104)
   CT_IDS=(20009000 20232400 20308096 20401080 20508080)
   ```

> 💡 Conformément à votre organisation, `/home/scripts` est le dossier de référence.

---

## ▶️ Utilisation
Exécuter en **root** sur l’hôte PVE :  
```bash
/home/scripts/check_swap_all.sh
```
**Extrait de sortie typique :**
```
======================
🔍 CHECK SWAP - VMs
======================

➡️ VM 102
✅ QEMU Agent actif sur VM 102
[swapon]
NAME      TYPE SIZE USED PRIO
/dev/sda2 file   4G 1.2G   -2

[free]
               total        used        free      shared  buff/cache   available
Mem:           16Gi        3.1Gi        8.7Gi        183Mi        4.0Gi         12Gi
Swap:         4.0Gi        1.2Gi        2.8Gi

➡️ VM 103
⚠️ VM 103 allumée mais QEMU agent inactif ou non installé

======================
🔍 CHECK SWAP - CTs
======================

➡️ CT 20009000
✅ CT 20009000 en cours d'exécution
[swapon]
Aucun swap

[free]
               total        used        free      shared  buff/cache   available
Mem:          2048Mi        350Mi       1400Mi         50Mi        297Mi       1720Mi
Swap:            0B           0B           0B

➡️ CT 20308096
⚠️ CT 20308096 éteint
```

---

## ⏱️ Planification (cron) — audit régulier
Pour un **rapport manuel** ponctuel, lancer le script à la demande.  
Pour un **contrôle régulier**, vous pouvez planifier un cron **journalier à 08:00** (exécution locale, sortie visible dans `mail` root ou redirigée vers un fichier) :  
```cron
0 8 * * * /home/scripts/check_swap_all.sh >> /var/log/check_swap_all.log 2>&1
```
- Supprimez la redirection `>>` si vous préférez recevoir l’email cron root.  
- Pour un run **silencieux** (uniquement log) : gardez la redirection comme ci-dessus.

---

## 🧰 Dépannage
- **“QEMU agent inactif”** sur VM :  
  - Vérifier l’installation/service côté VM (`systemctl status qemu-guest-agent`).  
  - Vérifier l’option **QEMU Agent** activée dans la conf PVE de la VM.  
- **Commandes introuvables** dans CT/VM :  
  - Installer `procps` pour `free`, et vérifier `util-linux` pour `swapon`.  
- **Temps de réponse long** sur certaines VMs :  
  - L’appel `qm guest exec` attend la fin de la commande ; sous forte charge, la sortie peut être retardée.

---

## 🛡️ Sécurité & impacts
- Le script est **read-only** côté invités (consultation d’état), sans modification de configuration.  
- Aucune opération n’est lancée si la VM/CT n’est pas **running**.  
- Les appels invités via **QEMU Agent** exigent une VM **fiablement configurée** (agent en service).

---

## 🗑️ Désinstallation
```bash
rm -f /home/scripts/check_swap_all.sh
rm -f /var/log/check_swap_all.log  # si vous aviez activé la redirection cron
```

---

## ✍️ Note
- Script compatible PVE standards (`qm`, `pct`).  
- Aucune dépendance externe hors PVE et outils système de base dans l’invité.  
- Idéal comme **check rapide** avant d’activer une purge automatisée (cf. `swap_cleaner.sh`).

---

## 📄 Licence
Utilisation interne. Adapter selon votre politique de sécurité.
