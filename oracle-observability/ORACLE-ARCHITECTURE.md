# 🔮 ORACLE - ARCHITECTURE SYSTÈME MOULINSART

## 🏰 CONTEXTE GÉNÉRAL
**Château de Moulinsart** - Écosystème multi-agents avec infrastructure centralisée

---

## 📋 STRUCTURE ORGANISATIONNELLE

### 👥 ÉQUIPES TMUX ACTIVES

#### **Équipe TMUX-Nestor** (`nestor-agents`)
- **Chef d'équipe** : Nestor (Panel 0)
- **Membres** : Tintin (Panel 1), Dupont1 (Panel 2), Dupont2 (Panel 3)
- **Session tmux** : `nestor-agents`
- **Répertoires** : `~/moulinsart/agents/{nestor,tintin,dupont1,dupont2}/`

#### **Équipe TMUX-Haddock** (`haddock-agents`)
- **Chef d'équipe** : Haddock (Panel 0)
- **Membres** : Rastapopoulos (Panel 1), Tournesol1 (Panel 2), Tournesol2 (Panel 3)
- **Session tmux** : `haddock-agents`
- **Répertoires** : `~/moulinsart/agents/{haddock,rastapopoulos,tournesol1,tournesol2}/`

---

## 🏗️ INFRASTRUCTURE TECHNIQUE

### **Services Backend Critiques**

#### 1. **Oracle Server** (Port 3001)
```bash
Service: ~/moulinsart/oracle-observability/server/index.ts
Status: ✅ ACTIF (PID 7827)
Fonction: API d'observabilité & WebSocket central
Endpoints:
  - http://localhost:3001/health
  - ws://localhost:3001/ws
Monitoring: 1 client connecté en permanence
```

#### 2. **Mail Server** (Ports 1025/1080)
```bash
Service: ~/moulinsart/oracle-observability/server/mail-server.ts
Status: ✅ ACTIF (PID 7828)
SMTP: Port 1025 (interne agents)
HTTP: Port 1080 (interface web)
Base: SQLite ~/moulinsart/oracle-observability/data/oracle.db
Emails: 711 messages stockés
```

#### 3. **Dashboard Web** (Port 5175)
```bash
Service: ~/moulinsart/oracle-observability/client/
Status: ✅ ACTIF (PID 7831)
Interface: Vue.js Dashboard
URL: http://localhost:5175
Framework: Vite + Bun
```

---

## 🌐 FLUX DE COMMUNICATION & NOTIFICATIONS

### **Schéma de Réseau Complet**
```
Agent → SMTP:1025 → SQLite → WebSocket:3001 → Dashboard:5175
  ↓                     ↓                        ↓
Claude CLI         Oracle API              Interface Web
  ↓                     ↓                        ↓
Tmux Panels    ← Heartbeat Notifications → Boutons TMUX
```

### **📧 WORKFLOW EMAIL → TMUX DÉTAILLÉ**

#### **Étape 1: Réception Email**
```bash
Agent envoie email → SMTP:1025 → stockage SQLite
Trigger: mail-server.ts:injectTmuxNotification()
```

#### **Étape 2: Heartbeat Notification Automatique**
```javascript
buildNotificationMessage() génère template:
━━━━━━━━━━━━━━━━━━━━
📧 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
AVANT TOUT lis Claude.md dans ton répertoire
Quand tu juge une tâche complète, notifie ton supérieur
MANDATORY: utiliser que les scripts API testés
ON EST EN PRODUCTION, NE JAMAIS RIEN SIMULER
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail de {sender}
📬 Sujet: {subject}
━━━━━━━━━━━━━━━━━━━━
📖 LIRE: curl http://localhost:1080/api/mailbox/{recipient}
✉️ RÉPONDRE: ./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"
━━━━━━━━━━━━━━━━━━━━
{commandes spécifiques agent}
━━━━━━━━━━━━━━━━━━━━
```

#### **Étape 3: Injection TMUX Intelligente**
```bash
# Routage automatique par agent:
Équipe TMUX-Nestor → nestor-agents:agents.[0-3]
Équipe TMUX-Haddock → haddock-agents:agents.[0-3]

# Commande exécutée:
tmux send-keys -t [SESSION]:agents.[PANEL] C-l  # Clear screen
tmux send-keys -t [SESSION]:agents.[PANEL] '{ligne1}' Enter
tmux send-keys -t [SESSION]:agents.[PANEL] '{ligne2}' Enter
# ... pour chaque ligne du message
```

#### **Étape 4: Fallback & Robustesse**
```bash
1. Tentative session principale (nestor-agents/haddock-agents)
2. Si échec → Fallback session par défaut (nestor-agents)
3. Si échec → Tentative panel global sans session
4. Logging complet de chaque étape
```

### **Distribution Email Active**
```sql
Nestor@moulinsart.local     : 142 emails
Tintin@moulinsart.local     : 140 emails
Haddock@moulinsart.local    : 98 emails
Dupont1@moulinsart.local    : 84 emails
Rastapopoulos@moulinsart.local : 67 emails
Dupont2@moulinsart.local    : 64 emails
Tournesol2@moulinsart.local : 46 emails
Tournesol1@moulinsart.local : 34 emails
[Author]@moulinsart.local   : 19 emails
```

---

## 🎯 RÔLE DE L'ORACLE

### **Responsabilités Principales**
- **Infrastructure** : Maintien des 3 services backend
- **Monitoring** : Surveillance ports 3001/1025/1080/5175
- **Support** : Troubleshooting dysfonctionnements système
- **Documentation** : Mise à jour procédures techniques

### **Limites Strictes**
- ❌ **Interdiction** : Modifier le travail des agents autonomes
- ❌ **Interdiction** : Toucher aux CLAUDE.md des équipes
- ❌ **Interdiction** : Intervenir dans le contenu métier
- ✅ **Autorisation** : Infrastructure et support technique uniquement

---

## 🛠️ GESTION OPÉRATIONNELLE

### **Script Manager Principal**
```bash
Fichier: ~/moulinsart/moulinsart-manager.sh
Version: Corrigée avec naming TMUX-Nestor/TMUX-Haddock

Options disponibles:
1) Lancer Équipe TMUX-Nestor
2) Lancer Équipe TMUX-Haddock
3) Lancer les DEUX équipes
4) Attacher à une session
5) Nettoyer tout
6) Redémarrer services (Oracle/Mail/Web)
7) Fix d'urgence
```

### **Scripts Simplifiés**
```bash
# Services backend uniquement
./start-services.sh  # Lance Oracle + Mail + Web
./stop-services.sh   # Arrête tous les services
```

---

## 📊 MÉTRIQUES & MONITORING

### **États Système Actuels**
```
Oracle API           : ✅ Opérationnel (1 client connecté)
Mail Server          : ✅ Opérationnel (notifications TMUX actives)
Dashboard            : ✅ Accessible (sessions corrigées)
Équipe TMUX-Nestor   : ❌ Session fermée (nestor-agents)
Équipe TMUX-Haddock  : ✅ Session active (haddock-agents, 4 agents)
Workflow Email→TMUX  : ✅ Fonctionnel (heartbeat configuré)
```

### **🔔 Configuration Notifications**
```json
Template: tmux-notification-config.json
- Heartbeat automatique sur réception email
- Instructions standardisées (Claude.md, API testées)
- Commandes spécifiques par agent
- Fallback multi-niveau pour robustesse
- Clear screen avant injection
```

### **Santé Réseau**
```bash
Port 3001: Oracle API      (LISTEN ✅)
Port 1025: SMTP Server     (LISTEN ✅)
Port 1080: Mail HTTP API   (LISTEN ✅)
Port 5175: Dashboard Vue   (LISTEN ✅)
```

### **Charge Système**
```
Processus Bun   : 3 instances (~600MB total)
Base SQLite     : 711 emails (optimisée)
Sessions TMUX   : 1 active (haddock-agents)
```

---

## 🚨 PROCÉDURES D'URGENCE

### **Redémarrage Complet**
```bash
# 1. Arrêter tout
pkill -f "bun.*oracle"
pkill -f "bun.*mail-server"
pkill -f "vite"

# 2. Nettoyer ports
lsof -ti :3001,1025,1080,5175 | xargs kill -9

# 3. Redémarrer services
cd ~/moulinsart/oracle-observability
bun run server/index.ts &
bun run server/mail-server.ts &
cd client && bun run dev &
```

### **Diagnostic Rapide**
```bash
# Vérifier services
curl -s http://localhost:3001/health
nc -zv localhost 1025
curl -s http://localhost:5175

# État sessions
tmux list-sessions

# Processus actifs
ps aux | grep -E "(bun|claude|tmux)"
```

---

## 🔄 ÉVOLUTION & MAINTENANCE

### **Logs Centralisés**
```bash
Oracle  : tail -f /tmp/oracle.log
Mail    : tail -f /tmp/mail.log
Web     : tail -f /tmp/web.log
```

### **Base de Données**
```bash
# Vérification intégrité
sqlite3 data/oracle.db "PRAGMA integrity_check"

# Backup automatique
cp data/oracle.db data/oracle.db.backup-$(date +%Y%m%d)
```

### **Mise à Jour Configuration**
- **Agents** : Modification uniquement de `/oracle-observability/CLAUDE.md`
- **Sessions** : Via `moulinsart-manager.sh` corrigé
- **Services** : Redémarrage avec `start-services.sh`

---

## 📈 ARCHITECTURE ÉVOLUTIVE

### **Support Multi-Projets**
```bash
# Système préparé pour projets parallèles
# Domaines virtuels : @projet.local
# Sessions isolées : [projet]-agents
# APIs extensibles
```

### **Monitoring Avancé**
```bash
# WebSocket temps réel
# Métriques de performance
# Alertes automatisées
# Dashboard centralisé
```

---

**🔮 Oracle de La Poste de Moulinsart**
*Gardien de l'infrastructure - Support technique 24/7*

---
*Document généré le $(date) - Version 1.0*
*Architecture validée pour Château de Moulinsart*