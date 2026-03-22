#!/bin/bash

# 🌌 ORBITE DU SILENCE - Système de veille absolue HADDOCK
# Agent Général - Gardien du système en l'absence du Commandant

LOG_FILE="/tmp/orbite-silence.log"
SESSION="manitoba-agents"
AGENT_GENERAL="haddock"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🌌 ORBITE DU SILENCE ACTIVÉE - Agent Général HADDOCK$(date)${NC}" | tee -a $LOG_FILE
echo -e "${CYAN}👁️ Surveillance toutes les 2 minutes${NC}" | tee -a $LOG_FILE

# Fonction test statut équipe
test_statut_equipe() {
    echo -e "${YELLOW}📡 Test statut équipe TMUX...${NC}" | tee -a $LOG_FILE

    TIMESTAMP=$(date '+%H:%M:%S')

    # Envoyer ping à chaque agent
    for agent in rastapopoulos tournesol1 tournesol2; do
        PING_MSG="🏓 PING STATUT ÉQUIPE
━━━━━━━━━━━━━━━━━━━━
⏰ ${TIMESTAMP} - Test automatique Agent Général
🎯 RÉPONDRE: 'PONG ${agent}' dans les 30s
━━━━━━━━━━━━━━━━━━━━
⚓ HADDOCK - Orbite du Silence"

        ./send-mail.sh "${agent}@moulinsart.local" "🏓 PING STATUT ÉQUIPE" "$PING_MSG"
        echo -e "${CYAN}📤 Ping envoyé à $agent${NC}" | tee -a $LOG_FILE
    done

    # Attendre réponses 60s
    echo -e "${YELLOW}⏳ Attente réponses 60s...${NC}" | tee -a $LOG_FILE
    sleep 60

    # Vérifier réponses
    RESPONSES=0
    START_TIME=$(date -d "2 minutes ago" -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    MAILBOX_RESPONSE=$(curl -s "http://localhost:1080/api/mailbox/haddock@moulinsart.local" 2>/dev/null)

    if [ $? -eq 0 ] && [ ! -z "$MAILBOX_RESPONSE" ]; then
        for agent in rastapopoulos tournesol1 tournesol2; do
            PONG_COUNT=$(echo "$MAILBOX_RESPONSE" | jq -r --arg start "$START_TIME" --arg from "${agent}@moulinsart.local" '.emails[] | select(.timestamp > $start and .from == $from) | .body' 2>/dev/null | grep -c "PONG" 2>/dev/null || echo "0")

            if [ "$PONG_COUNT" -gt 0 ]; then
                echo -e "${GREEN}✅ $agent RÉPOND${NC}" | tee -a $LOG_FILE
                RESPONSES=$((RESPONSES + 1))
            else
                echo -e "${RED}❌ $agent SILENCE${NC}" | tee -a $LOG_FILE
            fi
        done
    fi

    return $RESPONSES
}

# Plan de panique
plan_panique() {
    echo -e "${RED}🚨 PLAN PANIQUE ACTIVÉ${NC}" | tee -a $LOG_FILE
    echo -e "${RED}💀 SILENCE TOTAL DÉTECTÉ${NC}" | tee -a $LOG_FILE

    # Notification visuelle TMUX
    tmux display-message -t "$SESSION:agents.0" -d 10000 "🚨 PLAN PANIQUE - SILENCE TOTAL" 2>/dev/null

    # Tentative réveil force
    echo -e "${YELLOW}⚡ Tentative réveil force...${NC}" | tee -a $LOG_FILE

    for agent_pane in 1 2 3; do
        # Envoi multiple signaux réveil
        tmux send-keys -t "$SESSION:agents.$agent_pane" C-c 2>/dev/null
        sleep 0.5
        tmux send-keys -t "$SESSION:agents.$agent_pane" "echo '🚨 RÉVEIL FORCE - Agent Général HADDOCK'" C-m 2>/dev/null
        tmux send-keys -t "$SESSION:agents.$agent_pane" C-m 2>/dev/null
    done

    echo -e "${MAGENTA}🌌 HADDOCK maintient l'orbite du silence${NC}" | tee -a $LOG_FILE
}

# Boucle principale orbite
CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))
    echo -e "${CYAN}🌌 Cycle $CYCLE - $(date '+%H:%M:%S')${NC}" | tee -a $LOG_FILE

    # Test si session TMUX existe
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo -e "${RED}💀 Session TMUX morte - Attente...${NC}" | tee -a $LOG_FILE
        sleep 120
        continue
    fi

    # Test statut équipe
    test_statut_equipe
    RESPONSES=$?

    if [ $RESPONSES -eq 0 ]; then
        echo -e "${RED}🚨 SILENCE TOTAL - Activation plan panique${NC}" | tee -a $LOG_FILE
        plan_panique
    elif [ $RESPONSES -lt 3 ]; then
        echo -e "${YELLOW}⚠️ Réponses partielles ($RESPONSES/3)${NC}" | tee -a $LOG_FILE
    else
        echo -e "${GREEN}✅ Équipe opérationnelle ($RESPONSES/3)${NC}" | tee -a $LOG_FILE
    fi

    # Attendre 2 minutes
    echo -e "${CYAN}⏳ Prochaine orbite dans 120s...${NC}" | tee -a $LOG_FILE
    sleep 120
done