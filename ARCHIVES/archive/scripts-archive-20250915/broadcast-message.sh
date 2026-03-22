#!/bin/bash
# Script pour envoyer un message à tous les agents simultanément

MESSAGE="${1:-Message système important}"

echo "📢 Envoi du message aux 4 agents..."

# Méthode 1: Via tmux direct (pour messages courts)
for panel in 0 1 2 3; do
    tmux send-keys -t moulinsart-agents:agents.$panel "$MESSAGE" Enter &
done
wait

echo "✅ Message envoyé aux 4 agents via tmux"

# Méthode 2: Via email (pour messages longs)
if [ "$2" == "--email" ]; then
    AGENTS=("nestor" "tintin" "dupont1" "dupont2")
    for agent in "${AGENTS[@]}"; do
        curl -X POST http://localhost:1080/api/send \
          -H "Content-Type: application/json" \
          -d "{
            \"from\": \"system@moulinsart.local\",
            \"to\": \"${agent}@moulinsart.local\",
            \"subject\": \"Broadcast\",
            \"body\": \"$MESSAGE\"
          }" 2>/dev/null &
    done
    wait
    echo "✅ Emails envoyés aux 4 agents"
fi