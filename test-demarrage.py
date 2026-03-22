#!/usr/bin/env python3
"""
Test de démarrage du système La Poste de Moulinsart
"""

import smtplib
from email.mime.text import MIMEText
from datetime import datetime

# Configuration
SMTP_HOST = 'localhost'
SMTP_PORT = 1025
FROM = 'commandant@moulinsart.local'
TO = 'nestor@moulinsart.local'

# Message de test
message_content = """
Bonjour Nestor,

CECI EST UN TEST DE DÉMARRAGE DU SYSTÈME.

Tu es NESTOR, le chef d'orchestre de notre ferme de création d'applications iOS.

MISSION DE TEST:
1. Lis cet email attentivement
2. Transmets l'information à tes équipes (Tintin, Dupont1, Dupont2)
3. Chaque agent doit créer un fichier texte contenant:
   - Son nom et rôle
   - Sa compréhension qu'il fait partie d'une ferme de création iOS
   - Sa position dans la hiérarchie
   
Nom du fichier à créer: /tmp/test-[nom-agent].txt

RAPPEL DE LA HIÉRARCHIE:
- Tu es le CHEF, tu reportes directement au commandant
- TINTIN est ton lieutenant (QA Lead)
- DUPONT1 et DUPONT2 sont sous les ordres de Tintin

Cette ferme de création iOS utilise la communication par email uniquement.
Chaque agent a un rôle spécifique dans la chaîne de production d'applications.

Merci de coordonner ce test avec ton équipe.

Cordialement,
Le Commandant
"""

# Créer l'email
msg = MIMEText(message_content)
msg['Subject'] = f'[TEST SYSTÈME] Démarrage Ferme iOS - {datetime.now().strftime("%H:%M")}'
msg['From'] = FROM
msg['To'] = TO

# Envoyer
try:
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.send_message(msg)
        print(f"✉️ Email de test envoyé à {TO}")
        print(f"📍 Sujet: {msg['Subject']}")
        print("\n🔔 Nestor devrait recevoir une notification tmux...")
        print("👀 Surveillez: tmux attach -t nestor")
except Exception as e:
    print(f"❌ Erreur: {e}")