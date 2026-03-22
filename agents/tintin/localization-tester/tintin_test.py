#!/usr/bin/env python3
"""
Tintin's Localization Test Suite
Interface principale pour les tests de localisation
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from tests.quick_test import run_quick_french_test
from tests.full_test import run_full_test
import argparse
import json
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Tintin's Localization Tester")
    parser.add_argument(
        "--mode", 
        choices=["quick", "full", "custom"],
        default="quick",
        help="Test mode: quick (French only), full (8 languages), custom"
    )
    parser.add_argument(
        "--language",
        choices=["en", "fr", "de", "it", "es", "ja", "ko", "sk"],
        help="Specific language to test (for custom mode)"
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Generate detailed HTML report"
    )
    
    args = parser.parse_args()
    
    print("""
    🚀 TINTIN'S LOCALIZATION TESTER
    ================================
    Using GPT-4o-mini for fast visual analysis
    """)
    
    if args.mode == "quick":
        print("Mode: Quick test (French only)")
        results = run_quick_french_test()
        
    elif args.mode == "full":
        print("Mode: Full test (8 languages)")
        results = run_full_test()
        
    elif args.mode == "custom" and args.language:
        print(f"Mode: Custom test ({args.language})")
        # TODO: Implement custom single language test
        print("Custom mode coming soon...")
        return
    
    # Generate HTML report if requested
    if args.report and results:
        generate_html_report(results)
    
    # Quick verdict
    if results.get("verdict") == "PASS":
        print("\n✅ TEST PASSED - Localization working!")
        return 0
    else:
        print("\n❌ TEST FAILED - Issues detected!")
        return 1

def generate_html_report(results):
    """Generate an HTML report"""
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Localization Test Report</title>
        <style>
            body {{ font-family: -apple-system, sans-serif; margin: 40px; }}
            .pass {{ color: green; }}
            .fail {{ color: red; }}
            .screenshot {{ max-width: 300px; margin: 10px; }}
            .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
        </style>
    </head>
    <body>
        <h1>Localization Test Report</h1>
        <p>Date: {results.get('test_date', 'N/A')}</p>
        <p>Type: {results.get('test_type', 'N/A')}</p>
        <h2>Verdict: <span class="{'pass' if results.get('verdict') == 'PASS' else 'fail'}">{results.get('verdict', 'N/A')}</span></h2>
        
        <h3>Details:</h3>
        <pre>{json.dumps(results, indent=2)}</pre>
    </body>
    </html>
    """
    
    report_path = Path("reports/latest_report.html")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(html)
    print(f"📊 HTML report generated: {report_path}")

if __name__ == "__main__":
    exit(main())