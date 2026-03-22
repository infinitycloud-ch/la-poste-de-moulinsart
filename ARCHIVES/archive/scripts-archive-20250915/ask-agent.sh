#!/bin/bash
# Script pour poser une question directe à un agent

AGENT="$1"
QUESTION="${2:-Quel est le statut de ton travail actuel?}"

# Mapping des agents aux panels
case $AGENT in
    nestor) PANEL=0 ;;
    tintin) PANEL=1 ;;
    dupont1) PANEL=2 ;;
    dupont2) PANEL=3 ;;
    *) echo "Agent inconnu: $AGENT"; exit 1 ;;
esac

echo "📞 Appel direct à $AGENT..."

# Nettoyer la ligne
tmux send-keys -t moulinsart-agents:agents.$PANEL C-c
sleep 0.1
tmux send-keys -t moulinsart-agents:agents.$PANEL C-u  # Clear line
sleep 0.1

# Envoyer directement la question (Claude va la traiter)
tmux send-keys -t moulinsart-agents:agents.$PANEL "$QUESTION" Enter

echo "✅ Question envoyée à $AGENT: $QUESTION"
echo "📺 Pour voir la réponse: tmux attach -t moulinsart-agents"