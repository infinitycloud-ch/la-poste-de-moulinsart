# 📋 PRD - PrivExpensIA Sprint 3: Corrections Critiques

## 📅 État du Projet
- **Date**: 12 Septembre 2025
- **Sprint**: 3 (Corrections post-validation)
- **Statut**: EN COURS - En attente du système email

## 🎯 Objectif
Corriger les bugs identifiés par [Author] lors du test de validation Sprint 2.

## 🐛 Bugs Identifiés et Assignations

### 1. **Localization Cassée** 🔴 CRITIQUE
**Assigné à**: DUPONT2
**Description**: Le picker affiche "Deutsch" mais l'interface reste en anglais
**Fichiers concernés**:
- `LocalizationManager.swift`
- Toutes les Views (remplacer strings hardcodées par localized)
**Critères d'acceptation**:
- [ ] Changer la langue dans Settings change TOUTE l'interface
- [ ] 8 langues fonctionnelles (fr-CH, de-CH, it-CH, en, ja, ko, sk, es)
- [ ] Screenshots de validation pour chaque langue

### 2. **Glass Card Design** 🟡 IMPORTANT
**Assigné à**: DUPONT1
**Description**: Les coins des Glass Cards sont carrés au lieu d'arrondis
**Fichiers concernés**:
- `GlassComponents.swift`
- `LiquidGlassTheme.swift`
**Critères d'acceptation**:
- [ ] Tous les Glass Cards ont des coins arrondis uniformes
- [ ] Cohérence visuelle sur tous les écrans
- [ ] Screenshot avant/après

### 3. **Currency Non Synchronisée** 🟡 IMPORTANT
**Assigné à**: DUPONT1
**Description**: Home Stats affiche € au lieu de la devise sélectionnée (CHF)
**Fichiers concernés**:
- `HomeGlassView.swift`
- `StatsGlassView.swift`
**Critères d'acceptation**:
- [ ] La devise dans Stats correspond à celle sélectionnée dans Settings
- [ ] Format correct avec espace (CHF 146, pas CHF146)
- [ ] Persistence après redémarrage app

### 4. **Stats Mockées** 🟢 NORMAL
**Assigné à**: DUPONT1
**Description**: Les statistiques utilisent des données mockées
**Fichiers concernés**:
- `StatsGlassView.swift`
- `StatsViewModel.swift`
**Critères d'acceptation**:
- [ ] Calculs basés sur vraies données ExpenseData
- [ ] Mise à jour en temps réel
- [ ] Graphiques reflètent les vraies dépenses

### 5. **Pluralisation** 🟢 NORMAL
**Assigné à**: DUPONT2
**Description**: Affiche "1 Days" au lieu de "1 Day"
**Fichiers concernés**:
- `LocalizationManager.swift`
- Fichiers de localisation
**Critères d'acceptation**:
- [ ] Gestion correcte singulier/pluriel
- [ ] Fonctionne dans toutes les langues
- [ ] Tests avec 0, 1, 2+ items

## 📊 Tests de Validation
**Responsable**: TINTIN

### Checklist de Tests
- [ ] **Test Langues**: Switcher FR → DE → EN avec screenshots
- [ ] **Test Devises**: Switcher CHF → EUR → USD avec screenshots  
- [ ] **Test Design**: Vérifier coins arrondis sur tous les écrans
- [ ] **Test Stats**: Ajouter expense et vérifier mise à jour stats
- [ ] **Test Pluriel**: Vérifier "1 Day" vs "2 Days"

## 🚀 Commandes de Build
```bash
cd ~/moulinsart/PrivExpensIA
xcodegen generate
open PrivExpensIA.xcodeproj
# Build: Cmd+B
# Run: Cmd+R
```

## ⚠️ Points d'Attention
1. **STOP au Sprint 2**: Attendre validation [Author] avant de continuer
2. **Discipline**: Chaque agent corrige SES PROPRES bugs uniquement
3. **Communication**: Si email en panne, NESTOR communique directement avec [Author]
4. **Doutes**: TOUJOURS s'arrêter et demander plutôt que prendre des initiatives

## 📈 Métriques de Succès
- [ ] App compile sans warning
- [ ] Tous les tests passent
- [ ] Screenshots validés par [Author]
- [ ] Aucun bug critique restant

## 🔄 Workflow
1. NESTOR reçoit feedback de [Author] ✅
2. NESTOR assigne à TINTIN ⏳ (en attente email)
3. TINTIN coordonne DUPONTs
4. DUPONTs corrigent leurs bugs respectifs
5. TINTIN teste et fait screenshots
6. NESTOR valide avec [Author]
7. Si OK → Livraison
8. Si KO → Nouveau cycle de corrections

## 📝 Notes
- **Infrastructure Email**: Gérée par agent externe, ne pas troubleshooter
- **Communication actuelle**: Directe avec [Author] dans le terminal
- **Statut**: En attente du rétablissement du système email pour coordination équipe