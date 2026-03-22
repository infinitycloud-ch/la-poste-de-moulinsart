#!/bin/bash
# Script de lancement MonoCLI - PANDA Portal Integration
# TOURNESOL1 - Équipe TMUX
# Sprint 7 - Toutes variantes modèles locaux

cd ~/moulinsart/projects/mono-cli

echo "🚀 MonoCLI - PANDA Portal Integration"
echo "📡 Backend: PANDA Portal (localhost:3010)"
echo "🧠 Planification séquentielle + 10 tools MonoCLI"
echo "---------------------------------------------------"

# Vérifier PANDA Portal
if curl -s http://localhost:3010/api/models/ollama >/dev/null 2>&1; then
    echo "✅ PANDA Portal disponible"
else
    echo "❌ PANDA Portal indisponible - Démarrer PANDA Portal d'abord"
    exit 1
fi

echo ""
echo "🤖 Modèles locaux disponibles via PANDA:"
echo "1. mixtral     → dolphin-mixtral:latest (26GB, LLaMA)"
echo "2. qwen        → qwen2.5:3b (1.9GB, Qwen2)"
echo "3. qwen3       → deepresearch:latest (2.4GB, Qwen3) ✨"
echo "4. deepresearch → deepresearch:latest (2.4GB, Qwen3)"
echo ""

# Menu de sélection
echo "Choisir un modèle:"
echo "[1] mixtral (puissant, 26GB)"
echo "[2] qwen (léger, 1.9GB)"
echo "[3] qwen3 (nouveau, 2.4GB) ✨"
echo "[4] deepresearch (alias qwen3)"
echo "[q] Quitter"
echo ""

read -p "Votre choix [1-4/q]: " choice

case $choice in
    1)
        MODEL="mixtral"
        echo "🧠 Lancement avec Mixtral (modèle puissant)..."
        ;;
    2)
        MODEL="qwen"
        echo "⚡ Lancement avec Qwen 2.5:3b (léger et rapide)..."
        ;;
    3)
        MODEL="qwen3"
        echo "✨ Lancement avec Qwen3 (nouveau modèle)..."
        ;;
    4)
        MODEL="deepresearch"
        echo "🔬 Lancement avec DeepResearch (Qwen3)..."
        ;;
    q|Q)
        echo "👋 Au revoir!"
        exit 0
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "🎯 Commande exécutée:"
echo "python3 -m mono.cli.main chat --backend panda --model $MODEL --tools"
echo ""

# Lancement MonoCLI avec PANDA Portal
python3 -m mono.cli.main chat --backend panda --model $MODEL --tools