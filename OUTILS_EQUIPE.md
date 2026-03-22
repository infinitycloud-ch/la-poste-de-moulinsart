# 🧐 BOÎTE À OUTILS - ÉQUIPE MOULINSART

## 🔴 RÈGLE D'OR
**TOUS les agents doivent utiliser ces outils pour la validation**
**NE JAMAIS dire "c'est fait" sans avoir exécuté les validations**

---

## 🎨 OUTILS DE VALIDATION PRIVEXPENSIA

### 1. 🌍 Validation i18n (Localisation)
```bash
# Test complet des 8 langues avec screenshots
cd ~/moulinsart/PrivExpensIA
./scripts/i18n_snapshots.sh

# Générer le rapport HTML de validation
./generate_i18n_report.sh
```
**Résultats**: `/proof/i18n/` contient tous les screenshots et rapports

### 2. ✅ Validation Générale
```bash
# Script de validation global
~/moulinsart/validate.sh
```
**But**: Compile, teste et génère des screenshots de validation

### 3. 🔍 Extraction de Code
```bash
# Extraire tout le code Swift dans un seul fichier
cd ~/moulinsart/PrivExpensIA
python3 get_code.py
# Choisir option 2 pour générer le markdown
```
**Résultat**: `code_output_[timestamp].md` avec tout le code

### 4. 🏗️ Build et Génération Xcode
```bash
# Générer le projet Xcode
cd ~/moulinsart/PrivExpensIA
xcodegen generate

# Build en ligne de commande
xcodebuild -project PrivExpensIA.xcodeproj \
           -scheme PrivExpensIA \
           -sdk iphonesimulator \
           clean build
```

---

## 📧 OUTILS DE COMMUNICATION

### 1. 📨 Envoi d'Email Simple
```bash
# Message court
~/moulinsart/send-mail.sh \
  tintin@moulinsart.local \
  "Sujet" \
  "Message court"
```

### 2. 📢 Broadcast à Tous
```bash
# Message à tous les agents
~/moulinsart/broadcast.sh "Message urgent"
```

### 3. 📝 Messages Longs
```bash
# Pour les contenus volumineux
cat > /tmp/mission.txt << 'EOF'
Contenu très long...
EOF

# Informer l'agent
./send-mail.sh agent@moulinsart.local \
  "Mission" \
  "Lire /tmp/mission.txt"
```

---

## 🔧 OUTILS DE GESTION D'AGENTS

### 1. 🚀 Démarrage/Arrêt
```bash
# Démarrer tous les agents
~/moulinsart/start-agents.sh

# Arrêter tous les agents
~/moulinsart/stop-agents.sh

# Statut des agents
~/moulinsart/status-agents.sh
```

### 2. 🔍 Monitoring
```bash
# Surveiller les agents en temps réel
~/moulinsart/monitor-agents.sh

# Ouvrir les fenêtres des agents
~/moulinsart/open-agents.sh
```

### 3. 🆘 Urgences
```bash
# Débloquer un agent gelé
~/moulinsart/unfreeze-agent.sh [nom_agent]

# Réveiller un agent
~/moulinsart/wake-agent.sh [nom_agent]
```

---

## 📊 OUTILS DE TEST SPÉCIFIQUES

### Scripts dans `/scripts/`
```bash
cd ~/moulinsart/PrivExpensIA/scripts/

# Point de contrôle Sprint 2
./checkpoint_sprint2.sh

# Diagnostic du bundle
./diagnose_bundle.sh

# Reconstruction complète automatique
./full_auto_rebuild.sh

# Garde de localisation
./localization_guard.sh

# Validation des xcstrings
./xcstrings_validator.sh
```

---

## 📁 STRUCTURE DES PREUVES

Toutes les validations génèrent des preuves dans:
```
~/moulinsart/PrivExpensIA/
├── proof/
│   ├── i18n/           # Screenshots de localisation
│   │   ├── app_*.png   # Screenshots par langue
│   │   ├── results_*.md
│   │   └── validation_report_*.html
│   ├── build/          # Logs de compilation
│   └── tests/          # Résultats de tests
```

---

## 🔴 PROTOCOLE DE VALIDATION OBLIGATOIRE

### Pour CHAQUE tâche terminée:

1. **Exécuter le script de validation approprié**
2. **Vérifier TOUS les screenshots** (pas un échantillon)
3. **Générer le rapport HTML**
4. **Ouvrir et vérifier le rapport**
5. **Documenter les résultats**

### Commande type pour validation complète:
```bash
# 1. Tester
cd ~/moulinsart/PrivExpensIA
./scripts/i18n_snapshots.sh

# 2. Générer rapport
./generate_i18n_report.sh

# 3. Le rapport s'ouvre automatiquement
# 4. Vérifier VISUELLEMENT tous les résultats
```

---

## 📝 NOTES IMPORTANTES

1. **JAMAIS de raccourcis** - Toujours validation complète
2. **TOUJOURS des preuves** - Screenshots obligatoires
3. **RAPPORT HTML** - Doit être généré et ouvert
4. **DOCUMENTATION** - Tout doit être tracé

---

## 🆘 EN CAS DE PROBLÈME

1. **Build échoue**: Vérifier `project.yml` et relancer `xcodegen`
2. **Localisation cassée**: Utiliser `localization_guard.sh`
3. **Tests échouent**: Consulter les logs dans `/proof/`
4. **Agent bloqué**: Utiliser `unfreeze-agent.sh`

---

*Document maintenu par NESTOR - À partager avec TOUS les agents*
*Dernière mise à jour: 13 Septembre 2025*