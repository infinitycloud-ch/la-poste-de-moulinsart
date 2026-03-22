#!/usr/bin/env python3
"""
Test séquentiel de localisation PrivExpensIA
Séquence: Home -> Settings -> Change Language -> Home -> Screenshot
"""

import subprocess
import time
import os
from datetime import datetime

class SequentialLocalizationTest:
    def __init__(self):
        self.simulator = "tintin"
        self.app_bundle = "com.minhtam.ExpenseAI"
        self.screenshot_dir = "~/moulinsart/agents/localization-test-mcp/screenshots"
        self.languages = {
            "en": "English",
            "fr": "Français", 
            "de": "Deutsch",
            "it": "Italiano",
            "es": "Español",
            "ja": "日本語",
            "ko": "한국어",
            "sk": "Slovenčina"
        }
        
        # Positions des éléments UI
        self.tabs = {
            "home": (50, 850),
            "settings": (370, 850)
        }
        
        os.makedirs(self.screenshot_dir, exist_ok=True)
        
    def get_simulator_id(self):
        """Obtenir l'ID du simulateur"""
        cmd = f"xcrun simctl list devices | grep '{self.simulator}' | grep -E 'Booted|Shutdown' | head -1"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.stdout:
            device_id = result.stdout.split('(')[1].split(')')[0]
            return device_id
        return None
        
    def boot_simulator(self):
        """Démarrer le simulateur"""
        sim_id = self.get_simulator_id()
        if not sim_id:
            print("❌ Simulateur non trouvé")
            return None
            
        # Vérifier si déjà démarré
        status = subprocess.run(f"xcrun simctl list devices | grep '{sim_id}'", 
                              shell=True, capture_output=True, text=True)
        if "Booted" not in status.stdout:
            print(f"🚀 Démarrage du simulateur {self.simulator}...")
            subprocess.run(f"xcrun simctl boot {sim_id}", shell=True)
            time.sleep(5)
        else:
            print(f"✅ Simulateur {self.simulator} déjà démarré")
            
        return sim_id
        
    def launch_app(self, sim_id):
        """Lancer l'application"""
        print(f"📱 Lancement de {self.app_bundle}...")
        subprocess.run(f"xcrun simctl terminate {sim_id} {self.app_bundle}", 
                      shell=True, capture_output=True)
        time.sleep(1)
        subprocess.run(f"xcrun simctl launch {sim_id} {self.app_bundle}", shell=True)
        time.sleep(3)
        
    def tap_at(self, sim_id, x, y):
        """Simuler un tap à une position"""
        subprocess.run(f"xcrun simctl io {sim_id} tap {x} {y}", shell=True)
        time.sleep(1)
        
    def take_screenshot(self, sim_id, filename):
        """Prendre un screenshot"""
        filepath = os.path.join(self.screenshot_dir, filename)
        subprocess.run(f"xcrun simctl io {sim_id} screenshot {filepath}", shell=True)
        print(f"📸 Screenshot: {filename}")
        return filepath
        
    def test_language_sequence(self, sim_id, lang_code):
        """
        Séquence complète pour une langue:
        1. Home (screenshot initial)
        2. Settings 
        3. Changer langue
        4. Retour Home
        5. Screenshot final
        """
        print(f"\n🌍 Test de {self.languages[lang_code]} ({lang_code})")
        print("-" * 50)
        
        # 1. Lancer l'app (arrive sur Home)
        self.launch_app(sim_id)
        print("1️⃣ App lancée - sur Home")
        self.take_screenshot(sim_id, f"{lang_code}_1_home_initial.png")
        
        # 2. Aller dans Settings
        print("2️⃣ Navigation vers Settings...")
        self.tap_at(sim_id, self.tabs["settings"][0], self.tabs["settings"][1])
        time.sleep(2)
        self.take_screenshot(sim_id, f"{lang_code}_2_settings.png")
        
        # 3. Changer la langue (tap sur le bouton de langue)
        print("3️⃣ Changement de langue...")
        # Position approximative du sélecteur de langue (à ajuster)
        self.tap_at(sim_id, 200, 250)  # Tap sur Language picker
        time.sleep(2)
        
        # Sélectionner la langue dans la liste
        language_positions = {
            "en": 200,
            "fr": 250,
            "de": 300,
            "it": 350,
            "es": 400,
            "ja": 450,
            "ko": 500,
            "sk": 550
        }
        
        if lang_code in language_positions:
            self.tap_at(sim_id, 200, language_positions[lang_code])
            time.sleep(2)
        
        # 4. Retour sur Home
        print("4️⃣ Retour sur Home...")
        self.tap_at(sim_id, self.tabs["home"][0], self.tabs["home"][1])
        time.sleep(2)
        
        # 5. Screenshot final
        print("5️⃣ Screenshot final avec nouvelle langue")
        final_screenshot = self.take_screenshot(sim_id, f"{lang_code}_5_home_final.png")
        
        print(f"✅ Test {self.languages[lang_code]} terminé\n")
        return final_screenshot
        
    def run_all_tests(self):
        """Exécuter les tests pour toutes les langues"""
        print("\n" + "="*60)
        print("🚀 DÉBUT DES TESTS SÉQUENTIELS DE LOCALISATION")
        print("="*60)
        
        sim_id = self.boot_simulator()
        if not sim_id:
            print("❌ Impossible de démarrer le simulateur")
            return
            
        results = {}
        
        for lang_code in self.languages.keys():
            try:
                screenshot = self.test_language_sequence(sim_id, lang_code)
                results[lang_code] = {
                    "status": "✅",
                    "screenshot": screenshot,
                    "language": self.languages[lang_code]
                }
            except Exception as e:
                print(f"❌ Erreur pour {lang_code}: {e}")
                results[lang_code] = {
                    "status": "❌",
                    "error": str(e),
                    "language": self.languages[lang_code]
                }
                
        print("\n" + "="*60)
        print("📊 RÉSUMÉ DES TESTS")
        print("="*60)
        
        for lang_code, result in results.items():
            status = result["status"]
            lang_name = result["language"]
            print(f"{status} {lang_name} ({lang_code})")
            
        return results

if __name__ == "__main__":
    tester = SequentialLocalizationTest()
    results = tester.run_all_tests()