#!/bin/bash

# 📧 EMAIL WATCHER ÉQUIPE TMUX - Surveillance autonome
# Surveille les nouveaux emails et notifie l'équipe TMUX

LOG_FILE="/tmp/email-watcher-tmux.log"
LAST_CHECK_FILE="/tmp/last-email-check-tmux"
SESSION="manitoba-agents"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🔔 Email Watcher TMUX démarré $(date)${NC}" | tee -a $LOG_FILE

# Initialiser timestamp si n'existe pas
if [ ! -f "$LAST_CHECK_FILE" ]; then
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" > $LAST_CHECK_FILE
fi

# Fonction pour vérifier nouveaux emails
check_new_emails() {
    LAST_CHECK=$(cat $LAST_CHECK_FILE)

    # Vérifier chaque agent TMUX (exclure haddock car déjà actif)
    for agent in rastapopoulos tournesol1 tournesol2; do
        MAILBOX_URL="http://localhost:1080/api/mailbox/${agent}@moulinsart.local"

        # Récupérer emails
        EMAILS=$(curl -s "$MAILBOX_URL" 2>/dev/null)

        if [ $? -eq 0 ] && [ ! -z "$EMAILS" ]; then
            # Vérifier nouveaux emails depuis dernière vérification
            NEW_COUNT=$(echo "$EMAILS" | jq -r --arg last "$LAST_CHECK" '.emails[] | select(.timestamp > $last) | .id' 2>/dev/null | wc -l)

            if [ "$NEW_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}📧 $NEW_COUNT nouveaux emails pour $agent${NC}" | tee -a $LOG_FILE

                # Notification TMUX
                AGENT_PANE=""
                case $agent in
                    haddock) AGENT_PANE="0" ;;
                    rastapopoulos) AGENT_PANE="1" ;;
                    tournesol1) AGENT_PANE="2" ;;
                    tournesol2) AGENT_PANE="3" ;;
                esac

                if [ ! -z "$AGENT_PANE" ]; then
                    # Notification visuelle
                    tmux display-message -t "$SESSION:agents.$AGENT_PANE" -d 5000 "🔔 $NEW_COUNT nouveaux emails!" 2>/dev/null

                    # TECHNIQUE TESTÉE 6H - Simple et efficace
                    NOTIFICATION="🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu pour ${agent}
📖 LIRE: curl http://localhost:1080/api/mailbox/${agent}@moulinsart.local
✉️ RÉPONDRE: ./send-mail.sh destinataire@moulinsart.local \"Sujet\" \"Message\"
━━━━━━━━━━━━━━━━━━━━"

                    tmux send-keys -t "$SESSION:agents.$AGENT_PANE" "echo '$NOTIFICATION'" C-m 2>/dev/null
                    # Return pour exécuter l'echo
                    tmux send-keys -t "$SESSION:agents.$AGENT_PANE" C-m 2>/dev/null

                    echo -e "${CYAN}✅ Notification envoyée à $agent (pane $AGENT_PANE)${NC}" | tee -a $LOG_FILE
                fi
            fi
        fi
    done

    # Mettre à jour timestamp
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" > $LAST_CHECK_FILE
}

# Boucle principale de surveillance
while true; do
    # Vérifier si session TMUX existe
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        check_new_emails
    else
        echo -e "${YELLOW}⚠️ Session $SESSION non trouvée, attente...${NC}" | tee -a $LOG_FILE
    fi

    # Vérifier toutes les 15 secondes
    sleep 15
done