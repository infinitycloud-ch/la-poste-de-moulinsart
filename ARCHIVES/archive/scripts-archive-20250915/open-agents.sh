#!/bin/bash

# 🖥️ OPEN AGENTS IN TERMINAL
# Script simple pour ouvrir Terminal avec les agents

# Vérifier si tmux est déjà actif
if tmux has-session -t moulinsart-agents 2>/dev/null; then
    echo "🔄 Session déjà active, attachement..."
    osascript -e 'tell application "Terminal" to do script "tmux attach-session -t moulinsart-agents"'
else
    echo "🚀 Lancement des agents..."
    
    # Créer la session tmux
    tmux new-session -d -s moulinsart-agents -n agents
    
    # Panel 0: NESTOR (bas gauche)
    tmux send-keys -t moulinsart-agents:0 'cd ~/moulinsart/agents/nestor && echo "🎩 NESTOR starting..." && bun run index.ts' C-m
    
    # Panel 1: TINTIN (haut gauche)
    tmux split-window -t moulinsart-agents:0 -v
    tmux send-keys -t moulinsart-agents:0.1 'cd ~/moulinsart/agents/tintin && echo "🚀 TINTIN starting..." && bun run index.ts' C-m
    
    # Panel 2: DUPONT1 (haut droite)
    tmux split-window -t moulinsart-agents:0 -h
    tmux send-keys -t moulinsart-agents:0.2 'cd ~/moulinsart/agents/dupont1 && echo "🎨 DUPONT1 starting..." && bun run index.ts' C-m
    
    # Panel 3: DUPONT2 (bas droite)
    tmux select-pane -t moulinsart-agents:0.0
    tmux split-window -t moulinsart-agents:0 -h
    tmux send-keys -t moulinsart-agents:0.1 'cd ~/moulinsart/agents/dupont2 && echo "🔍 DUPONT2 starting..." && bun run index.ts' C-m
    
    # Ouvrir Terminal avec la session attachée
    osascript -e 'tell application "Terminal" to do script "tmux attach-session -t moulinsart-agents"'
fi

echo "✅ Terminal ouvert avec les agents!"