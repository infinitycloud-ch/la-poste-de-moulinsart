#!/bin/bash
# Envoyer un message à TOUS les agents simultanément

MESSAGE="${1:-🚨 MESSAGE SYSTÈME: Vérifiez vos emails!}"

echo "📢 Broadcasting: $MESSAGE"

# Envoyer à tous les panels en parallèle
for PANEL in 0 1 2 3; do
    (
        tmux send-keys -t moulinsart-agents:agents.$PANEL Enter
        sleep 0.1
        tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
        tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '📢 BROADCAST SYSTÈME'" Enter
        tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '$MESSAGE'" Enter
        tmux send-keys -t moulinsart-agents:agents.$PANEL "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
    ) &
done

wait
echo "✅ Message diffusé à tous les agents"