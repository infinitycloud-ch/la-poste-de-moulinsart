#!/bin/bash

# 🎮 Script de contrôle des agents Moulinsart
# Permet d'interagir avec les agents via tmux

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Vérifier si la session existe
check_session() {
    tmux has-session -t moulinsart-agents 2>/dev/null
    if [ $? != 0 ]; then
        echo -e "${RED}❌ Session tmux 'moulinsart-agents' non trouvée!${NC}"
        echo "Lancez d'abord: ./launch-agents-tmux.sh"
        exit 1
    fi
}

# Afficher le menu
show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🎮 CONTRÔLE DES AGENTS MOULINSART${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Commandes Disponibles:${NC}"
    echo ""
    echo "  1) 📧 Consulter emails d'un agent"
    echo "  2) 💬 Envoyer message à un agent"
    echo "  3) 📸 Capturer output d'un agent"
    echo "  4) 🔄 Synchroniser tous les agents"
    echo "  5) 🧹 Clear tous les écrans"
    echo "  6) 📊 Status de tous les agents"
    echo "  7) 🚀 Envoyer prompt à tous"
    echo "  8) 📮 Envoyer email test"
    echo "  9) 👁️  Voir la session tmux"
    echo "  0) 🚪 Quitter"
    echo ""
}

# Sélectionner un agent
select_agent() {
    echo -e "${BLUE}Sélectionnez l'agent:${NC}"
    echo "  1) 🎩 Nestor (Chef)"
    echo "  2) 🚀 Tintin (QA)"
    echo "  3) 🎨 Dupont1 (Dev)"
    echo "  4) 🔍 Dupont2 (Dev)"
    read -p "Choix: " agent_choice
    
    case $agent_choice in
        1) AGENT_PANE="0"; AGENT_NAME="Nestor"; AGENT_EMAIL="nestor@moulinsart.local";;
        2) AGENT_PANE="1"; AGENT_NAME="Tintin"; AGENT_EMAIL="tintin@moulinsart.local";;
        3) AGENT_PANE="2"; AGENT_NAME="Dupont1"; AGENT_EMAIL="dupont1@moulinsart.local";;
        4) AGENT_PANE="3"; AGENT_NAME="Dupont2"; AGENT_EMAIL="dupont2@moulinsart.local";;
        *) echo "Choix invalide"; return 1;;
    esac
}

# Consulter emails
check_emails() {
    select_agent
    echo -e "${CYAN}📧 Consultation des emails de $AGENT_NAME...${NC}"
    curl -s http://localhost:1080/api/mailbox/$AGENT_EMAIL | jq '.' 2>/dev/null || echo "Pas d'emails ou service indisponible"
    read -p "Appuyez sur Entrée pour continuer..."
}

# Envoyer message
send_message() {
    select_agent
    echo -e "${BLUE}💬 Message pour $AGENT_NAME:${NC}"
    read -p "> " message
    
    tmux send-keys -t moulinsart-agents:agents.$AGENT_PANE "$message" Enter
    echo -e "${GREEN}✅ Message envoyé!${NC}"
    sleep 1
}

# Capturer output
capture_output() {
    select_agent
    echo -e "${CYAN}📸 Capture de l'output de $AGENT_NAME...${NC}"
    
    OUTPUT_FILE="/tmp/agent_${AGENT_NAME}_output.txt"
    tmux capture-pane -t moulinsart-agents:agents.$AGENT_PANE -p > "$OUTPUT_FILE"
    
    echo -e "${GREEN}✅ Output sauvé dans: $OUTPUT_FILE${NC}"
    echo ""
    echo "Dernières 20 lignes:"
    echo "===================="
    tail -20 "$OUTPUT_FILE"
    read -p "Appuyez sur Entrée pour continuer..."
}

# Synchroniser agents
sync_agents() {
    echo -e "${YELLOW}🔄 Synchronisation des agents...${NC}"
    tmux setw -t moulinsart-agents:agents synchronize-panes
    STATUS=$(tmux show-window-options -t moulinsart-agents:agents | grep synchronize-panes | cut -d' ' -f2)
    
    if [ "$STATUS" == "on" ]; then
        echo -e "${GREEN}✅ Synchronisation activée!${NC}"
        echo "Tous les agents recevront les mêmes commandes"
    else
        echo -e "${RED}❌ Synchronisation désactivée${NC}"
    fi
    sleep 2
}

# Clear tous les écrans
clear_all() {
    echo -e "${CYAN}🧹 Nettoyage de tous les écrans...${NC}"
    for i in 0 1 2 3; do
        tmux send-keys -t moulinsart-agents:agents.$i "clear" Enter
    done
    echo -e "${GREEN}✅ Écrans nettoyés!${NC}"
    sleep 1
}

# Status des agents
show_status() {
    echo -e "${CYAN}📊 STATUS DES AGENTS${NC}"
    echo "===================="
    
    # Vérifier si les panels existent
    for i in 0 1 2 3; do
        case $i in
            0) NAME="Nestor";;
            1) NAME="Tintin";;
            2) NAME="Dupont1";;
            3) NAME="Dupont2";;
        esac
        
        if tmux list-panes -t moulinsart-agents:agents -F "#{pane_index}" | grep -q "^$i$"; then
            echo -e "${GREEN}✅ $NAME: Actif${NC}"
        else
            echo -e "${RED}❌ $NAME: Inactif${NC}"
        fi
    done
    
    echo ""
    echo "Services:"
    curl -s http://localhost:3001/health >/dev/null 2>&1 && echo -e "${GREEN}✅ Oracle API: OK${NC}" || echo -e "${RED}❌ Oracle API: DOWN${NC}"
    curl -s http://localhost:1080 >/dev/null 2>&1 && echo -e "${GREEN}✅ Mail Server: OK${NC}" || echo -e "${RED}❌ Mail Server: DOWN${NC}"
    
    read -p "Appuyez sur Entrée pour continuer..."
}

# Envoyer prompt à tous
broadcast_prompt() {
    echo -e "${MAGENTA}🚀 Message à diffuser à tous les agents:${NC}"
    read -p "> " prompt
    
    # Synchroniser temporairement
    tmux setw -t moulinsart-agents:agents synchronize-panes on
    tmux send-keys -t moulinsart-agents:agents.0 "$prompt" Enter
    sleep 1
    tmux setw -t moulinsart-agents:agents synchronize-panes off
    
    echo -e "${GREEN}✅ Message diffusé!${NC}"
    sleep 1
}

# Envoyer email test
send_test_email() {
    echo -e "${YELLOW}📮 Envoi d'un email test à Nestor...${NC}"
    
    # Créer un email test
    EMAIL_DATA=$(cat <<EOF
{
  "from": "commandant@moulinsart.local",
  "to": "nestor@moulinsart.local",
  "subject": "Test Mission",
  "body": "Nestor, ceci est un test du système de communication. Veuillez confirmer réception et dispatcher aux agents appropriés."
}
EOF
)
    
    # Envoyer via curl (simuler SMTP)
    curl -X POST http://localhost:1080/api/send-email \
         -H "Content-Type: application/json" \
         -d "$EMAIL_DATA" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Email envoyé!${NC}"
    else
        echo -e "${RED}❌ Erreur d'envoi (vérifiez le mail server)${NC}"
    fi
    sleep 2
}

# Attacher à la session
attach_session() {
    echo -e "${CYAN}👁️  Attachement à la session tmux...${NC}"
    tmux attach -t moulinsart-agents
}

# Programme principal
check_session

while true; do
    show_menu
    read -p "Votre choix: " choice
    
    case $choice in
        1) check_emails;;
        2) send_message;;
        3) capture_output;;
        4) sync_agents;;
        5) clear_all;;
        6) show_status;;
        7) broadcast_prompt;;
        8) send_test_email;;
        9) attach_session;;
        0) echo -e "${GREEN}Au revoir!${NC}"; exit 0;;
        *) echo -e "${RED}Choix invalide${NC}"; sleep 1;;
    esac
done