#!/bin/bash

# Script d'envoi d'email via curl pour Nestor
# Usage: ./send-mail-curl.sh destinataire@moulinsart.local "Sujet" "Message"

TO="$1"
SUBJECT="$2"
BODY="$3"
FROM="nestor@moulinsart.local"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 destinataire@moulinsart.local \"Sujet\" \"Message\""
    echo ""
    echo "Exemple:"
    echo "  ./send-mail-curl.sh tintin@moulinsart.local \"Sprint 1\" \"Démarrer le travail\""
    exit 1
fi

# Envoyer via curl avec le bon Content-Type
curl -X POST http://localhost:1080/api/send \
  -H "Content-Type: application/json" \
  -d "{
    \"from\": \"$FROM\",
    \"to\": \"$TO\",
    \"subject\": \"$SUBJECT\",
    \"body\": \"$BODY\"
  }"

if [ $? -eq 0 ]; then
    echo "✅ Email envoyé à $TO"
else
    echo "❌ Erreur lors de l'envoi"
fi