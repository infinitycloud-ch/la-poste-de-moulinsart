#!/bin/bash

# 🎮 Gestionnaire Manitoba - Projet Séparé
# Session tmux indépendante avec nouveaux agents

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration Manitoba
SESSION_NAME="manitoba-agents"
PROJECT_NAME="manitoba"
AGENTS=("haddock" "rastapopoulos" "tournesol1" "tournesol2")

# Fonction pour afficher le header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}${BOLD}🌾 GESTIONNAIRE MANITOBA${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction pour nettoyer tout
clean_all() {
    echo -e "${RED}🧹 Nettoyage complet Manitoba...${NC}"
    echo ""
    
    # 1. Tuer la session Manitoba
    echo "• Fermeture de la session Manitoba..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    
    # 2. Tuer tous les processus Claude du projet
    echo "• Arrêt des processus Claude Manitoba..."
    # Rechercher spécifiquement les Claude dans les dossiers Manitoba
    pkill -f "claude.*manitoba" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✅ Nettoyage Manitoba terminé!${NC}"
    sleep 2
}

# Fonction pour créer les dossiers agents
create_agent_directories() {
    echo "• Création des dossiers agents Manitoba..."
    
    MANITOBA_BASE="~/moulinsart/manitoba-agents"
    mkdir -p "$MANITOBA_BASE"
    
    for agent in "${AGENTS[@]}"; do
        mkdir -p "$MANITOBA_BASE/$agent"
        echo "  ✓ Dossier $agent créé"
    done
}

# Fonction pour lancer les agents Manitoba
launch_agents() {
    echo -e "${GREEN}🚀 Lancement du système Manitoba...${NC}"
    echo ""
    
    # Vérifier si la session existe déjà
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  La session Manitoba existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$SESSION_NAME"
        else
            echo "Annulation..."
            return
        fi
    fi
    
    # Créer les dossiers si nécessaire
    create_agent_directories
    
    # Créer la session avec 4 panels
    echo "• Création de la session tmux Manitoba..."
    tmux new-session -d -s "$SESSION_NAME" -n agents
    
    # Forcer base-index à 0 pour cette session
    tmux set -t "$SESSION_NAME" base-index 0
    tmux set -t "$SESSION_NAME" pane-base-index 0
    
    echo "• Division en 4 panels..."
    # Créer le layout 2x2 avec tailles parfaitement équilibrées
    tmux split-window -h -t "$SESSION_NAME:agents" -p 50
    tmux split-window -v -t "$SESSION_NAME:agents.0" -p 50
    tmux split-window -v -t "$SESSION_NAME:agents.1" -p 50
    
    # Forcer l'équilibrage parfait après création
    tmux select-layout -t "$SESSION_NAME:agents" tiled
    
    # Naviguer dans les répertoires Manitoba
    MANITOBA_BASE="~/moulinsart/manitoba-agents"
    
    # Panel 0: HADDOCK (haut gauche)
    tmux send-keys -t "$SESSION_NAME:agents.0" "cd $MANITOBA_BASE/haddock" Enter
    
    # Panel 1: RASTAPOPOULOS (bas gauche) 
    tmux send-keys -t "$SESSION_NAME:agents.1" "cd $MANITOBA_BASE/rastapopoulos" Enter
    
    # Panel 2: TOURNESOL1 (haut droite)
    tmux send-keys -t "$SESSION_NAME:agents.2" "cd $MANITOBA_BASE/tournesol1" Enter
    
    # Panel 3: TOURNESOL2 (bas droite)
    tmux send-keys -t "$SESSION_NAME:agents.3" "cd $MANITOBA_BASE/tournesol2" Enter
    
    # Configuration visuelle avec couleurs Manitoba
    tmux set -t "$SESSION_NAME" pane-border-status top
    tmux set -t "$SESSION_NAME" pane-border-format "#[fg=white,bg=red,bold] #{pane_title} #[default]"
    tmux set -t "$SESSION_NAME" pane-active-border-style "fg=orange,bg=default"
    tmux set -t "$SESSION_NAME" pane-border-style "fg=white,bg=default"
    
    # Configurer les titres avec couleurs
    tmux select-pane -t "$SESSION_NAME:agents.0" -T "⚓ HADDOCK"
    tmux select-pane -t "$SESSION_NAME:agents.1" -T "🧔 RASTAPOPOULOS" 
    tmux select-pane -t "$SESSION_NAME:agents.2" -T "🧪 TOURNESOL1"
    tmux select-pane -t "$SESSION_NAME:agents.3" -T "🔬 TOURNESOL2"
    
    # Couleurs de fond distinctes pour Manitoba
    tmux select-pane -t "$SESSION_NAME:agents.0" -P 'bg=#2e1a1a'
    tmux select-pane -t "$SESSION_NAME:agents.1" -P 'bg=#1e0f0f'
    tmux select-pane -t "$SESSION_NAME:agents.2" -P 'bg=#2e1a2e'
    tmux select-pane -t "$SESSION_NAME:agents.3" -P 'bg=#1a2e1a'
    
    # Équilibrer les panels en grille 2x2 parfaite
    tmux select-layout -t "$SESSION_NAME:agents" tiled
    
    sleep 1
    
    # Afficher les bannières colorées spécifiques Manitoba
    echo "• Lancement de Claude dans chaque panel Manitoba..."
    
    # HADDOCK - Bannière rouge marine
    tmux send-keys -t "$SESSION_NAME:agents.0" "clear && echo -e '\\033[1;31m'
    echo '╔════════════════════════════════════════╗'
    echo '║       ⚓ HADDOCK - Chef Manitoba        ║'
    echo '║         haddock@manitoba.local         ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # RASTAPOPOULOS - Bannière noire
    tmux send-keys -t "$SESSION_NAME:agents.1" "clear && echo -e '\\033[1;37m'
    echo '╔════════════════════════════════════════╗'
    echo '║    🧔 RASTAPOPOULOS - QA Manitoba      ║'
    echo '║       rastapopoulos@manitoba.local     ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # TOURNESOL1 - Bannière jaune
    tmux send-keys -t "$SESSION_NAME:agents.2" "clear && echo -e '\\033[1;33m'
    echo '╔════════════════════════════════════════╗'
    echo '║      🧪 TOURNESOL1 - Développeur       ║'
    echo '║        tournesol1@manitoba.local       ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    # TOURNESOL2 - Bannière verte
    tmux send-keys -t "$SESSION_NAME:agents.3" "clear && echo -e '\\033[1;32m'
    echo '╔════════════════════════════════════════╗'
    echo '║      🔬 TOURNESOL2 - Recherche         ║'
    echo '║        tournesol2@manitoba.local       ║'
    echo '╚════════════════════════════════════════╝'
    echo -e '\\033[0m'" Enter
    
    sleep 2
    
    # Lancer Claude dans chaque panel
    tmux send-keys -t "$SESSION_NAME:agents.0" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.1" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.2" "claude --dangerously-skip-permissions" Enter
    tmux send-keys -t "$SESSION_NAME:agents.3" "claude --dangerously-skip-permissions" Enter
    
    echo ""
    echo -e "${GREEN}✅ Système Manitoba lancé avec succès!${NC}"
    echo ""
    
    read -p "Voulez-vous attacher à la session Manitoba maintenant? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        tmux attach -t "$SESSION_NAME"
    fi
}

# Fonction pour attacher à la session
attach_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}📎 Attachement à la session Manitoba...${NC}"
        echo ""
        echo -e "${CYAN}💡 Raccourcis tmux utiles:${NC}"
        echo "   • Ctrl+B puis flèches : naviguer entre panels"
        echo "   • Ctrl+B puis Z : zoom/dézoom sur un panel"
        echo "   • Ctrl+B puis D : détacher la session"
        echo ""
        sleep 2
        tmux attach -t "$SESSION_NAME"
    else
        echo -e "${RED}❌ Aucune session Manitoba active trouvée${NC}"
        echo ""
        read -p "Voulez-vous lancer le système Manitoba? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            launch_agents
        fi
    fi
}

# Fonction pour reprendre Claude avec --resume
resume_claude_in_agents() {
    echo -e "${YELLOW}🔄 Reprise de Claude Manitoba avec --resume...${NC}"
    echo ""
    
    # Vérifier si la session existe
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}❌ Aucune session Manitoba active trouvée${NC}"
        echo ""
        read -p "Voulez-vous lancer le système? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            launch_agents
        fi
        return
    fi
    
    echo "• Arrêt de Claude dans chaque panel Manitoba..."
    # Arrêter Claude proprement dans chaque panel (Ctrl+C)
    for i in 0 1 2 3; do
        tmux send-keys -t "$SESSION_NAME:agents.$i" C-c
    done
    sleep 2
    
    echo "• Relance avec --resume..."
    # Relancer avec --resume dans chaque panel
    tmux send-keys -t "$SESSION_NAME:agents.0" "claude --dangerously-skip-permissions --resume" Enter
    tmux send-keys -t "$SESSION_NAME:agents.1" "claude --dangerously-skip-permissions --resume" Enter
    tmux send-keys -t "$SESSION_NAME:agents.2" "claude --dangerously-skip-permissions --resume" Enter
    tmux send-keys -t "$SESSION_NAME:agents.3" "claude --dangerously-skip-permissions --resume" Enter
    
    echo ""
    echo -e "${GREEN}✅ Claude Manitoba relancé avec --resume!${NC}"
    echo ""
    
    read -p "Voulez-vous attacher à la session? (o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        tmux attach -t "$SESSION_NAME"
    fi
}

# Fonction pour le status rapide
quick_status() {
    echo -e "${CYAN}📊 STATUS MANITOBA${NC}"
    echo "==================="
    
    # Session Manitoba
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ Session Manitoba: Active${NC}"
        
        # Vérifier chaque panel
        for i in 0 1 2 3; do
            case $i in
                0) agent="Haddock";;
                1) agent="Rastapopoulos";;
                2) agent="Tournesol1";;
                3) agent="Tournesol2";;
            esac
            
            if tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_index}" | grep -q "^$i$"; then
                echo -e "  ${GREEN}●${NC} $agent: OK"
            else
                echo -e "  ${RED}●${NC} $agent: Manquant"
            fi
        done
    else
        echo -e "${RED}❌ Session Manitoba: Inactive${NC}"
    fi
    
    echo ""
}

# Menu principal
show_menu() {
    show_header
    quick_status
    echo -e "${BOLD}OPTIONS MANITOBA:${NC}"
    echo ""
    echo "  1) 🧹 Reset complet et lancer Manitoba"
    echo "  2) 📎 Attacher/Reprendre session Manitoba"
    echo "  3) 🚀 Lancer Manitoba sans reset"
    echo "  4) 🗑️  Nettoyer Manitoba (sans relancer)"
    echo "  9) 🔄 Resume Claude (garde le contexte)"
    echo ""
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
            launch_agents
            ;;
        4)
            show_header
            clean_all
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        9)
            show_header
            resume_claude_in_agents
            ;;
        0)
            echo -e "${GREEN}Au revoir Manitoba!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            sleep 1
            ;;
    esac
done