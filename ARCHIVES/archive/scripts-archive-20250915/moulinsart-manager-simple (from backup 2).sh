#!/bin/bash

# 🎮 Gestionnaire Principal Moulinsart - VERSION SIMPLE
# Lance directement Claude dans chaque panel

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
SESSION_NAME="moulinsart-agents"
AGENTS=("nestor" "tintin" "dupont1" "dupont2")

# Fonction pour afficher le header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}${BOLD}📮 GESTIONNAIRE MOULINSART${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction pour nettoyer tout
clean_all() {
    echo -e "${RED}🧹 Nettoyage complet en cours...${NC}"
    echo ""
    
    # 1. Tuer la session principale
    echo "• Fermeture de la session principale..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    
    # 2. Tuer tous les processus Claude restants
    echo "• Arrêt des processus Claude..."
    pkill -f "claude --dangerously-skip-permissions" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✅ Nettoyage terminé!${NC}"
    sleep 2
}

# Fonction pour lancer les agents - VERSION SIMPLE
launch_agents() {
    echo -e "${GREEN}🚀 Lancement du système d'agents...${NC}"
    echo ""
    
    # Vérifier si la session existe déjà
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  La session existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$SESSION_NAME"
        else
            echo "Annulation..."
            return
        fi
    fi
    
    # Créer la session avec 4 panels
    echo "• Création de la session tmux..."
    tmux new-session -d -s "$SESSION_NAME" -n agents
    
    echo "• Division en 4 panels..."
    # Créer le layout 2x2 avec tailles équilibrées
    tmux split-window -h -t "$SESSION_NAME:agents" -p 50
    tmux split-window -v -t "$SESSION_NAME:agents.0" -p 50
    tmux split-window -v -t "$SESSION_NAME:agents.2" -p 50
    
    # Naviguer dans les bons répertoires
    # Panel 0: NESTOR (haut gauche)
    tmux send-keys -t "$SESSION_NAME:agents.0" 'cd ~/moulinsart/agents/nestor' Enter
    
    # Panel 1: TINTIN (bas gauche) 
    tmux send-keys -t "$SESSION_NAME:agents.1" 'cd ~/moulinsart/agents/tintin' Enter
    
    # Panel 2: DUPONT1 (haut droite)
    tmux send-keys -t "$SESSION_NAME:agents.2" 'cd ~/moulinsart/agents/dupont1' Enter
    
    # Panel 3: DUPONT2 (bas droite)
    tmux send-keys -t "$SESSION_NAME:agents.3" 'cd ~/moulinsart/agents/dupont2' Enter
    
    # Configuration visuelle avancée avec couleurs
    tmux set -t "$SESSION_NAME" pane-border-status top
    tmux set -t "$SESSION_NAME" pane-border-format "#[fg=white,bg=blue,bold] #{pane_title} #[default]"
    tmux set -t "$SESSION_NAME" pane-active-border-style "fg=yellow,bg=default"
    tmux set -t "$SESSION_NAME" pane-border-style "fg=white,bg=default"
    
    # Configurer les titres avec couleurs
    tmux select-pane -t "$SESSION_NAME:agents.0" -T "🎩 NESTOR"
    tmux select-pane -t "$SESSION_NAME:agents.1" -T "🚀 TINTIN" 
    tmux select-pane -t "$SESSION_NAME:agents.2" -T "🎨 DUPONT1"
    tmux select-pane -t "$SESSION_NAME:agents.3" -T "🔍 DUPONT2"
    
    # Couleurs de fond distinctes pour chaque panel
    tmux select-pane -t "$SESSION_NAME:agents.0" -P 'bg=#1a1a2e'
    tmux select-pane -t "$SESSION_NAME:agents.1" -P 'bg=#0f0f1e'
    tmux select-pane -t "$SESSION_NAME:agents.2" -P 'bg=#1e1a2e'
    tmux select-pane -t "$SESSION_NAME:agents.3" -P 'bg=#1a1e2e'
    
    # Équilibrer les panels parfaitement
    tmux select-layout -t "$SESSION_NAME:agents" even-vertical
    tmux resize-pane -t "$SESSION_NAME:agents.0" -x 50%
    tmux resize-pane -t "$SESSION_NAME:agents.2" -x 50%
    
    sleep 1
    
    # Afficher les bannières colorées et lancer Claude
    echo "• Lancement de Claude dans chaque panel..."
    
    # NESTOR - Bannière dorée
    tmux send-keys -t "$SESSION_NAME:agents.0" "clear && echo -e '\\033[1;33m'
    echo '╔════════════════════════════════════════╗'
    echo '║       🎩 NESTOR - Chef d\\''Orchestre      ║'
    echo '║         nestor@moulinsart.local        ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # TINTIN - Bannière bleue
    tmux send-keys -t "$SESSION_NAME:agents.1" "clear && echo -e '\\033[1;36m'
    echo '╔════════════════════════════════════════╗'
    echo '║         🚀 TINTIN - QA Lead            ║'
    echo '║         tintin@moulinsart.local        ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # DUPONT1 - Bannière verte
    tmux send-keys -t "$SESSION_NAME:agents.2" "clear && echo -e '\\033[1;32m'
    echo '╔════════════════════════════════════════╗'
    echo '║       🎨 DUPONT1 - Développeur         ║'
    echo '║        dupont1@moulinsart.local        ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # DUPONT2 - Bannière magenta
    tmux send-keys -t "$SESSION_NAME:agents.3" "clear && echo -e '\\033[1;35m'
    echo '╔════════════════════════════════════════╗'
    echo '║      🔍 DUPONT2 - Recherche & Docs     ║'
    echo '║        dupont2@moulinsart.local        ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    sleep 2
    
    # Lancer Claude dans chaque panel
    tmux send-keys -t "$SESSION_NAME:agents.0" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.1" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.2" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.3" "claude --dangerously-skip-permissions" Enter
    
    echo ""
    echo -e "${GREEN}✅ Système lancé avec succès!${NC}"
    echo ""
    
    read -p "Voulez-vous attacher à la session maintenant? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        tmux attach -t "$SESSION_NAME"
    fi
}

# Fonction pour attacher à la session
attach_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}📎 Attachement à la session...${NC}"
        echo ""
        echo -e "${CYAN}💡 Raccourcis tmux utiles:${NC}"
        echo "   • Ctrl+B puis flèches : naviguer entre panels"
        echo "   • Ctrl+B puis Z : zoom/dézoom sur un panel"
        echo "   • Ctrl+B puis D : détacher la session"
        echo "   • Ctrl+B puis : puis 'select-layout even-vertical' : réorganiser"
        echo ""
        sleep 2
        tmux attach -t "$SESSION_NAME"
    else
        echo -e "${RED}❌ Aucune session active trouvée${NC}"
        echo ""
        read -p "Voulez-vous lancer le système? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            launch_agents
        fi
    fi
}

# Fonction pour le status rapide
quick_status() {
    echo -e "${CYAN}📊 STATUS RAPIDE${NC}"
    echo "================"
    
    # Session principale
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ Session principale: Active${NC}"
        
        # Vérifier chaque panel
        for i in 0 1 2 3; do
            case $i in
                0) agent="Nestor";;
                1) agent="Tintin";;
                2) agent="Dupont1";;
                3) agent="Dupont2";;
            esac
            
            if tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_index}" | grep -q "^$i$"; then
                echo -e "  ${GREEN}●${NC} $agent: OK"
            else
                echo -e "  ${RED}●${NC} $agent: Manquant"
            fi
        done
    else
        echo -e "${RED}❌ Session principale: Inactive${NC}"
    fi
    
    echo ""
    # Vérifier les processus Claude
    CLAUDE_COUNT=$(ps aux | grep -v grep | grep "claude --dangerously" | wc -l)
    if [ $CLAUDE_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ $CLAUDE_COUNT processus Claude actifs${NC}"
    else
        echo -e "${RED}❌ Aucun processus Claude actif${NC}"
    fi
    
    echo ""
}

# Menu principal
show_menu() {
    show_header
    quick_status
    echo -e "${BOLD}OPTIONS AGENTS:${NC}"
    echo ""
    echo "  1) 🧹 Reset complet et lancer"
    echo "  2) 📎 Attacher/Reprendre session"
    echo "  3) 🚀 Lancer sans reset"
    echo "  4) 🗑️  Nettoyer tout (sans relancer)"
    echo ""
    echo -e "${BOLD}OPTIONS SERVEURS:${NC}"
    echo ""
    echo "  5) 🔄 Redémarrer serveur Oracle"
    echo "  6) 📧 Redémarrer serveur Mail"
    echo "  7) 🌐 Redémarrer client Web"
    echo "  8) ♻️  Redémarrer TOUT (Oracle + Mail + Web)"
    echo ""
    echo "  0) 🚪 Quitter"
    echo ""
}

# Fonction pour redémarrer Oracle
restart_oracle() {
    echo -e "${YELLOW}🔄 Redémarrage du serveur Oracle...${NC}"
    pkill -f "bun.*server/index.ts" 2>/dev/null
    sleep 1
    cd ~/moulinsart/oracle-observability
    nohup bun run server/index.ts > /dev/null 2>&1 &
    sleep 2
    if lsof -i :3001 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Oracle redémarré sur port 3001${NC}"
    else
        echo -e "${RED}❌ Erreur au redémarrage d'Oracle${NC}"
    fi
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour redémarrer Mail
restart_mail() {
    echo -e "${YELLOW}📧 Redémarrage du serveur Mail...${NC}"
    pkill -f "bun.*mail-server" 2>/dev/null
    sleep 1
    cd ~/moulinsart/oracle-observability
    nohup bun run server/mail-server.ts > /dev/null 2>&1 &
    sleep 2
    if lsof -i :1080 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Mail Server redémarré sur port 1080${NC}"
    else
        echo -e "${RED}❌ Erreur au redémarrage du Mail Server${NC}"
    fi
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour redémarrer le client Web
restart_web() {
    echo -e "${YELLOW}🌐 Redémarrage du client Web...${NC}"
    # Tuer tous les processus Vite
    pkill -f "vite" 2>/dev/null
    lsof -ti :5175 | xargs kill -9 2>/dev/null
    sleep 2
    cd ~/moulinsart/oracle-observability/client
    nohup bun run dev > /dev/null 2>&1 &
    sleep 3
    if lsof -i :5175 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Client Web redémarré${NC}"
        echo "Accessible sur: http://localhost:5175"
    else
        echo -e "${RED}❌ Erreur au redémarrage du client Web${NC}"
    fi
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour tout redémarrer
restart_all_services() {
    echo -e "${MAGENTA}♻️  Redémarrage de TOUS les services...${NC}"
    echo ""
    
    # Oracle
    echo "• Redémarrage Oracle..."
    pkill -f "bun.*server/index.ts" 2>/dev/null
    sleep 1
    cd ~/moulinsart/oracle-observability
    nohup bun run server/index.ts > /dev/null 2>&1 &
    
    # Mail
    echo "• Redémarrage Mail Server..."
    pkill -f "bun.*mail-server" 2>/dev/null
    sleep 1
    nohup bun run server/mail-server.ts > /dev/null 2>&1 &
    
    # Web
    echo "• Redémarrage Client Web..."
    pkill -f "vite" 2>/dev/null
    sleep 1
    cd client
    nohup bun run dev > /dev/null 2>&1 &
    
    sleep 3
    echo ""
    echo -e "${GREEN}✅ Tous les services ont été redémarrés!${NC}"
    echo ""
    echo "Services disponibles:"
    echo "  📡 Oracle API: http://localhost:3001"
    echo "  📧 Mail Server: http://localhost:1080"
    echo "  🌐 Dashboard: http://localhost:5175"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Programme principal
while true; do
    show_menu
    read -p "Votre choix: " choice
    
    case $choice in
        1)
            show_header
            clean_all
            launch_agents
            ;;
        2)
            show_header
            attach_session
            ;;
        3)
            show_header
            launch_agents
            ;;
        4)
            show_header
            clean_all
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        5)
            show_header
            restart_oracle
            ;;
        6)
            show_header
            restart_mail
            ;;
        7)
            show_header
            restart_web
            ;;
        8)
            show_header
            restart_all_services
            ;;
        0)
            echo -e "${GREEN}Au revoir!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            sleep 1
            ;;
    esac
done