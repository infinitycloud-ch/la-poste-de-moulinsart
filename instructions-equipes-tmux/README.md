# 🎩 Système de Briefing TMUX Teams

## 🎯 Objectif
Système automatisé de briefing et d'instructions pour les équipes TMUX de Moulinsart.

## 📁 Structure

```
instructions-equipes-tmux/
├── README.md                    # Ce fichier
├── template-claude.md           # Template générique pour tous les agents
├── reset-briefing.sh           # Script principal de génération
├── boite-outils.sh             # Boîte à outils interactive
├── nestor-equipe/              # Instructions équipe Nestor
│   ├── nestor                  # Instructions spécifiques Nestor
│   ├── tintin                  # Instructions spécifiques Tintin
│   ├── dupont1                 # Instructions spécifiques Dupont1
│   └── dupont2                 # Instructions spécifiques Dupont2
└── haddock-equipe/             # Instructions équipe Haddock
    ├── haddock                 # Instructions spécifiques Haddock
    ├── rastapopoulos           # Instructions spécifiques Rastapopoulos
    ├── tournesol1              # Instructions spécifiques Tournesol1
    └── tournesol2              # Instructions spécifiques Tournesol2
```

## 🚀 Usage Principal

### **Briefing d'un agent :**
```bash
./reset-briefing.sh [agent_name]
```

**Exemple :**
```bash
./reset-briefing.sh nestor
./reset-briefing.sh tintin
./reset-briefing.sh haddock
```

### **Boîte à outils interactive :**
```bash
./boite-outils.sh
```

## 👥 Équipes TMUX

### **Équipe Nestor (nestor-agents)**
- **nestor** (Panel 0) - Orchestrateur
- **tintin** (Panel 1) - Reporter/QA
- **dupont1** (Panel 2) - Développeur iOS
- **dupont2** (Panel 3) - Documentation/i18n

### **Équipe Haddock (haddock-agents)**
- **haddock** (Panel 0) - Capitaine
- **rastapopoulos** (Panel 1) - Sécurité
- **tournesol1** (Panel 2) - Scientifique
- **tournesol2** (Panel 3) - Ingénieur

## 🔧 Fonctionnement

### **1. Reset Briefing**
Le script `reset-briefing.sh` :
1. Identifie l'équipe de l'agent
2. Charge le template générique
3. Injecte les instructions spécifiques depuis le fichier correspondant
4. Génère un CLAUDE.md personnalisé dans `~/moulinsart/agents/[agent]/`
5. Effectue des vérifications système

### **2. Template System**
- **Template générique** : Informations communes (TMUX, email, règles)
- **Instructions spécifiques** : Fichiers par agent avec rôles et responsabilités
- **Variables dynamiques** : Remplacées automatiquement selon l'agent

### **3. Variables Template**
- `{AGENT_NAME}` → nom de l'agent
- `{TEAM_NAME}` → nom de l'équipe
- `{SESSION_NAME}` → session TMUX
- `{PANEL_NUMBER}` → numéro de panel
- `{AGENT_EMAIL}` → adresse email
- `{TEAM_MEMBERS}` → liste des équipiers
- `{AUTHORIZED_RECIPIENTS}` → destinataires autorisés
- `{MISSION_INSTRUCTIONS}` → instructions spécifiques chargées depuis le fichier

## 📧 Communication

### **Règles strictes :**
- **Équipe Nestor** ne communique QUE entre eux
- **Équipe Haddock** ne communique QUE entre eux
- **Pas de communication inter-équipes** (sauf Commandant)

### **Canaux disponibles :**
- **Email** : Communications formelles via send-mail.sh
- **TMUX send-keys** : Commandes directes entre équipiers
- **Oracle API** : Statuts et notifications système

## 🧰 Boîte à Outils

Le script `boite-outils.sh` propose un menu interactif :

1. **🔄 Reset briefing complet** - Régénère le CLAUDE.md
2. **📧 Consulter mes mails** - Affiche les emails récents
3. **✉️ Envoyer un email** - Interface d'envoi email
4. **🖥️ Voir ma session TMUX** - Informations session
5. **👥 Contacter mon équipe** - Options de communication
6. **🏥 Diagnostics système** - Vérifications santé
7. **📋 Relire mon CLAUDE.md** - Affiche les instructions
8. **🚀 Attacher à ma session TMUX** - Connexion directe
9. **❌ Quitter**

## 🎯 Instructions Commandant

### **Pour briefer un agent :**
```bash
# Dire à l'agent :
"Exécutez : ./instructions-equipes-tmux/reset-briefing.sh [votre_nom]"
"Puis lisez votre CLAUDE.md et exécutez."
```

### **Pour une mission :**
1. **Modifier les fichiers d'instructions** spécifiques dans les dossiers d'équipe
2. **Lancer le reset** pour tous les agents concernés
3. **Les agents recevront automatiquement** les nouvelles instructions dans leur CLAUDE.md

### **Exemple workflow :**
```bash
# 1. Modifier les instructions
echo "Mission spéciale X" >> nestor-equipe/nestor
echo "Tâche Y assignée" >> nestor-equipe/tintin

# 2. Briefer l'équipe
./reset-briefing.sh nestor
./reset-briefing.sh tintin
./reset-briefing.sh dupont1
./reset-briefing.sh dupont2

# 3. Informer Nestor
"Lisez votre CLAUDE.md et exécutez la mission."
```

## ⚠️ Points Importants

- **Fichiers générés** : Les CLAUDE.md sont ÉCRASÉS à chaque reset
- **Instructions persistantes** : Modifiez les fichiers source dans les dossiers d'équipe
- **Séparation stricte** : Les équipes ne se mélangent jamais
- **Validation système** : Chaque reset vérifie Oracle/TMUX/Mail
- **Automatisation complète** : Aucune intervention manuelle nécessaire après setup

## 🔍 Troubleshooting

### **Agent ne trouve pas ses instructions :**
```bash
# Vérifier que le fichier existe
ls -la instructions-equipes-tmux/[equipe]/[agent]

# Régénérer
./reset-briefing.sh [agent]
```

### **Session TMUX inactive :**
```bash
# Vérifier les sessions
tmux ls

# Le système Oracle doit créer les sessions
```

### **Emails ne fonctionnent pas :**
```bash
# Vérifier services
curl -s http://localhost:3001/health
nc -z localhost 1025
```

---
*Système créé pour automatiser le briefing des équipes TMUX Moulinsart*