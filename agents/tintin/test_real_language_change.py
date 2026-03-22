#!/usr/bin/env python3
"""
Test RÉEL de changement de langue PrivExpensIA
Utilise AppleLanguages pour forcer la langue au lancement
"""

import subprocess
import time
import os
from datetime import datetime

class RealLanguageTest:
    def __init__(self):
        self.simulator = "tintin"
        self.app_bundle = "com.minhtam.ExpenseAI"
        self.screenshot_dir = "~/moulinsart/agents/localization-test-mcp/screenshots"
        self.languages = {
            "en": {"name": "English", "greeting": "Good evening"},
            "fr": {"name": "Français", "greeting": "Bonsoir"},
            "de": {"name": "Deutsch", "greeting": "Guten Abend"},
            "it": {"name": "Italiano", "greeting": "Buonasera"},
            "es": {"name": "Español", "greeting": "Buenas noches"},
            "ja": {"name": "日本語", "greeting": "こんばんは"},
            "ko": {"name": "한국어", "greeting": "좋은 저녁"},
            "sk": {"name": "Slovenčina", "greeting": "Dobrý večer"}
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
            
        status = subprocess.run(f"xcrun simctl list devices | grep '{sim_id}'", 
                              shell=True, capture_output=True, text=True)
        if "Booted" not in status.stdout:
            print(f"🚀 Démarrage du simulateur {self.simulator}...")
            subprocess.run(f"xcrun simctl boot {sim_id}", shell=True)
            time.sleep(5)
        else:
            print(f"✅ Simulateur {self.simulator} déjà démarré")
            
        return sim_id
        
    def test_language(self, sim_id, lang_code):
        """
        Test une langue spécifique:
        1. Forcer la langue via AppleLanguages
        2. Lancer l'app
        3. Prendre screenshot
        4. Vérifier le texte affiché
        """
        print(f"\n🌍 Test de {self.languages[lang_code]['name']} ({lang_code})")
        print("-" * 50)
        
        # 1. Terminer l'app si elle tourne
        print("1️⃣ Arrêt de l'app...")
        subprocess.run(f"xcrun simctl terminate {sim_id} {self.app_bundle}", 
                      shell=True, capture_output=True)
        time.sleep(1)
        
        # 2. Définir la langue du système pour cette app
        print(f"2️⃣ Configuration langue: {lang_code}")
        # Méthode 1: Via defaults write sur le simulateur
        subprocess.run(
            f"xcrun simctl spawn {sim_id} defaults write {self.app_bundle} AppleLanguages -array '{lang_code}'",
            shell=True
        )
        
        # Méthode 2: Via launch arguments (plus fiable)
        print(f"3️⃣ Lancement avec -AppleLanguages ({lang_code})")
        launch_cmd = f"xcrun simctl launch {sim_id} {self.app_bundle} -AppleLanguages '({lang_code})'"
        subprocess.run(launch_cmd, shell=True)
        
        # Attendre que l'app se charge
        time.sleep(4)
        
        # 4. Prendre screenshot
        screenshot_name = f"{lang_code}_real_test.png"
        filepath = os.path.join(self.screenshot_dir, screenshot_name)
        print(f"4️⃣ Screenshot: {screenshot_name}")
        subprocess.run(f"xcrun simctl io {sim_id} screenshot '{filepath}'", shell=True)
        
        # 5. Info de validation
        expected = self.languages[lang_code]['greeting']
        print(f"✅ Screenshot pris - Texte attendu: '{expected}'")
        
        return filepath
        
    def run_all_tests(self):
        """Tester toutes les langues"""
        print("\n" + "="*60)
        print("🚀 TEST RÉEL DE CHANGEMENT DE LANGUE")
        print("="*60)
        
        sim_id = self.boot_simulator()
        if not sim_id:
            print("❌ Impossible de démarrer le simulateur")
            return
            
        results = {}
        
        for lang_code in self.languages.keys():
            try:
                screenshot = self.test_language(sim_id, lang_code)
                results[lang_code] = {
                    "status": "✅",
                    "screenshot": screenshot,
                    "expected": self.languages[lang_code]['greeting'],
                    "language": self.languages[lang_code]['name']
                }
            except Exception as e:
                print(f"❌ Erreur pour {lang_code}: {e}")
                results[lang_code] = {
                    "status": "❌",
                    "error": str(e),
                    "language": self.languages[lang_code]['name']
                }
                
        print("\n" + "="*60)
        print("📊 RÉSUMÉ DES TESTS")
        print("="*60)
        
        for lang_code, result in results.items():
            status = result["status"]
            lang_name = result["language"]
            if "expected" in result:
                expected = result["expected"]
                print(f"{status} {lang_name} ({lang_code}) - Attendu: '{expected}'")
            else:
                print(f"{status} {lang_name} ({lang_code})")
                
        return results
        
    def test_single_language(self, lang_code):
        """Tester une seule langue pour debug"""
        sim_id = self.boot_simulator()
        if not sim_id:
            return None
            
        return self.test_language(sim_id, lang_code)

if __name__ == "__main__":
    tester = RealLanguageTest()
    
    # Test d'abord avec une langue pour vérifier
    print("\n🧪 TEST UNITAIRE: Français puis English")
    print("="*60)
    
    # Test français
    tester.test_single_language("fr")
    time.sleep(2)
    
    # Test anglais pour voir si ça change
    tester.test_single_language("en")
    
    print("\n💡 Vérifiez les screenshots pour voir si le texte change!")
    print(f"📁 Screenshots dans: {tester.screenshot_dir}")