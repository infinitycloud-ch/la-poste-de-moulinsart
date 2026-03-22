#!/bin/bash

# 📮 MAIL SERVER MONITOR - Système de surveillance et redémarrage automatique
# Garde le serveur mail TOUJOURS en vie

LOG_FILE="/tmp/mail-monitor.log"
MAIL_LOG="/tmp/mail.log"
PID_FILE="/tmp/mail-server.pid"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Mail Monitor démarré $(date)${NC}" | tee -a $LOG_FILE

# Fonction pour vérifier si le serveur répond
check_server_health() {
    # Test 1: Port SMTP
    nc -zv localhost 1025 &>/dev/null
    SMTP_STATUS=$?
    
    # Test 2: API HTTP
    curl -s http://localhost:1080/api/emails >/dev/null 2>&1
    HTTP_STATUS=$?
    
    if [ $SMTP_STATUS -eq 0 ] && [ $HTTP_STATUS -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour redémarrer le serveur
restart_server() {
    echo -e "${YELLOW}⚠️  Redémarrage du serveur mail...${NC}" | tee -a $LOG_FILE
    
    # Tuer l'ancien processus
    pkill -f "bun.*mail-server" 2>/dev/null
    sleep 1
    
    # Redémarrer
    cd ~/moulinsart/oracle-observability
    nohup bun run server/mail-server.ts > $MAIL_LOG 2>&1 &
    echo $! > $PID_FILE
    
    sleep 3
    
    if check_server_health; then
        echo -e "${GREEN}✅ Serveur mail redémarré avec succès${NC}" | tee -a $LOG_FILE
        
        # Notifier les agents (toutes les équipes)
        for agent in nestor tintin dupont1 dupont2; do
            tmux display-message -t moulinsart-agents:agents -d 3000 "📧 Serveur mail redémarré" 2>/dev/null
        done
        for agent in haddock rastapopoulos tournesol1 tournesol2; do
            tmux display-message -t manitoba-agents:agents -d 3000 "📧 Serveur mail redémarré" 2>/dev/null
        done
        return 0
    else
        echo -e "${RED}❌ Échec du redémarrage${NC}" | tee -a $LOG_FILE
        return 1
    fi
}

# Boucle principale de surveillance
FAILURES=0
MAX_FAILURES=3

while true; do
    if ! check_server_health; then
        FAILURES=$((FAILURES + 1))
        echo -e "${RED}⚠️  Serveur mail ne répond pas (tentative $FAILURES/$MAX_FAILURES)${NC}" | tee -a $LOG_FILE
        
        if [ $FAILURES -ge $MAX_FAILURES ]; then
            restart_server
            FAILURES=0
        fi
    else
        if [ $FAILURES -gt 0 ]; then
            echo -e "${GREEN}✅ Serveur mail répond à nouveau${NC}" | tee -a $LOG_FILE
            FAILURES=0
        fi
    fi
    
    # Vérifier toutes les 30 secondes
    sleep 30
done