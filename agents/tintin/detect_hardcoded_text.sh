#!/bin/bash
# Script détection texte en dur - TINTIN QA
# Pour validation S1-QA-02 Internationalisation

PROJECT_PATH="~/moulinsart/projects/plato"
ENGINE_PATH="$PROJECT_PATH/Engine"

echo "=== DETECTION TEXTE EN DUR - PLATO ==="
echo "Path: $ENGINE_PATH"
echo "Date: $(date)"
echo

if [ ! -d "$ENGINE_PATH" ]; then
    echo "[ERROR] Dossier Engine non trouvé. Structure pas encore créée par NESTOR."
    exit 1
fi

echo "Recherche chaînes en dur dans /Engine/Views..."
echo

# Recherche strings littérales (entre guillemets) dans Swift
grep -r "Text(\s*\"" "$ENGINE_PATH/Views" 2>/dev/null || echo "Aucun fichier Views trouvé"

echo
echo "Recherche autres patterns suspects..."

# Recherche autres patterns
grep -r "LocalizedStringKey(\s*\"" "$ENGINE_PATH" 2>/dev/null || echo "OK - Pas de LocalizedStringKey direct"
grep -r "NSLocalizedString(\s*\"" "$ENGINE_PATH" 2>/dev/null || echo "OK - Pas de NSLocalizedString direct"

echo
echo "=== VALIDATION COMPLETE ==="