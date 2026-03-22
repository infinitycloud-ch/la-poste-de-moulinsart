#!/bin/bash

# 🚨 TRIGGER INACTIVITÉ MOULINSART - Système de réveil automatique NESTOR avec Screenshots
# Se déclenche si TOUS les agents Moulinsart sont inactifs pendant 10 secondes
# ACTIVATION: Créer fichier /tmp/tmux-monitor-active pour activer

LOG_FILE="/tmp/inactivity-trigger-nestor.log"
SESSION="tmux-nestor"
AGENT_GENERAL="nestor"
INACTIVITY_THRESHOLD=10  # 10 secondes
ACTIVATION_FILE="/tmp/tmux-monitor-active"
SCREENSHOT_DIR="/tmp/tmux-screenshots"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Créer dossier screenshots
mkdir -p "$SCREENSHOT_DIR"

echo -e "${MAGENTA}🚨 TRIGGER INACTIVITÉ MOULINSART avec Screenshots - Chef NESTOR $(date)${NC}" | tee -a $LOG_FILE
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

    echo -e "${YELLOW}🔍 Vérification activité équipe Moulinsart...${NC}" | tee -a $LOG_FILE

    # Vérifier chaque agent (panes 0,1,2,3 = nestor, tintin, dupont1, dupont2)
    for pane in 0 1 2 3; do
        local agent_names=("nestor" "tintin" "dupont1" "dupont2")
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

# Fonction pour capturer screenshots des 4 panes
capture_tmux_screenshots() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')

    echo -e "${CYAN}📸 Capture screenshots TMUX...${NC}" | tee -a $LOG_FILE

    # Capturer chaque pane individuellement
    for pane in 0 1 2 3; do
        local agent_names=("nestor" "tintin" "dupont1" "dupont2")
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
    local full_screenshot="$SCREENSHOT_DIR/${timestamp}_full_tmux.txt"
    tmux capture-pane -t "$SESSION:agents" -p > "$full_screenshot" 2>/dev/null

    return "$timestamp"
}

# Fonction de réveil d'urgence - SEULEMENT POUR NESTOR + Screenshots
trigger_wake_up() {
    echo -e "${RED}🚨 TRIGGER DÉCLENCHÉ - INACTIVITÉ TOTALE ÉQUIPE NESTOR${NC}" | tee -a $LOG_FILE

    # Capturer screenshots avant réveil
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    capture_tmux_screenshots

    # Message de réveil UNIQUEMENT pour NESTOR (pane 0)
    WAKE_MESSAGE="🚨 RÉVEIL AUTOMATIQUE TMUX NESTOR - SYSTÈME FIGÉ DÉTECTÉ
━━━━━━━━━━━━━━━━━━━━
⏰ $(date '+%H:%M:%S') - Toute l'équipe TMUX était inactive >10s
🔥 SYSTÈME FIGÉ - REPRISE D'ACTIVITÉ REQUISE
📸 Screenshots capturés: $SCREENSHOT_DIR/${timestamp}_*
📊 ACTION REQUISE: Faire un STATUS de l'équipe
🎩 Si tu reçois ceci = SYSTÈME BLOQUÉ, fais un diagnostic
━━━━━━━━━━━━━━━━━━━━"

    # Envoyer signal de réveil SEULEMENT au pane 0 (NESTOR)
    if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^0$"; then
        # Affichage du message de réveil UNIQUEMENT chez NESTOR
        tmux send-keys -t "$SESSION:agents.0" "echo '$WAKE_MESSAGE'" C-m 2>/dev/null
        tmux send-keys -t "$SESSION:agents.0" C-m 2>/dev/null

        echo -e "${CYAN}🔔 Réveil + Screenshots envoyés à NESTOR uniquement (pane 0)${NC}" | tee -a $LOG_FILE
    fi

    echo -e "${MAGENTA}⚡ TRIGGER NESTOR + SCREENSHOTS EXÉCUTÉ - Surveillance continue...${NC}" | tee -a $LOG_FILE
}

# Boucle principale de surveillance continue
CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))

    # Vérifier si monitoring activé
    if [ ! -f "$ACTIVATION_FILE" ]; then
        echo -e "${YELLOW}💤 Monitoring désactivé - Attente activation...${NC}" | tee -a $LOG_FILE
        sleep 10
        continue
    fi

    # Test si session TMUX existe
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo -e "${RED}💀 Session MOULINSART TMUX absente - Attente...${NC}" | tee -a $LOG_FILE
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