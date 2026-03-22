#!/usr/bin/env python3
"""
Debug version - Test minimal pour identifier le problème
"""
import subprocess
import time
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.simulator import SimulatorController
from core.vision_analyzer import VisionAnalyzer
import config

print("🔍 DEBUG TEST - Version simplifiée")
print("=" * 50)

# Test 1: Simulator ID
print("\n1. Test du simulateur...")
sim = SimulatorController("tintin", config.APP_BUNDLE_ID)
actual_id = sim.get_simulator_id()
print(f"   Simulator ID: {actual_id}")

# Test 2: Launch app
print("\n2. Lancement de l'app...")
try:
    success = sim.launch_app()
    print(f"   Launch result: {success}")
except Exception as e:
    print(f"   ❌ Erreur: {e}")

# Test 3: Screenshot
print("\n3. Test screenshot...")
try:
    screenshot_path = "/tmp/debug_test.png"
    success = sim.screenshot(screenshot_path)
    print(f"   Screenshot saved: {success}")
    if success:
        print(f"   Path: {screenshot_path}")
except Exception as e:
    print(f"   ❌ Erreur: {e}")

# Test 4: Vision API
print("\n4. Test GPT-4o-mini...")
try:
    analyzer = VisionAnalyzer(config.OPENAI_API_KEY, config.OPENAI_MODEL)
    result = analyzer.detect_localization_issues(screenshot_path)
    print(f"   API Response received: {bool(result)}")
    if "error" in result:
        print(f"   ❌ API Error: {result['error']}")
    else:
        print(f"   ✅ Analysis successful")
        print(f"   Has underscore keys: {result.get('has_underscore_keys', 'N/A')}")
        print(f"   Language detected: {result.get('language_detected', 'N/A')}")
except Exception as e:
    print(f"   ❌ Erreur: {e}")

print("\n✅ Debug test completed")