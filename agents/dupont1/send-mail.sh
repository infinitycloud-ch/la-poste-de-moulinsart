#!/bin/bash
# Script pour envoyer des emails via le serveur SMTP local

TO="$1"
SUBJECT="$2"
BODY="$3"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 <destinataire> <sujet> <message>"
    exit 1
fi

# Formatter l'email
EMAIL_DATA="Subject: $SUBJECT
To: $TO
From: dupont1@moulinsart.local

$BODY"

# Envoyer via curl au serveur SMTP
echo "$EMAIL_DATA" | curl -s --url "smtp://localhost:1025" \
  --mail-from "dupont1@moulinsart.local" \
  --mail-rcpt "$TO" \
  --upload-file -

echo "✉️ Email envoyé à $TO"