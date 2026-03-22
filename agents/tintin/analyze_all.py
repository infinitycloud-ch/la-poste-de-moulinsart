#!/usr/bin/env python3
"""Analyse rapide de tous les screenshots"""
import requests
import base64
import json

API_KEY = "sk-YOUR_KEY_HERE"

def analyze(image_path):
    with open(image_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        json={
            "model": "gpt-4o-mini",
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": "Check this iOS screen. Answer in JSON: {\"has_underscore_keys\": true/false, \"main_texts\": [list of 3 main texts you see], \"is_settings_screen\": true/false}"},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}", "detail": "low"}}
                ]
            }],
            "max_tokens": 200
        }
    )
    return response.json()['choices'][0]['message']['content']

screens = ["1_home", "2_expenses", "3_scanner", "4_statistics", "5_settings"]

print("🔍 ANALYSE DES 5 ÉCRANS")
print("=" * 50)

for screen in screens:
    print(f"\n📱 {screen}:")
    try:
        result = analyze(f"/tmp/{screen}.png")
        data = json.loads(result)
        print(f"   Underscore keys: {data.get('has_underscore_keys', '?')}")
        print(f"   Main texts: {data.get('main_texts', [])[:2]}")
        if data.get('is_settings_screen'):
            print("   ⚙️ C'EST L'ÉCRAN SETTINGS!")
    except Exception as e:
        print(f"   ❌ Erreur: {e}")

print("\n" + "=" * 50)
print("✅ Analyse terminée")