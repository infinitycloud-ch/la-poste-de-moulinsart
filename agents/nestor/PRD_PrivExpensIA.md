# 📋 PRD - PrivExpensIA: Expense Tracker Privacy Edition

## 🎯 Objectif
Créer une application iOS de tracking des dépenses avec un focus sur la privacy et l'élégance suisse.

## 📱 Description
PrivExpensIA est une app iOS native qui permet de tracker ses dépenses personnelles avec:
- Design Glass minimaliste et élégant
- Support multi-devises (focus Suisse: CHF, EUR, USD)
- Localisation complète (8 langues)
- Privacy by design (pas de tracking, pas de cloud)
- Calcul TVA automatique pour la Suisse

## 🎨 Design System: Liquid Glass
- Effets glassmorphism avec blur et transparence
- Couleurs douces et pastels
- Animations fluides
- Corners arrondis uniformes
- Typographie SF Pro

## 🌍 Localisation
Support complet pour:
- 🇨🇭 Français (Suisse)
- 🇨🇭 Allemand (Suisse)
- 🇨🇭 Italien (Suisse)
- 🇬🇧 Anglais
- 🇯🇵 Japonais
- 🇰🇷 Coréen
- 🇸🇰 Slovaque
- 🇪🇸 Espagnol

## 💰 Devises Supportées
- CHF (Franc suisse) - Par défaut
- EUR (Euro)
- USD (Dollar US)
- GBP (Livre sterling)
- JPY (Yen japonais)

## 📊 Fonctionnalités Principales

### 1. Dashboard
- Vue d'ensemble des dépenses
- Statistiques en temps réel
- Graphiques interactifs
- Balance mensuelle

### 2. Gestion des Dépenses
- Ajout rapide de dépenses
- Catégorisation automatique
- Photos de reçus
- Notes et tags

### 3. TVA Suisse
- Calcul automatique (7.7%, 3.7%, 2.5%)
- Extraction intelligente depuis reçus
- Export pour comptabilité

### 4. Settings
- Language picker
- Currency selector
- Theme customization
- Privacy controls

## 🛠️ Stack Technique
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Persistance**: Core Data
- **Build**: xcodegen
- **Min iOS**: 16.0
- **Devices**: iPhone uniquement

## 📦 Structure du Projet
```
PrivExpensIA/
├── Models/
│   ├── ExpenseModel.swift
│   ├── CategoryModel.swift
│   └── CurrencyModel.swift
├── Views/
│   ├── HomeGlassView.swift
│   ├── ExpenseGlassView.swift
│   ├── StatsGlassView.swift
│   └── SettingsGlassView.swift
├── ViewModels/
│   ├── ExpenseViewModel.swift
│   └── StatsViewModel.swift
├── Utils/
│   ├── LocalizationManager.swift
│   ├── CurrencyManager.swift
│   └── TaxCalculator.swift
└── Resources/
    ├── Localizable.strings
    └── Assets.xcassets
```

## ✅ Critères de Succès
- [ ] App compile sans erreur
- [ ] Tous les écrans sont fonctionnels
- [ ] Localisation fonctionne pour 8 langues
- [ ] Currency switcher fonctionne
- [ ] Design Glass uniforme
- [ ] Calcul TVA correct
- [ ] Screenshots de validation

## 🚀 Sprints

### Sprint 1: Foundation
- Setup projet xcodegen
- Structure MVVM
- Core Data models
- Navigation de base

### Sprint 2: Core Features
- UI Glass complète
- CRUD expenses
- Localisation
- Currency management

### Sprint 3: Polish
- Animations
- Charts et stats
- TVA calculator
- Final testing

## 📝 Notes
- Privacy first: Aucune donnée ne quitte l'appareil
- Design inspiré de l'horlogerie suisse
- Focus sur l'expérience utilisateur premium
- Compatible avec les standards de comptabilité suisse