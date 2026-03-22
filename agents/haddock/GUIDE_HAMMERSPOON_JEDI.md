# GUIDE D'UTILISATION - MODE JEDI HAMMERSPOON
## Sprint 21 - Intégration Complète

**Date**: 2025-10-04
**Statut**: OPÉRATIONNEL

---

## 1. INSTALLATION EFFECTUÉE

### Fichiers créés/modifiés
- ✅ `~/.hammerspoon/jedi-menu.lua` - Module Jedi
- ✅ `~/.hammerspoon/init.lua` - Chargement via `require("jedi-menu")`
- ✅ Configuration rechargée automatiquement

---

## 2. INTERFACE UTILISATEUR

### Menu dans la barre de menu
Cherchez l'icône **🔴** (point rouge) dans votre barre de menu macOS.

### Structure du menu
```
🔴 MODE JEDI - SPRINT 21
├── 🚀 MISSIONS
│   └── ⚡ Premier Vol Solo (Test)
├── 📺 Session tmux
├── 📋 Voir les logs
├── 🧹 Nettoyer sandbox
└── ℹ️ État: 🟢 Prêt / 🟡 En cours
```

---

## 3. RACCOURCIS CLAVIER

### Hotkeys globaux configurés

| Raccourci | Action | Description |
|-----------|--------|-------------|
| **⌘⇧⌃J** | Lancer mission | Execute "Premier Vol Solo" |
| **⌘⇧⌃T** | Terminal tmux | Ouvre session jedi-sprint21 |
| **⌘⇧⌃L** | Logs | Ouvre dossier des logs |

**Note**: ⌘ = Cmd, ⇧ = Shift, ⌃ = Ctrl

---

## 4. UTILISATION

### Méthode 1: Via le menu
1. Cliquez sur **🔴** dans la barre de menu
2. Sélectionnez **⚡ Premier Vol Solo (Test)**
3. Terminal s'ouvre automatiquement
4. La mission s'exécute

### Méthode 2: Via raccourci clavier
1. Appuyez sur **⌘⇧⌃J**
2. La mission démarre immédiatement
3. Terminal s'ouvre avec l'exécution

### Méthode 3: Session tmux directe
1. **⌘⇧⌃T** pour ouvrir la session tmux
2. Vous êtes dans l'environnement Mode Jedi
3. Lancez manuellement: `./execute.sh ./missions_log/001_premier_vol.sh`

---

## 5. INDICATEURS VISUELS

### États du système
- **🟢 Prêt** : Aucune mission en cours
- **🟡 En cours** : Mission active
- **🔴 Point menu** : Mode Jedi actif

### Notifications Hammerspoon
- Alert au lancement: "🔴 Lancement: 001_premier_vol"
- Alert tmux: "📺 Session tmux: jedi-sprint21"
- Alert nettoyage: "🧹 Sandbox nettoyé"

---

## 6. WORKFLOW TYPIQUE

### Test rapide
1. **⌘⇧⌃J** - Lance Premier Vol Solo
2. Observe l'exécution dans Terminal
3. Vérifiez le cowsay "Mode Jedi Certifié!"
4. **⌘⇧⌃L** - Consultez les logs

### Développement de mission
1. Créez nouveau script dans `missions_log/`
2. **⌘⇧⌃T** - Ouvrez session tmux
3. Testez avec `./execute.sh`
4. Ajoutez au menu Hammerspoon si succès

### Nettoyage
1. Menu **🔴** → **🧹 Nettoyer sandbox**
2. Supprime tous les artefacts de test
3. Prêt pour nouvelle mission

---

## 7. STRUCTURE DES FICHIERS

```
~/moulinsart/projects/mono-cli/
├── execute.sh              # Exécuteur avec garde-fous
├── missions_log/
│   ├── 001_premier_vol.sh  # Mission test
│   └── execution_*.log     # Logs d'exécution
└── sandbox/
    └── mission_001_*/      # Artefacts créés
```

---

## 8. DÉPANNAGE

### Si le menu 🔴 n'apparaît pas
1. Ouvrez Console Hammerspoon: **⌘⌥⌃H**
2. Tapez: `hs.reload()`
3. Vérifiez les erreurs

### Si la mission ne démarre pas
1. Vérifiez que tmux est installé: `brew install tmux`
2. Vérifiez les permissions: `chmod +x execute.sh`
3. Testez manuellement dans Terminal

### Si Terminal ne s'ouvre pas
1. Autorisez Hammerspoon dans Préférences Système
2. Sécurité & Confidentialité → Accessibilité
3. Cochez Hammerspoon

---

## 9. EXTENSION DU SYSTÈME

### Ajouter une nouvelle mission
1. Créez `missions_log/002_nouvelle_mission.sh`
2. Éditez `jedi-menu.lua`
3. Ajoutez entrée menu:
```lua
{ title = "🆕 Nouvelle Mission", fn = function()
    executeMission("002_nouvelle_mission")
end }
```
4. Rechargez Hammerspoon

---

## 10. COMMANDES DE TEST

### Test immédiat depuis Terminal
```bash
# Vérifier que tout fonctionne
cd ~/moulinsart/projects/mono-cli
./execute.sh ./missions_log/001_premier_vol.sh
```

### Test via Hammerspoon Console
```lua
-- Dans la console Hammerspoon
hs.execute("cd ~/moulinsart/projects/mono-cli && ./execute.sh ./missions_log/001_premier_vol.sh")
```

---

## RÉSUMÉ

**Mode Jedi est maintenant intégré à votre bureau macOS.**

- Menu **🔴** toujours accessible
- Hotkeys **⌘⇧⌃J/T/L** configurés
- Missions exécutables en 1 clic
- Terminal s'ouvre automatiquement
- Logs et monitoring intégrés

**Prêt pour production!**