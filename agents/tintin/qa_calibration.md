# 🧪 FASTDAW - Plan de Test QA Global
**Agent**: TINTIN
**Date**: 2025-11-22
**Sprint**: 21

---

## 1. Plan de Test Global pour FASTDAW

### 1.1 Architecture de Test
- **Tests unitaires** : DSP, Audio Graph, State Manager
- **Tests d'intégration** : Audio Engine ↔ UI
- **Tests fonctionnels** : Scénarios utilisateur complets
- **Tests de performance** : CPU < 5%, Latence < 10ms
- **Tests de stabilité** : 48h sans crash, Memory leaks

### 1.2 Environnements de Test
- **macOS** : 14.x (Sonoma), M1/M2/M3
- **Configurations audio** : 44.1/48/96 kHz, 64-2048 samples
- **Plugins** : VST3, AU (sandboxed)

### 1.3 Critères de Validation
- ✅ Zero crash pendant 5 minutes d'utilisation intense
- ✅ Audio underruns < 20 / 5 min
- ✅ Save/Load roundtrip identique
- ✅ Theme switching sans artefacts

---

## 2. Tests Backend Critiques

### 2.1 AudioEngine Core
```cpp
TEST: ProcessBlock_6Tracks_Parallel
- Créer 6 TrackProcessors
- Injecter audio simultanément
- Vérifier MixerSumNode output
- PASS: Somme correcte, pas de corruption
```

### 2.2 Thread Safety
```cpp
TEST: RaceCondition_AudioThread
- Utiliser TSAN (Thread Sanitizer)
- Déclencher play/stop rapides
- Modifier paramètres pendant playback
- PASS: Aucune race détectée
```

### 2.3 Plugin Management
```cpp
TEST: VST_Sandbox_Crash_Recovery
- Charger plugin malformé
- Vérifier isolation sandbox
- Tester recovery après crash
- PASS: DAW continue sans interruption
```

### 2.4 StateManager
```cpp
TEST: Save_Load_Consistency
- Sauvegarder projet .fdaw
- Recharger et comparer états
- Vérifier plugins, automation, MIDI
- PASS: Identique bit à bit
```

---

## 3. Tests UI Critiques

### 3.1 TrackView Components
```cpp
TEST: Track_Resize_Stability
- Redimensionner tracks min→max
- Vérifier repaint sans flicker
- Tester avec 6 tracks simultanés
- PASS: Fluide, < 16ms frame time
```

### 3.2 Mixer Integration
```cpp
TEST: Mute_Solo_Logic
- Mute track 1, Solo track 2
- Vérifier exclusive solo
- Tester automation mute/solo
- PASS: Logique correcte, pas de pop
```

### 3.3 Theme Engine
```cpp
TEST: Theme_Switch_Cyberpunk_Paper
- Basculer thème pendant playback
- Vérifier couleurs et contrastes
- Tester avec piano roll ouvert
- PASS: Transition instantanée
```

### 3.4 VU-Meters
```cpp
TEST: Metering_Accuracy
- Générer sine -6dB, -12dB, -18dB
- Vérifier affichage VU-meter
- Tester peak hold et decay
- PASS: Précision ±0.5dB
```

---

## 4. Tests MIDI/Piano Roll

### 4.1 Piano Roll Rendering
```cpp
TEST: Note_Display_Zoom_Levels
- Zoom 1% → 600%
- Vérifier lisibilité notes
- Tester overlay performances
- PASS: 60fps à tous niveaux
```

### 4.2 MIDI Input/Recording
```cpp
TEST: MIDI_Realtime_Recording
- Enregistrer 1000 notes/min
- Vérifier timing précision
- Tester quantization 1/16
- PASS: Latence < 3ms
```

### 4.3 Loop Markers
```cpp
TEST: Loop_Marker_Precision
- Définir loop 4 mesures
- Vérifier boucle sans glitch
- Tester avec tempo changes
- PASS: Sample-accurate looping
```

### 4.4 Note Editing
```cpp
TEST: Multi_Note_Selection
- Sélectionner 100+ notes
- Déplacer, copier, supprimer
- Vérifier undo/redo stack
- PASS: Opérations < 100ms
```

---

## 5. Tests Mixeur

### 5.1 Master Bus
```cpp
TEST: MasterBus_Limiting
- Injecter signal +6dB
- Vérifier limiter engage
- Tester TruePeak detection
- PASS: Pas de clipping
```

### 5.2 LUFS Metering
```cpp
TEST: LUFS_Measurement
- Signal test EBU R128
- Vérifier LUFS-I, LUFS-S
- Comparer référence
- PASS: Conforme EBU ±0.3 LU
```

### 5.3 FX Chain
```cpp
TEST: FX_Chain_4Slots
- Charger 4 FX par track
- Vérifier ordre processing
- Tester bypass/enable
- PASS: CPU total < 30%
```

### 5.4 Automation
```cpp
TEST: Volume_Automation_Smooth
- Créer automation 0→100%
- Vérifier interpolation
- Tester avec 6 tracks
- PASS: Pas de zipper noise
```

---

## 6. Méthode d'Analyse Crash

### 6.1 Crash Report Apple
```bash
# 1. Localiser crash log
~/Library/Logs/DiagnosticReports/FastDAW_*.crash

# 2. Analyser stack trace
atos -arch arm64 -o FastDAW.app/Contents/MacOS/FastDAW -l 0x100000000 <address>

# 3. Symbolication
xcrun crashlog FastDAW_*.crash --symbolicate
```

### 6.2 Points de Vérification
1. **Thread crashé** : Main, Audio, Render ?
2. **Exception Type** : EXC_BAD_ACCESS, EXC_CRASH ?
3. **Call Stack** : Identifier fonction fautive
4. **Memory state** : Heap corruption ?
5. **Plugin impliqué** : VST crash dans sandbox ?

### 6.3 Reproduction
```cpp
TEST: Crash_Reproduction_Script
1. Capturer user actions pre-crash
2. Créer script JUCE automation
3. Replay avec debug symbols
4. Isoler minimal repro case
```

---

## 7. Check-list de Non-Régression

### 7.1 Tests Quotidiens (CI/CD)
- [ ] Build Debug + Release
- [ ] Unit tests suite complète
- [ ] Memory leaks (Valgrind/ASAN)
- [ ] Thread races (TSAN)
- [ ] Code coverage > 80%

### 7.2 Tests Sprint (Manuel)
- [ ] New project → Save → Load
- [ ] Import MIDI file
- [ ] Export Audio (WAV/AIFF)
- [ ] 6 tracks avec plugins
- [ ] Automation sur Master
- [ ] Theme switching
- [ ] Piano roll zoom/scroll
- [ ] Loop playback 5 min
- [ ] CPU usage < 5%
- [ ] Memory stable < 200MB

### 7.3 Tests Release Candidate
- [ ] Installation clean macOS
- [ ] Migration ancien projet
- [ ] VST scan complet
- [ ] Stress test 48h
- [ ] Performance benchmarks
- [ ] Accessibility (VoiceOver)
- [ ] Documentation à jour

---

## 8. Questions & Points d'Attention

### 8.1 Questions Techniques
1. **VST3 vs AU** : Quelle priorité pour les tests ?
2. **Apple Silicon** : Tests Rosetta nécessaires ?
3. **Sandbox** : Niveau d'isolation souhaité ?
4. **Automation** : Résolution temporelle (samples/ms) ?

### 8.2 Points de Vigilance
- ⚠️ **Memory peaks** lors du chargement de samples
- ⚠️ **Thread priority** audio vs UI
- ⚠️ **Plugin compatibility** avec macOS updates
- ⚠️ **Undo stack** limitation mémoire

### 8.3 Outils Recommandés
- **Instruments** : Time Profiler, Allocations
- **Xcode Sanitizers** : ASAN, TSAN, UBSAN
- **JUCE Test Runner** : Tests unitaires
- **Audio Test Tools** : REW, PluginDoctor

---

## 📊 Métriques de Qualité

| Métrique | Cible | Actuel | Status |
|----------|-------|---------|---------|
| Crashes/jour | 0 | TBD | 🔄 |
| CPU usage | < 5% | TBD | 🔄 |
| Latence audio | < 10ms | TBD | 🔄 |
| Memory leaks | 0 | TBD | 🔄 |
| Test coverage | > 80% | TBD | 🔄 |
| FPS Piano Roll | 60 | TBD | 🔄 |

---

## 🚀 Prochaines Actions

1. **Implémenter tests backend** dans `Source/Tests/`
2. **Créer harness automation** pour UI tests
3. **Configurer CI/CD** avec tests automatiques
4. **Documentation bugs** template Markdown
5. **Scripts reproduction** pour bugs critiques

---

*Document généré par TINTIN - Agent QA/Tests/Research*
*Contact: tintin@moulinsart.local*