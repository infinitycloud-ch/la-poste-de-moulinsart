#!/bin/bash

# 📊 STATUS CHECK
echo "📊 Statut des agents Moulinsart"
echo "================================"

# Vérifier tmux
if tmux has-session -t moulinsart-agents 2>/dev/null; then
    echo "✅ Session tmux active"
    echo ""
    echo "Panels:"
    tmux list-panes -t moulinsart-agents -F "  Panel #{pane_index}: #{pane_current_path}"
else
    echo "❌ Aucune session tmux active"
fi

echo ""
echo "Processus Claude:"
ps aux | grep "claude-desktop --agent" | grep -v grep | awk '{print "  🟢", $NF}' || echo "  ❌ Aucun agent actif"