#!/bin/bash

# Script d'envoi d'email pour les agents de Moulinsart
# Usage: ./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"

TO="$1"
SUBJECT="$2"
BODY="$3"
FROM="nestor@moulinsart.local"

if [ -z "$TO" ] || [ -z "$SUBJECT" ] || [ -z "$BODY" ]; then
    echo "Usage: $0 destinataire@moulinsart.local \"Sujet\" \"Message\""
    exit 1
fi

python3 -c "
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

msg = MIMEMultipart()
msg['From'] = '$FROM'
msg['To'] = '$TO'
msg['Subject'] = '''$SUBJECT'''

body = '''$BODY'''

msg.attach(MIMEText(body, 'plain'))

try:
    server = smtplib.SMTP('localhost', 1025)
    server.send_message(msg)
    server.quit()
    print('✅ Email envoyé à ' + msg['To'])
except Exception as e:
    print('❌ Erreur: ' + str(e))
"
