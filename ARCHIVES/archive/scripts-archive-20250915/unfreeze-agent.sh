#!/bin/bash

# Script pour débloquer un agent gelé
# Usage: ./unfreeze-agent.sh [0|1|2|3]

AGENT=$1
SESSION="moulinsart-agents"

case $AGENT in
    0) NAME="NESTOR" ; DIR="nestor" ;;
    1) NAME="TINTIN" ; DIR="tintin" ;;
    2) NAME="DUPONT1" ; DIR="dupont1" ;;
    3) NAME="DUPONT2" ; DIR="dupont2" ;;
    *) echo "Usage: $0 [0|1|2|3]" ; exit 1 ;;
esac

echo "🔄 Déblocage de $NAME (panel $AGENT)..."

# 1. Forcer l'arrêt
tmux send-keys -t "$SESSION:agents.$AGENT" C-c
sleep 1

# 2. Clear
tmux send-keys -t "$SESSION:agents.$AGENT" "clear" Enter

# 3. Naviguer
tmux send-keys -t "$SESSION:agents.$AGENT" "cd ~/moulinsart/agents/$DIR" Enter

# 4. Relancer Claude
tmux send-keys -t "$SESSION:agents.$AGENT" "claude --dangerously-skip-permissions" Enter

echo "✅ $NAME débloqué!"