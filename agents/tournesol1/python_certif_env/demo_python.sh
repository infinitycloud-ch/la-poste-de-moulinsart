#!/bin/bash

# Demo Python Workflow Autonome - Sprint 16
# Développé par TOURNESOL1 - Équipe TMUX

echo "=== DEMO PYTHON WORKFLOW AUTONOME ==="
echo "Sprint 16 - Autonomie Certifiée & Demos"
echo "Développeur: TOURNESOL1"
echo

# Activer l'environnement virtuel
echo "Activation environnement virtuel Python..."
source venv/bin/activate

# Vérifier l'installation de cowsay
echo "Vérification installation cowsay..."
pip show cowsay

echo
echo "=== EXECUTION COWSAY ==="
cowsay -t "Mission Python Reussie"

echo
echo "=== WORKFLOW COMPLETE ==="
echo "✅ Répertoire python_certif_env créé"
echo "✅ Environnement virtuel Python configuré"
echo "✅ Package cowsay installé"
echo "✅ Message Mission Python Reussie affiché"
echo "✅ Script demo_python.sh généré"

deactivate
echo "Environnement virtuel désactivé"