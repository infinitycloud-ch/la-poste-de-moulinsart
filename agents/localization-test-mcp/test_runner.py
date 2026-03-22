#!/usr/bin/env python3
"""
Localization Test Runner - MCP for PrivExpensIA
Automatise les tests de localisation avec screenshots et analyse
"""
import json
import subprocess
import time
import base64
import requests
from datetime import datetime
from pathlib import Path

class LocalizationTester:
    def __init__(self, config_path="config.json"):
        with open(config_path) as f:
            self.config = json.load(f)
        self.results = {}
        self.simulator_id = self._get_simulator_id()
        
    def _get_simulator_id(self):
        """Récupère l'ID du simulateur par nom"""
        result = subprocess.run(
            "xcrun simctl list devices --json",
            shell=True, capture_output=True, text=True
        )
        devices = json.loads(result.stdout)
        
        for runtime, device_list in devices['devices'].items():
            for device in device_list:
                if device['name'] == self.config.get('simulator_name', 'tintin'):
                    return device['udid']
        return None
    
    def screenshot(self, name):
        """Prend un screenshot"""
        path = f"screenshots/{name}.png"
        Path("screenshots").mkdir(exist_ok=True)
        subprocess.run(
            f"xcrun simctl io {self.simulator_id} screenshot {path}",
            shell=True, capture_output=True
        )
        return path
    
    def analyze_with_gpt(self, image_path, expected_texts):
        """Analyse le screenshot avec GPT-4o-mini"""
        with open(image_path, "rb") as f:
            base64_img = base64.b64encode(f.read()).decode()
        
        prompt = f"""
        Analyze this iOS app screenshot. Check for:
        1. Are these texts visible: {expected_texts}?
        2. Do you see any underscore keys like 'settings_label'?
        3. What language is the interface in?
        
        Return JSON: {{"has_expected_texts": true/false, "has_underscore_keys": true/false, "detected_language": "code", "visible_texts": []}}
        """
        
        headers = {
            "Authorization": f"Bearer {self.config['openai_api_key']}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "gpt-4o-mini",
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{base64_img}", "detail": "low"}}
                ]
            }],
            "max_tokens": 300,
            "temperature": 0.1
        }
        
        try:
            response = requests.post(
                "https://api.openai.com/v1/chat/completions",
                headers=headers, json=payload, timeout=10
            )
            content = response.json()['choices'][0]['message']['content']
            return json.loads(content)
        except Exception as e:
            print(f"  ⚠️ Analyse GPT échouée: {e}")
            return {"error": str(e)}
    
    def test_language(self, lang_code):
        """Test une langue spécifique"""
        lang_info = self.config['languages'][lang_code]
        print(f"\n🌍 Testing {lang_info['name']} ({lang_code})...")
        
        # 1. Terminer l'app
        subprocess.run(
            f"xcrun simctl terminate {self.simulator_id} {self.config['app_bundle']}",
            shell=True, capture_output=True
        )
        time.sleep(1)
        
        # 2. Changer la langue du simulateur
        subprocess.run(
            f"xcrun simctl spawn {self.simulator_id} defaults write -g AppleLanguages -array {lang_code}",
            shell=True, capture_output=True
        )
        subprocess.run(
            f"xcrun simctl spawn {self.simulator_id} defaults write -g AppleLocale {lang_code}",
            shell=True, capture_output=True  
        )
        
        # 3. Relancer l'app
        subprocess.run(
            f"xcrun simctl launch {self.simulator_id} {self.config['app_bundle']}",
            shell=True, capture_output=True
        )
        time.sleep(3)
        
        # 4. Screenshot Home
        home_path = self.screenshot(f"{lang_code}_home")
        print(f"  📸 Home screenshot: {home_path}")
        
        # 5. Analyser avec GPT
        analysis = self.analyze_with_gpt(home_path, lang_info['home_texts'])
        
        # 6. Déterminer le statut
        passed = (
            analysis.get('has_expected_texts', False) and 
            not analysis.get('has_underscore_keys', False) and
            analysis.get('detected_language', '') == lang_code
        )
        
        result = {
            "language": lang_code,
            "name": lang_info['name'],
            "passed": passed,
            "screenshot": home_path,
            "analysis": analysis,
            "timestamp": datetime.now().isoformat()
        }
        
        if passed:
            print(f"  ✅ {lang_info['name']}: PASS")
        else:
            print(f"  ❌ {lang_info['name']}: FAIL")
            if analysis.get('has_underscore_keys'):
                print(f"     - Clés underscore détectées")
            if not analysis.get('has_expected_texts'):
                print(f"     - Textes attendus non trouvés")
        
        return result
    
    def run_all_tests(self):
        """Test toutes les langues"""
        print("🚀 LOCALIZATION TEST SUITE")
        print("=" * 50)
        print(f"App: {self.config['app_bundle']}")
        print(f"Simulator: {self.simulator_id}")
        print(f"Languages: {', '.join(self.config['languages'].keys())}")
        
        for lang_code in self.config['languages']:
            self.results[lang_code] = self.test_language(lang_code)
        
        self.generate_report()
        return self.results
    
    def run_quick_test(self, lang="fr"):
        """Test rapide d'une seule langue"""
        print(f"🚀 QUICK TEST - {lang}")
        print("=" * 50)
        
        self.results[lang] = self.test_language(lang)
        self.generate_report()
        return self.results[lang]
    
    def generate_report(self):
        """Génère un rapport HTML détaillé"""
        Path("reports").mkdir(exist_ok=True)
        
        total = len(self.results)
        passed = sum(1 for r in self.results.values() if r.get('passed', False))
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Localization Test Report - PrivExpensIA</title>
            <style>
                body {{ 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    margin: 0; 
                    padding: 40px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }}
                .container {{
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                }}
                h1 {{ 
                    color: #333; 
                    border-bottom: 3px solid #667eea;
                    padding-bottom: 20px;
                }}
                .summary {{
                    display: flex;
                    gap: 20px;
                    margin: 30px 0;
                }}
                .metric {{
                    flex: 1;
                    padding: 20px;
                    border-radius: 10px;
                    text-align: center;
                }}
                .metric.success {{ background: #d4edda; color: #155724; }}
                .metric.danger {{ background: #f8d7da; color: #721c24; }}
                .metric.info {{ background: #d1ecf1; color: #0c5460; }}
                .metric h2 {{ margin: 0; font-size: 36px; }}
                .metric p {{ margin: 5px 0 0 0; }}
                .grid {{ 
                    display: grid; 
                    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
                    gap: 20px;
                    margin-top: 30px;
                }}
                .card {{ 
                    border: 2px solid #e0e0e0; 
                    border-radius: 12px;
                    overflow: hidden;
                    transition: transform 0.2s;
                }}
                .card:hover {{ 
                    transform: translateY(-5px);
                    box-shadow: 0 10px 20px rgba(0,0,0,0.1);
                }}
                .card.pass {{ border-color: #28a745; }}
                .card.fail {{ border-color: #dc3545; }}
                .card-header {{
                    padding: 15px;
                    font-weight: bold;
                    color: white;
                }}
                .card.pass .card-header {{ background: #28a745; }}
                .card.fail .card-header {{ background: #dc3545; }}
                .card-body {{ padding: 15px; }}
                .card img {{ 
                    width: 100%; 
                    height: 200px;
                    object-fit: cover;
                    border-bottom: 1px solid #e0e0e0;
                }}
                .details {{
                    font-size: 12px;
                    color: #666;
                    margin-top: 10px;
                }}
                .footer {{
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e0e0e0;
                    text-align: center;
                    color: #666;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🌍 Localization Test Report</h1>
                <p style="color: #666;">Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                
                <div class="summary">
                    <div class="metric {'success' if passed == total else 'danger'}">
                        <h2>{passed}/{total}</h2>
                        <p>Languages Passed</p>
                    </div>
                    <div class="metric info">
                        <h2>{total}</h2>
                        <p>Total Languages</p>
                    </div>
                    <div class="metric {'success' if passed == total else 'danger'}">
                        <h2>{int(passed/total*100) if total > 0 else 0}%</h2>
                        <p>Success Rate</p>
                    </div>
                </div>
                
                <h2>Test Results by Language</h2>
                <div class="grid">
        """
        
        for lang_code, result in self.results.items():
            status = "pass" if result.get('passed', False) else "fail"
            analysis = result.get('analysis', {})
            
            html += f"""
                <div class="card {status}">
                    <div class="card-header">
                        {result.get('name', lang_code.upper())} ({lang_code})
                        {'✅' if status == 'pass' else '❌'}
                    </div>
                    <img src="../{result.get('screenshot', '')}" alt="{lang_code}">
                    <div class="card-body">
                        <div class="details">
                            <p><strong>Status:</strong> {status.upper()}</p>
                            <p><strong>Has Expected Texts:</strong> {'✅' if analysis.get('has_expected_texts') else '❌'}</p>
                            <p><strong>Has Underscore Keys:</strong> {'❌' if analysis.get('has_underscore_keys') else '✅'}</p>
                            <p><strong>Detected Language:</strong> {analysis.get('detected_language', 'unknown')}</p>
                        </div>
                    </div>
                </div>
            """
        
        html += f"""
                </div>
                
                <div class="footer">
                    <p>PrivExpensIA Localization Test Suite v1.0</p>
                    <p>Powered by GPT-4o-mini</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        report_path = f"reports/report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        with open(report_path, "w") as f:
            f.write(html)
        
        # Aussi sauvegarder comme latest
        with open("reports/latest.html", "w") as f:
            f.write(html)
        
        print(f"\n📊 Report saved: {report_path}")
        print(f"   Open: file://{Path(report_path).absolute()}")
        
        # Résumé dans la console
        print("\n" + "=" * 50)
        print("SUMMARY:")
        print(f"✅ Passed: {passed}/{total}")
        print(f"❌ Failed: {total - passed}/{total}")
        
        if passed < total:
            print("\nFailed languages:")
            for lang, result in self.results.items():
                if not result.get('passed'):
                    print(f"  - {result.get('name', lang)}")

if __name__ == "__main__":
    import sys
    
    tester = LocalizationTester()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--quick":
        # Test rapide (français seulement)
        lang = sys.argv[2] if len(sys.argv) > 2 else "fr"
        tester.run_quick_test(lang)
    else:
        # Test complet
        tester.run_all_tests()