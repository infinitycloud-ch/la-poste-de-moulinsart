#!/bin/bash
# Script d'envoi d'emails pour le Commandant [Author]

TO="$1"
SUBJECT="$2"
BODY="$3"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 <destinataire> <sujet> <message>"
    echo "Exemple: $0 nestor@moulinsart.local \"Mission Urgente\" \"Votre mission...\""
    exit 1
fi

# Créer le message email
EMAIL_DATA=$(cat <<EMAIL
From: author@moulinsart.local
To: $TO
Subject: $SUBJECT

$BODY
EMAIL
)

# Envoyer via curl au serveur SMTP
echo "$EMAIL_DATA" | curl -s --url "smtp://localhost:1025" \
  --mail-from "author@moulinsart.local" \
  --mail-rcpt "$TO" \
  --upload-file -

echo "✉️ Email du Commandant envoyé à $TO"