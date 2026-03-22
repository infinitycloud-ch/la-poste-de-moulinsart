# 📚 DOCUMENTATION NESTOR - Architecture IA et Coordination

**Agent :** NESTOR (Chef d'Orchestre)
**Date :** 14 Janvier 2025
**Domaine :** Intégration IA, Architecture Globale, Coordination Multi-Agents

---

## 🏗️ Architecture Globale du Projet PrivExpensIA

### Vue d'Ensemble
PrivExpensIA est une application iOS de gestion de dépenses avec extraction IA de tickets de caisse. L'architecture suit le pattern MVVM avec Core Data pour la persistance et MLX pour l'inférence IA.

```
┌─────────────────────────────────────────┐
│           Interface Utilisateur         │
│         (SwiftUI + Glass Theme)         │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│         Services & Managers             │
│  (AIExtractionService, QwenManager)     │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│           Modèle IA (MLX)               │
│      (Qwen 2.5-0.5B - 942MB)           │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│        Persistance (Core Data)          │
│         (Expense Entity)                │
└─────────────────────────────────────────┘
```

---

## 🤖 Intégration du Modèle Qwen

### 1. Architecture du Bridge Python-Swift

#### Fichier : `mlx_bridge.py`
```python
# Bridge permettant l'utilisation de MLX depuis Swift
class QwenMLXBridge:
    - load_model() : Charge le modèle Qwen avec MLX
    - run_inference(prompt) : Exécute l'inférence et retourne JSON
```

**Chemin du modèle :** `~/Documents/models/qwen2.5-0.5b-4bit/`
- `model.safetensors` (942MB)
- `config.json`
- `tokenizer.json`

### 2. QwenModelManager

#### Fonctionnalités Clés

**Lazy Loading :**
```swift
// Le modèle n'est chargé qu'au premier usage
private func ensureModelLoaded(completion: @escaping (Result<Void, Error>) -> Void)
```

**Système de Cache :**
```swift
// Cache SHA256 avec TTL de 24h
class InferenceCache {
    - Stockage : 100 entrées max
    - Génération de clé : SHA256 du prompt
    - Purge automatique des entrées expirées
}
```

**Gestion Mémoire :**
- Limite stricte : 150MB
- Monitoring en temps réel
- Fallback automatique si dépassement

### 3. Modes d'Extraction

| Mode | Méthode | Temps | Précision |
|------|---------|-------|-----------|
| **Rapide** | Regex Patterns | <100ms | 60-70% |
| **Qwen** | MLX AI | ~2s | 90-95% |

**Switch dans l'UI :**
```swift
@State private var useQwenMode = false
// Toggle active = Mode Qwen
// Toggle inactif = Mode Rapide
```

---

## 📧 Système de Communication "La Poste de Moulinsart"

### Architecture Email

```
Oracle → NESTOR → Tintin → {Dupont1, Dupont2}
```

**Serveurs :**
- SMTP : Port 1025
- Web UI : Port 1080
- API : Port 3001

### Format des Emails

```
De: [agent]@moulinsart.local
À: [destinataire]@moulinsart.local
Objet: [OPERATION] - [Description]

[Corps structuré avec sections claires]
```

### Hooks de Capture

**Fichiers :**
- `oracle_prompt_hook.py` : Capture les prompts
- `oracle_stop_hook.py` : Capture les arrêts
- `email_trigger_hook.py` : Déclenche les emails

---

## 🔄 Flux de Données Complet

### Scan → Sauvegarde

1. **ScannerGlassView** capture l'image
2. **AIExtractionService** préprocesse le texte
3. **Mode Decision:**
   - Si `useQwenMode == true` → MLXService → mlx_bridge.py → Qwen
   - Si `useQwenMode == false` → QwenModelManager (patterns)
4. **Extraction** retourne JSON structuré
5. **CoreDataManager** sauvegarde l'Expense
6. **ExpenseListGlassView** affiche via @FetchRequest

### Structure JSON Extraite

```json
{
  "merchant": "string",
  "total_amount": number,
  "tax_amount": number,
  "date": "YYYY-MM-DD",
  "category": "enum",
  "items": [
    {"name": "string", "price": number}
  ],
  "confidence": 0.0-1.0,
  "extraction_method": "string"
}
```

---

## 🛠️ Configuration Technique

### Paths Critiques

```bash
# Modèle IA
~/Documents/models/qwen2.5-0.5b-4bit/

# Projet iOS
~/moulinsart/PrivExpensIA/

# Agents
~/moulinsart/agents/
├── nestor/
├── tintin/
├── dupont1/
└── dupont2/
```

### Build Configuration

```bash
# Build Debug
xcodebuild -scheme PrivExpensIA -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  build

# Build Release
xcodebuild -scheme PrivExpensIA -configuration Release \
  -sdk iphoneos \
  archive
```

### Dépendances Python

```bash
# Pour MLX
pip install mlx-lm

# Path MLX
~/Library/Python/3.13/lib/python/site-packages
```

---

## 📊 Métriques de Performance

### Modèle Qwen
- **Chargement initial :** 3-5 secondes
- **Inférence moyenne :** 500ms - 2s
- **RAM utilisée :** ~300MB
- **Taux de succès :** >90%

### Cache
- **Hit Rate moyen :** 30-40%
- **Économie temps :** ~1.5s par hit
- **Taille max :** 100 entrées

---

## 🚨 Points d'Attention

### Erreurs Communes

1. **"Model not loaded"**
   - Cause : Première utilisation
   - Solution : Attendre le lazy loading

2. **"Memory limit exceeded"**
   - Cause : >150MB utilisés
   - Solution : Fallback automatique activé

3. **"Timeout"**
   - Cause : Inférence >1s
   - Solution : Utiliser Mode Rapide

### Debugging

```swift
// Activer les logs détaillés
QwenModelManager.shared.enableVerboseLogging = true

// Vérifier les métriques
let metrics = QwenModelManager.shared.getPerformanceMetrics()
print("Success Rate: \(metrics.successRate)")
print("Avg Time: \(metrics.averageInferenceTime)")
```

---

## 🔐 Sécurité et Privacy

- **Modèle local :** Aucune donnée envoyée au cloud
- **Cache chiffré :** SHA256 pour les clés
- **Purge auto :** TTL 24h sur le cache
- **Sandbox iOS :** Isolation complète

---

## 📝 Checklist de Maintenance

### Hebdomadaire
- [ ] Vérifier les métriques de performance
- [ ] Nettoyer le cache si >80 entrées
- [ ] Valider les tests d'intégration

### Mensuelle
- [ ] Mettre à jour le modèle si nouvelle version
- [ ] Optimiser les patterns regex
- [ ] Revoir les seuils de confidence

---

## 🎯 Prochaines Étapes Recommandées

1. **Optimisation Cache** : Implémenter LRU au lieu de FIFO
2. **Multi-Model** : Support pour différents modèles selon la langue
3. **Batch Processing** : Traiter plusieurs tickets simultanément
4. **Cloud Backup** : Optionnel pour synchronisation multi-devices

---

**Document maintenu par :** NESTOR
**Dernière mise à jour :** 14 Janvier 2025
**Version :** 1.0.0