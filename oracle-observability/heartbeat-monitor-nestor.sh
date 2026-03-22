#!/bin/bash

# 🎩 HEARTBEAT MONITOR NESTOR - Surveillance intelligente à la demande
# LOGIQUE: Clic → 10s inactivité → Notification → Re-clic = STOP

LOG_FILE="/tmp/heartbeat-nestor.log"
SESSION="tmux-nestor"
SCREENSHOT_DIR="/tmp/tmux-screenshots"
ACTIVATION_FILE="/tmp/heartbeat-nestor-active"
STOP_FILE="/tmp/heartbeat-nestor-stop"
NOTIFICATION_SENT_FILE="/tmp/heartbeat-nestor-notified"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Créer dossier screenshots
mkdir -p "$SCREENSHOT_DIR"

echo -e "${MAGENTA}🎩 HEARTBEAT MONITOR NESTOR DÉMARRÉ $(date)${NC}" | tee -a $LOG_FILE
echo -e "${CYAN}📋 LOGIQUE: Clic → 10s inactivité → Notification → Re-clic = STOP${NC}" | tee -a $LOG_FILE

# Fonction pour capturer screenshots des 4 panes
capture_tmux_screenshots() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')

    echo -e "${CYAN}📸 Capture screenshots TMUX NESTOR...${NC}" | tee -a $LOG_FILE

    # Capturer chaque pane individuellement
    for pane in 0 1 2 3; do
        local agent_names=("nestor" "tintin" "dupont1" "dupont2")
        local agent_name=${agent_names[$pane]}

        if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^$pane$"; then
            local screenshot_file="$SCREENSHOT_DIR/${timestamp}_${agent_name}_pane${pane}.txt"
            tmux capture-pane -t "$SESSION:agents.$pane" -p > "$screenshot_file" 2>/dev/null

            if [ -f "$screenshot_file" ]; then
                echo -e "${GREEN}✅ Screenshot $agent_name: $screenshot_file${NC}" | tee -a $LOG_FILE
            fi
        fi
    done

    # Capturer vue complète
    local full_screenshot="$SCREENSHOT_DIR/${timestamp}_full_tmux_nestor.txt"
    tmux capture-pane -t "$SESSION:agents" -p > "$full_screenshot" 2>/dev/null

    echo -e "${GREEN}📸 Screenshots sauvés: ${timestamp}_*${NC}" | tee -a $LOG_FILE
}

# Fonction pour vérifier inactivité équipe
check_team_inactive() {
    local current_time=$(date +%s)
    local all_inactive=true

    # Vérifier chaque agent (panes 0,1,2,3 = nestor, tintin, dupont1, dupont2)
    for pane in 0 1 2 3; do
        local agent_names=("nestor" "tintin" "dupont1" "dupont2")
        local agent_name=${agent_names[$pane]}

        if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^$pane$"; then
            local last_activity=$(tmux display-message -t "$SESSION:agents.$pane" -p '#{pane_activity}' 2>/dev/null || echo "0")
            local inactivity_duration=$((current_time - last_activity))

            if [ $inactivity_duration -lt 10 ]; then
                all_inactive=false
                break
            fi
        fi
    done

    if [ "$all_inactive" = true ]; then
        return 0  # Tous inactifs >10s
    else
        return 1  # Au moins un actif
    fi
}

# Fonction de notification ONE-SHOT
send_heartbeat_notification() {
    echo -e "${RED}🚨 HEARTBEAT TRIGGER - ÉQUIPE INACTIVE >10s${NC}" | tee -a $LOG_FILE

    # Capturer screenshots
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    capture_tmux_screenshots

    # Message pour NESTOR uniquement
    WAKE_MESSAGE="🚨 HEARTBEAT NESTOR - SYSTÈME FIGÉ DÉTECTÉ
━━━━━━━━━━━━━━━━━━━━
⏰ $(date '+%H:%M:%S') - Équipe TMUX inactive >10s
🔥 SYSTÈME FIGÉ - DIAGNOSTIC REQUIS
📸 Screenshots: $SCREENSHOT_DIR/${timestamp}_*
📊 ACTION: Faire un STATUS de l'équipe
🎩 Re-clic bouton = STOP monitoring
━━━━━━━━━━━━━━━━━━━━"

    # Envoyer SEULEMENT au pane 0 (NESTOR)
    if tmux list-panes -t "$SESSION:agents" -F '#{pane_index}' 2>/dev/null | grep -q "^0$"; then
        tmux send-keys -t "$SESSION:agents.0" "echo '$WAKE_MESSAGE'" C-m 2>/dev/null
        tmux send-keys -t "$SESSION:agents.0" C-m 2>/dev/null
        echo -e "${CYAN}🔔 Notification envoyée à NESTOR (pane 0)${NC}" | tee -a $LOG_FILE
    fi

    # Marquer notification envoyée
    touch "$NOTIFICATION_SENT_FILE"
    echo -e "${MAGENTA}⚡ HEARTBEAT NOTIFICATION ENVOYÉE - Attente re-clic pour STOP${NC}" | tee -a $LOG_FILE
}

# Boucle principale HEARTBEAT
CYCLE=0
START_TIME=$(date +%s)

while true; do
    CYCLE=$((CYCLE + 1))
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # Vérifier si STOP demandé (re-clic dans les 2 minutes)
    if [ -f "$STOP_FILE" ]; then
        echo -e "${GREEN}🛑 STOP détecté - Re-clic reçu. Arrêt monitoring.${NC}" | tee -a $LOG_FILE
        rm -f "$ACTIVATION_FILE" "$STOP_FILE" "$NOTIFICATION_SENT_FILE" 2>/dev/null
        exit 0
    fi

    # PAS D'AUTO-STOP - Surveillance continue pour projet agentic
    # SEUL STOP: Si 2ème notification dans 2min = Agents terminés

    # Vérifier si session TMUX existe
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo -e "${YELLOW}💤 Session $SESSION absente - Attente...${NC}" | tee -a $LOG_FILE
        sleep 3
        continue
    fi

    # Si notification déjà envoyée dans les 2 dernières minutes, vérifier si nouvel inactif = FIN
    if [ -f "$NOTIFICATION_SENT_FILE" ]; then
        NOTIF_TIME=$(stat -f %m "$NOTIFICATION_SENT_FILE" 2>/dev/null || echo "0")
        TIME_SINCE_NOTIF=$((CURRENT_TIME - NOTIF_TIME))

        # Si <2min depuis dernière notif ET nouvel inactif = PROJET TERMINÉ
        if [ $TIME_SINCE_NOTIF -lt 120 ] && check_team_inactive; then
            echo -e "${GREEN}🎯 2ème inactivité en <2min = PROJET TERMINÉ - STOP${NC}" | tee -a $LOG_FILE
            rm -f "$ACTIVATION_FILE" "$NOTIFICATION_SENT_FILE" 2>/dev/null
            exit 0
        fi

        # Si >2min, on peut re-notifier si inactif
        if [ $TIME_SINCE_NOTIF -gt 120 ]; then
            rm -f "$NOTIFICATION_SENT_FILE"
        else
            sleep 3
            continue
        fi
    fi

    # Vérifier inactivité et notifier si besoin
    if check_team_inactive; then
        send_heartbeat_notification
    fi

    sleep 3
done