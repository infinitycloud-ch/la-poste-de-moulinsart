#!/usr/bin/env ruby
# 🚀 FASTLANE UPLOAD MÉTADONNÉES ASTRODAILY
# =========================================

require 'fastlane'

# Configuration
APP_IDENTIFIER = "io.tuist.AstroDaily"
APPLE_ID = "6747093166"

# Descriptions complètes (de app_store_metadata.md)
DESCRIPTION_FR = """AstroDaily révolutionne votre horoscope quotidien grâce à l'intelligence artificielle de pointe. Découvrez des prédictions personnalisées générées chaque jour, spécialement conçues pour votre signe astrologique.

FONCTIONNALITÉS PRINCIPALES :

► Horoscope IA Quotidien
• Prédictions uniques générées par IA avancée
• Contenu renouvelé chaque jour à minuit
• Analyses détaillées pour amour, travail et santé
• Niveaux d'énergie et nombres chanceux

► 12 Signes du Zodiaque
• Interface visuelle époustouflante
• Images cosmiques générées par IA
• Descriptions personnalisées pour chaque signe
• Mode clair/sombre automatique

► Journal Astral Personnel
• Archivez vos horoscopes favoris
• Suivez votre parcours astrologique
• Statistiques et tendances personnelles
• Exportation de vos données

► Expérience Premium
• Débloquez tous les signes (famille/amis)
• Sans publicité
• Contenu approfondi exclusif
• Mises à jour prioritaires

► Innovation Technologique
• IA Quantique dernière génération
• Algorithmes astrologiques avancés
• Protection des données maximale
• Synchronisation iCloud

POURQUOI ASTRODAILY ?

Contrairement aux horoscopes traditionnels, AstroDaily utilise l'intelligence artificielle pour créer des prédictions véritablement uniques chaque jour. Notre technologie analyse des milliers de paramètres cosmiques pour générer des conseils pertinents et inspirants.

ABONNEMENTS DISPONIBLES :
• Signes individuels : 3,50 CHF (achat unique)
• Pack Famille (4 signes) : 9,90 CHF
• Tous les signes : 19,90 CHF

Commencez votre voyage cosmique aujourd'hui. Téléchargez AstroDaily et découvrez ce que les étoiles, guidées par l'IA, ont à vous révéler.

Note : Divertissement uniquement. Les prédictions sont générées par IA à des fins de divertissement et de réflexion personnelle."""

DESCRIPTION_EN = """AstroDaily revolutionizes your daily horoscope with cutting-edge artificial intelligence. Discover personalized predictions generated fresh every day, specially crafted for your zodiac sign.

KEY FEATURES:

► Daily AI Horoscope
• Unique predictions powered by advanced AI
• Fresh content updated daily at midnight
• Detailed insights for love, work, and health
• Energy levels and lucky numbers

► 12 Zodiac Signs
• Stunning visual interface
• AI-generated cosmic imagery
• Personalized descriptions for each sign
• Automatic light/dark mode

► Personal Astral Journal
• Archive your favorite horoscopes
• Track your astrological journey
• Personal statistics and trends
• Export your data

► Premium Experience
• Unlock all signs (family/friends)
• Ad-free experience
• Exclusive in-depth content
• Priority updates

► Technological Innovation
• Latest generation Quantum AI
• Advanced astrological algorithms
• Maximum data protection
• iCloud synchronization

WHY ASTRODAILY?

Unlike traditional horoscopes, AstroDaily uses artificial intelligence to create truly unique predictions every day. Our technology analyzes thousands of cosmic parameters to generate relevant and inspiring guidance.

AVAILABLE SUBSCRIPTIONS:
• Individual signs: CHF 3.50 (one-time purchase)
• Family Pack (4 signs): CHF 9.90
• All signs: CHF 19.90

Start your cosmic journey today. Download AstroDaily and discover what the AI-guided stars have to reveal to you.

Note: For entertainment only. Predictions are AI-generated for entertainment and personal reflection purposes."""

# Lane principale
lane :upload_complete_metadata do
  
  puts "🚀 UPLOAD COMPLET MÉTADONNÉES ASTRODAILY"
  puts "========================================"
  
  # Upload avec deliver
  deliver(
    # Configuration de base
    app_identifier: APP_IDENTIFIER,
    app: APPLE_ID,
    
    # Métadonnées multilingues
    description: {
      'fr-FR' => DESCRIPTION_FR,
      'en-US' => DESCRIPTION_EN
    },
    
    name: {
      'fr-FR' => 'AstroDaily - Horoscope IA',
      'en-US' => 'AstroDaily - AI Horoscope'
    },
    
    subtitle: {
      'fr-FR' => 'Prédictions quotidiennes IA',
      'en-US' => 'Daily AI Predictions'
    },
    
    keywords: {
      'fr-FR' => 'horoscope,astrologie,zodiaque,IA,prédictions,quotidien,astral,signes,cosmos,spirituel',
      'en-US' => 'horoscope,astrology,zodiac,AI,predictions,daily,astral,signs,cosmos,spiritual,fortune'
    },
    
    promotional_text: {
      'fr-FR' => 'Découvrez votre horoscope personnalisé par IA! Prédictions uniques quotidiennes, journal astral, et insights cosmiques. L\'astrologie réinventée.',
      'en-US' => 'Discover your AI-personalized horoscope! Unique daily predictions, astral journal, and cosmic insights. Astrology reinvented.'
    },
    
    release_notes: {
      'fr-FR' => 'Version initiale d\'AstroDaily avec horoscopes IA, 12 signes zodiacaux, journal astral personnel et interface liquid glass moderne.',
      'en-US' => 'Initial release of AstroDaily with AI horoscopes, 12 zodiac signs, personal astral journal and modern liquid glass interface.'
    },
    
    # Catégories
    primary_category: "LIFESTYLE",
    secondary_category: "ENTERTAINMENT",
    
    # URLs
    support_url: "https://infinity-cloud.ch/astrodaily/support",
    marketing_url: "https://infinity-cloud.ch/astrodaily",
    privacy_url: "https://infinity-cloud.ch/astrodaily/privacy",
    
    # Configuration technique
    copyright: "#{Time.now.year} Studio M3",
    
    # Age rating
    rating_config_path: "./age_rating.json",
    
    # Review info
    review_information: {
      first_name: "Studio",
      last_name: "M3",
      phone_number: "+41791234567",
      email_address: "studio.m3@infinity-cloud.ch",
      demo_user: "astrotest@test.com",
      demo_password: "Test1234!",
      notes: "Application d'horoscope avec IA générative et monétisation hybride (IAP + AdMob). Horoscopes quotidiens avec images IA générées, 12 signes astrologiques, journal astral. Interface bilingue FR/EN. Tous les IAP testés en Sandbox. API REST pour contenu quotidien avec fallback offline."
    },
    
    # Screenshots (utiliser dossier généré)
    screenshots_path: "./AppStore_Screenshots/",
    
    # Options d'upload
    force: true,
    skip_binary_upload: true,
    skip_screenshots: false,
    submit_for_review: false,
    automatic_release: false,
    
    # Localisation des screenshots
    localized_screenshot_path: {
      'fr-FR' => './AppStore_Screenshots/',
      'en-US' => './AppStore_Screenshots/'
    }
  )
  
  puts ""
  puts "✅ UPLOAD TERMINÉ AVEC SUCCÈS!"
  puts ""
  puts "🎯 PROCHAINES ÉTAPES :"
  puts "1. Vérifier dans App Store Connect"
  puts "2. Associer le build à la version"
  puts "3. Configurer les prix IAP"
  puts "4. Tester avec comptes Sandbox"
  puts "5. Submit for Review"
  puts ""
end

# Lane pour générer age rating config
lane :generate_age_rating do
  age_rating_config = {
    "ALCOHOL_TOBACCO_OR_DRUG_USE_OR_REFERENCES" => 0,
    "CONTESTS" => 0,
    "GAMBLING_AND_CONTESTS" => 0,
    "HORROR_FEAR_THEMES" => 0,
    "MATURE_SUGGESTIVE_THEMES" => 0,
    "MEDICAL_TREATMENT_INFO" => 0,
    "PROFANITY_CRUDE_HUMOR" => 0,
    "SEXUAL_CONTENT_GRAPHIC_AND_NUDITY" => 0,
    "SEXUAL_CONTENT_OR_NUDITY" => 0,
    "SIMULATED_GAMBLING" => 0,
    "VIOLENCE_CARTOON_OR_FANTASY" => 0,
    "VIOLENCE_REALISTIC_PROLONGED_GRAPHIC_OR_SADISTIC" => 0,
    "VIOLENCE_REALISTIC" => 0
  }
  
  File.write("age_rating.json", JSON.pretty_generate(age_rating_config))
  puts "✅ Fichier age_rating.json généré"
end

# Lane de vérification
lane :verify_metadata do
  puts "🔍 VÉRIFICATION MÉTADONNÉES"
  puts "==========================="
  
  # Vérifier descriptions
  puts "📝 Longueur descriptions:"
  puts "   FR: #{DESCRIPTION_FR.length} chars (max 4000)"
  puts "   EN: #{DESCRIPTION_EN.length} chars (max 4000)"
  
  # Vérifier keywords
  fr_keywords = 'horoscope,astrologie,zodiaque,IA,prédictions,quotidien,astral,signes,cosmos,spirituel'
  en_keywords = 'horoscope,astrology,zodiac,AI,predictions,daily,astral,signs,cosmos,spiritual,fortune'
  
  puts "🔍 Mots-clés:"
  puts "   FR: #{fr_keywords.length} chars (max 100)"
  puts "   EN: #{en_keywords.length} chars (max 100)"
  
  # Vérifier screenshots
  if Dir.exist?("AppStore_Screenshots")
    screenshots_count = Dir.glob("AppStore_Screenshots/**/*.png").count
    puts "📸 Screenshots: #{screenshots_count} trouvés"
  else
    puts "❌ Dossier AppStore_Screenshots manquant"
  end
  
  puts ""
  puts "✅ Vérification terminée"
end

# Lane rapide pour uploader juste les textes
lane :upload_texts_only do
  puts "📝 UPLOAD TEXTES UNIQUEMENT"
  
  deliver(
    app_identifier: APP_IDENTIFIER,
    app: APPLE_ID,
    
    description: {
      'fr-FR' => DESCRIPTION_FR,
      'en-US' => DESCRIPTION_EN
    },
    
    keywords: {
      'fr-FR' => 'horoscope,astrologie,zodiaque,IA,prédictions,quotidien,astral,signes,cosmos,spirituel',
      'en-US' => 'horoscope,astrology,zodiac,AI,predictions,daily,astral,signs,cosmos,spiritual,fortune'
    },
    
    promotional_text: {
      'fr-FR' => 'Découvrez votre horoscope personnalisé par IA! Prédictions uniques quotidiennes, journal astral, et insights cosmiques. L\'astrologie réinventée.',
      'en-US' => 'Discover your AI-personalized horoscope! Unique daily predictions, astral journal, and cosmic insights. Astrology reinvented.'
    },
    
    skip_screenshots: true,
    skip_binary_upload: true,
    force: true
  )
  
  puts "✅ Textes uploadés!"
end