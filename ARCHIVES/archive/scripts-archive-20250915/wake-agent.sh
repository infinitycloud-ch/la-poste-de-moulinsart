#!/bin/bash
# Script pour réveiller un agent avec notification directe

AGENT="$1"
MESSAGE="${2:-Réveil! Tu as du travail}"

# Mapping des agents aux panels
case $AGENT in
    nestor) PANEL=0 ;;
    tintin) PANEL=1 ;;
    dupont1) PANEL=2 ;;
    dupont2) PANEL=3 ;;
    *) echo "Agent inconnu: $AGENT"; exit 1 ;;
esac

# Envoyer plusieurs Enter pour nettoyer
tmux send-keys -t moulinsart-agents:agents.$PANEL C-c  # Ctrl+C pour interrompre
sleep 0.1
tmux send-keys -t moulinsart-agents:agents.$PANEL Enter
sleep 0.1
tmux send-keys -t moulinsart-agents:agents.$PANEL Enter
sleep 0.1

# Afficher le message de réveil (visuel)
tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '🔔 RÉVEIL SYSTÈME'" Enter
tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '$MESSAGE'" Enter
tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
sleep 0.5

# IMPORTANT: Envoyer le message comme INPUT pour Claude
tmux send-keys -t moulinsart-agents:agents.$PANEL "$MESSAGE" Enter

echo "✅ Agent $AGENT réveillé avec: $MESSAGE"