#!/bin/bash

# 🚨 TRIGGER INACTIVITÉ HADDOCK - Système de réveil automatique avec Screenshots
# Se déclenche si TOUS les agents sont inactifs pendant 10 secondes
# ACTIVATION: Créer fichier /tmp/tmux-monitor-haddock-active pour activer

LOG_FILE="/tmp/inactivity-trigger-haddock.log"
SESSION="tmux-haddock"
AGENT_GENERAL="haddock"
INACTIVITY_THRESHOLD=10  # 10 secondes
ACTIVATION_FILE="/tmp/tmux-monitor-haddock-active"
SCREENSHOT_DIR="/tmp/tmux-screenshots-haddock"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Créer dossier screenshots
mkdir -p "$SCREENSHOT_DIR"

echo -e "${MAGENTA}🚨 TRIGGER INACTIVITÉ HADDOCK avec Screenshots - Agent Général $(date)${NC}" | tee -a $LOG_FILE
echo -e "${CYAN}⏰ Déclenchement si inactivité totale > ${INACTIVITY_THRESHOLD}s${NC}" | tee -a $LOG_FILE
echo -e "${YELLOW}🔧 ACTIVATION: touch $ACTIVATION_FILE${NC}" | tee -a $LOG_FILE

# Fonction pour obtenir la dernière activité d'un agent TMUX
get_last_activity() {
    local agent_pane=$1

    # Obtenir le timestamp de la dernière activité du pane
    tmux display-message -t "$SESSION:agents.$agent_pane" -p '#{pane_activity}' 2>/dev/null || echo "0"
}

# Fonction pour vérifier l'inactivité totale
check_total_inactivity() {
    local current_time=$(date +%s)
    local all_inactive=true

    echo -e "${YELLOW}🔍 Vérification activité équipe...${NC}" | tee -a $LOG_FILE

    # Vérifier chaque agent (panes 0,1,2,3 = haddock, rastapopoulos, tournesol1, tournesol2)
    for pane in 0 1 2 3; do
        local agent_names=("haddock" "rastapopoulos" "tournesol1" "tournesol2")
        local agent_name=${agent_names[$pane]}

        # Vérifier si le pane existe et est actif
        if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^$pane$"; then
            local last_activity=$(get_last_activity $pane)
            local inactivity_duration=$((current_time - last_activity))

            if [ $inactivity_duration -lt $INACTIVITY_THRESHOLD ]; then
                echo -e "${GREEN}✅ $agent_name actif (${inactivity_duration}s)${NC}" | tee -a $LOG_FILE
                all_inactive=false
            else
                echo -e "${YELLOW}💤 $agent_name inactif (${inactivity_duration}s)${NC}" | tee -a $LOG_FILE
            fi
        else
            echo -e "${RED}❌ $agent_name pane manquant${NC}" | tee -a $LOG_FILE
        fi
    done

    if [ "$all_inactive" = true ]; then
        return 0  # Tous inactifs
    else
        return 1  # Au moins un actif
    fi
}

# Fonction pour capturer screenshots des 4 panes HADDOCK
capture_tmux_screenshots() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')

    echo -e "${CYAN}📸 Capture screenshots TMUX HADDOCK...${NC}" | tee -a $LOG_FILE

    # Capturer chaque pane individuellement
    for pane in 0 1 2 3; do
        local agent_names=("haddock" "rastapopoulos" "tournesol1" "tournesol2")
        local agent_name=${agent_names[$pane]}

        if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^$pane$"; then
            local screenshot_file="$SCREENSHOT_DIR/${timestamp}_${agent_name}_pane${pane}.txt"
            tmux capture-pane -t "$SESSION:agents.$pane" -p > "$screenshot_file" 2>/dev/null

            if [ -f "$screenshot_file" ]; then
                echo -e "${GREEN}✅ Screenshot $agent_name sauvé: $screenshot_file${NC}" | tee -a $LOG_FILE
            fi
        fi
    done

    # Capturer vue complète
    local full_screenshot="$SCREENSHOT_DIR/${timestamp}_full_tmux_haddock.txt"
    tmux capture-pane -t "$SESSION:agents" -p > "$full_screenshot" 2>/dev/null

    return "$timestamp"
}

# Fonction de réveil d'urgence - SEULEMENT POUR HADDOCK + Screenshots
trigger_wake_up() {
    echo -e "${RED}🚨 TRIGGER DÉCLENCHÉ - INACTIVITÉ TOTALE ÉQUIPE HADDOCK${NC}" | tee -a $LOG_FILE

    # Capturer screenshots avant réveil
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    capture_tmux_screenshots

    # Message de réveil UNIQUEMENT pour HADDOCK (pane 0)
    WAKE_MESSAGE="🚨 RÉVEIL AUTOMATIQUE TMUX HADDOCK - SYSTÈME FIGÉ DÉTECTÉ
━━━━━━━━━━━━━━━━━━━━
⏰ $(date '+%H:%M:%S') - Toute l'équipe TMUX était inactive >10s
🔥 SYSTÈME FIGÉ - REPRISE D'ACTIVITÉ REQUISE
📸 Screenshots capturés: $SCREENSHOT_DIR/${timestamp}_*
📊 ACTION REQUISE: Faire un STATUS de l'équipe
⚓ Si tu reçois ceci = SYSTÈME BLOQUÉ, fais un diagnostic
━━━━━━━━━━━━━━━━━━━━"

    # Envoyer signal de réveil SEULEMENT au pane 0 (HADDOCK)
    if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^0$"; then
        # Affichage du message de réveil UNIQUEMENT chez HADDOCK
        tmux send-keys -t "$SESSION:agents.0" "echo '$WAKE_MESSAGE'" C-m 2>/dev/null
        tmux send-keys -t "$SESSION:agents.0" C-m 2>/dev/null

        echo -e "${CYAN}🔔 Réveil + Screenshots envoyés à HADDOCK uniquement (pane 0)${NC}" | tee -a $LOG_FILE
    fi

    echo -e "${MAGENTA}⚡ TRIGGER HADDOCK + SCREENSHOTS EXÉCUTÉ - Surveillance continue...${NC}" | tee -a $LOG_FILE
}

# Boucle principale de surveillance continue
CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))

    # Vérifier si monitoring activé
    if [ ! -f "$ACTIVATION_FILE" ]; then
        echo -e "${YELLOW}💤 Monitoring HADDOCK désactivé - Attente activation...${NC}" | tee -a $LOG_FILE
        sleep 10
        continue
    fi

    # Test si session TMUX existe
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo -e "${RED}💀 Session HADDOCK TMUX absente - Attente...${NC}" | tee -a $LOG_FILE
        sleep 10
        continue
    fi

    # Vérifier l'inactivité totale
    if check_total_inactivity; then
        trigger_wake_up
        # Attendre un peu après trigger pour éviter spam
        sleep 15
    fi

    # Vérification toutes les 3 secondes (surveillance plus rapide pour 10s)
    sleep 3
done