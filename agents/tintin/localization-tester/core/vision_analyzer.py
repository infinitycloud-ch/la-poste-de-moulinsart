"""
Vision analyzer using GPT-4o-mini
"""
import base64
import json
import requests
from pathlib import Path
from typing import Dict, List, Optional

class VisionAnalyzer:
    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.api_key = api_key
        self.model = model
        self.api_url = "https://api.openai.com/v1/chat/completions"
        
    def encode_image(self, image_path: str) -> str:
        """Encode image to base64"""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')
    
    def analyze_screenshot(self, image_path: str, prompt: str) -> Dict:
        """Analyze a screenshot with GPT-4o-mini"""
        if not Path(image_path).exists():
            return {"error": f"Image not found: {image_path}"}
            
        base64_image = self.encode_image(image_path)
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }
        
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a QA tester analyzing iOS app screenshots. Always respond in valid JSON format."
                },
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
                                "url": f"data:image/png;base64,{base64_image}",
                                "detail": "low"  # Use low detail for faster response
                            }
                        }
                    ]
                }
            ],
            "max_tokens": 500,
            "temperature": 0.1  # Low temperature for consistent results
        }
        
        try:
            response = requests.post(self.api_url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            content = response.json()['choices'][0]['message']['content']
            # Try to parse as JSON
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                # If not valid JSON, return as text
                return {"raw_response": content}
                
        except requests.exceptions.RequestException as e:
            return {"error": f"API request failed: {str(e)}"}
        except Exception as e:
            return {"error": f"Analysis failed: {str(e)}"}
    
    def detect_localization_issues(self, image_path: str) -> Dict:
        """Specifically check for localization issues"""
        prompt = """
        Analyze this iOS app screenshot for localization issues. Return JSON with:
        {
            "has_underscore_keys": boolean (true if you see text like "settings_label", "home_title"),
            "blank_areas": boolean (true if there are blank/white areas where content should be),
            "visible_texts": [list of main visible text strings],
            "language_detected": "en/fr/de/etc or unknown",
            "ui_elements": {
                "has_language_picker": boolean,
                "language_picker_location": [x, y] or null,
                "tab_bar_visible": boolean,
                "current_tab": "home/expenses/scanner/statistics/settings or unknown"
            }
        }
        """
        return self.analyze_screenshot(image_path, prompt)
    
    def verify_language_change(self, image_path: str, expected_language: str, expected_texts: List[str]) -> Dict:
        """Verify if the language has changed correctly"""
        prompt = f"""
        Check if this iOS app is displaying in {expected_language}. Return JSON:
        {{
            "language_correct": boolean,
            "found_expected_texts": [list of expected texts that were found],
            "missing_texts": [list of expected texts that were NOT found],
            "actual_texts": [main texts visible on screen],
            "has_errors": boolean (true if you see error messages or broken UI)
        }}
        Expected texts to look for: {json.dumps(expected_texts)}
        """
        return self.analyze_screenshot(image_path, prompt)