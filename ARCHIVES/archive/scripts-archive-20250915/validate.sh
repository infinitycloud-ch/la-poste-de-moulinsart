#!/bin/bash
# validate.sh - Script de validation OBLIGATOIRE avant de dire "c'est fait"
# Auteur: NESTOR - Pour éviter les validations bâclées

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VALIDATION AUTOMATIQUE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROJECT_DIR="~/moulinsart/PrivExpensIA"
RESULTS_DIR="/tmp/validation_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

cd "$PROJECT_DIR"

# 1. BUILD TEST
echo ""
echo "1️⃣ Test de compilation..."
if xcodebuild -project PrivExpensIA.xcodeproj -scheme PrivExpensIA -sdk iphonesimulator build 2>&1 | tee "$RESULTS_DIR/build.log" | grep -q "BUILD SUCCEEDED"; then
    echo "✅ Build réussi"
    BUILD_STATUS="✅ SUCCESS"
else
    echo "❌ BUILD FAILED - Voir $RESULTS_DIR/build.log"
    BUILD_STATUS="❌ FAILED"
    exit 1
fi

# 2. LANCER SIMULATEUR
echo ""
echo "2️⃣ Préparation du simulateur..."
DEVICE="iPhone 16"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator

# 3. INSTALLER L'APP
echo "Installation de l'app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PrivExpensIA-*/Build/Products/Debug-iphonesimulator -name "PrivExpensIA.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ App non trouvée - Build d'abord!"
    exit 1
fi
xcrun simctl install booted "$APP_PATH"

# 4. TESTS MULTI-LANGUES
echo ""
echo "3️⃣ Tests de localisation..."
LANGUAGES=("en:English" "fr:Français" "de:Deutsch")

for lang_pair in "${LANGUAGES[@]}"; do
    IFS=':' read -r code name <<< "$lang_pair"
    echo "   Testing $name ($code)..."

    # Changer la langue et lancer
    xcrun simctl launch --terminate-running-app booted com.privexpensia --args -AppleLanguages "($code)"
    sleep 3

    # Screenshot
    xcrun simctl io booted screenshot "$RESULTS_DIR/screen_${code}.png"
    echo "   📸 Screenshot pris: screen_${code}.png"
done

# 5. GÉNÉRATION DU RAPPORT HTML
echo ""
echo "4️⃣ Génération du rapport..."
cat > "$RESULTS_DIR/report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Validation Report - PrivExpensIA</title>
    <style>
        body { font-family: -apple-system, sans-serif; padding: 20px; background: #f5f5f5; }
        h1 { color: #333; border-bottom: 3px solid #007AFF; padding-bottom: 10px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 8px; }
        .success { background: #d4edda; color: #155724; }
        .failed { background: #f8d7da; color: #721c24; }
        .screenshots { display: flex; gap: 20px; flex-wrap: wrap; margin: 20px 0; }
        .screenshot { text-align: center; }
        .screenshot img { width: 300px; border: 2px solid #ddd; border-radius: 8px; }
        .checklist { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .checklist li { margin: 10px 0; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>📊 Validation Report - PrivExpensIA</h1>
    <p class="timestamp">Generated: $(date)</p>

    <div class="status $([ "$BUILD_STATUS" = "✅ SUCCESS" ] && echo "success" || echo "failed")">
        <h2>Build Status: $BUILD_STATUS</h2>
    </div>

    <h2>🌍 Localisation Tests</h2>
    <div class="screenshots">
        <div class="screenshot">
            <h3>English</h3>
            <img src="screen_en.png" alt="English">
        </div>
        <div class="screenshot">
            <h3>Français</h3>
            <img src="screen_fr.png" alt="Français">
        </div>
        <div class="screenshot">
            <h3>Deutsch</h3>
            <img src="screen_de.png" alt="Deutsch">
        </div>
    </div>

    <div class="checklist">
        <h2>✅ Validation Checklist</h2>
        <ul>
            <li>☐ Build compile sans erreur</li>
            <li>☐ Textes changent selon la langue</li>
            <li>☐ Pas de clés "key.missing" visibles</li>
            <li>☐ UI correctement alignée</li>
            <li>☐ Toutes les pages testées</li>
        </ul>
    </div>

    <div class="checklist">
        <h2>⚠️ Points à vérifier manuellement</h2>
        <ul>
            <li>Les textes sont-ils VRAIMENT traduits?</li>
            <li>Y a-t-il des textes hardcodés restants?</li>
            <li>L'UI s'adapte-t-elle aux textes longs?</li>
        </ul>
    </div>
</body>
</html>
EOF

# 6. OUVRIR LE RAPPORT
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VALIDATION TERMINÉE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Résultats dans: $RESULTS_DIR"
echo "📊 Ouverture du rapport..."
open "$RESULTS_DIR/report.html"

echo ""
echo "⚠️  IMPORTANT: Vérifiez VISUELLEMENT que:"
echo "   1. Les textes changent vraiment"
echo "   2. Pas de 'key.missing'"
echo "   3. L'UI n'est pas cassée"
echo ""
echo "NE PAS dire 'c'est fait' sans avoir vérifié!"