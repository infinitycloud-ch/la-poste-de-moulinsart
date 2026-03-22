# 🎹 RAPPORT TECHNIQUE : Piano Roll Professionnel JUCE
**Agent**: TINTIN - QA/Research
**Date**: 2025-11-22
**Mission**: Recherche technique complète Piano Roll avancé
**Destinataires**: DUPONT1 (iOS/Core), DUPONT2 (Doc/i18n)

---

## 📋 RÉSUMÉ EXÉCUTIF

### Verdict Principal
✅ **FAISABLE** : Piano Roll pro avec notation musicale en JUCE
⚡ **Architecture recommandée** : Hybrid Layered Component (Option B)
🎯 **Temps estimé** : 3 sprints (21 jours)
⚠️ **Risque principal** : Performance avec 1000+ notes

### Points Clés
1. JUCE supporte nativement le rendu vectoriel nécessaire
2. SMuFL intégrable via `Typeface::createSystemTypefaceFor()`
3. Architecture en couches optimale pour performance
4. Séparation claire rendu/logique possible

---

## 🏗️ TROIS ARCHITECTURES CANDIDATES

### Architecture A : Simple Direct Render
```cpp
class SimplePianoRoll : public juce::Component {
    void paint(Graphics& g) override {
        // Tout dessiner dans paint()
        drawGrid(g);
        drawNotes(g);
        drawOverlays(g);
    }
};
```
**Pros**: Simple, rapide à implémenter
**Cons**: Performance catastrophique > 500 notes
**Verdict**: ❌ Pas viable pour production

### Architecture B : Hybrid Layered Component ⭐ RECOMMANDÉ
```cpp
class PianoRollViewport : public Viewport {
    class GridLayer : public Component { }      // Grille statique
    class NotesLayer : public Component { }     // Notes dynamiques
    class OverlayLayer : public Component { }   // Sélection, curseurs
    class RulerLayer : public Component { }     // Mesures, tempo
};
```
**Pros**: Performance optimale, séparation claire
**Cons**: Complexité moyenne
**Verdict**: ✅ **OPTIMAL pour FastDAW**

### Architecture C : Full Component Tree
```cpp
class NoteComponent : public Component {
    // Chaque note = Component individuel
    void paint(Graphics& g) override;
    void mouseDown(MouseEvent& e) override;
};
```
**Pros**: Interaction naturelle par note
**Cons**: Overhead mémoire énorme
**Verdict**: ⚠️ Viable mais coûteux

---

## 🎨 SYSTÈME DE RENDU MUSICAL

### 1. Intégration SMuFL (Glyphes Musicaux)
```cpp
// Chargement police Bravura/Petaluma
class MusicFontLoader {
    std::unique_ptr<Typeface> musicFont;

    void loadSMuFL() {
        auto fontData = BinaryData::Bravura_otf;
        musicFont = Typeface::createSystemTypefaceFor(
            fontData, BinaryData::Bravura_otfSize
        );
    }

    // Glyphes SMuFL standards
    const int NOTEHEAD_BLACK = 0xE0A4;
    const int NOTEHEAD_HALF = 0xE0A3;
    const int EIGHTH_FLAG = 0xE240;
    const int BEAM = 0xE1F7;
};
```

### 2. Rendu Vectoriel vs Raster
**Décision**: **VECTORIEL** pour tout sauf textures de fond

```cpp
class NoteRenderer {
    Path createNotePath(NoteType type, Rectangle<float> bounds) {
        Path p;
        switch(type) {
            case NoteType::Eighth:
                p.addEllipse(bounds.reduced(2));
                p.addLineSegment({bounds.getCentreX(), bounds.getY(),
                                  bounds.getCentreX(), bounds.getY() - 20}, 2);
                // Ajouter flag
                break;
        }
        return p;
    }
};
```

### 3. Système de Ligatures (Beams)
```cpp
class BeamCalculator {
    struct BeamGroup {
        Array<Note*> notes;
        float angle;
        float yStart, yEnd;
    };

    void calculateBeams(Array<Note*>& selectedNotes) {
        // Algorithme de groupement par temps
        // Calcul angle optimal (règles de gravure)
        // Anti-collision avec autres éléments
    }
};
```

---

## 🚀 OPTIMISATIONS PERFORMANCE

### 1. Dirty Rectangle System
```cpp
class OptimizedNotesLayer : public Component {
    Rectangle<int> dirtyRegion;

    void markDirty(Rectangle<int> area) {
        dirtyRegion = dirtyRegion.getUnion(area);
        repaint(dirtyRegion);
    }

    void paint(Graphics& g) override {
        g.reduceClipRegion(dirtyRegion);
        // Dessiner uniquement zone modifiée
    }
};
```

### 2. View Culling
```cpp
void paintNotes(Graphics& g) {
    auto visibleArea = getViewportBounds();

    for (auto& note : allNotes) {
        if (note.bounds.intersects(visibleArea)) {
            drawNote(g, note);
        }
    }
}
```

### 3. Caching Strategies
```cpp
class CachedGrid {
    Image gridCache;

    void updateCache() {
        gridCache = Image(Image::ARGB, width, height, true);
        Graphics g(gridCache);
        drawGridLines(g);
    }

    void paint(Graphics& g) {
        g.drawImageAt(gridCache, 0, 0);
    }
};
```

---

## 🎮 INTERACTION UTILISATEUR

### 1. Sélection Multi-Notes
```cpp
class SelectionManager {
    Array<Note*> selectedNotes;
    Rectangle<float> lassoRect;

    void mouseDrag(MouseEvent& e) {
        lassoRect = Rectangle<float>(dragStart, e.position);

        selectedNotes.clear();
        for (auto& note : visibleNotes) {
            if (lassoRect.intersects(note.bounds)) {
                selectedNotes.add(&note);
            }
        }
    }
};
```

### 2. Drag & Resize Fluides
```cpp
class NoteDragger : public ComponentDragger {
    void startDraggingComponent(Component* comp, const MouseEvent& e) {
        // Snap to grid
        auto snappedPos = snapToGrid(e.position);
        ComponentDragger::startDraggingComponent(comp, e);
    }
};
```

---

## 🎨 THÈMES CYBERPUNK / PAPER

### Structure Thème
```cpp
struct PianoRollTheme {
    struct Colours {
        Colour background;
        Colour gridLines;
        Colour noteDefault;
        Colour noteSelected;
        Colour noteVelocity;
        Colour overlay;
    };

    struct Fonts {
        Font rulerFont;
        Font noteFont;
        Typeface::Ptr musicSymbols;
    };
};

// Cyberpunk Theme
PianoRollTheme cyberpunkTheme {
    .colours = {
        0xFF1A1A1A,  // background (dark)
        0xFF3D3D00,  // gridLines (yellow)
        0xFFFFD700,  // noteDefault (gold)
        0xFFFF6B35,  // noteSelected (orange)
        0xFF00FFFF,  // noteVelocity (cyan)
        0x40FFFF00   // overlay (transparent yellow)
    }
};

// Paper Theme
PianoRollTheme paperTheme {
    .colours = {
        0xFFF5F5DC,  // background (beige)
        0xFF2B2B2B,  // gridLines (dark gray)
        0xFF000000,  // noteDefault (black)
        0xFFFF0000,  // noteSelected (red)
        0xFF0000FF,  // noteVelocity (blue)
        0x400000FF   // overlay (transparent blue)
    }
};
```

---

## ✅ CHECKLIST DUPONT1 (Core/iOS)

### Sprint 1 - Fondations (7 jours)
- [ ] Créer `PianoRollViewport` héritant de `Viewport`
- [ ] Implémenter `GridLayer` avec cache
- [ ] Setup `NotesLayer` avec paint() de base
- [ ] Créer `Note` data structure (pitch, start, length, velocity)
- [ ] Implémenter snap-to-grid (1/16, 1/8, 1/4)
- [ ] Gestion zoom (10% - 600%)
- [ ] Scrolling horizontal/vertical fluide

### Sprint 2 - Notation Musicale (7 jours)
- [ ] Intégrer SMuFL (Bravura.otf dans BinaryData)
- [ ] Créer `NoteRenderer` avec types (whole, half, quarter, eighth, sixteenth)
- [ ] Implémenter `BeamCalculator` pour ligatures
- [ ] Ajouter flags pour croches isolées
- [ ] Système de durées avec ties
- [ ] Anti-aliasing (`g.setImageResamplingQuality(Graphics::highResamplingQuality)`)

### Sprint 3 - Polish & Thèmes (7 jours)
- [ ] Implémenter `ThemeManager` Cyberpunk/Paper
- [ ] Optimiser avec dirty rectangles
- [ ] View culling pour > 1000 notes
- [ ] Animations smooth (fade in/out sélection)
- [ ] Export/Import MIDI propre
- [ ] Tests performance Instruments.app

---

## ✅ CHECKLIST DUPONT2 (Doc/i18n)

### Documentation Technique
- [ ] Documenter API `PianoRollComponent`
- [ ] Guide intégration thèmes custom
- [ ] Flowchart architecture en couches
- [ ] Exemples de code pour extensions

### Localisation Interface
- [ ] Strings pour tooltips notes (Do, Ré, Mi vs C, D, E)
- [ ] Labels durées (Noire, Croche vs Quarter, Eighth)
- [ ] Messages d'erreur multilingues
- [ ] Raccourcis claviers par région

### Assets Visuels
- [ ] Préparer icônes outils (pencil, eraser, select)
- [ ] Curseurs custom pour chaque mode
- [ ] Sprites pour velocity lanes
- [ ] Mockups Cyberpunk vs Paper pour validation

---

## ⚠️ RISQUES & MITIGATIONS

### Risque 1: Performance avec 10,000+ notes
**Mitigation**:
- Utiliser `OpenGLContext` si nécessaire
- Implémenter LOD (Level of Detail) pour zoom out
- Batching de notes proches

### Risque 2: Précision temporelle
**Mitigation**:
- Travailler en samples, pas en pixels
- Double precision pour calculs timing
- Sync avec AudioEngine thread-safe

### Risque 3: Complexité ligatures
**Mitigation**:
- Commencer simple (horizontal beams)
- Algorithme progressif (v1 basique, v2 avancé)
- Fallback sur notes séparées si trop complexe

### Risque 4: Conflits z-order
**Mitigation**:
- Ordre strict : Grid → Notes → Overlays → Cursors
- `Component::toFront()` / `toBack()` explicites
- Alpha blending pour transparences

---

## 💻 PSEUDO-CODE ARCHITECTURE FINALE

```cpp
// PianoRoll/PianoRollViewport.h
class PianoRollViewport : public juce::Viewport {
public:
    PianoRollViewport();

    void setNotes(const Array<MidiNote>& notes);
    void setTheme(const PianoRollTheme& theme);
    void setGridDivision(int division); // 1/16, 1/8, etc

private:
    class GridLayer;
    class NotesLayer;
    class OverlayLayer;
    class RulerLayer;

    std::unique_ptr<GridLayer> gridLayer;
    std::unique_ptr<NotesLayer> notesLayer;
    std::unique_ptr<OverlayLayer> overlayLayer;
    std::unique_ptr<RulerLayer> rulerLayer;

    PianoRollTheme currentTheme;
    SelectionManager selection;
    NoteRenderer renderer;
    BeamCalculator beamCalc;
};

// PianoRoll/NotesLayer.cpp
void NotesLayer::paint(Graphics& g) {
    g.setImageResamplingQuality(Graphics::highResamplingQuality);

    auto visibleArea = getVisibleArea();

    // Render beams first (background)
    for (auto& beam : beamCalc.getBeams()) {
        if (beam.intersects(visibleArea)) {
            renderer.drawBeam(g, beam, currentTheme);
        }
    }

    // Render notes
    for (auto& note : notes) {
        if (note.bounds.intersects(visibleArea)) {
            renderer.drawNote(g, note, currentTheme);

            if (note.type <= NoteType::Eighth && !note.beamed) {
                renderer.drawFlag(g, note, currentTheme);
            }
        }
    }

    // Render selection overlay
    if (selection.hasSelection()) {
        g.setColour(currentTheme.colours.overlay);
        g.fillRect(selection.getBounds());
    }
}
```

---

## 📚 CONCEPTS CLÉS (Références)

### JUCE Classes Essentielles
- `Graphics` : Contexte de rendu principal
- `Path` : Formes vectorielles complexes
- `GlyphArrangement` : Positionnement glyphes
- `Viewport` : Scrolling optimisé
- `OpenGLContext` : Accélération GPU
- `ComponentAnimator` : Animations fluides

### Patterns Recommandés
- **Dirty Rectangles** : Ne repeindre que zones modifiées
- **Double Buffering** : Éviter flicker
- **Object Pooling** : Réutiliser NoteComponents
- **Spatial Indexing** : QuadTree pour notes

### Standards Musicaux
- **SMuFL** : Standard Music Font Layout
- **MIDI 2.0** : Précision accrue timing
- **MusicXML** : Import/Export notation

---

## 🎯 RECOMMANDATION FINALE

### Architecture Gagnante
**➡️ HYBRID LAYERED COMPONENT (Architecture B)**

### Justification
1. **Performance** : Séparation grid statique / notes dynamiques
2. **Maintenabilité** : Code modulaire par couche
3. **Évolutivité** : Ajout facile de nouvelles couches
4. **JUCE-Native** : Utilise patterns JUCE standards

### Planning Réaliste
- **Sprint 1** : Base fonctionnelle (rectangles simples)
- **Sprint 2** : Notation musicale (SMuFL + beams)
- **Sprint 3** : Polish (thèmes + optimisations)

### Coût/Bénéfice
- **Investissement** : 21 jours-homme
- **ROI** : Piano Roll AAA différenciant FastDAW
- **Risque** : Faible avec architecture proposée

---

## 🚀 PROCHAINES ÉTAPES IMMÉDIATES

1. **DUPONT1** : Créer branche `feature/piano-roll-pro`
2. **DUPONT1** : Implémenter `PianoRollViewport` squelette
3. **DUPONT2** : Préparer assets Bravura.otf
4. **DUPONT2** : Créer mockups validation UX
5. **TINTIN** : Préparer tests unitaires structure

---

**Rapport terminé — prêt pour intégration par Dupont1 & Dupont2.**

*Document technique par TINTIN*
*Agent QA/Research - FastDAW Project*
*Contact: tintin@moulinsart.local*