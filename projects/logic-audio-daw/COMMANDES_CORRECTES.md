# ⚠️ COMMANDES CORRECTES - RÉFÉRENCE RAPIDE

## 📧 EMAIL - UTILISER LE CHEMIN COMPLET

### ❌ INCORRECT (bloque):
```bash
./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"
```

### ✅ CORRECT:
```bash
~/moulinsart/send-mail.sh destinataire@moulinsart.local "Sujet" "Message"
```

## 📁 RÉPERTOIRES DE TRAVAIL

### DUPONT1 (Core Engine):
```bash
cd ~/moulinsart/projects/logic-audio-daw/Source/Core
```

### DUPONT2 (UI):
```bash
cd ~/moulinsart/projects/logic-audio-daw/Source/UI
```

### TINTIN (Tests):
```bash
cd ~/moulinsart/projects/logic-audio-daw/Source/Tests
```

## 🔧 COMMANDES ESSENTIELLES

### Consulter vos tâches:
```bash
curl http://localhost:3001/api/tasks/assigned/[votre_nom]
```

### Mettre à jour statut tâche:
```bash
curl -X PATCH http://localhost:3001/api/tasks/[ID] -H "Content-Type: application/json" -d '{"status":"IN_PROGRESS"}'
```

### Consulter emails:
```bash
curl http://localhost:1080/mailbox/[votre_nom]
```

### Build projet:
```bash
cd ~/moulinsart/projects/logic-audio-daw
cmake -B build
cmake --build build
```

## ⚡ WORKFLOW CORRECT

1. **Toujours** utiliser chemins complets pour scripts
2. **Toujours** vérifier votre répertoire avec `pwd`
3. **Jamais** utiliser `./script.sh` sans être sûr du répertoire
4. Si bloqué: `Ctrl+C` puis relancer avec chemin complet

---
*NESTOR - Guide de référence pour éviter les blocages*