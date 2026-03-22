#!/bin/bash

# 🎮 Gestionnaire Principal Moulinsart - VERSION CORRIGÉE
# Gère les sessions tmux des agents avec les bons répertoires

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

# Fonction pour scanner les sessions
scan_sessions() {
    echo -e "${BLUE}📡 Scan des sessions tmux...${NC}"
    echo "================================"
    
    # Vérifier toutes les sessions tmux
    if tmux ls 2>/dev/null; then
        echo ""
        echo -e "${GREEN}Sessions actives trouvées:${NC}"
        tmux ls | while IFS= read -r line; do
            session=$(echo "$line" | cut -d: -f1)
            if [[ "$session" == "$SESSION_NAME" ]]; then
                echo -e "  ${GREEN}✅${NC} $line ${YELLOW}(Session principale)${NC}"
            elif [[ " ${AGENTS[@]} " =~ " ${session} " ]]; then
                echo -e "  ${YELLOW}⚠️${NC}  $line ${RED}(Session individuelle - à nettoyer)${NC}"
            else
                echo -e "  ${BLUE}●${NC} $line"
            fi
        done
    else
        echo -e "${RED}Aucune session tmux active${NC}"
    fi
    
    echo ""
    # Vérifier les processus Claude
    echo -e "${BLUE}Processus Claude actifs:${NC}"
    ps aux | grep -v grep | grep "claude-desktop --agent" | wc -l | xargs echo "  Nombre d'agents Claude:"
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction pour nettoyer tout
clean_all() {
    echo -e "${RED}🧹 Nettoyage complet en cours...${NC}"
    echo ""
    
    # 1. Tuer la session principale
    echo "• Fermeture de la session principale..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    
    # 2. Tuer les sessions individuelles des agents
    for agent in "${AGENTS[@]}"; do
        echo "• Fermeture de la session $agent..."
        tmux kill-session -t "$agent" 2>/dev/null
    done
    
    # 3. Tuer tous les processus Claude restants
    echo "• Arrêt des processus Claude..."
    pkill -f "claude-desktop --agent" 2>/dev/null
    
    # 4. Nettoyer les autres sessions si nécessaire
    echo ""
    echo -e "${YELLOW}Sessions restantes:${NC}"
    if tmux ls 2>/dev/null; then
        tmux ls
        echo ""
        read -p "Voulez-vous tuer TOUTES les sessions tmux? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-server 2>/dev/null
            echo -e "${GREEN}✅ Toutes les sessions tmux fermées${NC}"
        fi
    else
        echo "Aucune"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Nettoyage terminé!${NC}"
    sleep 2
}

# Fonction pour lancer les agents - VERSION CORRIGÉE
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
    # Panel 0: NESTOR (haut gauche)
    tmux send-keys -t "$SESSION_NAME:agents" 'cd ~/moulinsart/agents/nestor' Enter
    
    # Panel 1: TINTIN (haut droite)
    tmux split-window -h -t "$SESSION_NAME:agents"
    tmux send-keys -t "$SESSION_NAME:agents.1" 'cd ~/moulinsart/agents/tintin' Enter
    
    # Panel 2: DUPONT1 (bas gauche)
    tmux select-pane -t "$SESSION_NAME:agents.0"
    tmux split-window -v -t "$SESSION_NAME:agents"
    tmux send-keys -t "$SESSION_NAME:agents.2" 'cd ~/moulinsart/agents/dupont1' Enter
    
    # Panel 3: DUPONT2 (bas droite)
    tmux select-pane -t "$SESSION_NAME:agents.1"
    tmux split-window -v -t "$SESSION_NAME:agents"
    tmux send-keys -t "$SESSION_NAME:agents.3" 'cd ~/moulinsart/agents/dupont2' Enter
    
    # Équilibrer les panels
    tmux select-layout -t "$SESSION_NAME:agents" tiled
    
    # Configurer les titres
    tmux select-pane -t "$SESSION_NAME:agents.0" -T "🎩 NESTOR"
    tmux select-pane -t "$SESSION_NAME:agents.1" -T "🚀 TINTIN"
    tmux select-pane -t "$SESSION_NAME:agents.2" -T "🎨 DUPONT1"
    tmux select-pane -t "$SESSION_NAME:agents.3" -T "🔍 DUPONT2"
    
    # Configuration visuelle
    tmux set -t "$SESSION_NAME" pane-border-status top
    tmux set -t "$SESSION_NAME" pane-border-format "#{pane_title}"
    
    sleep 1
    
    # PREMIÈRE PHASE: Afficher les bannières
    echo "• Phase 1: Préparation des agents..."
    tmux send-keys -t "$SESSION_NAME:agents.0" "clear && echo '🎩 NESTOR - Chef d\\''Orchestre' && echo '=========================' && echo" Enter
    tmux send-keys -t "$SESSION_NAME:agents.1" "clear && echo '🚀 TINTIN - QA Lead' && echo '=========================' && echo" Enter
    tmux send-keys -t "$SESSION_NAME:agents.2" "clear && echo '🎨 DUPONT1 - Développeur' && echo '=========================' && echo" Enter
    tmux send-keys -t "$SESSION_NAME:agents.3" "clear && echo '🔍 DUPONT2 - Recherche' && echo '=========================' && echo" Enter
    
    sleep 2
    
    # DEUXIÈME PHASE: Lancer bun run index.ts dans chaque panel
    echo "• Phase 2: Lancement des serveurs TypeScript..."
    tmux send-keys -t "$SESSION_NAME:agents.0" "bun run index.ts" Enter
    tmux send-keys -t "$SESSION_NAME:agents.1" "bun run index.ts" Enter
    tmux send-keys -t "$SESSION_NAME:agents.2" "bun run index.ts" Enter
    tmux send-keys -t "$SESSION_NAME:agents.3" "bun run index.ts" Enter
    
    echo ""
    echo -e "${GREEN}✅ Système lancé avec succès!${NC}"
    echo ""
    echo -e "${YELLOW}Les agents sont maintenant en écoute sur leurs ports respectifs.${NC}"
    echo -e "${YELLOW}Ils attendent les emails pour démarrer leurs sessions Claude.${NC}"
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
        sleep 1
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
    # Services
    curl -s http://localhost:3001/health >/dev/null 2>&1 && echo -e "${GREEN}✅ Oracle API: OK${NC}" || echo -e "${RED}❌ Oracle API: DOWN${NC}"
    curl -s http://localhost:1080 >/dev/null 2>&1 && echo -e "${GREEN}✅ Mail Server: OK${NC}" || echo -e "${RED}❌ Mail Server: DOWN${NC}"
    
    # Vérifier les ports des agents
    echo ""
    echo -e "${BLUE}Ports des agents:${NC}"
    lsof -i :3010 >/dev/null 2>&1 && echo -e "  ${GREEN}●${NC} Nestor (3010): OK" || echo -e "  ${RED}●${NC} Nestor (3010): DOWN"
    lsof -i :3011 >/dev/null 2>&1 && echo -e "  ${GREEN}●${NC} Tintin (3011): OK" || echo -e "  ${RED}●${NC} Tintin (3011): DOWN"
    lsof -i :3012 >/dev/null 2>&1 && echo -e "  ${GREEN}●${NC} Dupont1 (3012): OK" || echo -e "  ${RED}●${NC} Dupont1 (3012): DOWN"
    lsof -i :3013 >/dev/null 2>&1 && echo -e "  ${GREEN}●${NC} Dupont2 (3013): OK" || echo -e "  ${RED}●${NC} Dupont2 (3013): DOWN"
    
    echo ""
}

# Fonction pour envoyer un email test
send_test_email() {
    echo -e "${YELLOW}📮 Envoi d'un email test à Nestor...${NC}"
    
    # Créer l'email test
    EMAIL_JSON=$(cat <<EOF
{
  "from": "system@moulinsart.local",
  "to": "nestor@moulinsart.local",
  "subject": "Test Mission - $(date)",
  "body": "Nestor, ceci est un test du système. Veuillez initier une session Claude et dispatcher cette mission aux agents appropriés."
}
EOF
)
    
    # Envoyer via l'API mail
    RESPONSE=$(curl -s -X POST http://localhost:1025/send \
         -H "Content-Type: application/json" \
         -d "$EMAIL_JSON" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Email envoyé avec succès!${NC}"
        echo "Nestor devrait maintenant démarrer sa session Claude."
    else
        echo -e "${RED}❌ Erreur d'envoi (vérifiez le mail server)${NC}"
    fi
    
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Menu principal
show_menu() {
    show_header
    quick_status
    echo -e "${BOLD}OPTIONS:${NC}"
    echo ""
    echo "  1) 🧹 Reset complet et lancer"
    echo "  2) 📎 Attacher/Reprendre session"
    echo "  3) 📡 Scanner toutes les sessions"
    echo "  4) 🚀 Lancer sans reset"
    echo "  5) 🗑️  Nettoyer tout (sans relancer)"
    echo "  6) 📮 Envoyer email test à Nestor"
    echo "  7) 🎮 Contrôle des agents"
    echo "  0) 🚪 Quitter"
    echo ""
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
            scan_sessions
            ;;
        4)
            show_header
            launch_agents
            ;;
        5)
            show_header
            clean_all
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        6)
            show_header
            send_test_email
            ;;
        7)
            # Lancer le script de contrôle s'il existe
            if [ -f "~/moulinsart/control-agents.sh" ]; then
                ~/moulinsart/control-agents.sh
            else
                echo -e "${RED}Script de contrôle non trouvé${NC}"
                sleep 2
            fi
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