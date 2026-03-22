#!/bin/bash

# 📬 ENVOI EMAIL AVEC ACCUSÉ DE RÉCEPTION AUTOMATIQUE
# Usage: ./send-with-ack.sh destinataire@moulinsart.local "Sujet" "Message"

RECIPIENT=$1
SUBJECT=$2
MESSAGE=$3
TIMEOUT=30

if [ -z "$RECIPIENT" ] || [ -z "$SUBJECT" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 destinataire@moulinsart.local \"Sujet\" \"Message\""
    exit 1
fi

# Ajouter demande accusé réception au message
MESSAGE_WITH_ACK="$MESSAGE

━━━━━━━━━━━━━━━━━━━━
⚠️ ACCUSÉ DE RÉCEPTION REQUIS
Merci de confirmer réception par simple 'OK' ou 'REÇU'
Timeout: ${TIMEOUT}s pour autonomie système
━━━━━━━━━━━━━━━━━━━━"

echo "📧 Envoi email avec accusé de réception..."

# Envoyer l'email
./send-mail.sh "$RECIPIENT" "$SUBJECT" "$MESSAGE_WITH_ACK"

if [ $? -ne 0 ]; then
    echo "❌ Échec envoi email"
    exit 1
fi

echo "⏳ Attente accusé de réception (${TIMEOUT}s)..."

# Extraire nom agent du recipient
AGENT_NAME=$(echo "$RECIPIENT" | cut -d'@' -f1)

# Timestamp actuel pour vérifier nouveaux emails
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# Attendre réponse
for i in $(seq 1 $TIMEOUT); do
    sleep 1

    # Vérifier nouveaux emails depuis envoi
    RESPONSE=$(curl -s "http://localhost:1080/api/mailbox/haddock@moulinsart.local" 2>/dev/null)

    if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
        # Chercher réponse récente du destinataire
        NEW_EMAILS=$(echo "$RESPONSE" | jq -r --arg start "$START_TIME" --arg from "$RECIPIENT" '.emails[] | select(.timestamp > $start and .from == $from) | .body' 2>/dev/null)

        if echo "$NEW_EMAILS" | grep -qi -E "(OK|REÇU|ACK|CONFIRMÉ)" 2>/dev/null; then
            echo "✅ Accusé de réception reçu en ${i}s"
            exit 0
        fi
    fi

    # Afficher progression
    if [ $((i % 10)) -eq 0 ]; then
        echo "⏳ Attente... ${i}/${TIMEOUT}s"
    fi
done

echo "⚠️ TIMEOUT: Pas d'accusé de réception en ${TIMEOUT}s"
echo "🚨 Agent $AGENT_NAME possiblement endormi - intervention requise"
exit 2