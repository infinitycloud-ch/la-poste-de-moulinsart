#!/usr/bin/env python3
"""
Script automatisé pour tester la localisation de PrivExpensIA
Utilise GPT-4 Vision pour analyser les screenshots
"""

import subprocess
import time
import base64
import json
import os
from pathlib import Path
import requests

# Configuration
SIMULATOR_ID = "tintin"  # Ton émulateur dédié
APP_BUNDLE = "com.minhtam.ExpenseAI"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")  # À configurer

def take_screenshot(name):
    """Prend un screenshot et retourne le path"""
    path = f"/tmp/test_{name}.png"
    cmd = f"xcrun simctl io {SIMULATOR_ID} screenshot {path}"
    subprocess.run(cmd, shell=True, capture_output=True)
    print(f"📸 Screenshot: {path}")
    return path

def encode_image(image_path):
    """Encode image en base64 pour GPT-4V"""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def analyze_screenshot(image_path, prompt):
    """Analyse le screenshot avec GPT-4 Vision"""
    base64_image = encode_image(image_path)
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }
    
    payload = {
        "model": "gpt-4-vision-preview",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{base64_image}"
                        }
                    }
                ]
            }
        ],
        "max_tokens": 300
    }
    
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers=headers,
        json=payload
    )
    
    return response.json()['choices'][0]['message']['content']

def click_at_position(x, y):
    """Simule un click à une position"""
    # Via AppleScript car xcrun simctl ne supporte pas les taps directs
    script = f'''
    tell application "Simulator" to activate
    delay 0.5
    tell application "System Events"
        click at {{{x}, {y}}}
    end tell
    '''
    subprocess.run(['osascript', '-e', script], capture_output=True)
    time.sleep(1)

def launch_app():
    """Lance l'app dans le simulateur"""
    subprocess.run(f"xcrun simctl launch {SIMULATOR_ID} {APP_BUNDLE}", shell=True)
    time.sleep(2)

def terminate_app():
    """Ferme l'app"""
    subprocess.run(f"xcrun simctl terminate {SIMULATOR_ID} {APP_BUNDLE}", shell=True)

def run_localization_test():
    """Test principal de localisation"""
    report = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "results": {}
    }
    
    print("🚀 Démarrage du test de localisation automatisé")
    
    # 1. Lancer l'app
    print("📱 Lancement de l'app...")
    terminate_app()
    launch_app()
    
    # 2. Aller dans Settings (5ème tab)
    print("⚙️ Navigation vers Settings...")
    # Position approximative du tab Settings (à ajuster selon l'écran)
    click_at_position(350, 850)  # Position du 5ème tab
    time.sleep(1)
    
    # 3. Analyser l'écran Settings
    print("🔍 Analyse de l'écran Settings...")
    settings_screenshot = take_screenshot("settings_initial")
    
    settings_analysis = analyze_screenshot(settings_screenshot, """
    Analyse cet écran iOS. Réponds en JSON avec ces infos:
    1. Y a-t-il des textes avec des underscores (comme settings_label, notification_label)?
    2. Vois-tu un language picker? Si oui, quelle est sa position approximative (x,y)?
    3. La page est-elle blanche/vide ou y a-t-il du contenu?
    4. Liste tous les textes visibles
    Format: {"has_underscore_keys": bool, "language_picker_position": [x,y] ou null, "is_blank": bool, "visible_texts": []}
    """)
    
    print(f"Analyse Settings: {settings_analysis}")
    report["results"]["settings_initial"] = json.loads(settings_analysis)
    
    # 4. Essayer de changer la langue
    if report["results"]["settings_initial"].get("language_picker_position"):
        print("🌍 Changement de langue vers Français...")
        x, y = report["results"]["settings_initial"]["language_picker_position"]
        click_at_position(x, y)
        time.sleep(1)
        
        # Sélectionner Français (2ème option généralement)
        click_at_position(x, y + 44)  # 44 points est la hauteur standard d'une row
        time.sleep(2)
        
        # 5. Vérifier chaque écran
        tabs = [
            ("Home", 50, 850),
            ("Expenses", 150, 850),
            ("Scanner", 250, 850),
            ("Statistics", 350, 850),
            ("Settings", 450, 850)
        ]
        
        for tab_name, x, y in tabs:
            print(f"📍 Test de {tab_name}...")
            click_at_position(x, y)
            time.sleep(1)
            
            screenshot = take_screenshot(f"fr_{tab_name.lower()}")
            analysis = analyze_screenshot(screenshot, f"""
            Cet écran devrait être en français. Vérifie:
            1. Les textes sont-ils en français ou en anglais?
            2. Y a-t-il des clés non traduites (avec underscore)?
            3. Liste les principaux textes visibles
            Format JSON: {{"is_french": bool, "has_keys": bool, "main_texts": []}}
            """)
            
            report["results"][f"fr_{tab_name.lower()}"] = json.loads(analysis)
    
    # 6. Générer le rapport final
    print("\n📊 RAPPORT FINAL")
    print("=" * 50)
    
    if report["results"]["settings_initial"].get("has_underscore_keys"):
        print("❌ PROBLÈME: Des clés de localisation sont visibles (underscore)")
    
    french_working = all(
        result.get("is_french", False) 
        for key, result in report["results"].items() 
        if key.startswith("fr_")
    )
    
    if french_working:
        print("✅ La localisation française fonctionne")
    else:
        print("❌ La localisation française NE fonctionne PAS")
        print("   Les écrans restent en anglais après changement de langue")
    
    # Sauvegarder le rapport
    with open("/tmp/localization_report.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📄 Rapport complet sauvé: /tmp/localization_report.json")
    return report

if __name__ == "__main__":
    # Vérifier la clé API
    if not OPENAI_API_KEY:
        print("⚠️ Configure OPENAI_API_KEY dans l'environnement")
        print("export OPENAI_API_KEY='ta-clé-ici'")
        exit(1)
    
    try:
        report = run_localization_test()
    except Exception as e:
        print(f"❌ Erreur: {e}")
        import traceback
        traceback.print_exc()