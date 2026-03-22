# 📱 PRD - ExpenseAI Privacy Edition
## 100% Offline. 100% Private. Your Data Never Leaves Your Device.

---

## 🎯 VISION PRODUIT
Application iOS de gestion des dépenses 100% offline utilisant l'IA locale pour analyser les reçus. Migration prévue vers Apple Intelligence dès iOS 26. Aucune donnée ne quitte jamais l'appareil.

## 🔐 SLOGAN PRINCIPAL
**"100% Private. 100% Offline. Apple Intelligence Ready."**

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Phase 1: MVP avec Vision Framework (Immédiat)
**Stack Technique:**
- **OCR**: Apple Vision Framework (VNRecognizeTextRequest)
- **Extraction**: NSDataDetector pour dates, montants, adresses
- **Catégorisation**: Core ML avec modèle custom léger
- **Storage**: Core Data 100% local
- **UI**: SwiftUI avec Liquid Glass design (sans animations bounce)

### Phase 2: LLM Vision Local (Court terme)
**Options évaluées:**
1. **Apple Foundation Models** (iOS 18.4+)
   - Modèle ~3B paramètres on-device
   - API native Swift (3 lignes de code)
   - Support multimodal texte + image
   - GRATUIT pour développeurs

2. **MLX Framework + LLaVA** (Alternative)
   - Framework Apple pour M-series/A17 Pro+
   - LLaVA pour vision multimodale
   - TinyLlama comme base (1.1B params)
   - Taille: ~2GB sur device

3. **Llama 3.2 Vision** via llama.cpp (Backup)
   - 11B model quantifié en 4-bit (~6GB)
   - Excellent pour OCR et documents
   - Support iOS via XCFramework

### Phase 3: Apple Intelligence (iOS 26)
**Migration automatique vers:**
- Apple Intelligence natif (Q3 2025)
- Private Cloud Compute pour cas complexes
- Chiffrement bout-en-bout
- Aucun accès Apple aux données

---

## 🌍 LOCALISATION & CATÉGORIES

### Langues supportées (Phase 1)
1. 🇬🇧 Anglais
2. 🇫🇷 Français  
3. 🇩🇪 Allemand
4. 🇮🇹 Italien
5. 🇪🇸 Espagnol
6. 🇯🇵 Japonais
7. 🇰🇷 Coréen
8. 🇨🇳 Chinois simplifié

### Système de catégories agnostique
**Catégories universelles par défaut:**
- Food & Dining
- Transportation
- Shopping
- Healthcare
- Entertainment
- Utilities
- Office Supplies
- Travel
- Services
- Other

**Features catégories:**
- ✅ Création de catégories custom
- ✅ Import/Export de templates
- ✅ Suggestions intelligentes basées sur l'historique
- ✅ Icônes et couleurs personnalisables
- ✅ Support multi-devises automatique

---

## 💎 FEATURES CLÉS

### Core Features (100% Offline)
1. **Smart Scan**
   - Photo → Extraction instantanée
   - Support multi-pages
   - Correction automatique perspective
   - Enhancement image automatique

2. **Data Extraction**
   - Montant (multi-devises)
   - Date et heure
   - Fournisseur/Marchand
   - TVA/Taxes (détection auto)
   - Articles détaillés (si visible)

3. **Organisation intelligente**
   - Catégorisation automatique
   - Tags personnalisables
   - Recherche full-text
   - Filtres avancés

4. **Export & Rapports**
   - CSV/Excel local
   - PDF avec images
   - Rapports mensuels/annuels
   - Graphiques interactifs

### Privacy Features
- 🔒 Aucune connexion internet requise
- 🔒 Pas de compte utilisateur
- 🔒 Chiffrement on-device (FileVault)
- 🔒 Backup iCloud chiffré (optionnel)
- 🔒 Face ID/Touch ID protection

---

## 💰 MODÈLE ÉCONOMIQUE

### Freemium simplifié
**GRATUIT**
- 10 scans/mois
- Catégories de base
- Export CSV

**PREMIUM** (CHF 4.90/mois ou CHF 39/an)
- Scans illimités
- Catégories custom illimitées
- Export Excel/PDF avancé
- Widgets iOS
- Shortcuts/Automations
- Support prioritaire

**ONE-TIME** (CHF 89)
- Lifetime Premium
- Early adopter bonus

---

## 📱 DESIGN SYSTEM

### Liquid Glass Apple (2025)
**Principes:**
- Transparences adaptatives subtiles
- Réfractions et lentilles physiques
- PAS d'animations bounce/parallax
- Contraste dynamique pour accessibilité
- Specular highlights subtils

**Palette:**
- Background: Système adaptatif iOS
- Accent: Tintable par utilisateur
- Glass layers: Multi-couches subtiles
- Typography: SF Pro optimisé

---

## 🚀 ROADMAP

### Q3 2024 - MVP Launch
- [x] Vision Framework OCR
- [x] Core Data local
- [x] 8 langues
- [x] Catégories universelles

### Q4 2024 - Enhanced AI
- [ ] MLX + LLaVA integration
- [ ] Smart categorization ML
- [ ] Batch processing
- [ ] Widgets

### Q1 2025 - Premium Features
- [ ] Custom categories
- [ ] Advanced exports
- [ ] Shortcuts integration
- [ ] Apple Watch app

### Q3 2025 - Apple Intelligence
- [ ] Migration iOS 26
- [ ] Foundation Models API
- [ ] Enhanced accuracy
- [ ] Voice input

---

## 📊 MÉTRIQUES SUCCÈS

### Launch (3 mois)
- 10,000 downloads
- 4.5+ App Store rating
- 15% conversion freemium
- 0 privacy incidents

### Year 1
- 100,000 users actifs
- 20% premium conversion
- Feature by Apple (Privacy)
- Expansion 5 nouveaux marchés

---

## ⚠️ RISQUES & MITIGATIONS

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Performance LLM local | Haut | Start avec Vision Framework, upgrade progressif |
| Taille app (>500MB) | Moyen | Modèles downloadables on-demand |
| Précision OCR | Moyen | Fallback manuel + corrections ML |
| Competition | Bas | Focus privacy unique selling point |

---

## 🎯 DIFFÉRENCIATEURS

1. **100% Offline** - Seule app majeure vraiment offline
2. **Privacy First** - Aucune donnée ne quitte l'appareil
3. **Apple Intelligence Ready** - Future-proof
4. **No Account Required** - Utilisation immédiate
5. **Universal Categories** - Fonctionne partout
6. **Multilingual Native** - 8 langues au lancement

---

## 📱 REQUIREMENTS SYSTÈME

**Minimum:**
- iOS 17.0+
- iPhone 12 ou plus récent
- 2GB espace libre

**Optimal (AI Features):**
- iOS 18.4+
- iPhone 15 Pro ou plus récent (A17 Pro)
- 4GB espace libre

**Apple Intelligence (Futur):**
- iOS 26+
- Compatible Apple Intelligence

---

## 🏆 SUCCESS METRICS

**User Satisfaction:**
- NPS > 70
- App Store 4.7+ stars
- < 2% churn mensuel

**Business:**
- CAC < CHF 5
- LTV > CHF 50
- Break-even: Mois 6

**Technical:**
- Crash rate < 0.1%
- OCR accuracy > 95%
- Processing time < 2s

---

## 🚨 LAUNCH STRATEGY

1. **Beta TestFlight** (Semaine 1-2)
   - 100 early adopters
   - Feedback integration
   - Bug fixes

2. **Soft Launch** (Semaine 3-4)
   - Suisse + France
   - App Store optimization
   - Reviews collection

3. **Global Launch** (Mois 2)
   - 8 pays simultanés
   - PR Privacy-focused
   - Apple pitch for featuring

---

**"Your expenses. Your device. Your privacy. ExpenseAI Privacy Edition."**