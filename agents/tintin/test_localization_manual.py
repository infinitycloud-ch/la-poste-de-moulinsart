#!/usr/bin/env python3
"""
Test manuel de localisation avec screenshots
"""
import subprocess
import time
import os

SIM_ID = "9D1B772E-7D9B-4934-A7F4-D2829CEB0065"
APP_BUNDLE = "com.minhtam.ExpenseAI"

def screenshot(name):
    """Prend un screenshot"""
    path = f"/tmp/loc_test_{name}.png"
    subprocess.run(f"xcrun simctl io {SIM_ID} screenshot {path}", shell=True, capture_output=True)
    print(f"📸 Screenshot: {path}")
    return path

def launch_with_language(lang_code):
    """Lance l'app avec une langue spécifique"""
    print(f"\n🌍 Testing {lang_code}...")
    
    # Terminer l'app
    subprocess.run(f"xcrun simctl terminate {SIM_ID} {APP_BUNDLE}", shell=True, capture_output=True)
    time.sleep(1)
    
    # Changer la langue du simulateur
    subprocess.run(f"xcrun simctl spawn {SIM_ID} defaults write -g AppleLanguages -array {lang_code}", shell=True, capture_output=True)
    subprocess.run(f"xcrun simctl spawn {SIM_ID} defaults write -g AppleLocale {lang_code}", shell=True, capture_output=True)
    
    # Relancer l'app
    subprocess.run(f"xcrun simctl launch {SIM_ID} {APP_BUNDLE}", shell=True, capture_output=True)
    time.sleep(3)  # Attendre le chargement
    
    # Screenshot home
    screenshot(f"{lang_code}_home")
    
    # Essayer de naviguer avec cliclick (si installé)
    if os.path.exists("/opt/homebrew/bin/cliclick"):
        # Settings tab (5ème)
        subprocess.run("cliclick c:2374,1226", shell=True, capture_output=True)
        time.sleep(1)
        screenshot(f"{lang_code}_settings")
    
    return True

# Test rapide - Français seulement
print("🚀 TEST DE LOCALISATION RAPIDE")
print("=" * 50)

# 1. Test en anglais (référence)
launch_with_language("en")

# 2. Test en français
launch_with_language("fr")

# 3. Analyser les screenshots
print("\n📊 ANALYSE")
print("Vérifiez les screenshots dans /tmp/:")
subprocess.run("ls -la /tmp/loc_test_*.png", shell=True)

print("\n✅ Test terminé - Vérifiez manuellement:")
print("1. /tmp/loc_test_en_home.png devrait être en anglais")
print("2. /tmp/loc_test_fr_home.png devrait être en français")
print("3. Si fr_home est toujours en anglais = LOCALISATION CASSÉE")