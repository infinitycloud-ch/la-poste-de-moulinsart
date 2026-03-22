#!/bin/bash

# 📧 EMAIL WATCHER ÉQUIPE NESTOR - Surveillance autonome
# Surveille les nouveaux emails et notifie l'équipe nestor-agents

LOG_FILE="/tmp/email-watcher-nestor.log"
LAST_CHECK_FILE="/tmp/last-email-check-nestor"
SESSION="nestor-agents"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔔 Email Watcher NESTOR démarré $(date)${NC}" | tee -a $LOG_FILE

# Initialiser timestamp si n'existe pas
if [ ! -f "$LAST_CHECK_FILE" ]; then
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" > $LAST_CHECK_FILE
fi

# Fonction pour envoyer notification TMUX
send_notification() {
    local agent=$1
    local subject=$2
    local from=$3
    local pane=$4

    # Format notification
    NOTIFICATION="
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail de $from
📬 Sujet: $subject
━━━━━━━━━━━━━━━━━━━━
"

    # Envoyer la notification avec retour à la ligne
    tmux send-keys -t ${SESSION}:agents.${pane} "$NOTIFICATION" C-m
    echo -e "${CYAN}Notification envoyée à $agent (pane $pane)${NC}" | tee -a $LOG_FILE
}

# Boucle principale
while true; do
    LAST_CHECK=$(cat $LAST_CHECK_FILE 2>/dev/null || echo "")

    # Vérifier chaque agent de l'équipe Nestor
    for agent in nestor tintin dupont1 dupont2; do
        MAILBOX_URL="http://localhost:1080/mailbox/${agent}"

        # Récupérer le dernier email
        RESPONSE=$(curl -s "$MAILBOX_URL" 2>/dev/null | tail -1)

        if [ ! -z "$RESPONSE" ] && [ "$RESPONSE" != "Not Found" ]; then
            # Parser l'email (format simple)
            FROM=$(echo "$RESPONSE" | grep -o "From: [^<]*" | sed 's/From: //')
            SUBJECT=$(echo "$RESPONSE" | grep -o "Subject: .*" | sed 's/Subject: //')

            if [ ! -z "$SUBJECT" ]; then
                # Déterminer le pane
                AGENT_PANE=""
                case $agent in
                    nestor) AGENT_PANE="0" ;;
                    tintin) AGENT_PANE="1" ;;
                    dupont1) AGENT_PANE="2" ;;
                    dupont2) AGENT_PANE="3" ;;
                esac

                if [ ! -z "$AGENT_PANE" ]; then
                    echo -e "${YELLOW}📧 Email pour $agent: $SUBJECT${NC}" | tee -a $LOG_FILE
                    send_notification "$agent" "$SUBJECT" "$FROM" "$AGENT_PANE"
                fi
            fi
        fi
    done

    # Mettre à jour le timestamp
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" > $LAST_CHECK_FILE

    # Attendre 5 secondes avant la prochaine vérification
    sleep 5
done