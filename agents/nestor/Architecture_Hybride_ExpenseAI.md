# 🏗️ Architecture Hybride ExpenseAI Privacy Edition
## Vision Framework + Qwen2.5-0.5B + Rules Fallback

---

## 🎯 STRATÉGIE 3-TIERS INTELLIGENTE

### Tier 1: Vision Framework (80% des cas)
**Cas d'usage**: Reçus simples et bien structurés
```swift
// VisionOCRService.swift
func quickExtract(image: UIImage) -> ExpenseData? {
    // VNRecognizeTextRequest
    // Extraction rapide < 1 seconde
    // Montants, dates, marchands standards
}
```

**Avantages**:
- Ultra-rapide (<1s)
- Natif iOS, zero overhead
- Excellent pour texte clair
- Support multilingue natif

### Tier 2: Qwen2.5-0.5B (15% des cas)
**Cas d'usage**: Reçus complexes, manuscrits, multi-colonnes
```swift
// QwenMLService.swift
func deepAnalysis(image: UIImage, ocrText: String) -> ExpenseData? {
    // Activation conditionnelle si Vision confidence < 70%
    // Model quantisé 4-bit ~250MB
    // Analyse contextuelle avancée
}
```

**Spécifications Qwen2.5-0.5B**:
- Taille originale: 500MB
- Quantisé 4-bit: ~250MB
- Performance: 3-5 tokens/sec sur A15
- Excellent pour extraction structurée

### Tier 3: Rules Engine (5% des cas)
**Cas d'usage**: Fallback ultime, patterns connus
```swift
// RulesEngine.swift
func fallbackExtraction(text: String) -> ExpenseData? {
    // Regex patterns pour montants
    // Dictionnaire marchands connus
    // Catégorisation par keywords
}
```

**Patterns**:
- Montants: `/\d+[.,]\d{2}/`
- Dates: Multiple formats
- TVA: Patterns européens
- Marchands: Dictionnaire 1000+ entrées

---

## 📊 FLUX DE DÉCISION INTELLIGENT

```
Photo Reçu
    ↓
[Vision Framework OCR]
    ↓
Confidence > 85% ?
    ├─ OUI → Résultat direct ✅
    └─ NON → [Qwen2.5 Analysis]
              ↓
         Score > 70% ?
              ├─ OUI → Résultat enrichi ✅
              └─ NON → [Rules Fallback]
                        ↓
                   Pattern match ?
                        ├─ OUI → Résultat basique ✅
                        └─ NON → Correction manuelle 📝
```

---

## 💾 OPTIMISATION TAILLE APP

| Composant | Taille | Optimisation |
|-----------|--------|--------------|
| App Base | 50MB | Code Swift/UI |
| Vision Framework | 0MB | Natif iOS |
| Qwen2.5-0.5B | 250MB | Quantisé 4-bit |
| Rules Engine | 5MB | Patterns + Dict |
| Assets/UI | 45MB | Images optimisées |
| Localization | 5MB | 8 langues |
| Core Data | 5MB | Schema + Index |
| **TOTAL** | **~360MB** | **< 400MB ✅** |

---

## ⚡ PERFORMANCE TARGETS

### Latence par tier:
- **Vision Only**: 0.5-1s (80% cas)
- **Vision + Qwen**: 3-5s (15% cas)
- **Full Pipeline**: 5-7s (5% cas)
- **Moyenne globale**: <2s ✅

### Précision attendue:
- Montants: 95%+
- Dates: 90%+
- Marchands: 85%+
- Catégories: 80%+
- **Global**: >90% ✅

---

## 🔧 IMPLÉMENTATION TECHNIQUE

### 1. Intégration Qwen2.5-0.5B

**Option A: MLX Framework (Recommandé)**
```bash
# Installation
pip install mlx-lm
mlx_lm.convert --hf-repo Qwen/Qwen2.5-0.5B-Instruct

# Quantization
mlx_lm.quantize --model qwen2.5 --bits 4
```

**Option B: llama.cpp**
```bash
# Conversion GGUF
python convert.py Qwen2.5-0.5B --outtype q4_0
# Integration iOS via Swift Package
```

### 2. Conditional Activation
```swift
class ExpenseAnalyzer {
    func analyze(image: UIImage) async -> ExpenseData {
        // Tier 1: Vision
        let visionResult = await visionOCR.extract(image)
        
        if visionResult.confidence > 0.85 {
            return visionResult.data
        }
        
        // Tier 2: Qwen si nécessaire
        if qwenService.isLoaded {
            let enhanced = await qwenService.analyze(
                image: image,
                text: visionResult.text
            )
            if enhanced.confidence > 0.70 {
                return enhanced.data
            }
        }
        
        // Tier 3: Fallback
        return rulesEngine.extract(visionResult.text)
    }
}
```

### 3. Memory Management
```swift
class ModelManager {
    // Chargement lazy de Qwen
    private var qwenModel: QwenModel?
    
    func loadQwenIfNeeded() {
        guard qwenModel == nil else { return }
        qwenModel = QwenModel.load(quantized: .int4)
    }
    
    func unloadQwen() {
        qwenModel = nil
        // Force memory cleanup
    }
}
```

---

## 🎯 AVANTAGES COMPÉTITIFS

| Critère | ExpenseAI v2 | Expensify | Concurrence |
|---------|--------------|-----------|-------------|
| Privacy | 100% local ✅ | Cloud ❌ | Cloud ❌ |
| Offline | 100% ✅ | Limité ⚠️ | Non ❌ |
| Taille | ~400MB ✅ | 150MB | 200MB+ |
| Précision | >90% ✅ | 85% | 80% |
| Langues | 8 ✅ | 5 | 3-4 |
| Coût | Gratuit/4.90 ✅ | 5-25$/mois | 10-30$/mois |
| IA | On-device ✅ | Cloud API | Cloud API |

---

## 🚀 ROADMAP IMPLEMENTATION

### Phase 1 (2h): Vision Framework
- [x] Setup VNRecognizeTextRequest
- [x] Extraction patterns basiques
- [x] Tests reçus simples

### Phase 2 (3h): Qwen2.5 Integration
- [ ] Conversion modèle quantisé
- [ ] Swift bindings MLX/llama.cpp
- [ ] Conditional activation logic

### Phase 3 (2h): Rules & Optimization
- [ ] Rules engine patterns
- [ ] Dictionnaire marchands
- [ ] Memory optimization

### Phase 4 (1h): Testing & Validation
- [ ] Performance benchmarks
- [ ] Accuracy validation
- [ ] Size optimization

---

**"Privacy First. Intelligence Local. Performance Native."**

ExpenseAI v2.0 - La nouvelle référence des apps expense 100% privées.