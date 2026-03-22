#!/usr/bin/env python3
"""
Quick localization test - Test français uniquement
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

def run_quick_french_test():
    """Test rapide - Français seulement"""
    print("🚀 Test rapide de localisation - Français")
    print("=" * 50)
    
    # Initialize components
    sim = SimulatorController(config.SIMULATOR_NAME, config.APP_BUNDLE_ID)
    analyzer = VisionAnalyzer(config.OPENAI_API_KEY, config.OPENAI_MODEL)
    
    # Create screenshots directory
    Path(config.SCREENSHOTS_DIR).mkdir(parents=True, exist_ok=True)
    
    results = {
        "test_date": datetime.now().isoformat(),
        "test_type": "quick_french",
        "steps": []
    }
    
    try:
        # 1. Launch app
        print("\n📱 Lancement de l'app...")
        sim.open_simulator_app()
        sim.launch_app()
        time.sleep(2)
        
        # 2. Go to Settings
        print("⚙️ Navigation vers Settings...")
        settings_x, settings_y = config.TABS["settings"]["position"]
        sim.click(settings_x, settings_y)
        time.sleep(1)
        
        # 3. Take screenshot and analyze
        print("📸 Analyse de l'écran Settings...")
        settings_path = f"{config.SCREENSHOTS_DIR}/settings_initial.png"
        sim.screenshot(settings_path)
        
        settings_analysis = analyzer.detect_localization_issues(settings_path)
        results["steps"].append({
            "step": "settings_initial",
            "analysis": settings_analysis
        })
        
        if settings_analysis.get("has_underscore_keys"):
            print("❌ PROBLÈME DÉTECTÉ: Clés de localisation visibles (underscore)")
        else:
            print("✅ Pas de clés underscore visibles")
            
        # 4. Try to change language to French
        print("\n🇫🇷 Tentative de changement vers Français...")
        
        # Click on language picker if found
        if settings_analysis.get("ui_elements", {}).get("has_language_picker"):
            picker_loc = settings_analysis["ui_elements"].get("language_picker_location")
            if picker_loc:
                print(f"  Clicking language picker at {picker_loc}")
                sim.click(picker_loc[0], picker_loc[1])
                time.sleep(1)
                
                # Select French (usually 2nd option)
                sim.click(picker_loc[0], picker_loc[1] + 44)
                time.sleep(2)
        else:
            print("  ⚠️ Language picker non détecté, tentative avec position par défaut")
            # Try default position for language picker
            sim.click(207, 400)  # Approximate middle of screen
            time.sleep(1)
            sim.click(207, 444)  # French option
            time.sleep(2)
        
        # 5. Test each tab for French
        print("\n🔍 Vérification de chaque écran...")
        french_working = True
        
        for tab_name, tab_info in config.TABS.items():
            print(f"\n  📍 Test de {tab_name}...")
            x, y = tab_info["position"]
            sim.click(x, y)
            time.sleep(1)
            
            screenshot_path = f"{config.SCREENSHOTS_DIR}/fr_{tab_name}.png"
            sim.screenshot(screenshot_path)
            
            # Check for French
            expected = config.EXPECTED_TRANSLATIONS.get("fr", {})
            expected_texts = [expected.get(f"{tab_name}_title", tab_info["fr_name"])]
            
            analysis = analyzer.verify_language_change(
                screenshot_path, 
                "French/Français",
                expected_texts
            )
            
            results["steps"].append({
                "step": f"fr_{tab_name}",
                "analysis": analysis
            })
            
            if analysis.get("language_correct"):
                print(f"    ✅ {tab_name}: Français OK")
            else:
                print(f"    ❌ {tab_name}: PAS en français")
                french_working = False
                if analysis.get("actual_texts"):
                    print(f"       Textes vus: {analysis['actual_texts'][:3]}")
        
        # 6. Final verdict
        print("\n" + "=" * 50)
        print("📊 VERDICT FINAL:")
        
        if french_working:
            print("✅ La localisation française FONCTIONNE")
            results["verdict"] = "PASS"
        else:
            print("❌ La localisation française NE FONCTIONNE PAS")
            print("   L'app reste en anglais après changement de langue")
            results["verdict"] = "FAIL"
            
        # Save report
        report_path = f"{config.REPORTS_DIR}/quick_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        Path(config.REPORTS_DIR).mkdir(parents=True, exist_ok=True)
        with open(report_path, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\n📄 Rapport sauvé: {report_path}")
        
    except Exception as e:
        print(f"\n❌ Erreur durant le test: {e}")
        import traceback
        traceback.print_exc()
        results["error"] = str(e)
        
    return results

if __name__ == "__main__":
    run_quick_french_test()