#!/bin/bash
# Script rapide pour corriger l'asymétrie du layout tmux

tmux select-layout -t moulinsart-agents:agents tiled 2>/dev/null && echo "✅ Layout équilibré!" || echo "❌ Session non trouvée"