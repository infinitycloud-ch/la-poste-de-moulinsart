#!/bin/bash

# 🎮 MOULINSART CONTROL CENTER
# Script de contrôle complet du système d'agents

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Fonction pour afficher le menu
show_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║       📮 MOULINSART CONTROL CENTER 📮         ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}[1]${NC} 🚀 Lancer tous les agents (avec Terminal attaché)"
    echo -e "${BLUE}${BOLD}[2]${NC} 👀 Attacher à la session existante"
    echo -e "${YELLOW}${BOLD}[3]${NC} 📊 Voir le statut des agents"
    echo -e "${MAGENTA}${BOLD}[4]${NC} 🔄 Redémarrer tous les agents"
    echo -e "${RED}${BOLD}[5]${NC} 🛑 Arrêter tous les agents"
    echo -e "${CYAN}${BOLD}[6]${NC} 📧 Tester l'envoi d'un email"
    echo -e "${BOLD}[0]${NC} ❌ Quitter"
    echo ""
    echo -e "${BOLD}Choisissez une option:${NC} "
}

# Fonction pour lancer les agents
launch_agents() {
    echo -e "${GREEN}🚀 Lancement des agents...${NC}"
    
    # Nettoyer les sessions existantes
    tmux kill-session -t moulinsart-agents 2>/dev/null
    
    # Lancer le script de création
    ~/moulinsart/launch-agents-tmux.sh
    
    sleep 2
    
    # Attacher automatiquement
    echo -e "${CYAN}📺 Attachement à la session...${NC}"
    tmux attach -t moulinsart-agents
}

# Fonction pour attacher à une session existante
attach_session() {
    if tmux has-session -t moulinsart-agents 2>/dev/null; then
        echo -e "${CYAN}📺 Attachement à la session...${NC}"
        tmux attach -t moulinsart-agents
    else
        echo -e "${RED}❌ Aucune session active. Lancez d'abord les agents (option 1)${NC}"
        sleep 3
    fi
}

# Fonction pour voir le statut
check_status() {
    echo -e "${YELLOW}📊 Statut des agents:${NC}"
    echo ""
    
    # Vérifier si la session tmux existe
    if tmux has-session -t moulinsart-agents 2>/dev/null; then
        echo -e "${GREEN}✅ Session tmux active${NC}"
        echo ""
        echo "Panels actifs:"
        tmux list-panes -t moulinsart-agents:agents -F "  Panel #{pane_index}: #{pane_current_path}" 2>/dev/null
    else
        echo -e "${RED}❌ Aucune session tmux active${NC}"
    fi
    
    echo ""
    echo "Processus Claude:"
    ps aux | grep "claude --dangerously" | grep -v grep | wc -l | xargs echo "  Nombre d'agents actifs:"
    
    echo ""
    echo -e "${BOLD}Appuyez sur une touche pour continuer...${NC}"
    read -n 1
}

# Fonction pour redémarrer
restart_agents() {
    echo -e "${YELLOW}🔄 Redémarrage des agents...${NC}"
    
    # Arrêter
    tmux kill-session -t moulinsart-agents 2>/dev/null
    pkill -f "claude --dangerously" 2>/dev/null
    
    sleep 2
    
    # Relancer
    launch_agents
}

# Fonction pour arrêter
stop_agents() {
    echo -e "${RED}🛑 Arrêt de tous les agents...${NC}"
    
    tmux kill-session -t moulinsart-agents 2>/dev/null
    pkill -f "claude --dangerously" 2>/dev/null
    
    echo -e "${GREEN}✅ Tous les agents ont été arrêtés${NC}"
    sleep 2
}

# Fonction pour tester l'email
test_email() {
    echo -e "${CYAN}📧 Test d'envoi d'email${NC}"
    echo ""
    echo "Destinataire (nestor/tintin/dupont1/dupont2):"
    read agent
    
    echo "Message:"
    read message
    
    # Envoyer via curl au serveur mail
    curl -X POST http://localhost:1080/api/send \
        -H "Content-Type: application/json" \
        -d "{
            \"from\": \"commandant@moulinsart.local\",
            \"to\": \"${agent}@moulinsart.local\",
            \"subject\": \"Test depuis Control Center\",
            \"body\": \"${message}\"
        }"
    
    echo ""
    echo -e "${GREEN}✅ Email envoyé!${NC}"
    sleep 2
}

# Boucle principale
while true; do
    show_menu
    read -n 1 choice
    echo ""
    
    case $choice in
        1)
            launch_agents
            ;;
        2)
            attach_session
            ;;
        3)
            check_status
            ;;
        4)
            restart_agents
            ;;
        5)
            stop_agents
            ;;
        6)
            test_email
            ;;
        0)
            echo -e "${GREEN}Au revoir!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Option invalide${NC}"
            sleep 1
            ;;
    esac
done