# 🎩 CLAUDE.md - {AGENT_NAME}

## 👤 Identité
- **Nom** : {AGENT_NAME}
- **Équipe TMUX** : {TEAM_NAME}
- **Session** : {SESSION_NAME}
- **Panel** : {PANEL_NUMBER}

## 📋 Équipe & Organisation

### **Votre Équipe TMUX :**
{TEAM_MEMBERS}

### **Communication Email**
- **Votre adresse** : {AGENT_EMAIL}
- **Boîte mail** : Consultez `curl http://localhost:1080/mailbox/{AGENT_NAME}`
- **Envoi email** : Utilisez le script `~/moulinsart/send-mail.sh`

## 🔧 Session TMUX

### **Commandes de base :**
```bash
# Voir votre session
tmux ls | grep {SESSION_NAME}

# Attacher à votre session
tmux attach-session -t {SESSION_NAME}

# Lister les panels
tmux list-panes -t {SESSION_NAME}:agents

# Envoyer commande à un autre agent de votre équipe
tmux send-keys -t {SESSION_NAME}:agents.{TARGET_PANEL} "votre commande" C-m
```

### **Règles de Communication :**
1. **Restez dans votre équipe** - Ne communiquez pas avec l'autre équipe TMUX
2. **Utilisez les emails** pour les communications formelles
3. **TMUX send-keys** pour les commandes directes entre équipiers
4. **Respectez les panels** de chaque agent

## 📧 Système Email

### **Consultation de vos mails :**
```bash
curl -s http://localhost:1080/mailbox/{AGENT_NAME} | tail -10
```

### **Envoi d'email :**
```bash
./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"
```

### **Destinataires autorisés (votre équipe) :**
{AUTHORIZED_RECIPIENTS}

## 🎯 Instructions Spécifiques de Mission

{MISSION_INSTRUCTIONS}

## ⚡ Actions Rapides

### **Reset complet de votre briefing :**
```bash
~/moulinsart/instructions-equipes-tmux/reset-briefing.sh {AGENT_NAME}
```

### **Vérification système :**
```bash
# Statut Oracle
curl -s http://localhost:3001/health

# Votre session TMUX
tmux has-session -t {SESSION_NAME} && echo "✅ Session active" || echo "❌ Session inactive"

# Vos emails récents
curl -s http://localhost:1080/mailbox/{AGENT_NAME} | tail -3
```

---
*Dernière mise à jour : Généré automatiquement par reset-briefing.sh*