#!/bin/bash

# ================================================================
# SEND-MAIL.sh - Utilitaire envoi emails Moulinsart
# ================================================================
# Usage: ./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"
# ================================================================

if [ $# -ne 3 ]; then
    echo "Usage: $0 <destinataire@moulinsart.local> \"Sujet\" \"Message\""
    echo "Exemple: $0 tournesol1@moulinsart.local \"MISSION Sprint 9\" \"Merci de repondre par: OK RECU\""
    exit 1
fi

DESTINATAIRE="$1"
SUJET="$2"
MESSAGE="$3"

# Validation email
if [[ ! "$DESTINATAIRE" =~ @moulinsart\.local$ ]]; then
    echo "ERROR: Email doit se terminer par @moulinsart.local"
    exit 1
fi

# Envoi via curl vers serveur mail local
RESPONSE=$(curl -s -X POST "http://localhost:1080/api/send" \
    -H "Content-Type: application/json" \
    -d "{
        \"from\": \"haddock@moulinsart.local\",
        \"to\": \"$DESTINATAIRE\",
        \"subject\": \"$SUJET\",
        \"body\": \"$MESSAGE\"
    }")

if [ $? -eq 0 ]; then
    echo "EMAIL ENVOYE: $DESTINATAIRE"
    echo "SUJET: $SUJET"
    echo "RESPONSE: $RESPONSE"
else
    echo "ERROR: Echec envoi email"
    exit 1
fi