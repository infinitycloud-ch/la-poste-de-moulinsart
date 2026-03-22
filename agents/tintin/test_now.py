#!/usr/bin/env python3
"""Test immédiat de localisation"""
import subprocess
import time
import requests
import base64
import json

# Config
API_KEY = "sk-YOUR_KEY_HERE"
SIM_ID = "9D1B772E-7D9B-4934-A7F4-D2829CEB0065"

def screenshot(name):
    path = f"/tmp/{name}.png"
    subprocess.run(f"xcrun simctl io {SIM_ID} screenshot {path}", shell=True)
    return path

def click(x, y):
    script = f'''
    tell application "Simulator" to activate
    delay 0.2
    tell application "System Events"
        click at {{{x}, {y}}}
    end tell
    '''
    subprocess.run(['osascript', '-e', script], capture_output=True)
    time.sleep(0.5)

def analyze_image(image_path, prompt):
    with open(image_path, "rb") as f:
        base64_img = base64.b64encode(f.read()).decode()
    
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": "gpt-4o-mini",
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{base64_img}", "detail": "low"}}
            ]
        }],
        "max_tokens": 300
    }
    
    response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
    return response.json()['choices'][0]['message']['content']

print("⏱️ TEST DÉMARRÉ:", time.strftime("%H:%M:%S"))

# 1. Go to Settings
print("📍 Navigation vers Settings...")
click(370, 850)
time.sleep(1)

# 2. Screenshot Settings
settings_img = screenshot("settings")
print("🔍 Analyse Settings...")
result = analyze_image(settings_img, "Look at this iOS Settings screen. Answer in one line: Do you see any text with underscores like 'settings_label' or 'notification_title'? Just say YES or NO and what you see.")
print(f"   → {result}")

# 3. Try to change language
print("🇫🇷 Changement vers Français...")
click(207, 400)  # Language picker
time.sleep(0.5)
click(207, 444)  # French option
time.sleep(2)

# 4. Check if French worked
click(50, 850)  # Home tab
time.sleep(1)
home_img = screenshot("home_french")
result = analyze_image(home_img, "Is this iOS app in French? Look for 'Bonsoir' or 'Dépenses'. Answer: YES (it's French) or NO (still English)")
print(f"   Home → {result}")

print("\n⏱️ TEST TERMINÉ:", time.strftime("%H:%M:%S"))
print("\n📊 VERDICT:")
if "YES" in result and "French" in result:
    print("✅ La localisation fonctionne!")
else:
    print("❌ La localisation NE fonctionne PAS!")