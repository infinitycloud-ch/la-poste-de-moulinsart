#!/bin/bash

# 🛑 STOP ALL AGENTS
echo "🛑 Arrêt des agents..."

# Tuer la session tmux
tmux kill-session -t moulinsart-agents 2>/dev/null

# Tuer tous les processus claude restants
pkill -f "claude-desktop --agent" 2>/dev/null

echo "✅ Tous les agents sont arrêtés"