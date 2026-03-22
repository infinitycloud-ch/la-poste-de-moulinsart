#!/usr/bin/env python3
"""
Hook pour envoyer les prompts par email à Nestor
"""

import json
import sys
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from pathlib import Path
import os

# Configuration MailHog Moulinsart
SMTP_HOST = 'localhost'
SMTP_PORT = 1025  # Port SMTP Moulinsart
FROM_EMAIL = 'oracle@moulinsart.local'
NESTOR_EMAIL = 'nestor@moulinsart.local'

def send_email_to_nestor(prompt_data):
    """Envoie le prompt à Nestor par email"""
    try:
        # Créer le message
        msg = MIMEMultipart()
        msg['From'] = FROM_EMAIL
        msg['To'] = NESTOR_EMAIL
        msg['Subject'] = f"[PROMPT] Nouveau projet: {prompt_data.get('project_name', 'Unknown')}"
        
        # Corps du message
        body = f"""
🔮 NOUVEAU PROMPT CAPTURÉ
========================

📁 Projet: {prompt_data.get('project_name', 'Unknown')}
📍 Chemin: {prompt_data.get('project_path', 'Unknown')}
🤖 Agent: {prompt_data.get('agent', 'claude')}
⏰ Timestamp: {prompt_data.get('timestamp', datetime.now().isoformat())}

💬 PROMPT:
----------
{prompt_data.get('prompt', 'No prompt content')}

---
Cet email a été généré automatiquement par Moulinsart Oracle.
Pour répondre, utilisez les commandes suivantes:

ÉQUIPE MOULINSART:
- FORWARD:tintin - Transférer à Tintin
- FORWARD:dupont1 - Transférer à Dupont1
- FORWARD:dupont2 - Transférer à Dupont2

ÉQUIPE MANITOBA:
- FORWARD:haddock - Transférer à Haddock
- FORWARD:rastapopoulos - Transférer à Rastapopoulos
- FORWARD:tournesol1 - Transférer à Tournesol1
- FORWARD:tournesol2 - Transférer à Tournesol2
"""
        
        msg.attach(MIMEText(body, 'plain'))
        
        # Envoyer via SMTP local
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.send_message(msg)
            print(f"📧 Email sent to Nestor", file=sys.stderr)
            
    except Exception as e:
        print(f"Failed to send email: {e}", file=sys.stderr)

def main():
    # Lire l'input depuis stdin
    input_data = sys.stdin.read()
    
    try:
        # Parser le JSON si possible
        data = json.loads(input_data) if input_data else {}
    except:
        data = {"raw": input_data}
    
    # Récupérer le répertoire de travail actuel
    cwd = os.getcwd()
    project_name = Path(cwd).name
    
    # Préparer les données du prompt
    prompt_data = {
        'prompt': data.get('prompt', input_data[:1000] if isinstance(input_data, str) else ''),
        'timestamp': datetime.now().isoformat(),
        'project_path': cwd,
        'project_name': project_name,
        'agent': 'claude'
    }
    
    # Envoyer l'email à Nestor
    send_email_to_nestor(prompt_data)
    
    # Passer le message original (important!)
    print(input_data, end='')

if __name__ == "__main__":
    main()