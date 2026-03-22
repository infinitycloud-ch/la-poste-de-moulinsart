#!/bin/bash
# Script simple pour envoyer des emails - comme Tintin

TO="$1"
SUBJECT="$2"
BODY="$3"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 <destinataire> <sujet> <message>"
    echo "Exemple: $0 tintin@moulinsart.local \"Sprint 1\" \"Démarrer le travail\""
    exit 1
fi

# Créer le message email
EMAIL_DATA=$(cat <<EMAIL
From: nestor@moulinsart.local
To: $TO
Subject: $SUBJECT

$BODY
EMAIL
)

# Envoyer via curl au serveur SMTP
echo "$EMAIL_DATA" | curl -s --url "smtp://localhost:1025" \
  --mail-from "nestor@moulinsart.local" \
  --mail-rcpt "$TO" \
  --upload-file -

echo "✉️ Email envoyé à $TO"