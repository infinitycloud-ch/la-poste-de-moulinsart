# Guide d'automatisation avec Fastlane pour AstroDaily

Ce guide explique comment mettre en place Fastlane pour automatiser complètement le processus de soumission de l'application AstroDaily à l'App Store.

## Prérequis

1. Xcode installé
2. Ruby installé (généralement préinstallé sur macOS)
3. Un compte Apple Developer actif
4. L'application AstroDaily correctement configurée avec les icônes et métadonnées

## Installation de Fastlane

```bash
# Installation via Ruby gems
gem install fastlane

# Ou avec Homebrew
brew install fastlane
```

## Configuration initiale

1. Dans le dossier racine du projet AstroDaily, initialisez Fastlane :

```bash
cd ~/swift_factory/SwissFactory3.0/AstroDaily
fastlane init
```

2. Lors de l'initialisation, Fastlane vous demandera plusieurs informations :
   - Choisissez "Automate App Store distribution"
   - Fournissez votre Apple ID
   - Sélectionnez l'application dans App Store Connect (ou créez-la si elle n'existe pas encore)

## Configuration des certificats et profils de provisionnement

Fastlane offre un outil appelé "match" pour gérer les certificats et profils :

```bash
# Initialisation de match
fastlane match init

# Génération des certificats et profils
fastlane match development
fastlane match appstore
```

Vous devrez spécifier un dépôt Git privé pour stocker vos certificats de manière sécurisée.

## Personnalisation du Fastfile

Le script `auto_doc_submit.sh` a déjà créé un Fastfile de base, mais vous pouvez l'étendre :

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and upload to App Store"
  lane :release do
    # Incrémenter le numéro de build
    increment_build_number

    # Mettre à jour les captures d'écran si nécessaire
    # snapshot
    
    # Mettre à jour les métadonnées
    # deliver(skip_binary_upload: true, force: true)
    
    # Utiliser match pour les certificats
    match(type: "appstore")
    
    # Construire l'application
    build_app(
      scheme: "AstroDaily",
      workspace: "AstroDaily/AstroDaily.xcworkspace",
      clean: true,
      output_directory: "build",
      export_method: "app-store"
    )
    
    # Télécharger vers l'App Store
    upload_to_app_store(
      skip_metadata: false,
      skip_screenshots: false,
      force: true,
      submit_for_review: true,
      automatic_release: true
    )
    
    # Notification Slack (optionnel)
    # slack(message: "AstroDaily v#{get_version_number} a été soumise à l'App Store!")
  end
  
  desc "Génère les captures d'écran pour tous les appareils"
  lane :screenshots do
    snapshot
  end
  
  desc "Incrémente le numéro de version"
  lane :bump_version do
    # Incrémente la version mineure (ex: 1.0.0 -> 1.1.0)
    increment_version_number(bump_type: "minor")
    # Réinitialise le numéro de build à 1
    increment_build_number(build_number: 1)
  end
end
```

## Fichier Appfile

Votre Appfile devrait ressembler à ceci :

```ruby
app_identifier("com.swissfactory.astrodaily") # Le bundle ID de votre app
apple_id("votre_apple_id@email.com") # Votre Apple ID
itc_team_id("123456789") # ID de votre équipe App Store Connect
team_id("AB12CD34EF") # ID de votre équipe Developer
```

## Automatisation complète

Pour automatiser complètement le processus de release, vous pouvez maintenant exécuter :

```bash
./auto_submit.sh
```

Ou directement avec Fastlane :

```bash
fastlane release
```

## Intégration CI/CD

Pour aller plus loin, vous pouvez intégrer Fastlane à un service CI/CD comme GitHub Actions, Travis CI ou Jenkins pour déclencher automatiquement des builds lors des commits ou des tags Git.

### Exemple de configuration GitHub Actions

Créez un fichier `.github/workflows/release.yml` :

```yaml
name: Release to App Store

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2
        
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '2.7'
          
      - name: Install Fastlane
        run: gem install fastlane
        
      - name: Setup certificates
        uses: ruby/setup-ruby@v1
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
        
      - name: Build and upload to App Store
        run: fastlane release
        env:
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
```

## Conseils supplémentaires

1. **Gestion des secrets** : Utilisez des variables d'environnement pour les mots de passe et les clés API.
2. **Tests automatisés** : Ajoutez `scan` dans votre Fastfile pour exécuter les tests automatiquement avant la soumission.
3. **Bêta TestFlight** : Créez une lane `beta` pour déployer uniquement sur TestFlight.
4. **Notifications** : Intégrez des notifications Slack ou Discord pour être informé des soumissions.
5. **Documentation** : Maintenez à jour ce guide pour les futurs développeurs du projet.

Avec cette configuration, vous disposez d'un pipeline complet d'automatisation pour AstroDaily, ce qui vous permet de vous concentrer sur le développement plutôt que sur les tâches manuelles de soumission. 