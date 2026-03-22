# 🌍 Localization Test MCP

**Model Context Protocol pour tests automatisés de localisation**

## 🎯 Objectif

Automatiser complètement les tests de localisation pour PrivExpensIA avec:
- Screenshots automatiques pour chaque langue
- Analyse visuelle avec GPT-4o-mini
- Rapports HTML détaillés
- Détection des problèmes (clés underscore, textes manquants)

## 🚀 Installation

```bash
# Aller dans le dossier MCP
cd ~/moulinsart/agents/localization-test-mcp

# Installer les dépendances Python
pip3 install requests

# Rendre le script exécutable
chmod +x test_runner.py
```

## 📋 Usage

### Test complet (8 langues)
```bash
python3 test_runner.py
```

### Test rapide (une langue)
```bash
python3 test_runner.py --quick fr
python3 test_runner.py --quick de
```

### Voir le rapport
```bash
open reports/latest.html
```

## 🔧 Configuration

Éditer `config.json` pour:
- Ajouter/modifier des langues
- Changer les textes attendus
- Modifier le simulateur cible

## 📊 Ce que le MCP teste

Pour chaque langue:
1. ✅ Présence des textes traduits
2. ❌ Absence de clés underscore (settings_label, etc.)
3. 🌍 Détection correcte de la langue
4. 📸 Screenshot pour validation visuelle

## 🤖 Intégration avec les agents

### Pour TINTIN (QA Lead)
```bash
# Après chaque build
cd ~/moulinsart/agents/localization-test-mcp
python3 test_runner.py
# Si échec, envoyer le rapport à DUPONT2
```

### Pour DUPONT2 (Localisation)
```bash
# Après chaque modification de localisation
cd ~/moulinsart/agents/localization-test-mcp
python3 test_runner.py --quick fr  # Test rapide
# Si OK, tester toutes les langues
python3 test_runner.py
```

## 🔄 Workflow recommandé

1. **DUPONT2** modifie les localisations
2. **DUPONT2** lance `test_runner.py --quick fr`
3. Si OK, **DUPONT2** lance le test complet
4. **TINTIN** valide avec le test complet
5. **TINTIN** envoie le rapport à NESTOR

## 📈 Métriques

Le rapport HTML montre:
- Taux de succès global (%)
- Statut par langue (PASS/FAIL)
- Screenshots pour validation visuelle
- Détails des problèmes détectés

## 🐛 Troubleshooting

### "Simulator not found"
```bash
# Vérifier le nom du simulateur
xcrun simctl list devices | grep tintin
# Mettre à jour config.json avec le bon nom
```

### "API key invalid"
```bash
# Vérifier la clé OpenAI dans config.json
# Tester avec: curl -H "Authorization: Bearer SK_KEY" https://api.openai.com/v1/models
```

### "App doesn't launch"
```bash
# Vérifier le bundle ID
xcrun simctl launch booted com.minhtam.ExpenseAI
# Si erreur, rebuilder l'app
```

## 📝 Notes importantes

- **TOUJOURS** lancer les tests après modification de localisation
- **JAMAIS** merger sans que tous les tests passent
- **DOCUMENTER** tout changement dans ce README

## 🎖️ Crédits

Créé par TINTIN (QA Lead) pour l'équipe Moulinsart
Utilise GPT-4o-mini pour l'analyse visuelle