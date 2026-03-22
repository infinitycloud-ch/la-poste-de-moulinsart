#!/bin/bash

# Script pour corriger le layout tmux de Moulinsart
# Résout le problème de redimensionnement des panels

SESSION="moulinsart-agents"

echo "🔧 Correction du layout tmux..."

# Vérifier si la session existe
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ Session $SESSION non trouvée"
    exit 1
fi

# Appliquer le layout 2x2 parfait
echo "📐 Application du layout 2x2..."

# Appliquer le layout "tiled" pour grille parfaite 2x2
tmux select-layout -t "$SESSION:agents" tiled

# Ajustements fins pour garantir une symétrie parfaite
# D'abord régler la largeur (50% pour chaque colonne)
tmux resize-pane -t "$SESSION:agents.0" -x 50%
tmux resize-pane -t "$SESSION:agents.1" -x 50%

# Puis régler la hauteur (50% pour chaque ligne)
tmux resize-pane -t "$SESSION:agents.0" -y 50%
tmux resize-pane -t "$SESSION:agents.2" -y 50%

# Réappliquer tiled pour finaliser
tmux select-layout -t "$SESSION:agents" tiled

# Réappliquer les couleurs et styles
echo "🎨 Application des couleurs..."

# Couleurs de fond distinctes
tmux select-pane -t "$SESSION:agents.0" -P 'bg=#1a1a2e'  # Nestor - Fond sombre bleuté
tmux select-pane -t "$SESSION:agents.1" -P 'bg=#0f1a1e'  # Tintin - Fond sombre
tmux select-pane -t "$SESSION:agents.2" -P 'bg=#1a2e1a'  # Dupont1 - Fond sombre verdâtre
tmux select-pane -t "$SESSION:agents.3" -P 'bg=#2e1a2e'  # Dupont2 - Fond sombre violet

# Bordures colorées
tmux set -t "$SESSION" pane-active-border-style "fg=yellow,bg=default,bold"
tmux set -t "$SESSION" pane-border-style "fg=white,bg=default"

# Format des titres avec couleurs
tmux set -t "$SESSION" pane-border-format "#[fg=black,bg=yellow,bold] #{pane_title} #[default]"

echo "✅ Layout corrigé!"
echo ""
echo "💡 Conseils:"
echo "   • Ctrl+B puis Z : zoom/dézoom sur un panel"
echo "   • Ctrl+B puis flèches : naviguer entre panels"
echo "   • Ctrl+B puis D : détacher la session"
echo "   • Ctrl+B puis Space : changer de layout automatiquement"
echo ""
echo "Pour attacher: tmux attach -t $SESSION"