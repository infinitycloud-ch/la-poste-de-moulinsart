#!/bin/bash

# Script pour visualiser toutes les sessions d'agents dans tmux

echo "📺 Ouverture du moniteur multi-agents..."

# Créer une nouvelle session de monitoring
tmux new-session -d -s monitor -n "Agents-Monitor"

# Diviser l'écran en 4 panneaux
tmux split-window -h -t monitor
tmux split-window -v -t monitor:0.0
tmux split-window -v -t monitor:0.2

# Attacher chaque session à un panneau
tmux send-keys -t monitor:0.0 "tmux attach -t nestor" Enter
tmux send-keys -t monitor:0.1 "tmux attach -t nestor-test" Enter
tmux send-keys -t monitor:0.2 "tmux attach -t tintin" Enter
tmux send-keys -t monitor:0.3 "tmux attach -t dupont1" Enter

# Attacher à la session monitor
echo "✅ Pour voir tous les agents: tmux attach -t monitor"
echo "📝 Navigation:"
echo "   • Ctrl+B puis flèches : changer de panneau"
echo "   • Ctrl+B puis D : détacher (sortir sans fermer)"
echo "   • Ctrl+B puis Z : zoom sur un panneau"

tmux attach -t monitor