# 🎵 MASTER PRD – Next Gen Logic Audio DAW By Mr D.

**Projet:** Logic Audio DAW
**Framework:** C++ & JUCE
**Vision:** DAW modulaire et minimaliste professionnel

---

## 🎯 1. Vision

Créer un DAW modulaire et minimaliste basé sur JUCE, focalisé sur :
- **Moteur audio stable** (AudioProcessorGraph)
- **Pistes verticales extensibles**
- **UI simple et évolutive**
- **Système de plugins par slots** (instrument + FX)
- **Pipeline MIDI propre**
- **Export audio fiable**

**Objectif:** Construire la base solide d'un DAW professionnel, sans complexité graphique prématurée.

---

## 🏗️ 2. Architecture Principale

### 2.1 Audio Engine (Core)

Chaque piste utilise une chaîne de traitement :
```
Instrument → FX1 → FX2 → TrackGain → Master
```

**Règles:**
- Stéréo obligatoire
- Aucun chemin parallèle vers le master
- FX chain reconstruite automatiquement lors d'ajouts/suppressions
- Volume appliqué en post-FX
- MIDI par piste

### 2.2 Pistes (Tracks)

Chaque piste contient :
- Instrument (obligatoire)
- Slots FX (dynamiques)
- Volume
- Mute / Arm
- VU meter post-fader
- MidiBuffer
- Loops placeholders

### 2.3 UI (Version 1 Minimal)

```
Ligne 1: Instrument Slot
Ligne 2: FX Slots (3 minimum)
Ligne 3: Volume + VU
Ligne 4: MIDI Viewer simple
Ligne 5: Loops (carrés)
```

### 2.4 Master Section

- Master volume
- Master VU
- Export WAV
- (évolution) Ozone / presets

---

## 🚀 3. Sprints de Développement

### Sprint 1 — Moteur Audio Minimal ⭐
**Assigné:** DUPONT1 (C++ Core)
**Objectif:** 1 piste, instrument + 1 FX, volume/mute, export WAV.

**Tâches:**
- [ ] Créer AudioEngine
- [ ] Implémenter AudioProcessorGraph minimal
- [ ] Brancher instrument → FX → Gain → Master
- [ ] Volume/mute fonctionnels
- [ ] VU post-fader
- [ ] Export offline

**Validation:**
- [ ] Le FX modifie le RMS
- [ ] Mute = silence
- [ ] Volume agit post-fx
- [ ] WAV export OK

### Sprint 2 — Multi-Pistes ⭐
**Assigné:** DUPONT1 (C++ Core)
**Objectif:** 4 pistes avec instrument + FX indépendants.

**Tâches:**
- [ ] Multi-track graph
- [ ] perTrackMidiBuffers
- [ ] Mixdown

**Validation:**
- [ ] 2 pistes jouent ensemble indépendamment

### Sprint 3 — UI Minimal Stable ⭐
**Assigné:** DUPONT2 (JUCE UI)
**Objectif:** Stabiliser un track strip simple.

**Tâches:**
- [ ] Instrument slot
- [ ] FX slots
- [ ] Volume fader
- [ ] Mute/arm
- [ ] VU

### Sprint 4 — FX Chain Dynamique ⭐
**Assigné:** DUPONT1 (C++ Core)
**Objectif:** Ajouter/supprimer FX à chaud.

**Tâches:**
- [ ] Gestion des slots dynamiques
- [ ] Reconstruction automatique de la FX chain

### Sprint 5 — MIDI Viewer Simple ⭐
**Assigné:** DUPONT2 (JUCE UI)
**Objectif:** Afficher notes MIDI en temps réel.

**Tâches:**
- [ ] Canvas simple
- [ ] Rectangles par note
- [ ] Scroll automatique

### Sprint 6 — Loops Placeholders ⭐
**Assigné:** DUPONT2 (JUCE UI)
**Objectif:** Structure des loops sans traitement audio.

**Tâches:**
- [ ] UI loops carrées
- [ ] Toggle ON/OFF

### Sprint 7 — Nouveau Piano Roll (Phase 1) ⭐
**Assigné:** DUPONT1 + DUPONT2 (Collaboration)
**Objectif:** Base propre d'un piano roll.

**Tâches:**
- [ ] Grid
- [ ] Scroll horizontal/vertical
- [ ] Notes rectangles
- [ ] Playhead

---

## ✅ 4. Ce qu'on garde

- Concept de pistes verticales
- Master Banner
- Routing Instrument → FX → Gain
- Slots carrés pour plugins
- MIDI routing Selected / Armed
- Piano roll comme module futur
- Loops façon Logic
- Export offline
- Architecture AudioProcessorGraph

---

## ❌ 5. Ce qu'on élimine

- Graphismes complexes
- Patches automatiques dangereux
- UI mélangée au moteur audio
- Reconstruction globale du graph à chaque action
- Slots non connectés
- Développement orienté esthétique avant audio

---

## 🏆 6. Règle d'or

**Le moteur audio doit être parfait avant toute esthétique.**

Quand l'audio est stable → on passe aux loops, piano roll, design.

---

## 🎖️ 7. Assignation Équipe Moulinsart

### Équipe TMUX Nestor
- **NESTOR** — Architecte & Coordinateur projet
- **TINTIN** — QA Lead (tests audio, validation builds)
- **DUPONT1** — Développeur C++ (Audio Engine, Core)
- **DUPONT2** — Développeur JUCE UI (Interface, Components)

### Équipe TMUX Haddock (Support)
- **HADDOCK** — Chef technique & Review architecture
- **RASTAPOPOULOS** — QA Audio (tests professionnels)
- **TOURNESOL1** — Documentation technique
- **TOURNESOL2** — Intégration & Tests système

---

## 📋 8. Sprint 1 Détaillé — Moteur Audio Minimal

### 🎯 Objectif Sprint 1
Construire une première version totalement fonctionnelle du moteur audio, entièrement stable.

### 📋 Tâches Détaillées (DUPONT1)

**1. Créer la structure AudioEngine**
- Fichier : `AudioEngine.h / AudioEngine.cpp`
- Rôle : encapsuler AudioProcessorGraph et gérer toute la logique audio

**Méthodes minimales:**
```cpp
void prepareToPlay()
void processBlock()
void addTrack()
void addInstrumentToTrack()
void addFXToTrack()
void rebuildTrackChain()
```

**2. Implémenter l'AudioProcessorGraph minimal**
```
AudioInputNode → MasterInputNode → MasterOutputNode
```

**3. Construire la chaîne de traitement (1 piste)**
```
Instrument → FX → TrackGain → MasterInput
```
- Stéréo obligatoire (2 canaux)
- Aucune connexion parallèle
- Aucune connexion implicite

**4. Créer struct Track**
```cpp
struct Track {
    instrumentNode;
    fxNodes[1];
    gainNode;
    volume;
    muted;
    midiBuffer;
}
```

**5. Volume & Mute fonctionnels**
- Volume appliqué post-FX dans TrackGain
- Mute coupe les connexions ou applique un gain = 0

**6. VU Meter post-fader**
- Calcul RMS + Peak après TrackGain
- Refresh via timer 30 Hz

**7. Export Offline**
- Rendu 32-bit float ou WAV
- Sauvegarde dans `~/Desktop/DAW_Test_Export.wav`

**8. Tests automatiques internes**
- Injecter un sinus 440 Hz
- Vérifier que FX change le RMS
- Vérifier que mute = RMS zéro
- Vérifier export ≠ buffer vide

### ✅ Critères de Validation Sprint 1

**Audio:**
- [ ] Jouer une note → son sort correctement
- [ ] Activer FX (compresseur) → changement clair dans RMS
- [ ] Volume agit après FX
- [ ] Mute coupe tout instantanément

**Export:**
- [ ] Export produit un fichier audible
- [ ] Taille cohérente (pas 0 bytes)
- [ ] FX audible dans le rendu

**Graph:**
- [ ] Graph dump contient exactement : `InstrumentNode → FXNode → TrackGainNode → MasterInputNode → MasterOutputNode`
- [ ] Pas d'autre connexion

### 🎬 Livrable Final Sprint 1

- `AudioEngine.cpp/h`
- `Track.cpp/h`
- Une app JUCE minimale avec :
  - 1 piste instrument
  - 1 FX
  - Fader volume
  - Mute
  - VU meter
  - Export WAV

---

**🚀 Quand Sprint 1 terminé → on lance Sprint 2 (Multi-Pistes)**

---

*Document créé pour la ferme Moulinsart*
*Ready pour exécution immédiate*