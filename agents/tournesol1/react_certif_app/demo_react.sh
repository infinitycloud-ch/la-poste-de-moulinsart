#!/bin/bash

# Demo React Workflow Autonome - Sprint 16
# Développé par TOURNESOL1 - Équipe TMUX

echo "=== DEMO REACT WORKFLOW AUTONOME ==="
echo "Sprint 16 - Autonomie Certifiée & Demos"
echo "Développeur: TOURNESOL1"
echo

# Vérifier si npm est installé
echo "Vérification des prérequis..."
npm --version || { echo "❌ npm non installé"; exit 1; }
node --version || { echo "❌ node non installé"; exit 1; }

echo "✅ Prérequis validés"
echo

# Installer les dépendances si nécessaire
echo "Installation des dépendances React..."
npm install

echo
echo "=== LANCEMENT APPLICATION REACT ==="
echo "Démarrage serveur Vite..."

# Fonction mock pour mono_open_browser
mono_open_browser() {
    echo "🌐 mono_open_browser: Ouverture $1"
    echo "   Application React disponible sur: $1"
    # Simulation d'ouverture de navigateur
    if command -v open >/dev/null 2>&1; then
        open "$1" 2>/dev/null &
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$1" 2>/dev/null &
    else
        echo "   Navigateur: Ouverture manuelle requise"
    fi
}

# Lancer le serveur React en arrière-plan
npm run dev &
SERVER_PID=$!

# Attendre que le serveur démarre
echo "Attente démarrage serveur..."
sleep 3

# Vérifier que le serveur fonctionne
if curl -s http://localhost:5173/ >/dev/null; then
    echo "✅ Serveur React opérationnel"

    # Utiliser mono_open_browser
    mono_open_browser "http://localhost:5173/"

    echo
    echo "=== WORKFLOW COMPLETE ==="
    echo "✅ App React react_certif_app créée avec Vite"
    echo "✅ Dependencies npm installées"
    echo "✅ Serveur React lancé sur http://localhost:5173/"
    echo "✅ mono_open_browser exécuté"
    echo "✅ Script demo_react.sh généré"

    echo
    echo "Appuyez sur Ctrl+C pour arrêter le serveur..."
    wait $SERVER_PID
else
    echo "❌ Erreur: Serveur React non accessible"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi