# 🌍 PRD - Automatisation i18n PrivExpensIA
## Version FINALE - Action Immédiate

### 🎯 OBJECTIF
Corriger définitivement la localisation et créer un système automatisé réutilisable.

### ⚠️ PROBLÈME CRITIQUE
- Les fichiers .lproj ne sont PAS dans le bundle compilé
- L'app affiche les clés (underscores) au lieu des traductions
- 7/8 langues en échec (seul le français fonctionne)

### 📱 ENVIRONNEMENT
- **Simulateur**: iPhone 16 Pro Max (alias "tintin")
- **UDID**: `9D1B772E-7D9B-4934-A7F4-D2829CEB0065`
- **iOS**: 18.6
- **Bundle ID**: `com.minhtam.ExpenseAI`

### 🔧 PLAN D'ACTION

#### PHASE 1: Corrections Code (DUPONT1)
1. **Vérifier Target Membership** dans Xcode:
   ```
   ✅ Base.lproj/Localizable.strings
   ✅ fr.lproj/Localizable.strings
   ✅ de.lproj/Localizable.strings
   ✅ it.lproj/Localizable.strings
   ✅ en.lproj/Localizable.strings
   ✅ ja.lproj/Localizable.strings
   ✅ ko.lproj/Localizable.strings
   ✅ sk.lproj/Localizable.strings
   ✅ es.lproj/Localizable.strings
   ```

2. **Modifier LocalizationManager.swift**:
   ```swift
   // Utiliser Bundle.main, PAS de chemins dev
   if let url = Bundle.main.url(forResource: "Localizable", 
                                withExtension: "strings",
                                subdirectory: "\(languageFile).lproj") {
       // Charger depuis le bundle compilé
   }
   ```

3. **Ajouter debug temporaire dans PrivExpensIAApp.swift**:
   ```swift
   init() {
       print("🌍 Preferred:", Bundle.main.preferredLocalizations)
       print("🌍 AppleLanguages:", UserDefaults.standard.array(forKey: "AppleLanguages") ?? [])
       print("🌍 Bundle languages:", Bundle.main.localizations)
   }
   ```

4. **Clean Build**: Product → Clean Build Folder (⇧⌘K)

#### PHASE 2: Validation Traductions (DUPONT2)
1. Vérifier TOUS les fichiers Localizable.strings
2. S'assurer que TOUTES les clés ont des traductions
3. Format correct: `"key" = "value";`

#### PHASE 3: Script Automatisation (TINTIN)
Créer `~/moulinsart/PrivExpensIA/scripts/i18n_snapshots.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
DEVICE="9D1B772E-7D9B-4934-A7F4-D2829CEB0065"
APP_ID="com.minhtam.ExpenseAI"
PROJECT_DIR="~/moulinsart/PrivExpensIA"
OUT="$PROJECT_DIR/proof/i18n"

# Langues à tester
langs=('fr-CH:fr_CH' 'de-CH:de_CH' 'it-CH:it_CH' 'en:en_US' 'ja:ja_JP' 'ko:ko_KR' 'sk:sk_SK' 'es:es_ES')

# Créer dossier de sortie
mkdir -p "$OUT"

# Build l'app
echo "🔨 Building app..."
cd "$PROJECT_DIR"
xcodegen generate
xcodebuild -project PrivExpensIA.xcodeproj \
           -scheme PrivExpensIA \
           -destination "id=$DEVICE" \
           -configuration Debug \
           clean build > "$OUT/build_log.txt" 2>&1

# Boot simulateur
echo "📱 Booting simulator..."
xcrun simctl boot "$DEVICE" || true
xcrun simctl bootstatus "$DEVICE" -b

# Test chaque langue
echo "🌍 Testing languages..."
for pair in "${langs[@]}"; do
  LANG="${pair%%:*}"
  LOCALE="${pair##*:}"
  echo "  Testing $LANG ($LOCALE)..."
  
  # Terminer l'app si elle tourne
  xcrun simctl terminate "$DEVICE" "$APP_ID" || true
  
  # Lancer avec langue spécifique
  xcrun simctl launch "$DEVICE" "$APP_ID" \
    --args -AppleLanguages "($LANG)" \
           -AppleLocale "$LOCALE"
  
  # Attendre que l'UI se charge
  sleep 3
  
  # Screenshot
  xcrun simctl io "$DEVICE" screenshot "$OUT/app_${LANG}.png"
done

echo "✅ i18n snapshots generated in $OUT"
```

#### PHASE 4: Tests & Validation
1. Exécuter le script
2. Vérifier TOUS les screenshots
3. Aucune clé brute visible = SUCCESS
4. Une seule clé visible = ÉCHEC → retour Phase 1

### 📊 LIVRABLES
1. **Dossier `proof/i18n/`** avec 8 screenshots
2. **`build_log.txt`** sans erreurs
3. **`i18n_fix_notes.md`** avec:
   - Liste des fichiers corrigés
   - Captures Target Membership
   - Output des prints debug
4. **Script automatisé** fonctionnel et documenté

### ⏰ TIMELINE
- **Phase 1**: 30 minutes (DUPONT1)
- **Phase 2**: 20 minutes (DUPONT2)
- **Phase 3**: 15 minutes (TINTIN)
- **Phase 4**: 15 minutes (TINTIN)
- **TOTAL**: 1h20

### 🚀 RÈGLES D'EXÉCUTION
1. **ACTION IMMÉDIATE** - Pas d'attente
2. **AUTONOMIE TOTALE** - Corriger sans validation
3. **RAPPORT UNIQUE** - Un seul email final avec tout
4. **ZÉRO BOUCLE** - Si échec, corriger et recommencer

### ✅ CRITÈRES DE SUCCÈS
- [ ] 8 langues fonctionnelles
- [ ] Aucune clé underscore visible
- [ ] Script automatisé réutilisable
- [ ] Documentation complète
- [ ] Build sans warning