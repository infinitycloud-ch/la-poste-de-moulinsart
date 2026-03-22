#!/bin/bash

# 🚀 Script de lancement des agents dans des fenêtres Terminal séparées
# Chaque agent a sa propre fenêtre Terminal indépendante

echo "🎬 Lancement des agents Moulinsart dans des fenêtres séparées..."

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Fonction pour lancer un agent dans une nouvelle fenêtre Terminal
launch_agent() {
    local agent_name=$1
    local agent_dir=$2
    local agent_title=$3
    local agent_color=$4
    
    echo -e "${agent_color}🚀 Lancement de ${agent_name}...${NC}"
    
    # Script pour chaque agent
    cat > "/tmp/launch_${agent_name}.sh" << EOF
#!/bin/bash
clear
echo -e "${agent_color}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${agent_color}║${NC}  ${agent_title}  ${agent_color}║${NC}"
echo -e "${agent_color}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "📧 Email: ${agent_name}@moulinsart.local"
echo "📁 Répertoire: ${agent_dir}"
echo ""
echo "🔄 Lancement de Claude..."
echo ""
cd "${agent_dir}"
claude --dangerously-skip-permissions
EOF
    
    chmod +x "/tmp/launch_${agent_name}.sh"
    
    # Lancer dans une nouvelle fenêtre Terminal
    osascript <<END
tell application "Terminal"
    do script "/tmp/launch_${agent_name}.sh"
    set current settings of front window to settings set "Basic"
    set the custom title of front window to "🤖 ${agent_title}"
end tell
END
    
    sleep 1
}

# Nettoyer les anciennes sessions si nécessaire
echo "🧹 Nettoyage des processus existants..."
pkill -f "claude --dangerously" 2>/dev/null || true

echo ""
echo "📮 Lancement des 4 agents dans des fenêtres séparées..."
echo ""

# Lancer chaque agent
launch_agent "nestor" "~/moulinsart/agents/nestor" "🎩 NESTOR - Chef d'Orchestre" "$GREEN"
launch_agent "tintin" "~/moulinsart/agents/tintin" "🚀 TINTIN - QA Lead" "$BLUE"
launch_agent "dupont1" "~/moulinsart/agents/dupont1" "🎨 DUPONT1 - Développeur Swift" "$YELLOW"
launch_agent "dupont2" "~/moulinsart/agents/dupont2" "🔍 DUPONT2 - Recherche & Docs" "$MAGENTA"

echo ""
echo -e "${GREEN}✅ Les 4 agents ont été lancés dans des fenêtres séparées!${NC}"
echo ""
echo "📌 Chaque agent a maintenant:"
echo "   • Sa propre fenêtre Terminal"
echo "   • Son répertoire de travail correct"
echo "   • Son identité CLAUDE.md"
echo ""
echo "💡 Pour envoyer un email à un agent:"
echo "   curl -X POST http://localhost:1080/api/send \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"from\": \"vous@moulinsart.local\","
echo "        \"to\": \"nestor@moulinsart.local\","
echo "        \"subject\": \"Test\","
echo "        \"body\": \"Message\"}'"
echo ""
echo "🎯 Les agents sont prêts à recevoir des missions!"