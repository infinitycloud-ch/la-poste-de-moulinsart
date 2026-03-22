#!/bin/bash
# Surveillance automatique des sessions Claude pour détecter les prompts
# Contournement temporaire du bug de hooks Claude Code

while true; do
    # Détecter les processus Claude actifs
    CLAUDE_PROCS=$(ps aux | grep -E "claude.*--dangerously" | grep -v grep | wc -l)

    if [ $CLAUDE_PROCS -gt 0 ]; then
        # Envoyer un ping d'activité toutes les 5 minutes
        curl -s -X POST http://localhost:3001/api/events \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"activity_ping\",
                \"agent\": \"system\",
                \"project\": \"moulinsart-monitor\",
                \"data\": {
                    \"active_sessions\": $CLAUDE_PROCS,
                    \"timestamp\": \"$(date -Iseconds)\"
                }
            }" > /dev/null
    fi

    sleep 300  # 5 minutes
done