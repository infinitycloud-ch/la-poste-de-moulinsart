# 📱 PRD - ExpenseAI : Assistant Intelligent de Gestion des Dépenses

## 🎯 Vision Produit
Application iOS native utilisant GPT-4 Vision Mini pour automatiser la catégorisation des dépenses professionnelles avec une UX minimaliste et futuriste.

## 🔑 Fonctionnalités Clés

### 1. Capture Intelligente
- **Photo → Catégorie**: Prendre une photo d'un reçu/facture
- **IA Classification**: GPT-4 Vision Mini analyse et catégorise automatiquement
- **Extraction OCR**: Montant, date, fournisseur extraits automatiquement

### 2. Catégories Prédéfinies (Suisse)
```
- Assurance TVA 8.1%
- Automobiles/Motos  
- Cadeau Clientèle TVA 8.1% (6642)
- Divers TVA 0% (6500)
- Fourniture bureau TVA 8.1% (6500)
- Frais déplacements TVA 8.1%
- Impôts
- Loyer TVA 8.1% (6000)
- Machines Bureau Immo TVA 8.1% (1520)
- Mobilier Bureau Immo TVA 8.1% (1513)
- Nuits Hôtel TVA 3.7% (5820)
- Repas/Divertissements TVA 8.1% (5880)
- Services Pro/Consulting TVA 8.1% (6530)
- Taxes/Amendes TVA 0% (6300)
```

### 3. UX Minimaliste
- **One-Tap Capture**: Bouton flottant pour photo rapide
- **Auto-Process**: Traitement IA immédiat sans action utilisateur
- **Swipe Actions**: Valider/Modifier/Supprimer par gestes
- **Dashboard Épuré**: Visualisation mensuelle simple

## 🏗️ Architecture Technique

### Stack
- **Frontend**: SwiftUI + Combine
- **IA**: OpenAI GPT-4 Vision Mini API
- **Storage**: Core Data (LOCAL UNIQUEMENT)
- **Design**: Neumorphism + Glassmorphism
- **Export**: CSV + PDF natif
- **Auth**: AUCUNE (app mono-utilisateur)

### Sécurité
- API Key hardcodée (fournie)
- Stockage 100% local sur device
- Pas de cloud, pas de sync
- Pas d'authentification

## 🎨 Design System

### Palette Futuriste
- Background: Gradient noir → gris foncé
- Accent: Cyan néon (#00FFFF)
- Secondary: Violet néon (#FF00FF)
- Success: Vert néon (#00FF00)
- Cards: Glassmorphism avec blur

### Composants
- Boutons: Neumorphiques avec glow
- Cards: Glass effect avec bordures néon
- Animations: Transitions fluides 60fps
- Typographie: SF Pro Display

## 📊 Écrans Principaux

### 1. Dashboard
- Total mensuel en grand
- Graph minimaliste des catégories
- Liste des 5 dernières dépenses

### 2. Capture
- Caméra plein écran
- Overlay minimal avec guide
- Bouton capture unique

### 3. Détail Dépense
- Photo floue en background
- Infos extraites en overlay
- Catégorie avec confidence IA %

### 4. Analytics & Rapports
- Donut chart par catégorie
- Timeline des dépenses
- Export CSV one-tap
- Génération PDF avec logo
- Rapports mensuels/trimestriels/annuels
- Totaux par catégorie avec TVA détaillée

## 🚀 Iterations de Développement

### Iteration 1: Core & IA (2 jours)
- Setup projet Xcode
- Intégration OpenAI API
- Core Data models
- Capture photo basique

### Iteration 2: UX Minimaliste (2 jours)
- Design system implementation
- Écrans principaux
- Animations & transitions
- Swipe gestures

### Iteration 3: Polish & Maquette (1 jour)
- Effets visuels futuristes
- Optimisations performance
- Screenshots haute qualité
- Documentation utilisateur

## 📦 Livrables

1. **Code Source**: Projet Xcode complet
2. **Maquettes**: Screenshots HD de tous les écrans
3. **Demo Video**: Capture du flow complet
4. **Documentation**: Guide d'installation et utilisation
5. **Build**: .ipa testable sur simulateur/device

## ⚡ Critères de Succès

- [ ] Classification IA précise à 90%+
- [ ] Temps capture→résultat < 3 secondes
- [ ] Interface fluide 60fps
- [ ] 0 action requise post-capture
- [ ] Export comptable fonctionnel

## 🎯 Objectif Final
Créer l'app de gestion des dépenses la plus efficace et élégante du marché, où l'IA fait 95% du travail.