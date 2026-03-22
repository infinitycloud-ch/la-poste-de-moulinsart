# 📋 DUPONT1 - Backend Calibration Document
## Date: 22 novembre 2025
## Sprint: 21

---

## 1. 🏗️ Résumé Complet de l'Architecture Backend

### Architecture Globale
- **Architecture parallèle** : 6 pistes audio indépendantes
- **Audio Graph** :
  ```
  Track1-6 → TrackProcessor → MixerSumNode (6→2) → MasterBus → Output
  ```
- **Thread-safety** : Lock-free, utilisation de `std::atomic` pour tous les paramètres
- **Modules principaux** :
  - `AudioEngine/` : Moteur audio principal JUCE
  - `Core/` : StateManager, ThreadSafeParams
  - `TrackProcessor/` : Traitement par piste
  - `MeteringProcessor/` : Analyse RMS/Peak/LUFS
  - `MasterBus/` : Limiter, TruePeak, LUFS, Oversampling 4×
  - `PluginScanner/` : VST3/AU scanning avec sandbox
  - `BackendAPI/` : Interface thread-safe UI↔Backend

### Spécifications Techniques
- **Performances** : CPU < 5%, Latence < 10ms
- **Stabilité** : Zero-crash, safe bypass pour crash protection
- **Audio** : Support VST3/AU, 4 slots FX par piste
- **Format** : Sauvegarde .fdaw, Export WAV/AIFF

---

## 2. 📝 Liste des Responsabilités Précises DUPONT1

### Domaines de Responsabilité Exclusive
1. **Moteur Audio (AudioEngine)**
   - AudioProcessorGraph JUCE
   - Routing audio entre composants
   - Gestion thread audio/UI
   - Synchronisation transport

2. **TrackProcessor**
   - Processing chain par piste
   - MIDI input handling
   - FX chain (4 slots)
   - Metering intégré

3. **MasterBus**
   - TruePeak + LUFS monitoring
   - Limiter avec oversampling 4×
   - Safe bypass system

4. **Backend API**
   - Interface thread-safe pour l'UI
   - Atomic parameters
   - State management

5. **Export Audio**
   - WAV/AIFF export
   - Bounce to disk
   - Render offline

6. **Plugin Management**
   - VST3/AU scanning
   - Plugin sandbox
   - Crash recovery

### Fichiers Autorisés à Modifier
- `Source/Core/*.h` et `Source/Core/*.cpp`
- `Source/AudioEngine/*.cpp` (pas les .h sans validation)
- `CMakeLists.txt` (uniquement si explicitement demandé)

---

## 3. ⚠️ Invariants & Règles Obligatoires

### Règles de Code Strictes
1. **JAMAIS casser le build** - Toujours compiler avant commit
2. **Thread-safety absolue** - Utiliser `std::atomic`, pas de mutex dans audio thread
3. **Zero allocation** dans processBlock()
4. **Lock-free** pour toute communication audio↔UI
5. **juce::Span** au lieu de raw pointers
6. **Pas de refactoring** sans validation [Author]

### Conventions JUCE/C++
- Namespaces propres et organisés
- Une classe par fichier
- Pas de raw pointers (utiliser smart pointers)
- Pas de hardcoded values
- Documentation complète des APIs publiques

### Contraintes Performance
- Audio underruns < 20 par 5 minutes
- CPU usage < 5% en idle
- Latence totale < 10ms
- Memory leaks = 0 (Valgrind clean)

---

## 4. ❓ Points Flous ou à Confirmer avec [Author]

1. **Structure exacte du dossier backend** - La doc mentionne `/docs/tech/backend` mais les fichiers sont dans `/docs/tech/`
2. **Modification des .h dans AudioEngine** - Puis-je modifier les headers ou seulement les .cpp?
3. **StateManager** - Qui gère les sauvegardes/chargements .fdaw?
4. **LoopCellManager** - Est-ce dans mon périmètre ou c'est UI?
5. **Tests unitaires** - Où sont-ils? Dois-je les maintenir?
6. **MIDI Sequencer** - Scheduler mentionné dans mon rôle mais pas vu dans le code
7. **Communication avec Tintin** - Quel protocole exact pour les impacts UI?

---

## 5. ✅ Check-list de Validation Backend

### Avant toute modification
- [ ] Lire le brief complet
- [ ] Identifier les fichiers impactés
- [ ] Vérifier que c'est dans mon périmètre (Core/ ou AudioEngine/)
- [ ] Comprendre les dépendances UI

### Pendant le développement
- [ ] Code thread-safe (atomic, lock-free)
- [ ] Pas d'allocation dans audio thread
- [ ] Respect conventions JUCE
- [ ] Documentation des changements d'API

### Avant de livrer
- [ ] Code compile sans warning
- [ ] Tests passent (si existants)
- [ ] CPU < 5%, latence < 10ms
- [ ] Pas de memory leak
- [ ] Format de réponse respecté:
  1. Résumé
  2. Liste fichiers modifiés
  3. Code complet
  4. Notes de test
  5. Warn si impact UI/Tintin

### Communication
- [ ] Si ambiguïté → demander à [Author]
- [ ] Si impact UI → prévenir Tintin
- [ ] Si blocage → escalader immédiatement

---

## 6. 🤔 Questions pour [Author]

1. **Organisation des tests** : Où sont les tests unitaires backend? Dois-je créer/maintenir des tests pour mes modifications?

2. **MIDI Sequencer** : Mon rôle mentionne "scheduler" mais je ne vois pas de séquenceur MIDI. Est-ce à implémenter?

3. **Headers AudioEngine** : Puis-je modifier les fichiers .h dans AudioEngine/ ou uniquement les .cpp?

4. **LoopCellManager** : Ce module est dans AudioEngine/ mais semble lié à l'UI. Est-ce dans mon périmètre?

5. **Pipeline CI/CD** : Y a-t-il des tests automatiques ou validation avant merge?

6. **Versioning API** : Comment gérer les breaking changes de l'API backend?

7. **Documentation technique** : Dois-je maintenir BackendAPI.h à jour après chaque modification?

---

## 7. 📌 Notes Importantes

### Architecture Audio Graph Actuelle
```
6 Tracks parallèles
    ↓
TrackProcessor (avec 4 FX slots chacun)
    ↓
MixerSumNode (somme 6→2 canaux)
    ↓
MasterBus (Limiter + LUFS + TruePeak)
    ↓
Audio Output
```

### Modules Critiques Identifiés
- **AudioEngine.cpp/h** : Cœur du moteur (~33KB + 9.6KB)
- **BackendAPI.h** : Documentation complète des APIs (~14KB)
- **StateManager** : Gestion état et persistence
- **ThreadSafeParams** : Paramètres atomiques
- **MeteringProcessor** : Analyse temps-réel

### Stack Technique
- **Framework** : JUCE 7.x
- **Build** : CMake
- **Audio** : VST3/AU support
- **Thread** : Lock-free, atomic operations
- **Format** : .fdaw (propriétaire), WAV/AIFF export

---

*Document de calibration établi par DUPONT1 - Backend Engineer*
*Prêt pour exécution des tâches dans le respect strict du périmètre défini*