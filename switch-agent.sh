#!/bin/bash

# 🔄 SYSTÈME D'UNISSAGE MOULINSART
# Switch rapide entre contextes d'agents

set -e

# Configuration
MOULINSART_ROOT="~/moulinsart"
AGENTS_DIR="$MOULINSART_ROOT/agents"
BACKUP_DIR="$MOULINSART_ROOT/.agent-contexts"
CURRENT_CLAUDE="~/moulinsart/CLAUDE.md"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Agents disponibles
AGENTS=("nestor" "tintin" "dupont1" "dupont2" "haddock" "rastapopoulos" "tournesol1" "tournesol2")

echo -e "${BLUE}🔄 SYSTÈME D'UNISSAGE MOULINSART${NC}"
echo "================================================="

# Vérifier l'argument
if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage: $0 <agent_name>${NC}"
    echo ""
    echo "Agents disponibles:"
    for agent in "${AGENTS[@]}"; do
        echo "  - $agent"
    done
    exit 1
fi

AGENT_NAME="$1"

# Vérifier que l'agent existe
if [[ ! " ${AGENTS[@]} " =~ " ${AGENT_NAME} " ]]; then
    echo -e "${RED}❌ Agent '$AGENT_NAME' non reconnu!${NC}"
    echo ""
    echo "Agents disponibles:"
    for agent in "${AGENTS[@]}"; do
        echo "  - $agent"
    done
    exit 1
fi

# Créer répertoire de backup si nécessaire
mkdir -p "$BACKUP_DIR"

# Fonctions
backup_current_context() {
    echo -e "${YELLOW}💾 Sauvegarde contexte actuel...${NC}"

    if [[ -f "$CURRENT_CLAUDE" ]]; then
        # Identifier l'agent actuel depuis le CLAUDE.md
        CURRENT_AGENT=$(grep -E "^# .* CLAUDE\.md - " "$CURRENT_CLAUDE" 2>/dev/null | head -1 | sed 's/.*CLAUDE\.md - \([a-z0-9]*\).*/\1/' || echo "unknown")

        if [[ "$CURRENT_AGENT" != "unknown" ]] && [[ "$CURRENT_AGENT" != "$AGENT_NAME" ]]; then
            echo "  → Contexte détecté: $CURRENT_AGENT"
            cp "$CURRENT_CLAUDE" "$BACKUP_DIR/$CURRENT_AGENT-context.md"
            echo -e "${GREEN}  ✅ Contexte $CURRENT_AGENT sauvegardé${NC}"
        else
            echo "  → Sauvegarde générique"
            cp "$CURRENT_CLAUDE" "$BACKUP_DIR/previous-context.md"
        fi
    else
        echo -e "${YELLOW}  ⚠️ Aucun CLAUDE.md actuel trouvé${NC}"
    fi
}

load_agent_context() {
    echo -e "${YELLOW}🔄 Chargement contexte $AGENT_NAME...${NC}"

    AGENT_CLAUDE="$AGENTS_DIR/$AGENT_NAME/CLAUDE.md"
    SAVED_CONTEXT="$BACKUP_DIR/$AGENT_NAME-context.md"

    if [[ -f "$SAVED_CONTEXT" ]]; then
        echo "  → Contexte sauvegardé trouvé"
        cp "$SAVED_CONTEXT" "$CURRENT_CLAUDE"
        echo -e "${GREEN}  ✅ Contexte $AGENT_NAME restauré depuis backup${NC}"
    elif [[ -f "$AGENT_CLAUDE" ]]; then
        echo "  → Utilisation CLAUDE.md de base agent"
        cp "$AGENT_CLAUDE" "$CURRENT_CLAUDE"
        echo -e "${GREEN}  ✅ CLAUDE.md de base $AGENT_NAME chargé${NC}"
    else
        echo -e "${RED}  ❌ Aucun contexte trouvé pour $AGENT_NAME${NC}"
        echo "  → Génération template générique..."
        generate_generic_template "$AGENT_NAME"
    fi
}

generate_generic_template() {
    local agent="$1"
    echo -e "${YELLOW}📝 Génération template générique pour $agent...${NC}"

    cat > "$CURRENT_CLAUDE" << EOF
# 🎩 CLAUDE.md - $agent

## 👤 Identité
- **Nom** : $agent
- **Équipe TMUX** : $(get_team_for_agent "$agent")
- **Session** : $(get_session_for_agent "$agent")
- **Panel** : $(get_panel_for_agent "$agent")

## 📧 Communication
- **Adresse email** : $agent@moulinsart.local
- **Boîte mail** : \`curl http://localhost:1080/mailbox/$agent\`
- **Envoi email** : \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## 🎯 Mission
**En attente d'assignation de projet...**

Cet agent est prêt à recevoir ses instructions via :
- Email de coordination
- API Oracle (\`http://localhost:3001\`)
- Dashboard Moulinsart (\`http://localhost:5175\`)

## 📋 Historique Projets

*Aucun projet assigné actuellement*

---
**Template généré automatiquement le $(date)**
EOF

    echo -e "${GREEN}  ✅ Template générique créé pour $agent${NC}"
}

get_team_for_agent() {
    case "$1" in
        "nestor"|"tintin"|"dupont1"|"dupont2") echo "Équipe Nestor" ;;
        "haddock"|"rastapopoulos"|"tournesol1"|"tournesol2") echo "Équipe Haddock" ;;
        *) echo "Équipe Inconnue" ;;
    esac
}

get_session_for_agent() {
    case "$1" in
        "nestor"|"tintin"|"dupont1"|"dupont2") echo "nestor-agents" ;;
        "haddock"|"rastapopoulos"|"tournesol1"|"tournesol2") echo "haddock-agents" ;;
        *) echo "session-inconnue" ;;
    esac
}

get_panel_for_agent() {
    case "$1" in
        "nestor"|"haddock") echo "0" ;;
        "tintin"|"rastapopoulos") echo "1" ;;
        "dupont1"|"tournesol1") echo "2" ;;
        "dupont2"|"tournesol2") echo "3" ;;
        *) echo "0" ;;
    esac
}

show_context_info() {
    echo ""
    echo -e "${BLUE}📊 CONTEXTE ACTUEL${NC}"
    echo "================================================="
    echo -e "${GREEN}🤖 Agent actif: $AGENT_NAME${NC}"
    echo -e "📧 Email: $AGENT_NAME@moulinsart.local"
    echo -e "🎯 Équipe: $(get_team_for_agent "$AGENT_NAME")"
    echo -e "💻 Session TMUX: $(get_session_for_agent "$AGENT_NAME")"
    echo -e "📱 Panel: $(get_panel_for_agent "$AGENT_NAME")"
    echo ""
    echo -e "${YELLOW}Commands utiles:${NC}"
    echo -e "  📬 Voir emails: ${BLUE}curl http://localhost:1080/mailbox/$AGENT_NAME${NC}"
    echo -e "  📊 Dashboard: ${BLUE}http://localhost:5175${NC}"
    echo -e "  🔧 API Oracle: ${BLUE}http://localhost:3001${NC}"
    echo ""
}

# Exécution principale
main() {
    backup_current_context
    load_agent_context
    show_context_info

    echo -e "${GREEN}🎉 Switch vers $AGENT_NAME terminé avec succès!${NC}"
}

main