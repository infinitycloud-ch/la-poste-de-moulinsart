"""
Configuration pour le testeur de localisation
"""

# OpenAI Configuration
OPENAI_API_KEY = "sk-YOUR_KEY_HERE"
OPENAI_MODEL = "gpt-4o-mini"  # Model multimodal rapide

# Simulator Configuration
SIMULATOR_NAME = "tintin"  # Ton émulateur dédié
APP_BUNDLE_ID = "com.minhtam.ExpenseAI"

# App Navigation
TABS = {
    "home": {"position": (50, 850), "fr_name": "Accueil"},
    "expenses": {"position": (140, 850), "fr_name": "Dépenses"},
    "scanner": {"position": (207, 850), "fr_name": "Scanner"},
    "statistics": {"position": (290, 850), "fr_name": "Statistiques"},
    "settings": {"position": (370, 850), "fr_name": "Paramètres"}
}

# Languages to test
LANGUAGES = {
    "en": {"name": "English", "index": 0},
    "fr": {"name": "Français", "index": 1},
    "de": {"name": "Deutsch", "index": 2},
    "it": {"name": "Italiano", "index": 3},
    "es": {"name": "Español", "index": 4},
    "ja": {"name": "日本語", "index": 5},
    "ko": {"name": "한국어", "index": 6},
    "sk": {"name": "Slovenčina", "index": 7}
}

# Expected translations (for validation)
EXPECTED_TRANSLATIONS = {
    "fr": {
        "settings_title": "Paramètres",
        "home_title": "Accueil",
        "expenses_title": "Dépenses",
        "good_evening": "Bonsoir",
        "today_spending": "Dépenses du jour"
    },
    "de": {
        "settings_title": "Einstellungen",
        "home_title": "Startseite",
        "expenses_title": "Ausgaben"
    }
}

# Paths
REPORTS_DIR = "~/moulinsart/agents/tintin/localization-tester/reports"
SCREENSHOTS_DIR = "/tmp/localization_screenshots"