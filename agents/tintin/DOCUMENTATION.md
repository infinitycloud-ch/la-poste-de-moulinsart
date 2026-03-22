# DOCUMENTATION TINTIN - QA Lead PrivExpensIA
> Documentation technique complète pour l'Opération Codex Moulinsart
> Date: 14 Janvier 2025
> Auteur: TINTIN (QA Lead)

## 1. INFRASTRUCTURE DE TEST

### Suites de Tests Disponibles

#### UITests - Tests Interface Utilisateur
- **Chemin**: `~/moulinsart/PrivExpensIA/PrivExpensIAUITests/`
- **Objectif**: Valider navigation, interactions et affichage
- **Coverage**: ~60%
- **Fichiers principaux**:
  - `PrivExpensIAUITests.swift`: Tests navigation principale
  - `PrivExpensIAUITestsLaunchTests.swift`: Tests de lancement
- **Commande**: `xcodebuild test -scheme PrivExpensIA -only-testing:PrivExpensIAUITests`

#### AIInferenceTests - Tests Modèle Qwen
- **Chemin**: `~/moulinsart/PrivExpensIA/Tests/AIInferenceTests.swift`
- **Objectif**: Précision extraction et performance
- **Coverage**: ~80%
- **Tests critiques**:
  - `testInitialModelLoadTime()`: Temps chargement < 10s
  - `testAverageInferenceTime()`: Inférence moyenne < 300ms
  - `testMemoryUsageDuringInference()`: Mémoire < 150MB
  - `testPerformanceInference()`: Mesures avec blocks
- **Métriques validées**:
  - Chargement: 2.34 secondes ✅
  - Inférence: 222ms moyenne ✅
  - Mémoire: 128.6MB ✅

#### LocalizationTests - Tests Internationalization
- **Chemin**: `~/moulinsart/PrivExpensIA/Tests/LocalizationScreenshotTests.swift`
- **Objectif**: Traductions complètes sans clés visibles
- **Coverage**: 100% (8 langues)
- **Langues supportées**:
  - Français (fr, fr-CH)
  - Anglais (en)
  - Allemand (de, de-CH)
  - Italien (it, it-CH)
  - Espagnol (es)
  - Japonais (ja)
  - Coréen (ko)
  - Slovaque (sk)
- **Points de validation**:
  - LocalizationManager.shared.localized() partout
  - Pas de String(localized:) (bug connu)
  - Changement langue immédiat dans Settings

#### CoreDataTests - Tests Persistance
- **Chemin**: `~/moulinsart/PrivExpensIA/Tests/CoreDataTests.swift`
- **Objectif**: CRUD, migration, performances
- **Coverage**: ~70%
- **Tests essentiels**:
  - `testCreateExpense()`: Création avec tous champs
  - `testFetchExpenses()`: Récupération @FetchRequest
  - `testDeleteExpense()`: Suppression complète
  - `testUpdateExpense()`: Modification et sauvegarde
  - `testReceiptImagePersistence()`: Images dans receiptImageData
- **Validation**:
  - Entité Expense avec 15+ attributs
  - Relation avec ExtractedData
  - Migration automatique v1→v2

#### IntegrationTests - Tests End-to-End
- **Chemin**: `~/moulinsart/PrivExpensIA/Tests/IntegrationFlowTest.swift`
- **Objectif**: Flow complet scan→save→display
- **Coverage**: ~70%
- **Flux validé**:
  1. Scanner → OCR (VisionKit)
  2. OCR → AIExtractionService
  3. AI → QwenModelManager/MLXService
  4. Fallback → ExpenseParser (regex)
  5. Save → CoreDataManager
  6. Display → ExpenseListGlassView
- **Performance**: < 300ms bout en bout

### Coverage Global
```
├── UI Tests: ~60%
├── Business Logic: ~80%
├── Localization: 100%
├── Core Data: ~70%
└── Integration: ~70%
```

## 2. TESTS DE LOCALISATION

### Scripts Automatisés

#### i18n_snapshots.sh
- **Chemin**: `~/moulinsart/PrivExpensIA/scripts/i18n_snapshots.sh`
- **Fonction**: Génère 40 screenshots (8 langues × 5 vues)
- **Output**: `/validation/localization_auto/`
- **Utilisation**:
```bash
cd ~/moulinsart/PrivExpensIA
./scripts/i18n_snapshots.sh
```
- **Vues capturées**:
  - Home (ExpenseListGlassView)
  - Scanner (ScannerGlassView)
  - Settings (SettingsView)
  - Detail (ExpenseDetailGlassView)
  - Beta Feedback (BetaFeedbackView)

#### auto_localization_test.sh
- **Chemin**: `~/moulinsart/PrivExpensIA/scripts/auto_localization_test.sh`
- **Fonction**: Test rapide FR/EN uniquement
- **Output**: Console + rapport JSON
- **Utilisation**:
```bash
./scripts/auto_localization_test.sh
```
- **Validation**: Détecte clés non traduites

#### test_localization_complete.sh
- **Chemin**: `~/moulinsart/PrivExpensIA/scripts/test_localization_complete.sh`
- **Fonction**: Test exhaustif toutes langues
- **Output**: `/validation/localization_complete_report.html`
- **Points de contrôle**:
  - 260+ clés par langue
  - Pas de fallback vers Base.lproj
  - Cohérence des traductions

#### test_localisation_fr_en.sh
- **Chemin**: `~/moulinsart/PrivExpensIA/scripts/test_localisation_fr_en.sh`
- **Fonction**: Test manuel guidé avec prompts
- **Output**: Screenshots interactifs
- **Utilisation**: Pour validation humaine

### Rapport HTML - Interprétation

#### Structure du Rapport
```html
validation/localization_complete_report.html
├── Summary (taux de réussite global)
├── Per-Language Results
│   ├── Missing Keys (❌ ÉCHEC si présent)
│   ├── Untranslated Keys (⚠️ WARNING)
│   └── Screenshots (validation visuelle)
└── Recommendations
```

#### Points de Validation
1. **Aucune clé visible**: Pas de "home.title" ou "settings_key"
2. **Traductions cohérentes**: Même concept = même traduction
3. **UI non cassée**: Pas de truncation ou overlap
4. **Format nombres**: Respect des conventions locales

### Ajout de Nouveaux Tests

#### Procédure Standard
1. **Modifier le script shell**:
```bash
# Ajouter dans i18n_snapshots.sh
xcrun simctl io booted screenshot "nouvelle_vue_${lang}.png"
```

2. **Ajouter commands simctl**:
```bash
# Navigation vers nouvelle vue
xcrun simctl launch booted com.minhtam.ExpenseAI
xcrun simctl openurl booted "expenseai://nouvelle-vue"
```

3. **Générer rapport**:
```bash
./scripts/generate_html_report.sh > nouveau_rapport.html
```

4. **Commit avec preuves**:
```bash
git add validation/screenshots/
git commit -m "Tests: Ajout validation nouvelle vue (8 langues)"
```

## 3. SCRIPTS DE VALIDATION

### validate.sh - Script Principal
- **Chemin**: `~/moulinsart/PrivExpensIA/scripts/validate.sh`
- **Fonction**: Validation complète du projet
- **Étapes**:
  1. Clean DerivedData
  2. Build complet (xcodebuild)
  3. Tests unitaires
  4. Tests UI
  5. Génération rapport HTML
- **Output**: `validation_report_$(date).html`
- **Durée**: ~5-10 minutes

### Scripts Spécialisés

#### build_and_test.sh
- **Fonction**: Build + tous tests
- **Utilisation**: CI/CD ou validation locale
- **Output**: Exit code 0 si succès
```bash
./scripts/build_and_test.sh || echo "ÉCHEC"
```

#### check_translations.sh
- **Fonction**: Vérification .strings files
- **Détecte**:
  - Clés manquantes
  - Duplicatas
  - Format invalide
  - Encodage incorrect
```bash
./scripts/check_translations.sh fr.lproj/Localizable.strings
```

#### generate_proof.sh
- **Fonction**: Création preuves visuelles
- **Génère**:
  - Screenshots annotés
  - GIF animations
  - PDF rapport complet
```bash
./scripts/generate_proof.sh "Sprint 3 Validation"
```

### CI/CD Pipeline

#### GitHub Actions (Non configuré)
```yaml
# .github/workflows/ios.yml
- Pourrait être ajouté
- Build sur chaque PR
- Tests automatiques
- Deploy TestFlight
```

#### Fastlane (Non configuré)
```ruby
# fastlane/Fastfile
- lane :test
- lane :beta
- lane :release
```

#### Xcode Cloud (Non activé)
- Intégration Apple native
- Build sur push
- Distribution automatique

### Checklist Pre-Release

#### Build & Compilation
- [ ] Build sans warning (0 warnings)
- [ ] Pas d'erreurs Analyze (Cmd+Shift+B)
- [ ] Architectures: arm64 + x86_64
- [ ] Minimum iOS: 17.0
- [ ] Swift 5.9 compatible

#### Tests
- [ ] Tous tests unitaires passent (100%)
- [ ] Tests UI passent (critiques uniquement)
- [ ] Tests performance dans limites
- [ ] Pas de memory leaks (Instruments)

#### Localisation
- [ ] 8 langues validées complètement
- [ ] Screenshots de validation générés
- [ ] Pas de clés hardcodées visibles
- [ ] Format dates/nombres correct par locale

#### Performance
- [ ] Scan → Résultat < 3 secondes
- [ ] Lancement app < 1 seconde
- [ ] Mémoire idle < 50MB
- [ ] Mémoire avec Qwen < 150MB
- [ ] Pas de main thread blocks

#### Sécurité
- [ ] Pas de clés API hardcodées
- [ ] Keychain pour données sensibles
- [ ] Pas de logs en production
- [ ] Privacy manifest à jour
- [ ] Permissions minimales requises

#### Documentation
- [ ] README.md à jour
- [ ] CHANGELOG.md complété
- [ ] Screenshots App Store prêts
- [ ] Description multilingue

## LEÇONS APPRISES

### Échecs Passés

#### Problème Localisation "POLI DE VERRE"
- **Symptôme**: Clés affichées au lieu des traductions
- **Cause**: String(localized:) ne fonctionne pas avec LocalizationManager custom
- **Solution**: Toujours utiliser LocalizationManager.shared.localized()
- **Prévention**: Regex search pour String(localized dans pre-commit

#### Build Failures Sprint 1
- **Symptôme**: "Cannot find type 'Expense'"
- **Cause**: CoreData génération non automatique
- **Solution**: Editor → Create NSManagedObject Subclass
- **Prévention**: Script de vérification CoreData

#### Performance Qwen
- **Symptôme**: 300MB au démarrage
- **Cause**: Modèle chargé immédiatement
- **Solution**: Lazy loading au premier scan
- **Validation**: Memory profiler dans Instruments

### Best Practices Établies

1. **Toujours tester sur device physique** pour performance réelle
2. **Screenshots systématiques** pour chaque feature
3. **Validation en cascade**: Unit → Integration → UI → Manual
4. **Documentation immédiate** des bugs trouvés
5. **Communication par email** avec traçabilité complète

## CONTACTS & SUPPORT

- **QA Lead**: tintin@moulinsart.local
- **Dev Swift**: dupont1@moulinsart.local
- **Dev Support**: dupont2@moulinsart.local
- **Chef Orchestre**: nestor@moulinsart.local

---
*Documentation créée pour l'Opération Codex Moulinsart*
*Dernière mise à jour: 14 Janvier 2025, 23:24*
*Par: TINTIN, QA Lead*