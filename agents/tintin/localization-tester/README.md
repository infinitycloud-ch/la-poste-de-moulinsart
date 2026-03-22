# 🚀 Tintin's Localization Tester

Système automatisé de test de localisation pour PrivExpensIA utilisant GPT-4o-mini.

## Structure

```
localization-tester/
├── config.py           # Configuration (API key, simulateur, etc.)
├── core/
│   ├── simulator.py    # Contrôle du simulateur
│   └── vision_analyzer.py  # Analyse visuelle avec GPT-4o-mini
├── tests/
│   ├── quick_test.py   # Test rapide (Français seulement)
│   └── full_test.py    # Test complet (8 langues)
├── reports/            # Rapports JSON et HTML
└── tintin_test.py      # Interface principale
```

## Usage

### Test rapide (Français seulement)
```bash
cd ~/moulinsart/agents/tintin/localization-tester
python3 tintin_test.py --mode quick
```

### Test complet (8 langues)
```bash
python3 tintin_test.py --mode full
```

### Avec rapport HTML
```bash
python3 tintin_test.py --mode quick --report
```

## Ce que le système fait

1. **Lance l'app** dans le simulateur "tintin"
2. **Navigate vers Settings**
3. **Analyse avec GPT-4o-mini** pour détecter:
   - Les clés avec underscores (settings_label, etc.)
   - Le language picker
   - Les zones blanches/vides
4. **Change la langue** (Français pour test rapide, ou les 8 langues)
5. **Vérifie chaque écran** (Home, Expenses, Scanner, Statistics, Settings)
6. **Génère un rapport** avec verdict PASS/FAIL

## Avantages

- **Rapide**: GPT-4o-mini analyse en <2 secondes par screenshot
- **Précis**: Détecte les underscores et textes non traduits
- **Modulaire**: Facile d'ajouter de nouveaux tests
- **Documenté**: Rapports JSON détaillés

## Personnalisation

Pour tester une langue spécifique, modifie `config.py` ou crée un nouveau test dans `tests/`.