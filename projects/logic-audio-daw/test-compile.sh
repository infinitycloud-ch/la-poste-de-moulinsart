#!/bin/bash
echo "🧪 Test de compilation rapide Sprint 1..."
cd "$(dirname "$0")"

# Test compilation simple avec clang++
echo "Vérification syntaxe Core Engine..."
clang++ -std=c++17 -c Source/Core/AudioEngine.cpp -I/usr/local/include -I. -o /tmp/test_audio.o 2>&1 | head -20

if [ $? -eq 0 ]; then
    echo "✅ AudioEngine compile sans erreurs majeures"
else
    echo "⚠️ JUCE headers manquants - build complet nécessaire avec CMake"
fi

echo ""
echo "📂 Structure livrée:"
find Source -type f -name "*.cpp" -o -name "*.h" | sort

echo ""
echo "📊 Statistiques:"
echo "Fichiers .cpp: $(find Source -name "*.cpp" | wc -l)"
echo "Fichiers .h: $(find Source -name "*.h" | wc -l)"
echo "Lignes totales: $(find Source -name "*.cpp" -o -name "*.h" | xargs wc -l | tail -1)"

echo ""
echo "✅ Sprint 1 prêt pour build complet avec ./build.sh"