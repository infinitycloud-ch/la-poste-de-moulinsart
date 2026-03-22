#!/usr/bin/env python3
"""
Moulinsart Oracle - Hook pour capturer les prompts Claude
"""

import json
import sys
import requests
import os
from datetime import datetime
from pathlib import Path

# Port 3001 pour le nouveau serveur Moulinsart
ORACLE_URL = "http://localhost:3001/api/events"

def send_to_oracle(event_data):
    """Envoie l'événement à Oracle Moulinsart"""
    try:
        response = requests.post(
            ORACLE_URL,
            json=event_data,
            headers={"Content-Type": "application/json"},
            timeout=2
        )
        if response.status_code != 200:
            print(f"Oracle response: {response.status_code}", file=sys.stderr)
    except Exception as e:
        # Silencieux en cas d'erreur pour ne pas perturber Claude
        pass

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
    
    # Créer l'événement pour Oracle
    event = {
        "type": "prompt",
        "source": "claude-hook",
        "data": {
            "prompt": data.get("prompt", input_data[:500] if isinstance(input_data, str) else ""),
            "timestamp": datetime.now().isoformat(),
            "project_path": cwd,
            "project_name": project_name,
            "agent": "claude"
        },
        "project": project_name,
        "project_path": cwd,
        "agent": "claude"
    }
    
    # Envoyer à Oracle
    send_to_oracle(event)
    
    # Passer le message original (important!)
    print(input_data, end='')

if __name__ == "__main__":
    main()