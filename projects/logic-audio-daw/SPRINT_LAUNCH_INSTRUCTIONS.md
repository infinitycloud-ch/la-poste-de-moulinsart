# 🚀 INSTRUCTIONS DE LANCEMENT - SPRINTS 2-10
## Orchestrateur: NESTOR

---

## 📅 SPRINT 2 - LANCEMENT IMMÉDIAT (IDs: 352-355)

### DUPONT1 - Core Multi-Pistes
```bash
# Fichiers à créer/modifier:
Source/Core/MidiRouter.h
Source/Core/MidiRouter.cpp
Source/Core/AudioEngine.cpp (update)

# Objectifs:
- 4 pistes avec perTrackMidiBuffers
- Modes Selected/Armed/Omni
- Mixdown sans overlap
```

### DUPONT2 - UI Multi-Track
```bash
# Fichiers à créer:
Source/UI/TrackSelector.h
Source/UI/TrackSelector.cpp
Source/UI/MultiTrackView.h
Source/UI/MultiTrackView.cpp

# Objectifs:
- 4 TrackComponents visibles
- Boutons solo/mute/arm
- Sélection active visible
```

### TINTIN - QA Multi-Pistes
```bash
# Fichiers à créer:
Source/Tests/MultiTrackTests.cpp
Source/Tests/MidiRoutingTests.cpp

# Objectifs:
- Test 4 instruments simultanés
- Test routing MIDI propre
- Test solo/mute sans artefacts
```

---

## 📊 PLANNING SPRINTS FUTURS

### Sprint 3 (J+1) - FX Chains
- Lead: DUPONT1
- Focus: Slots FX dynamiques
- IDs: 356-358

### Sprint 4 (J+2) - Master Bus
- Lead: DUPONT1
- Focus: Export professionnel
- IDs: 359-361

### Sprint 5 (J+3) - Loop Engine
- Lead: DUPONT2
- Focus: Loops visuelles

### Sprint 6 (J+4) - Piano Roll
- Lead: DUPONT2
- Focus: Éditeur MIDI

### Sprint 7 (J+5) - UI Layout
- Lead: DUPONT2
- Focus: Layout final

### Sprint 8 (J+6) - Audio Settings
- Lead: DUPONT1
- Focus: Device manager

### Sprint 9 (J+7) - Save/Load
- Lead: DUPONT1
- Focus: Persistance

### Sprint 10 (J+8) - Polish
- Lead: TINTIN
- Focus: Optimisation

---

## 🔧 COMMANDES TMUX SPRINT 2

```bash
# Envoyer instructions DUPONT1
tmux send-keys -t nestor-agents:agents.2 \
  "# SPRINT 2: Multi-Pistes - Créer MidiRouter + update AudioEngine" C-m

# Envoyer instructions DUPONT2
tmux send-keys -t nestor-agents:agents.3 \
  "# SPRINT 2: UI Multi-Track - TrackSelector + MultiTrackView" C-m

# Envoyer instructions TINTIN
tmux send-keys -t nestor-agents:agents.1 \
  "# SPRINT 2: QA - Tests multi-pistes et routing MIDI" C-m
```

---

## ✅ VALIDATION SPRINT PAR SPRINT

### Sprint 1 ✓ (En finalisation)
- [x] AudioEngine base
- [x] Track structure
- [x] UI components
- [ ] Export WAV

### Sprint 2 ⏳ (Prêt à lancer)
- [ ] Multi-track engine
- [ ] MIDI routing
- [ ] UI multi-track
- [ ] Tests

### Sprints 3-10 📋 (Planifiés)
- Tâches Oracle créées jusqu'à Sprint 4
- Plan détaillé disponible
- Équipe briefée

---

## 🎯 AUTONOMIE COMPLÈTE

L'équipe peut maintenant:
1. Exécuter Sprint 2 immédiatement
2. Enchaîner les sprints selon planning
3. Paralléliser Core/UI/Tests
4. Livrer DAW complet en 8-10 jours

---

*Instructions validées - Exécution autonome activée*
*NESTOR - Orchestrateur Principal*