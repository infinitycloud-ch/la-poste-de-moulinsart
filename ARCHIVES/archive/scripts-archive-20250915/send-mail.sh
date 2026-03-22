#!/bin/bash
# Script helper pour envoyer des emails facilement
# Usage: ./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"

TO="$1"
SUBJECT="$2"
BODY="$3"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 destinataire@moulinsart.local \"Sujet\" \"Message\""
    echo ""
    echo "Agents disponibles:"
    echo "  nestor@moulinsart.local  - Chef d'orchestre"
    echo "  tintin@moulinsart.local  - QA Lead"
    echo "  dupont1@moulinsart.local - Développeur Swift"
    echo "  dupont2@moulinsart.local - Recherche et docs"
    exit 1
fi

# Déterminer l'expéditeur selon le contexte tmux
FROM="system@moulinsart.local"
if [ -n "$TMUX" ]; then
    SESSION=$(tmux display-message -p '#S' 2>/dev/null)
    case "$SESSION" in
        nestor) FROM="nestor@moulinsart.local" ;;
        tintin) FROM="tintin@moulinsart.local" ;;
        dupont1) FROM="dupont1@moulinsart.local" ;;
        dupont2) FROM="dupont2@moulinsart.local" ;;
    esac
fi

# Envoyer l'email via curl
curl -X POST http://localhost:1080/api/send \
  -H "Content-Type: application/json" \
  -d "{
    \"from\": \"$FROM\",
    \"to\": \"$TO\",
    \"subject\": \"$SUBJECT\",
    \"body\": \"$BODY\"
  }" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✉️ Email envoyé à $TO"
else
    echo "❌ Erreur lors de l'envoi"
fi