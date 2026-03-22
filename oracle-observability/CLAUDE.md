# 📋 PRD ORACLE - ENVIRONNEMENT TECHNIQUE FIGÉ

## 🎯 MISSION & PÉRIMÈTRE
**Rôle :** Agent Oracle - Support technique infrastructure La Poste de Moulinsart
**Responsabilités :**
- Maintenance serveurs email/WebSocket
- Surveillance flux de communication TMUX
- Support technique agents (nestor, tintin, dupont1, dupont2, haddock, rastapopoulos, tournesol1, tournesol2)

## 🏗️ ARCHITECTURE VALIDÉE (25/09/2025)

### **Stack Technique Final**
```
┌─ Oracle Server (3001) ──────────────────────┐
│ • API centrale + WebSocket temps réel       │
│ • Base SQLite unifiée (mode WAL)           │
│ • Gestion événements TMUX                  │
└─────────────────────────────────────────────┘

┌─ Mail Server (1025/1080) ───────────────────┐
│ • SMTP entrant (port 1025)                 │
│ • API HTTP emails (port 1080)             │
│ • Notifications TMUX calibrées            │
└─────────────────────────────────────────────┘

┌─ Vue Client (5175) ─────────────────────────┐
│ • Interface AgentMailboxes unifiée         │
│ • Boîte Commandant intégrée               │
│ • Refresh automatique 3 secondes          │
└─────────────────────────────────────────────┘

┌─ Sessions TMUX ─────────────────────────────┐
│ • nestor-agents : Nestor,Tintin,Dupont1,2  │
│ • haddock-agents : Haddock,Rasta,Tournesol │
└─────────────────────────────────────────────┘
```

### **Configuration SQLite WAL (CRITIQUE)**
```typescript
// OBLIGATOIRE dans server/index.ts ET server/mail-server.ts
db.run("PRAGMA journal_mode = WAL");
db.run("PRAGMA synchronous = NORMAL");
db.run("PRAGMA cache_size = 1000");
db.run("PRAGMA temp_store = memory");
```
**Pourquoi :** Résout conflits de verrouillage base entre serveurs concurrent

## 🔧 NOTIFICATIONS TMUX CALIBRÉES

### **Algorithme Final Validé**
```typescript
// Dans mail-server.ts (ligne ~400)
mainCommand += ` && sleep 2 && tmux send-keys -t ${sessionName}:agents.${panelNumber} C-m`;
```

### **Mapping Agents → Panels**
```bash
# Session nestor-agents
Nestor → Panel 0
Tintin → Panel 1
Dupont1 → Panel 2
Dupont2 → Panel 3

# Session haddock-agents
Haddock → Panel 0
Rastapopoulos → Panel 1
Tournesol1 → Panel 2
Tournesol2 → Panel 3
```

**Problème résolu :** Notifications collantes aux commandes grâce à temporisation 2sec + return unique

## 📮 SYSTÈME EMAIL COMMANDANT

### **Composants Intégrés**
1. **Script Shell** : `~/moulinsart/send-mail-commandant.sh`
2. **API Envoi** : `POST /api/execute-shell` (Oracle 3001)
3. **API Lecture** : `GET /api/emails?from=author@moulinsart.local` (Oracle 3001)
4. **Interface** : Section Commandant dans AgentMailboxes.vue

### **Flow Fonctionnel**
```
Interface → API execute-shell → Script shell → SMTP (1025) → Base SQLite → Interface refresh
```

## ⚠️ RÈGLES D'INTERVENTION

**AUTORISÉ:**
- ✅ Maintenance infrastructure (serveurs, base, TMUX)
- ✅ Debug problèmes techniques système
- ✅ Répondre questions [Author] sur état services
- ✅ Mise à jour ce CLAUDE.md uniquement

**INTERDIT:**
- ❌ Modifier CLAUDE.md autres agents
- ❌ Intervenir dans projets/code agents
- ❌ Prendre décisions contenu métier
- ❌ Actions non-autorisées par [Author]

## 📊 PROCÉDURES DE SURVEILLANCE

### **Commandes de Monitoring Standard**
```bash
# Vue d'ensemble système
ps aux | grep -E "(bun.*oracle|bun.*mail-server|tmux.*agents)"
lsof -i :3001,1025,1080,5175

# Health checks critiques
curl -s http://localhost:3001/health  # Oracle
nc -z localhost 1025                 # SMTP
curl -s http://localhost:5175         # Vue Client

# Vérification SQLite WAL
sqlite3 data/oracle.db "PRAGMA journal_mode"  # Doit retourner "wal"
ls -la data/oracle.db* | wc -l                # Doit retourner 3 (db, wal, shm)

# Sessions TMUX
tmux ls | grep -E "(nestor|haddock)-agents"
```

### **Logs de Diagnostic**
```bash
# Logs temps réel
tail -f /tmp/oracle.log    # Serveur Oracle
tail -f /tmp/mail.log      # Serveur Mail (si existe)

# Test API emails Commandant
curl -s "http://localhost:3001/api/emails?from=author@moulinsart.local&limit=3"
```

## 🚨 TROUBLESHOOTING GUIDE

### **1. Emails Sporadiques/Disparaissent**
**Symptôme :** Emails apparaissent/disparaissent dans interface
**Cause :** Verrouillage SQLite entre serveurs concurrent
**Solution :**
```bash
# Vérifier mode WAL activé
sqlite3 data/oracle.db "PRAGMA journal_mode"  # Doit être "wal"

# Si pas WAL, redémarrer serveurs avec config WAL
kill $(ps aux | grep "bun.*oracle\|bun.*mail-server" | awk '{print $2}')
bun run server/index.ts > /tmp/oracle.log 2>&1 &
bun run server/mail-server.ts > /tmp/mail.log 2>&1 &
```

### **2. Notifications TMUX Collantes**
**Symptôme :** Commandes agents restent collées après notification
**Cause :** Pas de temporisation + return
**Solution :** Vérifier dans mail-server.ts ligne ~400:
```typescript
mainCommand += ` && sleep 2 && tmux send-keys -t ${sessionName}:agents.${panelNumber} C-m`;
```

### **3. Boîte Commandant Vide**
**Symptôme :** Section Commandant n'affiche aucun email
**Diagnostic :**
```bash
# Test API directe
curl -s "http://localhost:3001/api/emails?from=author@moulinsart.local&limit=3"
# Si vide, problème base. Si erreur, problème serveur.
```

## 📂 ARCHITECTURE FICHIERS MISE À JOUR

```
~/moulinsart/oracle-observability/
├── server/
│   ├── index.ts           # 🔷 Oracle Server (3001) + WebSocket + APIs
│   └── mail-server.ts     # 📧 Mail Server (1025/1080) + Notifications TMUX
├── client/
│   ├── src/components/
│   │   ├── AgentMailboxes.vue   # 🖥️ Boîtes mail + personnages + bordures
│   │   ├── MemoryPage.vue       # 🌙 Page mémoire + fusée lunaire background
│   │   └── AgentAvatar.vue      # 👤 Système avatars ronds + fallbacks
│   └── public/
│       ├── characters/          # 🎭 Images personnages Tintin (200px)
│       ├── fusee.png           # 🚀 Fusée horizontale workflow banner
│       └── lunefusee.png       # 🌙 Scène Tintin+Milou sur Lune
├── data/
│   ├── oracle.db          # 🗄️ Base SQLite unifiée (mode WAL)
│   ├── oracle.db-wal      # 🔄 Write-Ahead Log (auto-créé)
│   └── oracle.db-shm      # 🔄 Shared Memory (auto-créé)
└── CLAUDE.md              # 📋 CE PRD - ENVIRONNEMENT FIGÉ

~/moulinsart/
├── send-mail-commandant.sh       # 📤 Script envoi emails Commandant
├── moulinsart-manager.sh         # 🚀 Gestionnaire services principal
└── agents/[agent]/image.png      # 🎨 Sources images personnages
```

## 🎨 MAINTENANCE SYSTÈME VISUEL

### **Problèmes Visuels Résolus**
```bash
# 1. Images manquantes/paths incorrects
AgentAvatar.vue: /images/ → /characters/ (CORRIGÉ)
haddock.png: Image Rastapopoulos → Vraie image Haddock (CORRIGÉ)
tournesol1.png + tournesol2.png: Créées depuis tournesol.png (CORRIGÉ)

# 2. Transparence/Opacité
MemoryPage timeline: 75% → 10% transparence pour voir fusée (CORRIGÉ)
AgentMailboxes: background-blend-mode supprimé (CORRIGÉ)

# 3. Bordures invisibles
3px borders + box-shadow colorés par agent (CORRIGÉ)
Classes CSS .mailbox-{agent} avec :class dynamique (CORRIGÉ)
```

### **Vérifications Images Standard**
```bash
# Vérifier toutes les images présentes
ls -la ~/moulinsart/oracle-observability/client/public/characters/
# Doit contenir: nestor, tintin, dupont1, dupont2, haddock, rastapopoulos, tournesol1, tournesol2

# Test images manquantes agents
find ~/moulinsart/agents/ -name "image.png" -exec echo {} \;

# Vérifier images spéciales
ls -la ~/moulinsart/oracle-observability/client/public/fusee.png
ls -la ~/moulinsart/oracle-observability/client/public/lunefusee.png
```

### **Diagnostic Problèmes Visuels**
```bash
# 1. Personnages n'apparaissent pas → Vérifier paths images
# 2. Bordures invisibles → Vérifier classes CSS .mailbox-{agent}
# 3. Fusée lunaire cachée → Vérifier transparence timeline-event
# 4. Rocket animation bloquée → Vérifier workflow steps status
# 5. Avatars carrés → Vérifier border-radius: 50%
```

## 🚨 PROCÉDURE DE DÉMARRAGE/REDÉMARRAGE

### **Démarrage Standard**
```bash
cd ~/moulinsart/oracle-observability

# 1. Serveur Oracle (OBLIGATOIRE en premier)
bun run server/index.ts > /tmp/oracle.log 2>&1 &

# 2. Serveur Mail (avec logs séparés si désiré)
bun run server/mail-server.ts > /tmp/mail.log 2>&1 &

# 3. Interface Vue (si nécessaire)
cd client && bun run dev &
```

### **En Cas de Crash Total**
```bash
# 1. Kill tout
pkill -f "bun.*(oracle|mail-server)"
lsof -i :3001,1025,1080 | awk 'NR>1 {print $2}' | xargs kill -9

# 2. Vérification base SQLite
sqlite3 data/oracle.db "PRAGMA integrity_check"

# 3. Redémarrage avec config WAL
bun run server/index.ts > /tmp/oracle.log 2>&1 &
bun run server/mail-server.ts > /tmp/mail.log 2>&1 &
```

## 🎨 AMÉLIORATIONS VISUELLES TINTIN (28/09/2025)

### **Système de Personnages Intégré**
```
~/moulinsart/oracle-observability/client/public/characters/
├── nestor.png     # 🎩 Majordom en noir et blanc
├── tintin.png     # 🚀 Reporter en pull bleu
├── dupont1.png    # 🎨 Détective moustache
├── dupont2.png    # 🔍 Détective jumeau
├── haddock.png    # ⚓ Capitaine barbe rouge
├── rastapopoulos.png  # 🧔 Méchant moustache noire
├── tournesol1.png # 🧪 Professeur sourd
└── tournesol2.png # 🔬 Copie professeur
```

### **AgentMailboxes.vue - Bordures Colorées + Bustiers**
```css
/* Chaque agent a sa couleur distinctive */
.mailbox-nestor { border-color: #10B981; box-shadow: rgba(16, 185, 129, 0.4); }
.mailbox-tintin { border-color: #3B82F6; box-shadow: rgba(59, 130, 246, 0.4); }
.mailbox-dupont1 { border-color: #FBBF24; box-shadow: rgba(251, 191, 36, 0.4); }
.mailbox-dupont2 { border-color: #8B5CF6; box-shadow: rgba(139, 92, 246, 0.4); }
.mailbox-haddock { border-color: #1565C0; box-shadow: rgba(21, 101, 192, 0.4); }
.mailbox-rastapopoulos { border-color: #D32F2F; box-shadow: rgba(211, 47, 47, 0.4); }

/* Personnages en arrière-plan 200px, emails transparents par-dessus */
background-size: 200px auto;
background-position: center center;
mailbox-content: rgba(255, 255, 255, 0.85);
```

### **MemoryPage.vue - Fusée Lunaire de Tintin**
```css
/* Image complète Tintin+Milou sur Lune SEULEMENT sur panneau central */
.timeline-panel {
  background-image: url('/lunefusee.png');  # 🌙 Scène lunaire Hergé
  background-size: cover;
  background-position: center center;
}

/* Contenu 90% transparent pour voir la fusée */
.timeline-event: rgba(255, 255, 255, 0.1);
.filter-btn: rgba(255, 255, 255, 0.2);
```

### **Workflow Banner avec Fusée Animée**
```css
/* Fusée de Tintin traverse la bannière pendant workflow */
.rocket-container { position: relative; }
.rocket-image { src: "/fusee.png"; /* Fusée horizontale Hergé */ }
.rocket-trail { /* Fumée derrière fusée */ }

/* 4 positions : départ, génération, CLAUDE.md, purge */
.rocket-step-1, .rocket-step-2, .rocket-step-3, .rocket-step-4
```

### **AgentAvatar.vue - Avatars Ronds**
```css
/* Petits avatars ronds dans headers (38px) */
.agent-avatar { border-radius: 50%; }
.avatar-image { border-radius: 50%; object-fit: cover; }
path: /characters/nestor.png (corrigé depuis /images/)
```

## 🚀 WORKFLOW MÉMOIRE AUTOMATISÉ

### **Pipeline 4 Étapes Complet**
```typescript
// 1. Génération Mémoire (IA)
POST /api/memory/generate

// 2. Écriture PROJECT_MEMORY.md
POST /api/memory/write-project

// 3. Mise à jour CLAUDE.md agents (stratégie genius)
POST /api/memory/write-agents

// 4. Purge emails sélective
POST /api/memory/purge-mails
```

### **Stratégie "Genius" - Append Direct CLAUDE.md**
- ✅ **Fini PROJECT_MEMORY.md + CLAUDE_MEMORY.md séparés**
- ✅ **Append direct sur CLAUDE.md** existant de chaque agent
- ✅ **Session state seamless** pour agents
- ✅ **Purge sélective** : TMUX Nestor OU TMUX Haddock OU les deux

## ✅ VALIDATION SYSTÈME COMPLÈTE

### **Dernière Validation (30/09/2025 00:15)**
- ✅ Oracle Server : 4 clients WebSocket connectés
- ✅ Mail Server : SMTP opérationnel (port 1025)
- ✅ SQLite WAL : Mode activé, 3 fichiers présents
- ✅ Sessions TMUX : nestor-agents + haddock-agents actives
- ✅ Notifications : Temporisation 2sec + return fonctionnel
- ✅ Boîte Commandant : 10 emails récupérés, refresh 3s
- ✅ **Personnages Tintin** : 8 agents avec bordures colorées + bustiers
- ✅ **Fusée lunaire** : Background MemoryPage avec transparence 90%
- ✅ **Workflow animé** : Fusée traverse bannière pendant pipeline
- ✅ **Images authentiques** : Haddock corrigé (barbe vs moustache)
- ✅ **Avatar système** : Cercles 38px + fallback emoji
- ✅ Problème emails sporadiques : **RÉSOLU**
- ✅ **CORS Zero-Sécurité** : Bouton rouge suppression projets fonctionnel
- ✅ **Backup system** : Checkpoint WAL + ZIP automatique + redémarrage
- ✅ **Documentation technique** : Interface à onglets navigable

## 🔄 INSTRUCTIONS REMPLAÇANT

### **À Faire en Arrivant**
1. **Lire intégralement ce PRD**
2. **Vérifier l'état système** : `curl -s http://localhost:3001/health`
3. **Valider SQLite WAL** : `sqlite3 data/oracle.db "PRAGMA journal_mode"`
4. **Tester interface** : Ouvrir `http://localhost:5175`
5. **Ne rien modifier** sans autorisation [Author]

### **Environnement Figé et Validé**
- **Architecture** : Multi-serveurs avec base SQLite WAL
- **Notifications TMUX** : Algorithme calibré et stable
- **Email Commandant** : Système intégré fonctionnel
- **Tous problèmes techniques majeurs** : **RÉSOLUS**

### **Contact en Cas de Problème**
- Informer [Author] avant toute intervention
- Utiliser les procédures de ce PRD uniquement
- NE PAS modifier le travail des autres agents
- Périmètre : Infrastructure technique uniquement

## 🎨 LIQUID GLASS DESIGN SYSTEM (28/09/2025)

### **Apple Liquid Glass - Implémentation Complète**

Système de design inspiré d'iOS 26/macOS Tahoe 26 avec effets de verre liquide authentiques appliqué à toute l'interface Moulinsart Oracle.

### **🎯 Composants Transformés**

#### **1. Sprint Management Dashboard**
```css
/* Panneau principal liquid glass */
.liquid-glass-panel {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 20px !important;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

/* Effet hover avancé */
.liquid-glass-panel:hover {
  background: rgba(255, 255, 255, 0.35) !important;
  backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  transform: translateY(-2px) scale(1.005) !important;
}
```

#### **2. Agent Mailboxes System**
```css
/* Cartes mailbox avec liquid glass */
.mailbox-card {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border-radius: 20px !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

/* Headers colorés avec transparence */
.mailbox-header.nestor {
  background: rgba(16, 185, 129, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  border-radius: 20px 20px 0 0 !important;
}

/* Contenu avec subtle liquid glass */
.mailbox-body {
  background: rgba(255, 255, 255, 0.05) !important;
  backdrop-filter: blur(5px) saturate(120%) !important;
  border-radius: 0 0 20px 20px !important;
}
```

### **🔧 Spécifications Techniques**

#### **Paramètres Backdrop-Filter Standard**
```css
/* Base liquid glass */
backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%);

/* Hover state enhanced */
backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%);

/* Subtle elements */
backdrop-filter: blur(8px) saturate(160%);
```

#### **Box-Shadow Multi-Layer**
```css
/* Authentic Apple shadow stack */
box-shadow:
  0 8px 32px rgba(0, 0, 0, 0.12),    /* Ambient shadow */
  0 2px 8px rgba(0, 0, 0, 0.08),     /* Direct shadow */
  inset 0 1px 0 rgba(255, 255, 255, 0.5); /* Inset highlight */
```

#### **Transitions Optimisées**
```css
/* Apple-style cubic-bezier */
transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1);

/* Quick interactions */
transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
```

### **🎛️ Hierarchie Visuelle**

#### **Niveau 1 - Panneaux Principaux**
- **blur(20px)** : Sprint panels, mailbox cards
- **opacity(0.25)** : Background transparency
- **border-radius(20px)** : Rounded corners

#### **Niveau 2 - Headers & Navigation**
- **blur(15px)** : Headers, buttons
- **opacity(0.8)** : Semi-transparent with color
- **border-radius(12px-16px)** : Medium rounded

#### **Niveau 3 - Contenu & Détails**
- **blur(8px)** : Content areas, previews
- **opacity(0.1-0.15)** : Subtle transparency
- **border-radius(8px)** : Small rounded

### **🎨 Couleurs Agents Préservées**

Chaque agent conserve sa couleur signature avec transparence liquid glass :

```css
/* Exemples couleurs agents */
.mailbox-nestor: rgba(16, 185, 129, 0.8)   /* Vert Nestor */
.mailbox-tintin: rgba(59, 130, 246, 0.8)   /* Bleu Tintin */
.mailbox-dupont1: rgba(251, 191, 36, 0.8)  /* Jaune Dupont1 */
.mailbox-haddock: rgba(21, 101, 192, 0.8)  /* Bleu marine Haddock */
```

### **⚡ Performance & Compatibilité**

#### **Optimisations**
- **Hardware acceleration** : `transform: translateZ(0)`
- **Cross-browser support** : `-webkit-backdrop-filter` + `backdrop-filter`
- **Fallback graceful** : `rgba()` backgrounds si backdrop-filter non supporté

#### **Browser Support**
- ✅ **Safari** : Support complet natif
- ✅ **Chrome/Edge** : Support complet avec préfixe
- ⚠️ **Firefox** : Support partiel (fallback rgba)

### **🔍 Architecture CSS Modulaire**

#### **Fichiers Modifiés**
```
src/components/
├── SprintDashboard.vue    # Liquid glass panels & kanban
├── AgentMailboxes.vue     # Mailbox cards & headers
├── AgentAvatar.vue        # Avatar circles (unchanged)
└── TechDocsModal.vue      # Modal avec liquid glass (unchanged)
```

#### **Classes CSS Principales**
```css
.liquid-glass-panel      /* Panneaux principaux */
.mailbox-card           /* Cartes mailbox */
.mailbox-header.*       /* Headers colorés par agent */
.email-preview          /* Aperçus emails */
.project-section        /* Sections de projet */
.context-menu           /* Menus contextuels */
```

### **📏 Guidelines d'Usage**

#### **DO ✅**
- Utiliser `!important` pour override les styles existants
- Maintenir la hierarchie : 20px → 15px → 8px blur
- Préserver les couleurs d'agent avec transparence 0.8
- Appliquer border-radius cohérent (20px → 16px → 12px → 8px)

#### **DON'T ❌**
- Surcharger les backdrop-filter (performance)
- Oublier les préfixes `-webkit-`
- Utiliser blur < 5px (pas assez visible)
- Casser la continuité visuelle entre sections

### **🚀 Évolutions Futures**

#### **Package External Testé**
- **@zaosoula/liquid-glass-vue** : Installé mais incompatible avec structure Vue existante
- **Décision** : Maintenir implémentation CSS pure pour stabilité et performance

#### **Améliorations Possibles**
- Animation de déformation au mouseover
- Aberration chromatique subtile
- Particules flottantes en arrière-plan
- Mode sombre avec liquid glass inversé

## 🔥 AMÉLIORATIONS CRITIQUES (30/09/2025)

### **🚫 CORS Zero-Sécurité - RÉSOLU**

**Problème critique** : Bouton rouge suppression projets bloqué par CORS policy
**Solution finale** : Configuration zero-sécurité dans server/index.ts

```typescript
// Headers CORS - ZERO SECURITY (lignes 194-200)
const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "*",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Allow-Credentials": "true",
  "Access-Control-Max-Age": "86400"
};
```

**Résultat** : Suppression projets fonctionne parfaitement (testé sur Megatron 5)

### **💾 Système Backup WAL Checkpoint - IMPLÉMENTÉ**

**Script manager brutal renforcé** : `~/moulinsart/moulinsart-manager.sh`

**Nouvelles options ajoutées :**
- **7) Backup complet** (arrêt + ZIP avec choix redémarrage)
- **8) Backup + Redémarrage automatique** (tout-en-un) ← **RECOMMANDÉ**

**Workflow option 8** :
```bash
[1/4] CHECKPOINT WAL...     # sqlite3 "PRAGMA wal_checkpoint(FULL);"
[2/4] ARRÊT SERVICES...     # pkill brutal + ports
[3/4] CRÉATION ZIP...       # Backup 1.1G complet
[4/4] REDÉMARRAGE...        # Oracle → Mail → Web
```

**Critical Fix** : Checkpoint WAL avant arrêt garantit backup complet sans perte données

### **📋 Documentation Technique à Onglets - FINALISÉE**

**Fichier** : `~/moulinsart/documentation-technique.html`

**Interface modernisée** :
- 6 onglets navigables (Vue d'ensemble, Architecture, Communication, Mémoire, Améliorations, État)
- CSS responsive avec scrolling
- JavaScript intégré pour navigation
- Plus de scroll infini dans un seul document

### **🎯 Instructions Backup pour Remplaçant**

**OBLIGATOIRE avant toute intervention** :
```bash
# Backup automatique complet
./moulinsart-manager.sh
# Choisir option 8 (Backup + Redémarrage automatique)
```

**Backup créé** : `~/backups/moulinsart_backup_YYYYMMDD_HHMMSS.zip`

**Vérification post-backup** :
- Oracle Server actif : `curl -s http://localhost:3001/health`
- Interface web : `http://localhost:5175`
- Taille backup : ~1.1G (complet)

### **🔍 Monitoring État Système**

**Commandes de contrôle rapide** :
```bash
# Santé Oracle + Mail + Web
lsof -i :3001,1025,1080,5175

# Clients WebSocket connectés
tail -f /tmp/oracle.log | grep "Client connected\|Client disconnected"

# Mode SQLite WAL critique
sqlite3 data/oracle.db "PRAGMA journal_mode"  # Doit retourner "wal"

# Sessions TMUX agents
tmux ls | grep -E "(nestor|haddock)-agents"
```

### **🚨 Procédures d'Urgence Mises à Jour**

**En cas de problème critique** :
1. **Backup immédiat** : Option 8 du manager
2. **Logs de diagnostic** : `/tmp/oracle.log`, `/tmp/mail.log`
3. **Reset brutal** : Option 9 (Fix urgence) du manager
4. **Contact [Author]** avant intervention majeure

---
## 📋 **FIN DU PRD ORACLE - ENVIRONNEMENT STABILISÉ**