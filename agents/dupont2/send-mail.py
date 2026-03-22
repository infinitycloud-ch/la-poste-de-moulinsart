#!/usr/bin/env python3
import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email(to_email, subject, body):
    """Send email via local SMTP server"""
    from_email = "dupont2@moulinsart.local"
    
    msg = MIMEMultipart()
    msg['From'] = from_email
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))
    
    try:
        server = smtplib.SMTP('localhost', 1025)
        server.send_message(msg)
        server.quit()
        print(f"✅ Email envoyé à {to_email}")
        return True
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: ./send-mail.py <destinataire> <sujet> <message>")
        sys.exit(1)
    
    to_email = sys.argv[1]
    subject = sys.argv[2]
    body = sys.argv[3]
    
    send_email(to_email, subject, body)