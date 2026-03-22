#!/bin/bash

# Script pour envoyer une notification manuelle à un agent
# Usage: ./notify-agent.sh [0|1|2|3] [message optionnel]

AGENT=$1
MESSAGE=${2:-"📧 Tu as du courrier! Vérifie ta boîte mail"}
SESSION="moulinsart-agents"

case $AGENT in
    0) NAME="NESTOR" ;;
    1) NAME="TINTIN" ;;
    2) NAME="DUPONT1" ;;
    3) NAME="DUPONT2" ;;
    *) 
        echo "Usage: $0 [0|1|2|3] [message optionnel]"
        echo "  0 = Nestor"
        echo "  1 = Tintin"
        echo "  2 = Dupont1"
        echo "  3 = Dupont2"
        exit 1
        ;;
esac

# Notification formatée
NOTIFICATION="🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
$MESSAGE
📬 Consulte: http://localhost:1080
⏰ $(date '+%H:%M:%S')
━━━━━━━━━━━━━━━━━━━━"

echo "📤 Envoi de notification à $NAME (panel $AGENT)..."

# Envoyer la notification dans le panel tmux
tmux send-keys -t "$SESSION:agents.$AGENT" "echo '$NOTIFICATION'" C-m 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Notification envoyée à $NAME!"
else
    echo "❌ Erreur: Impossible d'envoyer la notification"
    echo "   Vérifiez que la session tmux '$SESSION' est active"
fi