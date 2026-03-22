#!/bin/bash

# 🚀 Script de lancement du système d'agents Moulinsart avec tmux
# Interface colorée style BD Tintin avec 4 panels

echo "🎬 Lancement du système d'agents Moulinsart..."

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Nettoyer les sessions existantes
echo "🧹 Nettoyage des sessions tmux existantes..."
tmux kill-session -t moulinsart-agents 2>/dev/null

# Créer la session principale avec 4 panels
echo "📦 Création de la session tmux avec 4 agents..."

# Créer la session avec le premier panel (Nestor)
tmux new-session -d -s moulinsart-agents -n agents -c ~/moulinsart/agents/nestor

# Diviser horizontalement pour Tintin (à droite)
tmux split-window -h -t moulinsart-agents:agents -c ~/moulinsart/agents/tintin

# Diviser verticalement pour Dupont1 (en bas à gauche)
tmux split-window -v -t moulinsart-agents:agents.0 -c ~/moulinsart/agents/dupont1

# Diviser verticalement pour Dupont2 (en bas à droite)  
tmux split-window -v -t moulinsart-agents:agents.2 -c ~/moulinsart/agents/dupont2

# Équilibrer les panels
tmux select-layout -t moulinsart-agents:agents tiled

# Configurer les titres des panels
tmux select-pane -t moulinsart-agents:agents.0 -T "🎩 NESTOR (Chef)"
tmux select-pane -t moulinsart-agents:agents.1 -T "🚀 TINTIN (QA)"
tmux select-pane -t moulinsart-agents:agents.2 -T "🎨 DUPONT1 (Dev)"
tmux select-pane -t moulinsart-agents:agents.3 -T "🔍 DUPONT2 (Dev)"

# Attendre un peu pour que les panels soient prêts
sleep 1

# IMPORTANT: Après "tiled" layout, les panels changent de position
# On doit d'abord les replacer dans les bons répertoires avec cd

echo -e "${GREEN}✅ Préparation de NESTOR (Panel 0)...${NC}"
tmux send-keys -t moulinsart-agents:agents.0 "cd ~/moulinsart/agents/nestor" Enter
tmux send-keys -t moulinsart-agents:agents.0 "clear" Enter
tmux send-keys -t moulinsart-agents:agents.0 "echo '🎩 NESTOR - Chef d\\'Orchestre'" Enter
tmux send-keys -t moulinsart-agents:agents.0 "echo '========================'" Enter
tmux send-keys -t moulinsart-agents:agents.0 "echo ''" Enter
tmux send-keys -t moulinsart-agents:agents.0 "claude --dangerously-skip-permissions" Enter

echo -e "${BLUE}✅ Préparation de TINTIN (Panel 1)...${NC}"  
tmux send-keys -t moulinsart-agents:agents.1 "cd ~/moulinsart/agents/tintin" Enter
tmux send-keys -t moulinsart-agents:agents.1 "clear" Enter
tmux send-keys -t moulinsart-agents:agents.1 "echo '🚀 TINTIN - QA Lead'" Enter
tmux send-keys -t moulinsart-agents:agents.1 "echo '=================='" Enter
tmux send-keys -t moulinsart-agents:agents.1 "echo ''" Enter
tmux send-keys -t moulinsart-agents:agents.1 "claude --dangerously-skip-permissions" Enter

echo -e "${YELLOW}✅ Préparation de DUPONT1 (Panel 2)...${NC}"
tmux send-keys -t moulinsart-agents:agents.2 "cd ~/moulinsart/agents/dupont1" Enter
tmux send-keys -t moulinsart-agents:agents.2 "clear" Enter
tmux send-keys -t moulinsart-agents:agents.2 "echo '🎨 DUPONT1 - Développeur Swift'" Enter
tmux send-keys -t moulinsart-agents:agents.2 "echo '=============================='" Enter
tmux send-keys -t moulinsart-agents:agents.2 "echo ''" Enter
tmux send-keys -t moulinsart-agents:agents.2 "claude --dangerously-skip-permissions" Enter

echo -e "${MAGENTA}✅ Préparation de DUPONT2 (Panel 3)...${NC}"
tmux send-keys -t moulinsart-agents:agents.3 "cd ~/moulinsart/agents/dupont2" Enter
tmux send-keys -t moulinsart-agents:agents.3 "clear" Enter
tmux send-keys -t moulinsart-agents:agents.3 "echo '🔍 DUPONT2 - Recherche & Docs'" Enter
tmux send-keys -t moulinsart-agents:agents.3 "echo '============================'" Enter
tmux send-keys -t moulinsart-agents:agents.3 "echo ''" Enter
tmux send-keys -t moulinsart-agents:agents.3 "claude --dangerously-skip-permissions" Enter

# Configurer la barre de status
tmux set -t moulinsart-agents status-style bg=blue,fg=white
tmux set -t moulinsart-agents status-left '#[bg=red,fg=white,bold] 📮 MOULINSART #[default] '
tmux set -t moulinsart-agents status-right '#[bg=green,fg=black] %H:%M:%S #[default]'
tmux set -t moulinsart-agents status-interval 1

# Activer les titres de panels
tmux set -t moulinsart-agents pane-border-status top
tmux set -t moulinsart-agents pane-border-format "#{pane_title}"

# Couleurs des bordures
tmux set -t moulinsart-agents pane-active-border-style fg=cyan,bg=default
tmux set -t moulinsart-agents pane-border-style fg=white,bg=default

echo ""
echo "🎉 Système d'agents Moulinsart lancé avec succès!"
echo ""
echo "📌 Commandes utiles:"
echo "   • Attacher à la session : tmux attach -t moulinsart-agents"
echo "   • Navigation : Ctrl+B puis flèches"
echo "   • Zoom panel : Ctrl+B puis Z"
echo "   • Détacher : Ctrl+B puis D"
echo ""
echo "🎯 Pour envoyer une commande à un agent:"
echo "   tmux send-keys -t moulinsart-agents:agents.0 \"votre message\" Enter"
echo "   (0=Nestor, 1=Tintin, 2=Dupont1, 3=Dupont2)"
echo ""

# Ne pas proposer d'attacher si lancé depuis un autre script
# (Le script parent s'en chargera)