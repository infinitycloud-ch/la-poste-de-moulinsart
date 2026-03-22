# 📖 PLAYBOOK - Localisation iOS Automatisée
## Guide Réutilisable pour Tous Projets iOS

### 🎯 Objectif
Ce playbook documente la méthode DÉFINITIVE pour implémenter et tester la localisation dans une app iOS, avec automatisation complète.

### ✅ Checklist Pré-Requis
- [ ] Xcode 15+ installé
- [ ] xcodegen installé (`brew install xcodegen`)
- [ ] Simulateur iOS configuré
- [ ] Structure de projet avec `project.yml`

### 📁 Structure Requise
```
MonProjet/
├── project.yml
├── MonApp/
│   ├── Base.lproj/
│   │   └── Localizable.strings
│   ├── fr.lproj/
│   │   └── Localizable.strings
│   ├── de.lproj/
│   │   └── Localizable.strings
│   ├── en.lproj/
│   │   └── Localizable.strings
│   └── [autres langues].lproj/
└── scripts/
    └── i18n_snapshots.sh
```

### 🔧 Étape 1: Configuration Xcode

#### Dans project.yml:
```yaml
targets:
  MonApp:
    settings:
      INFOPLIST_KEY_CFBundleDisplayName: "$(PRODUCT_NAME)"
      INFOPLIST_KEY_CFBundleDevelopmentRegion: "en"
    sources:
      - path: MonApp
        includes:
          - "**/*.swift"
          - "**/*.lproj/*.strings"
```

#### Target Membership (CRITIQUE):
1. Ouvrir Xcode
2. Sélectionner CHAQUE fichier .strings
3. Cocher la case Target Membership
4. Vérifier dans Build Phases → Copy Bundle Resources

### 💻 Étape 2: Code LocalizationManager

```swift
import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguageCode")
            loadLocalizations()
        }
    }
    
    private var localizations: [String: String] = [:]
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "en"
        loadLocalizations()
    }
    
    func loadLocalizations() {
        localizations.removeAll()
        
        // IMPORTANT: Utiliser Bundle.main, JAMAIS de chemins dev
        if let url = Bundle.main.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: "\(currentLanguage).lproj"
        ) {
            // Parser le fichier
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                parseLocalizationFile(contents)
            }
        } else {
            // Fallback vers les clés par défaut
            loadDefaultLocalizations()
        }
    }
    
    func localized(_ key: String) -> String {
        return localizations[key] ?? key
    }
}

// Extension pour faciliter l'usage
extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
```

### 🌍 Étape 3: Fichiers de Localisation

#### Format Localizable.strings:
```
/* Settings */
"settings_title" = "Réglages";
"settings_language" = "Langue";
"settings_currency" = "Devise";

/* Common */
"save" = "Enregistrer";
"cancel" = "Annuler";
```

⚠️ **IMPORTANT**: 
- Format exact: `"key" = "value";`
- Point-virgule OBLIGATOIRE
- Encodage UTF-8
- Pas d'espaces avant/après =

### 📱 Étape 4: Script d'Automatisation

Copier le script depuis `~/moulinsart/PrivExpensIA/scripts/i18n_snapshots.sh`

Adapter ces variables:
```bash
DEVICE="[VOTRE_UDID]"  # xcrun simctl list devices
APP_ID="[VOTRE_BUNDLE_ID]"
PROJECT_DIR="[VOTRE_PROJET]"
```

### 🧪 Étape 5: Tests Automatisés

#### Obtenir l'UDID du simulateur:
```bash
xcrun simctl list devices | grep Booted
```

#### Lancer les tests:
```bash
./scripts/i18n_snapshots.sh
```

#### Résultats attendus:
- `proof/i18n/` avec screenshots par langue
- `build_log_*.txt` sans erreurs
- `results_*.md` avec tableau de validation
- `i18n_fix_notes_*.md` pour documentation

### 🐛 Troubleshooting

#### Problème: Clés underscores visibles
**Solution**: Vérifier Target Membership des .lproj

#### Problème: Toujours même langue
**Solution**: Vérifier que LocalizationManager utilise Bundle.main

#### Problème: Build failed
**Solution**: Clean Build Folder (⇧⌘K)

#### Problème: Simulateur pas trouvé
**Solution**: Utiliser UDID au lieu du nom

### 📊 Métriques de Succès
- [ ] 0 clés underscore visibles
- [ ] Toutes langues distinctes
- [ ] Build sans warning
- [ ] Script < 2 minutes
- [ ] Documentation complète

### 🚀 Optimisations Avancées

#### String Catalogs (iOS 17+):
Remplacer .strings par .xcstrings pour:
- Interface Xcode intégrée
- Validation automatique
- Pluriels natifs

#### SwiftUI moderne:
```swift
Text("settings_title")  // Utilise automatiquement .xcstrings
```

### 📝 Template de Rapport
```markdown
# Rapport i18n - [Projet]
Date: [Date]
Version: [Version]

## Langues testées
- [ ] FR: ✅/❌
- [ ] DE: ✅/❌
- [ ] EN: ✅/❌
[...]

## Issues
- Aucune / Liste

## Screenshots
Voir dossier proof/i18n/

## Validation
Approuvé par: [Nom]
```

### 🎯 Réutilisation sur Nouveau Projet

1. Copier ce playbook
2. Adapter les chemins et bundle ID
3. Copier le script i18n_snapshots.sh
4. Créer structure .lproj
5. Implémenter LocalizationManager
6. Lancer script
7. Valider avec screenshots

---

**Ce playbook est LA référence pour l'i18n iOS chez Moulinsart.**
Version: 1.0
Auteur: NESTOR
Date: 13/09/2025