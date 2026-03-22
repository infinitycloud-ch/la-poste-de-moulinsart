# 🎮 COMMANDES RAPIDES POUR CONTRÔLER LES AGENTS

## 📞 COMMANDES DIRECTES TMUX

### Réveiller/Débloquer un agent
```bash
# Nestor (Panel 0)
tmux send-keys -t moulinsart-agents:agents.0 C-c Enter

# Tintin (Panel 1)  
tmux send-keys -t moulinsart-agents:agents.1 C-c Enter

# Dupont1 (Panel 2)
tmux send-keys -t moulinsart-agents:agents.2 C-c Enter

# Dupont2 (Panel 3)
tmux send-keys -t moulinsart-agents:agents.3 C-c Enter
```

### Envoyer une commande/question
```bash
# À Nestor
tmux send-keys -t moulinsart-agents:agents.0 "Quel est le statut du projet?" Enter

# À Tintin
tmux send-keys -t moulinsart-agents:agents.1 "Lance les tests du Sprint 1" Enter

# À Dupont1
tmux send-keys -t moulinsart-agents:agents.2 "Compile le code Swift" Enter

# À Dupont2
tmux send-keys -t moulinsart-agents:agents.3 "Vérifie la localisation" Enter

# À Haddock (Manitoba)
tmux send-keys -t manitoba-agents:agents.0 "Statut projets expérimentaux?" Enter

# À Rastapopoulos (Manitoba)
tmux send-keys -t manitoba-agents:agents.1 "Tests QA Manitoba" Enter

# À Tournesol1 (Manitoba)
tmux send-keys -t manitoba-agents:agents.2 "Développement en cours" Enter

# À Tournesol2 (Manitoba)
tmux send-keys -t manitoba-agents:agents.3 "Documentation recherche" Enter
```

### Débloquer TOUS les agents d'un coup
```bash
# Moulinsart
for i in {0..3}; do tmux send-keys -t moulinsart-agents:agents.$i C-c Enter; done

# Manitoba
for i in {0..3}; do tmux send-keys -t manitoba-agents:agents.$i C-c Enter; done

# TOUS LES AGENTS (8 agents)
for i in {0..3}; do tmux send-keys -t moulinsart-agents:agents.$i C-c Enter; done
for i in {0..3}; do tmux send-keys -t manitoba-agents:agents.$i C-c Enter; done
```

### Message à TOUS les agents
```bash
# Moulinsart
for i in {0..3}; do tmux send-keys -t moulinsart-agents:agents.$i "Vérifiez vos emails!" Enter; done

# Manitoba
for i in {0..3}; do tmux send-keys -t manitoba-agents:agents.$i "Vérifiez vos emails!" Enter; done
```

## 📧 ENVOI D'EMAILS


### Via SMTP direct
```bash
echo -e "From: system@moulinsart.local\nTo: tintin@moulinsart.local\nSubject: Test\n\nMessage" | \
  curl -s --url "smtp://localhost:1025" \
  --mail-from "system@moulinsart.local" \
  --mail-rcpt "tintin@moulinsart.local" \
  --upload-file -
```

## 🔍 VÉRIFICATION

### Voir la session tmux
```bash
tmux attach -t moulinsart-agents
# Pour détacher: Ctrl+B puis D
```

### Voir le contenu d'un panel
```bash
# Nestor
tmux capture-pane -t moulinsart-agents:agents.0 -p | tail -20

# Tintin
tmux capture-pane -t moulinsart-agents:agents.1 -p | tail -20
```

### Vérifier les boîtes mail
```bash
# ÉQUIPE MOULINSART
curl http://localhost:1080/api/mailbox/nestor@moulinsart.local
curl http://localhost:1080/api/mailbox/tintin@moulinsart.local
curl http://localhost:1080/api/mailbox/dupont1@moulinsart.local
curl http://localhost:1080/api/mailbox/dupont2@moulinsart.local

# ÉQUIPE MANITOBA
curl http://localhost:1080/api/mailbox/haddock@moulinsart.local
curl http://localhost:1080/api/mailbox/rastapopoulos@moulinsart.local
curl http://localhost:1080/api/mailbox/tournesol1@moulinsart.local
curl http://localhost:1080/api/mailbox/tournesol2@moulinsart.local
```

## 🚀 SCRIPTS UTILES

### Réveiller un agent
```bash
~/moulinsart/wake-agent.sh nestor "Message"
~/moulinsart/wake-agent.sh tintin "Message"
```

### Broadcast à tous
```bash
~/moulinsart/broadcast.sh "Message urgent à tous!"
```

### Poser une question
```bash
~/moulinsart/ask-agent.sh nestor "Question?"
```

## ⚡ RACCOURCIS ULTRA-RAPIDES

```bash
# Débloquer tout le monde
alias wake-all='for i in {0..3}; do tmux send-keys -t moulinsart-agents:agents.$i C-c Enter; done'

# Nestor
alias nestor='tmux send-keys -t moulinsart-agents:agents.0'

# Tintin  
alias tintin='tmux send-keys -t moulinsart-agents:agents.1'

# Dupont1
alias dupont1='tmux send-keys -t moulinsart-agents:agents.2'

# Dupont2
alias dupont2='tmux send-keys -t moulinsart-agents:agents.3'
```

## 📍 MAPPING AGENTS → PANELS

### 🎩 ÉQUIPE MOULINSART (Session: moulinsart-agents)
| Agent | Panel | Email |
|-------|-------|-------|
| NESTOR | 0 | nestor@moulinsart.local |
| TINTIN | 1 | tintin@moulinsart.local |
| DUPONT1 | 2 | dupont1@moulinsart.local |
| DUPONT2 | 3 | dupont2@moulinsart.local |

### 🌾 ÉQUIPE MANITOBA (Session: manitoba-agents)
| Agent | Panel | Email |
|-------|-------|-------|
| HADDOCK | 0 | haddock@moulinsart.local |
| RASTAPOPOULOS | 1 | rastapopoulos@moulinsart.local |
| TOURNESOL1 | 2 | tournesol1@moulinsart.local |
| TOURNESOL2 | 3 | tournesol2@moulinsart.local |
