#!/usr/bin/env python3
"""
Full localization test - Toutes les langues
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.simulator import SimulatorController
from core.vision_analyzer import VisionAnalyzer
import config
import time
import json
from datetime import datetime
from pathlib import Path

def test_language(sim, analyzer, lang_code, lang_info):
    """Test une langue spécifique"""
    results = {"language": lang_code, "checks": {}}
    
    print(f"\n🌐 Test de {lang_info['name']}...")
    
    # Go to Settings
    settings_x, settings_y = config.TABS["settings"]["position"]
    sim.click(settings_x, settings_y)
    time.sleep(1)
    
    # Change language
    sim.click(207, 400)  # Language picker
    time.sleep(0.5)
    # Calculate position based on index (44 points per row)
    lang_y = 400 + (lang_info['index'] * 44)
    sim.click(207, lang_y)
    time.sleep(2)
    
    # Test each tab
    for tab_name, tab_info in config.TABS.items():
        x, y = tab_info["position"]
        sim.click(x, y)
        time.sleep(1)
        
        screenshot_path = f"{config.SCREENSHOTS_DIR}/{lang_code}_{tab_name}.png"
        sim.screenshot(screenshot_path)
        
        analysis = analyzer.detect_localization_issues(screenshot_path)
        results["checks"][tab_name] = {
            "has_underscore_keys": analysis.get("has_underscore_keys", False),
            "language_detected": analysis.get("language_detected", "unknown")
        }
    
    return results

def run_full_test():
    """Test complet - toutes les langues"""
    print("🚀 Test complet de localisation - 8 langues")
    print("=" * 50)
    
    sim = SimulatorController(config.SIMULATOR_NAME, config.APP_BUNDLE_ID)
    analyzer = VisionAnalyzer(config.OPENAI_API_KEY, config.OPENAI_MODEL)
    
    Path(config.SCREENSHOTS_DIR).mkdir(parents=True, exist_ok=True)
    
    results = {
        "test_date": datetime.now().isoformat(),
        "test_type": "full_8_languages",
        "languages": {}
    }
    
    try:
        # Launch app
        print("📱 Lancement de l'app...")
        sim.open_simulator_app()
        sim.launch_app()
        time.sleep(2)
        
        # Test each language
        for lang_code, lang_info in config.LANGUAGES.items():
            lang_results = test_language(sim, analyzer, lang_code, lang_info)
            results["languages"][lang_code] = lang_results
            
            # Quick summary
            has_issues = any(
                check.get("has_underscore_keys", False) 
                for check in lang_results["checks"].values()
            )
            
            if has_issues:
                print(f"  ❌ {lang_info['name']}: Problèmes détectés")
            else:
                print(f"  ✅ {lang_info['name']}: OK")
        
        # Final summary
        print("\n" + "=" * 50)
        print("📊 RÉSUMÉ:")
        
        working_languages = []
        broken_languages = []
        
        for lang_code, lang_data in results["languages"].items():
            has_issues = any(
                check.get("has_underscore_keys", False) 
                for check in lang_data["checks"].values()
            )
            
            if has_issues:
                broken_languages.append(config.LANGUAGES[lang_code]["name"])
            else:
                working_languages.append(config.LANGUAGES[lang_code]["name"])
        
        print(f"\n✅ Langues fonctionnelles ({len(working_languages)}): {', '.join(working_languages)}")
        print(f"❌ Langues avec problèmes ({len(broken_languages)}): {', '.join(broken_languages)}")
        
        # Save report
        report_path = f"{config.REPORTS_DIR}/full_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        Path(config.REPORTS_DIR).mkdir(parents=True, exist_ok=True)
        with open(report_path, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\n📄 Rapport complet sauvé: {report_path}")
        
    except Exception as e:
        print(f"\n❌ Erreur: {e}")
        results["error"] = str(e)
    
    return results

if __name__ == "__main__":
    run_full_test()