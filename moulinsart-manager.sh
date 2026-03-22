#!/bin/bash

# Gestionnaire Principal Moulinsart & Manitoba
# Version corrigee sans options inexistantes

# Fix PATH pour tmux après mise à jour macOS
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Sessions tmux
NESTOR_SESSION="nestor-agents"
HADDOCK_SESSION="haddock-agents"

# Configuration environnement propre
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export PYTHONIOENCODING=utf-8

# Message anti-emoji a envoyer a Claude
CLAUDE_SAFE_PROMPT="REGLE IMPORTANTE: N'utilise JAMAIS d'emojis dans tes reponses ou ton code. Utilise uniquement des caracteres ASCII. Remplace tous les emojis par des tags comme [OK], [ERROR], [WARNING], etc."

# Fonction pour afficher le header
show_header() {
    clear
    echo -e "${CYAN}=========================================================${NC}"
    echo -e "${CYAN}|${NC}  ${YELLOW}${BOLD}GESTIONNAIRE CHÂTEAU DE MOULINSART${NC}              ${CYAN}|${NC}"
    echo -e "${CYAN}=========================================================${NC}"
    echo ""
}

# Fonction pour lancer l'équipe TMUX-Nestor
launch_equipe_nestor() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Nestor...${NC}"
    echo ""
    
    if tmux has-session -t "$NESTOR_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Nestor existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$NESTOR_SESSION"
            sleep 1
        else
            return
        fi
    fi
    
    # Creer la session avec layout 2x2 (largeur max: ~145 cols/panel)
    tmux new-session -d -s "$NESTOR_SESSION" -n agents

    # Layout 2x2 équilibré: Panel 1-2 colonne gauche, 3-4 colonne droite
    tmux split-window -h -t "$NESTOR_SESSION:agents"
    tmux split-window -v -t "$NESTOR_SESSION:agents.1"
    tmux split-window -v -t "$NESTOR_SESSION:agents.3"

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$NESTOR_SESSION:agents.1" -T "NESTOR"
    tmux select-pane -t "$NESTOR_SESSION:agents.2" -T "TINTIN"
    tmux select-pane -t "$NESTOR_SESSION:agents.3" -T "DUPONT1"
    tmux select-pane -t "$NESTOR_SESSION:agents.4" -T "DUPONT2"

    # Configurer et lancer chaque agent
    echo "Configuration de l'équipe TMUX-Nestor (4 agents)..."

    # NESTOR (pane 1)
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "cd ~/moulinsart/agents/nestor" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "claude --dangerously-skip-permissions" Enter

    # TINTIN (pane 2)
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "cd ~/moulinsart/agents/tintin" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "claude --dangerously-skip-permissions" Enter

    # DUPONT1 (pane 3)
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "cd ~/moulinsart/agents/dupont1" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "claude --dangerously-skip-permissions" Enter

    # DUPONT2 (pane 4)
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "cd ~/moulinsart/agents/dupont2" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "claude --dangerously-skip-permissions" Enter

    # Attendre que Claude se lance puis envoyer la regle anti-emoji
    sleep 4
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "$CLAUDE_SAFE_PROMPT" Enter
    
    echo -e "${GREEN}[OK] Équipe TMUX-Nestor lancée avec succès!${NC}"
}

# Fonction pour lancer l'équipe TMUX-Nestor en mode RESUME
launch_equipe_nestor_resume() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Nestor (mode RESUME)...${NC}"
    echo ""

    if tmux has-session -t "$NESTOR_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Nestor existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$NESTOR_SESSION"
            sleep 1
        else
            return
        fi
    fi

    # Creer la session avec layout 2x2 (largeur max: ~145 cols/panel)
    tmux new-session -d -s "$NESTOR_SESSION" -n agents

    # Layout 2x2 équilibré: Panel 1-2 colonne gauche, 3-4 colonne droite
    tmux split-window -h -t "$NESTOR_SESSION:agents"
    tmux split-window -v -t "$NESTOR_SESSION:agents.1"
    tmux split-window -v -t "$NESTOR_SESSION:agents.3"

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$NESTOR_SESSION:agents.1" -T "NESTOR"
    tmux select-pane -t "$NESTOR_SESSION:agents.2" -T "TINTIN"
    tmux select-pane -t "$NESTOR_SESSION:agents.3" -T "DUPONT1"
    tmux select-pane -t "$NESTOR_SESSION:agents.4" -T "DUPONT2"

    # Configurer et lancer chaque agent en mode RESUME
    echo "Configuration de l'équipe TMUX-Nestor (mode RESUME)..."

    # NESTOR (pane 1)
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "cd ~/moulinsart/agents/nestor" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "claude --dangerously-skip-permissions --resume" Enter

    # TINTIN (pane 2)
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "cd ~/moulinsart/agents/tintin" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "claude --dangerously-skip-permissions --resume" Enter

    # DUPONT1 (pane 3)
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "cd ~/moulinsart/agents/dupont1" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "claude --dangerously-skip-permissions --resume" Enter

    # DUPONT2 (pane 4)
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "cd ~/moulinsart/agents/dupont2" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "claude --dangerously-skip-permissions --resume" Enter

    echo -e "${GREEN}[OK] Équipe TMUX-Nestor lancée en mode RESUME avec succès!${NC}"
}

# Fonction pour lancer l'équipe TMUX-Haddock
launch_equipe_haddock() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Haddock...${NC}"
    echo ""
    
    if tmux has-session -t "$HADDOCK_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Haddock existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$HADDOCK_SESSION"
            sleep 1
        else
            return
        fi
    fi
    
    # Creer les dossiers si necessaire
    mkdir -p ~/moulinsart/agents/{haddock,rastapopoulos,tournesol1,tournesol2}
    
    # Creer la session avec layout 2x2 (largeur max: ~145 cols/panel)
    tmux new-session -d -s "$HADDOCK_SESSION" -n agents

    # Layout 2x2 équilibré: Panel 1-2 colonne gauche, 3-4 colonne droite
    tmux split-window -h -t "$HADDOCK_SESSION:agents"
    tmux split-window -v -t "$HADDOCK_SESSION:agents.1"
    tmux split-window -v -t "$HADDOCK_SESSION:agents.3"

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$HADDOCK_SESSION:agents.1" -T "HADDOCK"
    tmux select-pane -t "$HADDOCK_SESSION:agents.2" -T "RASTAPOPOULOS"
    tmux select-pane -t "$HADDOCK_SESSION:agents.3" -T "TOURNESOL1"
    tmux select-pane -t "$HADDOCK_SESSION:agents.4" -T "TOURNESOL2"

    # Configurer et lancer chaque agent
    echo "Configuration de l'équipe TMUX-Haddock..."

    # HADDOCK (pane 1)
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "cd ~/moulinsart/agents/haddock" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "claude --dangerously-skip-permissions" Enter

    # RASTAPOPOULOS (pane 2)
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "cd ~/moulinsart/agents/rastapopoulos" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "claude --dangerously-skip-permissions" Enter

    # TOURNESOL1 (pane 3)
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "cd ~/moulinsart/agents/tournesol1" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "claude --dangerously-skip-permissions" Enter

    # TOURNESOL2 (pane 4)
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "cd ~/moulinsart/agents/tournesol2" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "claude --dangerously-skip-permissions" Enter

    # Attendre que Claude se lance puis envoyer la regle anti-emoji
    sleep 4
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "$CLAUDE_SAFE_PROMPT" Enter

    echo -e "${GREEN}[OK] Équipe TMUX-Haddock lancée avec succès!${NC}"
}

# Fonction pour lancer l'équipe TMUX-Haddock en mode RESUME
launch_equipe_haddock_resume() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Haddock (mode RESUME)...${NC}"
    echo ""

    if tmux has-session -t "$HADDOCK_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Haddock existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$HADDOCK_SESSION"
            sleep 1
        else
            return
        fi
    fi

    # Creer les dossiers si necessaire
    mkdir -p ~/moulinsart/agents/{haddock,rastapopoulos,tournesol1,tournesol2}

    # Creer la session avec layout 2x2 (largeur max: ~145 cols/panel)
    tmux new-session -d -s "$HADDOCK_SESSION" -n agents

    # Layout 2x2 équilibré: Panel 1-2 colonne gauche, 3-4 colonne droite
    tmux split-window -h -t "$HADDOCK_SESSION:agents"
    tmux split-window -v -t "$HADDOCK_SESSION:agents.1"
    tmux split-window -v -t "$HADDOCK_SESSION:agents.3"

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$HADDOCK_SESSION:agents.1" -T "HADDOCK"
    tmux select-pane -t "$HADDOCK_SESSION:agents.2" -T "RASTAPOPOULOS"
    tmux select-pane -t "$HADDOCK_SESSION:agents.3" -T "TOURNESOL1"
    tmux select-pane -t "$HADDOCK_SESSION:agents.4" -T "TOURNESOL2"

    # Configurer et lancer chaque agent en mode RESUME
    echo "Configuration de l'équipe TMUX-Haddock (mode RESUME)..."

    # HADDOCK (pane 1)
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "cd ~/moulinsart/agents/haddock" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "claude --dangerously-skip-permissions --resume" Enter

    # RASTAPOPOULOS (pane 2)
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "cd ~/moulinsart/agents/rastapopoulos" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "claude --dangerously-skip-permissions --resume" Enter

    # TOURNESOL1 (pane 3)
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "cd ~/moulinsart/agents/tournesol1" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "claude --dangerously-skip-permissions --resume" Enter

    # TOURNESOL2 (pane 4)
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "cd ~/moulinsart/agents/tournesol2" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "claude --dangerously-skip-permissions --resume" Enter

    echo -e "${GREEN}[OK] Équipe TMUX-Haddock lancée en mode RESUME avec succès!${NC}"
}

# Fonction pour lancer l'équipe TMUX-Nestor avec 4 agents (layout 4 colonnes horizontales)
launch_equipe_nestor_3col() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Nestor (4 agents - 4 colonnes - RESUME)...${NC}"
    echo ""

    if tmux has-session -t "$NESTOR_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Nestor existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$NESTOR_SESSION"
            sleep 1
        else
            return
        fi
    fi

    # Creer la session avec 4 colonnes (pleine hauteur, ~68 cols/panel)
    tmux new-session -d -s "$NESTOR_SESSION" -n agents

    # Layout 4 colonnes horizontales
    tmux split-window -h -t "$NESTOR_SESSION:agents"
    tmux split-window -h -t "$NESTOR_SESSION:agents"
    tmux split-window -h -t "$NESTOR_SESSION:agents"
    tmux select-layout -t "$NESTOR_SESSION:agents" even-horizontal

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$NESTOR_SESSION:agents.1" -T "NESTOR"
    tmux select-pane -t "$NESTOR_SESSION:agents.2" -T "TINTIN"
    tmux select-pane -t "$NESTOR_SESSION:agents.3" -T "DUPONT1"
    tmux select-pane -t "$NESTOR_SESSION:agents.4" -T "DUPONT2"

    # Configurer et lancer chaque agent
    echo "Configuration de l'équipe TMUX-Nestor (4 agents - 4 colonnes)..."

    # NESTOR (pane 1)
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "cd ~/moulinsart/agents/nestor" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "claude --dangerously-skip-permissions --resume" Enter

    # TINTIN (pane 2)
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "cd ~/moulinsart/agents/tintin" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "claude --dangerously-skip-permissions --resume" Enter

    # DUPONT1 (pane 3)
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "cd ~/moulinsart/agents/dupont1" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "claude --dangerously-skip-permissions --resume" Enter

    # DUPONT2 (pane 4)
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "cd ~/moulinsart/agents/dupont2" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "claude --dangerously-skip-permissions --resume" Enter

    # Attendre que Claude se lance puis envoyer la regle anti-emoji
    sleep 4
    tmux send-keys -t "$NESTOR_SESSION:agents.1" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.2" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.3" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$NESTOR_SESSION:agents.4" "$CLAUDE_SAFE_PROMPT" Enter

    echo -e "${GREEN}[OK] Équipe TMUX-Nestor lancée avec 4 agents (4 colonnes - RESUME)!${NC}"
}

# Fonction pour lancer l'équipe TMUX-Haddock avec 4 agents (layout 4 colonnes horizontales)
launch_equipe_haddock_3col() {
    echo -e "${GREEN}[START] Lancement de l'équipe TMUX-Haddock (4 agents - 4 colonnes - RESUME)...${NC}"
    echo ""

    if tmux has-session -t "$HADDOCK_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] Session équipe TMUX-Haddock existe déjà!${NC}"
        read -p "Voulez-vous la fermer et relancer? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            tmux kill-session -t "$HADDOCK_SESSION"
            sleep 1
        else
            return
        fi
    fi

    # Creer les dossiers si necessaire
    mkdir -p ~/moulinsart/agents/{haddock,rastapopoulos,tournesol1,tournesol2}

    # Creer la session avec 4 colonnes (pleine hauteur, ~68 cols/panel)
    tmux new-session -d -s "$HADDOCK_SESSION" -n agents

    # Layout 4 colonnes horizontales
    tmux split-window -h -t "$HADDOCK_SESSION:agents"
    tmux split-window -h -t "$HADDOCK_SESSION:agents"
    tmux split-window -h -t "$HADDOCK_SESSION:agents"
    tmux select-layout -t "$HADDOCK_SESSION:agents" even-horizontal

    # Configurer les titres des panes (4 agents)
    tmux select-pane -t "$HADDOCK_SESSION:agents.1" -T "HADDOCK"
    tmux select-pane -t "$HADDOCK_SESSION:agents.2" -T "RASTAPOPOULOS"
    tmux select-pane -t "$HADDOCK_SESSION:agents.3" -T "TOURNESOL1"
    tmux select-pane -t "$HADDOCK_SESSION:agents.4" -T "TOURNESOL2"

    # Configurer et lancer chaque agent
    echo "Configuration de l'équipe TMUX-Haddock (4 agents - 4 colonnes)..."

    # HADDOCK (pane 1)
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "cd ~/moulinsart/agents/haddock" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "claude --dangerously-skip-permissions --resume" Enter

    # RASTAPOPOULOS (pane 2)
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "cd ~/moulinsart/agents/rastapopoulos" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "claude --dangerously-skip-permissions --resume" Enter

    # TOURNESOL1 (pane 3)
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "cd ~/moulinsart/agents/tournesol1" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "claude --dangerously-skip-permissions --resume" Enter

    # TOURNESOL2 (pane 4)
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "export LC_ALL=C.UTF-8 && export LANG=C.UTF-8" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "cd ~/moulinsart/agents/tournesol2" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "claude --dangerously-skip-permissions --resume" Enter

    # Attendre que Claude se lance puis envoyer la regle anti-emoji
    sleep 4
    tmux send-keys -t "$HADDOCK_SESSION:agents.1" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.2" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.3" "$CLAUDE_SAFE_PROMPT" Enter
    tmux send-keys -t "$HADDOCK_SESSION:agents.4" "$CLAUDE_SAFE_PROMPT" Enter

    echo -e "${GREEN}[OK] Équipe TMUX-Haddock lancée avec 4 agents (4 colonnes - RESUME)!${NC}"
}

# Fonction pour lancer les deux équipes
launch_both() {
    echo -e "${MAGENTA}[START] Lancement des deux équipes...${NC}"
    echo ""
    launch_equipe_nestor
    echo ""
    launch_equipe_haddock
    echo ""
    echo -e "${GREEN}[OK] Les deux équipes sont opérationnelles!${NC}"
}

# Fonction pour nettoyer tout
clean_all() {
    echo -e "${RED}[CLEAN] Nettoyage complet du systeme...${NC}"
    echo ""
    
    # Tuer les sessions tmux
    echo "- Fermeture des sessions tmux..."
    tmux kill-session -t "$NESTOR_SESSION" 2>/dev/null
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null
    
    # Tuer tous les processus Claude
    echo "- Arret des processus Claude..."
    pkill -f "claude --dangerously-skip-permissions" 2>/dev/null
    
    # Nettoyer le cache Claude
    echo "- Nettoyage du cache..."
    rm -rf /tmp/claude-* 2>/dev/null
    rm -rf ~/.cache/claude/* 2>/dev/null
    
    # Attendre un peu
    sleep 2
    
    echo -e "${GREEN}[OK] Nettoyage termine!${NC}"
}

# Fonction pour attacher a une session
attach_session() {
    echo -e "${CYAN}Quelle session voulez-vous attacher?${NC}"
    echo "  1) Équipe TMUX-Nestor"
    echo "  2) Équipe TMUX-Haddock"
    echo ""
    read -p "Votre choix: " choice

    case $choice in
        1)
            if tmux has-session -t "$NESTOR_SESSION" 2>/dev/null; then
                echo -e "${GREEN}Attachement à l'équipe TMUX-Nestor...${NC}"
                sleep 1
                tmux attach -t "$NESTOR_SESSION"
            else
                echo -e "${RED}[ERROR] Session équipe TMUX-Nestor non active${NC}"
                sleep 2
            fi
            ;;
        2)
            if tmux has-session -t "$HADDOCK_SESSION" 2>/dev/null; then
                echo -e "${GREEN}Attachement à l'équipe TMUX-Haddock...${NC}"
                sleep 1
                tmux attach -t "$HADDOCK_SESSION"
            else
                echo -e "${RED}[ERROR] Session équipe TMUX-Haddock non active${NC}"
                sleep 2
            fi
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            sleep 1
            ;;
    esac
}

# Fonction pour le status
quick_status() {
    echo -e "${CYAN}=== ETAT DU SYSTEME ===${NC}"
    echo ""
    
    # Équipe TMUX-Nestor
    if tmux has-session -t "$NESTOR_SESSION" 2>/dev/null; then
        echo -e "${GREEN}[ACTIF] Équipe TMUX-Nestor${NC}"
        echo "        Agents: Nestor, Tintin, Dupont1, Dupont2"
    else
        echo -e "${RED}[INACTIF] Équipe TMUX-Nestor${NC}"
    fi
    
    # Équipe TMUX-Haddock
    if tmux has-session -t "$HADDOCK_SESSION" 2>/dev/null; then
        echo -e "${GREEN}[ACTIF] Équipe TMUX-Haddock${NC}"
        echo "        Agents: Haddock, Rastapopoulos, Tournesol1, Tournesol2"
    else
        echo -e "${RED}[INACTIF] Équipe TMUX-Haddock${NC}"
    fi
    
    echo ""
    # Processus Claude
    CLAUDE_COUNT=$(ps aux | grep -v grep | grep "claude --dangerously" | wc -l | tr -d ' ')
    if [ "$CLAUDE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}[INFO] $CLAUDE_COUNT processus Claude actifs${NC}"
    else
        echo -e "${YELLOW}[INFO] Aucun processus Claude actif${NC}"
    fi
    echo ""
}

# Fonction pour redemarrer les services - VERSION BRUTALE
restart_services() {
    echo -e "${RED}[BRUTAL] Massacre complet de tous les ports...${NC}"
    echo ""

    # Path vers Bun
    BUN_PATH="~/.bun/bin/bun"

    # MASSACRE TOTAL - tous les ports potentiels
    echo "- MASSACRE: Tous les processus Bun/Node/Vite..."
    pkill -9 -f "bun" 2>/dev/null
    pkill -9 -f "node" 2>/dev/null
    pkill -9 -f "vite" 2>/dev/null
    pkill -9 -f "server/index.ts" 2>/dev/null
    pkill -9 -f "mail-server" 2>/dev/null

    # MASSACRE BRUTAL: Tous les ports utilisés par Moulinsart
    echo "- MASSACRE: Libération brutale des ports 3001, 1025, 1080, 5175..."
    lsof -ti:3001 | xargs kill -9 2>/dev/null
    lsof -ti:1025 | xargs kill -9 2>/dev/null
    lsof -ti:1080 | xargs kill -9 2>/dev/null
    lsof -ti:5175 | xargs kill -9 2>/dev/null

    # Attendre que tout crève
    sleep 5

    echo -e "${GREEN}[BRUTAL] Massacre terminé! Redémarrage propre...${NC}"
    echo ""

    # Oracle Observability - TOUJOURS sur port 3001
    if [ -d "~/moulinsart/oracle-observability" ]; then
        echo "- DEMARRAGE BRUTAL: Oracle sur port 3001..."
        cd ~/moulinsart/oracle-observability
        nohup "$BUN_PATH" run server/index.ts > /tmp/oracle.log 2>&1 &
        sleep 2
        echo "  Oracle démarre (logs: /tmp/oracle.log)"
    else
        echo -e "${RED}  [ERROR] Dossier oracle-observability introuvable${NC}"
    fi

    # Mail Server - TOUJOURS sur ports 1025/1080
    if [ -f "~/moulinsart/oracle-observability/server/mail-server.ts" ]; then
        echo "- DEMARRAGE BRUTAL: Mail Server sur ports 1025/1080..."
        cd ~/moulinsart/oracle-observability
        nohup "$BUN_PATH" run server/mail-server.ts > /tmp/mail.log 2>&1 &
        sleep 2
        echo "  Mail Server démarre (logs: /tmp/mail.log)"
    else
        echo -e "${RED}  [ERROR] Mail server introuvable${NC}"
    fi

    # Client Web - TOUJOURS sur port 5175
    if [ -d "~/moulinsart/oracle-observability/client" ]; then
        echo "- DEMARRAGE BRUTAL: Client Web sur port 5175..."
        cd ~/moulinsart/oracle-observability/client
        nohup "$BUN_PATH" run dev > /tmp/web.log 2>&1 &
        sleep 2
        echo "  Client Web démarre (logs: /tmp/web.log)"
    else
        echo -e "${RED}  [ERROR] Dossier client introuvable${NC}"
    fi

    # Vérification brutale des ports
    echo ""
    echo -e "${CYAN}[CHECK] Vérification des ports après redémarrage brutal:${NC}"
    echo "  Port 3001 (Oracle): $(lsof -ti:3001 >/dev/null && echo "ACTIF" || echo "LIBRE")"
    echo "  Port 1025 (SMTP): $(lsof -ti:1025 >/dev/null && echo "ACTIF" || echo "LIBRE")"
    echo "  Port 1080 (Mail): $(lsof -ti:1080 >/dev/null && echo "ACTIF" || echo "LIBRE")"
    echo "  Port 5175 (Web): $(lsof -ti:5175 >/dev/null && echo "ACTIF" || echo "LIBRE")"

    sleep 3
    echo ""
    echo -e "${GREEN}[BRUTAL OK] Services redémarrés en mode BRUTAL!${NC}"
    echo ""
    echo "  Accès aux services:"
    echo "  - Oracle: http://localhost:3001"
    echo "  - Mail: http://localhost:1080"
    echo "  - Dashboard: http://localhost:5175"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction de backup complet Moulinsart
backup_moulinsart() {
    echo -e "${CYAN}[BACKUP] Sauvegarde complète de Moulinsart...${NC}"
    echo ""

    # Générer timestamp pour le nom du backup
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_NAME="moulinsart_backup_${TIMESTAMP}"
    BACKUP_DIR="~/backups"

    echo -e "${YELLOW}[WARNING] Cette opération va arrêter TOUS les services!${NC}"
    echo "Backup sera créé dans: ${BACKUP_DIR}/${BACKUP_NAME}.zip"
    echo ""
    read -p "Continuer? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Backup annulé."
        return
    fi

    # 1. CHECKPOINT WAL CRITIQUE (avant arrêt)
    echo -e "${YELLOW}[CHECKPOINT] Flush de la base SQLite WAL...${NC}"
    DB_PATH="~/moulinsart/oracle-observability/data/oracle.db"

    if [ -f "$DB_PATH" ]; then
        echo "- Exécution checkpoint FULL..."
        sqlite3 "$DB_PATH" "PRAGMA wal_checkpoint(FULL);" 2>/dev/null

        # Vérifier que le checkpoint a réussi
        WAL_SIZE=$(ls -la "${DB_PATH}-wal" 2>/dev/null | awk '{print $5}' || echo "0")
        if [ "$WAL_SIZE" = "0" ] || [ ! -f "${DB_PATH}-wal" ]; then
            echo -e "${GREEN}✅ Checkpoint réussi - WAL vidé${NC}"
        else
            echo -e "${YELLOW}⚠️ WAL encore présent (${WAL_SIZE} bytes) - continuant quand même${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Base oracle.db introuvable - continuant${NC}"
    fi
    echo ""

    # 2. ARRÊT TOTAL DE TOUS LES SERVICES
    echo -e "${RED}[STOP] Arrêt brutal de tous les services...${NC}"

    # Sessions TMUX
    echo "- Fermeture sessions TMUX..."
    tmux kill-session -t "$NESTOR_SESSION" 2>/dev/null
    tmux kill-session -t "$HADDOCK_SESSION" 2>/dev/null

    # Processus Claude
    echo "- Arrêt processus Claude..."
    pkill -9 -f "claude --dangerously-skip-permissions" 2>/dev/null

    # Services Moulinsart (BRUTAL)
    echo "- Massacre services Moulinsart..."
    pkill -9 -f "bun" 2>/dev/null
    pkill -9 -f "node" 2>/dev/null
    pkill -9 -f "vite" 2>/dev/null

    # Libération ports
    echo "- Libération ports..."
    lsof -ti:3001 | xargs kill -9 2>/dev/null
    lsof -ti:1025 | xargs kill -9 2>/dev/null
    lsof -ti:1080 | xargs kill -9 2>/dev/null
    lsof -ti:5175 | xargs kill -9 2>/dev/null

    # Attendre que tout s'arrête
    sleep 5
    echo -e "${GREEN}[OK] Tous les services arrêtés!${NC}"
    echo ""

    # 3. CRÉATION DU BACKUP
    echo -e "${BLUE}[BACKUP] Création de l'archive...${NC}"

    # Créer le dossier backup si nécessaire
    mkdir -p "$BACKUP_DIR"

    # Aller dans le dossier parent de moulinsart
    cd ~

    # Créer l'archive ZIP complète
    echo "- Compression en cours..."
    zip -r "${BACKUP_DIR}/${BACKUP_NAME}.zip" moulinsart/ \
        --exclude="moulinsart/.DS_Store" \
        --exclude="moulinsart/*/node_modules/*" \
        --exclude="moulinsart/*/.git/*" \
        --exclude="moulinsart/*/dist/*" \
        --exclude="moulinsart/*/build/*" \
        2>/dev/null

    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.zip" | cut -f1)

    echo ""
    echo -e "${GREEN}[SUCCESS] Backup créé avec succès!${NC}"
    echo ""
    echo "📁 Fichier: ${BACKUP_DIR}/${BACKUP_NAME}.zip"
    echo "📊 Taille: $BACKUP_SIZE"
    echo "🕐 Date: $(date)"
    echo ""

    # 4. PROPOSER DE REDÉMARRER LES SERVICES
    echo -e "${YELLOW}[RESTART] Voulez-vous redémarrer les services maintenant?${NC}"
    read -p "(o/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        echo ""
        restart_services
    else
        echo -e "${YELLOW}Services arrêtés. Utilisez l'option 6 pour les redémarrer.${NC}"
        sleep 2
    fi
}

# Fonction principale : Lancer les deux équipes + attacher dans 2 terminaux
launch_both_teams_and_attach() {
    echo -e "${MAGENTA}[DÉMARRAGE RAPIDE] Lancement complet des deux équipes${NC}"
    echo ""

    # 1. NETTOYAGE PRÉALABLE
    echo -e "${RED}[1/4] Nettoyage des sessions existantes...${NC}"

    # Tuer les sessions tmux
    tmux kill-session -t "$NESTOR_SESSION" 2>/dev/null
    tmux kill-session -t "$HADDOCK_SESSION" 2>/dev/null

    # Tuer tous les processus Claude
    pkill -f "claude --dangerously-skip-permissions" 2>/dev/null

    # Nettoyer le cache Claude
    rm -rf /tmp/claude-* 2>/dev/null
    rm -rf ~/.cache/claude/* 2>/dev/null

    sleep 2
    echo "✅ Nettoyage terminé"

    # 2. LANCEMENT ÉQUIPE NESTOR
    echo -e "${GREEN}[2/4] Lancement équipe TMUX-Nestor...${NC}"
    launch_equipe_nestor
    echo "✅ Équipe Nestor prête"

    # 3. LANCEMENT ÉQUIPE HADDOCK
    echo -e "${GREEN}[3/4] Lancement équipe TMUX-Haddock...${NC}"
    launch_equipe_haddock
    echo "✅ Équipe Haddock prête"

    # 4. ATTACHEMENT DANS 2 TERMINAUX SÉPARÉS
    echo -e "${CYAN}[4/4] Ouverture de 2 terminaux avec attachement...${NC}"

    # Détecter le type de terminal
    if command -v osascript >/dev/null 2>&1; then
        # macOS - Utiliser Terminal.app
        echo "Ouverture de 2 fenêtres Terminal..."

        # Terminal 1 - Équipe Nestor
        osascript -e "tell application \"Terminal\" to do script \"tmux attach -t $NESTOR_SESSION\""

        # Terminal 2 - Équipe Haddock
        osascript -e "tell application \"Terminal\" to do script \"tmux attach -t $HADDOCK_SESSION\""

        echo "✅ 2 terminaux ouverts avec attachement automatique"

    elif command -v gnome-terminal >/dev/null 2>&1; then
        # Linux GNOME
        gnome-terminal -- tmux attach -t "$NESTOR_SESSION" &
        gnome-terminal -- tmux attach -t "$HADDOCK_SESSION" &
        echo "✅ 2 terminaux GNOME ouverts"

    else
        # Fallback - Instructions manuelles
        echo -e "${YELLOW}⚠️ Ouverture automatique non supportée${NC}"
        echo ""
        echo "Ouvrez manuellement 2 terminaux et exécutez :"
        echo "  Terminal 1: tmux attach -t $NESTOR_SESSION"
        echo "  Terminal 2: tmux attach -t $HADDOCK_SESSION"
    fi

    echo ""
    echo -e "${GREEN}[SUCCESS] Démarrage rapide terminé!${NC}"
    echo ""
    echo "🎯 Équipe Nestor : Nestor, Tintin, Dupont1, Dupont2"
    echo "🎯 Équipe Haddock : Haddock, Rastapopoulos, Tournesol1, Tournesol2"
    echo ""
    echo "Les agents sont prêts et disponibles dans leurs terminaux respectifs."
    echo ""
    read -p "Appuyez sur Entrée pour revenir au menu..."
}

# Fonction backup + redémarrage automatique (tout-en-un)
backup_and_restart() {
    echo -e "${MAGENTA}[BACKUP+RESTART] Sauvegarde complète + Redémarrage automatique${NC}"
    echo ""

    # Générer timestamp pour le nom du backup
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_NAME="moulinsart_backup_${TIMESTAMP}"
    BACKUP_DIR="~/backups"

    echo -e "${CYAN}Mode automatique : STOP → CHECKPOINT → ZIP → RESTART${NC}"
    echo "Backup sera créé dans: ${BACKUP_DIR}/${BACKUP_NAME}.zip"
    echo ""
    read -p "Lancer le processus complet? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Processus annulé."
        return
    fi

    # 1. CHECKPOINT WAL CRITIQUE
    echo -e "${YELLOW}[1/4] CHECKPOINT WAL...${NC}"
    DB_PATH="~/moulinsart/oracle-observability/data/oracle.db"

    if [ -f "$DB_PATH" ]; then
        sqlite3 "$DB_PATH" "PRAGMA wal_checkpoint(FULL);" 2>/dev/null
        WAL_SIZE=$(ls -la "${DB_PATH}-wal" 2>/dev/null | awk '{print $5}' || echo "0")
        if [ "$WAL_SIZE" = "0" ] || [ ! -f "${DB_PATH}-wal" ]; then
            echo "✅ Checkpoint réussi"
        else
            echo "⚠️ WAL encore présent (continuant)"
        fi
    fi

    # 2. ARRÊT BRUTAL
    echo -e "${YELLOW}[2/4] ARRÊT SERVICES...${NC}"
    tmux kill-session -t "$NESTOR_SESSION" 2>/dev/null
    tmux kill-session -t "$HADDOCK_SESSION" 2>/dev/null
    pkill -9 -f "claude --dangerously-skip-permissions" 2>/dev/null
    pkill -9 -f "bun" 2>/dev/null
    pkill -9 -f "node" 2>/dev/null
    pkill -9 -f "vite" 2>/dev/null
    lsof -ti:3001 | xargs kill -9 2>/dev/null
    lsof -ti:1025 | xargs kill -9 2>/dev/null
    lsof -ti:1080 | xargs kill -9 2>/dev/null
    lsof -ti:5175 | xargs kill -9 2>/dev/null
    sleep 3
    echo "✅ Services arrêtés"

    # 3. CRÉATION BACKUP
    echo -e "${YELLOW}[3/4] CRÉATION ZIP...${NC}"
    mkdir -p "$BACKUP_DIR"
    cd ~
    zip -r "${BACKUP_DIR}/${BACKUP_NAME}.zip" moulinsart/ \
        --exclude="moulinsart/.DS_Store" \
        --exclude="moulinsart/*/node_modules/*" \
        --exclude="moulinsart/*/.git/*" \
        --exclude="moulinsart/*/dist/*" \
        --exclude="moulinsart/*/build/*" \
        -q
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.zip" | cut -f1)
    echo "✅ Backup créé ($BACKUP_SIZE)"

    # 4. REDÉMARRAGE AUTOMATIQUE
    echo -e "${YELLOW}[4/4] REDÉMARRAGE...${NC}"
    cd ~/moulinsart/oracle-observability

    # Path vers Bun
    BUN_PATH="~/.bun/bin/bun"

    # Oracle
    nohup "$BUN_PATH" run server/index.ts > /tmp/oracle.log 2>&1 &
    sleep 2

    # Mail Server
    nohup "$BUN_PATH" run server/mail-server.ts > /tmp/mail.log 2>&1 &
    sleep 2

    # Client Web
    cd client
    nohup "$BUN_PATH" run dev > /tmp/web.log 2>&1 &
    sleep 2

    echo "✅ Services redémarrés"
    echo ""
    echo -e "${GREEN}[SUCCESS] Processus complet terminé!${NC}"
    echo ""
    echo "📁 Backup: ${BACKUP_DIR}/${BACKUP_NAME}.zip ($BACKUP_SIZE)"
    echo "🚀 Services: Oracle (3001), Mail (1025/1080), Web (5175)"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

# Fonction de fix d'urgence
emergency_fix() {
    echo -e "${RED}[FIX] Application du fix d'urgence...${NC}"
    echo ""

    echo "1. Arret complet de tous les processus..."
    tmux kill-server 2>/dev/null
    pkill -f claude 2>/dev/null

    echo "2. Nettoyage de l'environnement..."
    unset LANG
    unset LC_ALL
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8

    echo "3. Suppression des caches..."
    rm -rf ~/.cache/claude/* 2>/dev/null
    rm -rf /tmp/claude-* 2>/dev/null

    echo "4. Reset des configurations..."
    for agent in nestor tintin dupont1 dupont2 haddock rastapopoulos tournesol1 tournesol2; do
        rm -f ~/moulinsart/agents/$agent/.claude-config 2>/dev/null
        rm -f ~/moulinsart/agents/$agent/.clauderr 2>/dev/null
    done

    echo ""
    echo -e "${GREEN}[OK] Fix applique avec succes!${NC}"
    echo -e "${YELLOW}Vous pouvez maintenant relancer les agents.${NC}"
    sleep 3
}

# Menu principal
show_menu() {
    show_header
    quick_status
    echo -e "${BOLD}OPTIONS DISPONIBLES:${NC}"
    echo ""
    echo "  ${BOLD}--- DÉMARRAGE RAPIDE ---${NC}"
    echo "  0) 🚀 LANCER LES DEUX ÉQUIPES + Attacher (2 terminaux)"
    echo ""
    echo "  ${BOLD}--- GESTION DES AGENTS ---${NC}"
    echo "  1) Lancer Équipe TMUX-Nestor (4 agents - layout 2x2)"
    echo "  2) Lancer Équipe TMUX-Haddock (4 agents - layout 2x2)"
    echo "  10) 🔄 Lancer Équipe TMUX-Nestor (4 agents - layout 2x2 - RESUME)"
    echo "  11) 🔄 Lancer Équipe TMUX-Haddock (4 agents - layout 2x2 - RESUME)"
    echo "  12) 📏 Lancer Équipe TMUX-Nestor (4 agents - 4 colonnes - RESUME)"
    echo "  13) 📏 Lancer Équipe TMUX-Haddock (4 agents - 4 colonnes - RESUME)"
    echo "  3) Attacher a une session existante"
    echo "  4) Nettoyer tout (fermer sessions et processus)"
    echo ""
    echo "  ${BOLD}--- SERVICES ---${NC}"
    echo "  5) Redemarrer les services (Oracle, Mail, Web)"
    echo "  6) Backup complet Moulinsart (arrêt + ZIP)"
    echo "  7) Backup + Redemarrage automatique (tout-en-un)"
    echo "  8) [URGENCE] Fix erreurs API/Emojis"
    echo ""
    echo "  9) Quitter"
    echo ""
}

# Programme principal
while true; do
    show_menu
    read -p "Votre choix [0-13]: " choice
    
    case $choice in
        0)
            show_header
            launch_both_teams_and_attach
            ;;
        1)
            show_header
            launch_equipe_nestor
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$NESTOR_SESSION"
            fi
            ;;
        2)
            show_header
            launch_equipe_haddock
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$HADDOCK_SESSION"
            fi
            ;;
        10)
            show_header
            launch_equipe_nestor_resume
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$NESTOR_SESSION"
            fi
            ;;
        11)
            show_header
            launch_equipe_haddock_resume
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$HADDOCK_SESSION"
            fi
            ;;
        12)
            show_header
            launch_equipe_nestor_3col
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$NESTOR_SESSION"
            fi
            ;;
        13)
            show_header
            launch_equipe_haddock_3col
            echo ""
            read -p "Voulez-vous attacher a la session? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                tmux attach -t "$HADDOCK_SESSION"
            fi
            ;;
        3)
            show_header
            attach_session
            ;;
        4)
            show_header
            clean_all
            echo ""
            read -p "Appuyez sur Entree pour continuer..."
            ;;
        5)
            show_header
            restart_services
            ;;
        6)
            show_header
            backup_moulinsart
            ;;
        7)
            show_header
            backup_and_restart
            ;;
        8)
            show_header
            emergency_fix
            echo ""
            read -p "Appuyez sur Entree pour continuer..."
            ;;
        9)
            echo ""
            echo -e "${GREEN}Fermeture du gestionnaire. Au revoir!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide. Veuillez choisir entre 0 et 13.${NC}"
            sleep 2
            ;;
    esac
done
