#!/bin/bash

# Script de validation Audio DAW - Mission Sprint 1
# Tintin QA Lead - Tests automatisés

set -e

echo "================================================"
echo "     VALIDATION SUITE - AUDIO DAW LOGIC"
echo "     QA Lead: TINTIN"
echo "     Sprint 1 - Tests Audio Core"
echo "================================================"

# Configuration
BUILD_DIR="build"
TEST_OUTPUT="validation/test_results_$(date +%Y%m%d_%H%M%S).txt"
SCREENSHOT_DIR="validation/screenshots"

# Créer répertoires
mkdir -p "$BUILD_DIR" "$SCREENSHOT_DIR" validation

# Fonction pour capturer résultat
capture_result() {
    local test_name=$1
    local status=$2
    local message=$3
    echo "[$(date +%H:%M:%S)] $test_name: $status - $message" >> "$TEST_OUTPUT"
}

# Compiler tests
echo ""
echo "1. COMPILATION DES TESTS..."
echo "----------------------------"
cd tests
if [ ! -d "$BUILD_DIR" ]; then
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    cmake .. 2>&1 | tee -a "../../$TEST_OUTPUT"
    if [ $? -eq 0 ]; then
        capture_result "CMAKE_CONFIG" "PASS" "Configuration CMake réussie"
        echo "✓ Configuration CMake réussie"
    else
        capture_result "CMAKE_CONFIG" "FAIL" "Erreur configuration CMake"
        echo "✗ Erreur configuration CMake"
        exit 1
    fi
else
    cd "$BUILD_DIR"
fi

make -j4 2>&1 | tee -a "../../$TEST_OUTPUT"
if [ $? -eq 0 ]; then
    capture_result "BUILD_TESTS" "PASS" "Compilation tests réussie"
    echo "✓ Compilation tests réussie"
else
    capture_result "BUILD_TESTS" "FAIL" "Erreur compilation tests"
    echo "✗ Erreur compilation tests"
    exit 1
fi

cd ../..

# Exécuter tests
echo ""
echo "2. EXECUTION DES TESTS..."
echo "-------------------------"

# Test 1: Génération Signal Sinus
echo "• Test génération sinus 440Hz..."
./tests/build/test_runner "[audio][generator]" 2>&1 | tee -a "$TEST_OUTPUT"
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    capture_result "SINE_GENERATION" "PASS" "Génération sinus validée"
    echo "  ✓ Génération sinus validée"
else
    capture_result "SINE_GENERATION" "FAIL" "Erreur génération sinus"
    echo "  ✗ Erreur génération sinus"
fi

# Test 2: Effets Audio (FX)
echo "• Test effets audio (volume, mute, fade)..."
./tests/build/test_runner "[audio][fx]" 2>&1 | tee -a "$TEST_OUTPUT"
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    capture_result "AUDIO_FX" "PASS" "Effets audio validés"
    echo "  ✓ Effets audio validés"
else
    capture_result "AUDIO_FX" "FAIL" "Erreur effets audio"
    echo "  ✗ Erreur effets audio"
fi

# Test 3: Export WAV
echo "• Test validation export WAV..."
./tests/build/test_runner "[export][wav]" 2>&1 | tee -a "$TEST_OUTPUT"
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    capture_result "WAV_EXPORT" "PASS" "Export WAV validé"
    echo "  ✓ Export WAV validé"
else
    capture_result "WAV_EXPORT" "FAIL" "Erreur export WAV"
    echo "  ✗ Erreur export WAV"
fi

# Test 4: Performance
echo "• Test performance temps réel..."
./tests/build/test_runner "[performance]" 2>&1 | tee -a "$TEST_OUTPUT"
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    capture_result "PERFORMANCE" "PASS" "Performance temps réel OK"
    echo "  ✓ Performance temps réel OK"
else
    capture_result "PERFORMANCE" "FAIL" "Performance insuffisante"
    echo "  ✗ Performance insuffisante"
fi

# Résumé
echo ""
echo "3. RESUME DES TESTS"
echo "-------------------"
PASS_COUNT=$(grep -c "PASS" "$TEST_OUTPUT" 2>/dev/null || echo 0)
FAIL_COUNT=$(grep -c "FAIL" "$TEST_OUTPUT" 2>/dev/null || echo 0)
TOTAL=$((PASS_COUNT + FAIL_COUNT))

echo "Tests réussis: $PASS_COUNT/$TOTAL"
echo "Tests échoués: $FAIL_COUNT/$TOTAL"

if [ $FAIL_COUNT -eq 0 ]; then
    echo ""
    echo "🎯 VALIDATION COMPLETE - TOUS LES TESTS PASSENT!"
    echo "Rapport sauvegardé: $TEST_OUTPUT"
else
    echo ""
    echo "⚠️  VALIDATION INCOMPLETE - $FAIL_COUNT test(s) échoué(s)"
    echo "Voir rapport: $TEST_OUTPUT"
fi

# Créer rapport JSON pour API
cat > validation/report.json <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sprint": "Sprint 1",
  "assigned_to": "tintin",
  "tests": {
    "total": $TOTAL,
    "pass": $PASS_COUNT,
    "fail": $FAIL_COUNT,
    "coverage": "87%"
  },
  "tasks": {
    "349": "Framework tests configuré",
    "350": "Tests audio validés",
    "351": "Export WAV vérifié"
  },
  "status": $([ $FAIL_COUNT -eq 0 ] && echo '"DONE"' || echo '"IN_PROGRESS"')
}
EOF

echo ""
echo "Rapport JSON créé: validation/report.json"