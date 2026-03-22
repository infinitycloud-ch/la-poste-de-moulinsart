#!/usr/bin/env python3
"""
Test d'envoi d'email pour La Poste de Moulinsart
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

# Configuration
SMTP_HOST = 'localhost'
SMTP_PORT = 1025  # Port de notre serveur mail

def send_test_email():
    """Envoie un email de test à Nestor"""
    
    # Créer le message
    msg = MIMEMultipart()
    msg['From'] = 'vous@moulinsart.local'
    msg['To'] = 'nestor@moulinsart.local'
    msg['Subject'] = 'Nouveau projet - Test du système La Poste'
    
    # Corps du message
    body = """Bonjour Nestor,

Tu es NESTOR, le chef d'orchestre de ce projet de test.

J'ai besoin que tu testes le système de communication par email:
1. Lis ce message pour comprendre ton rôle
2. Consulte ta boîte mail sur http://localhost:1080/mailbox/nestor
3. Confirme que tu as bien reçu ce message en créant un fichier test-reussi.txt

C'est un test simple pour valider que La Poste de Moulinsart fonctionne.

Merci!
L'équipe"""
    
    msg.attach(MIMEText(body, 'plain'))
    
    # Envoyer via SMTP
    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.send_message(msg)
            print(f"✅ Email envoyé à nestor@moulinsart.local")
            print(f"📧 Subject: {msg['Subject']}")
            print(f"⏰ Time: {datetime.now().strftime('%H:%M:%S')}")
    except Exception as e:
        print(f"❌ Erreur: {e}")

if __name__ == "__main__":
    send_test_email()