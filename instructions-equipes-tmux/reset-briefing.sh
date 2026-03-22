#!/bin/bash
# 🎩 Script de Reset/Briefing TMUX Teams
# Usage: ./reset-briefing.sh [agent_name]

AGENT_NAME="$1"
BASE_DIR="~/moulinsart/instructions-equipes-tmux"
TEMPLATE_FILE="$BASE_DIR/template-claude.md"

# Validation agent
if [ -z "$AGENT_NAME" ]; then
    echo "❌ Usage: $0 [nestor|tintin|dupont1|dupont2|haddock|rastapopoulos|tournesol1|tournesol2]"
    exit 1
fi

# Mapping agents → équipes
case "$AGENT_NAME" in
    nestor|tintin|dupont1|dupont2)
        TEAM_NAME="Équipe Nestor"
        SESSION_NAME="nestor-agents"
        TEAM_DIR="$BASE_DIR/nestor-equipe"
        TEAM_MEMBERS="• Nestor (Panel 0) - Orchestrateur
• Tintin (Panel 1) - Reporter/QA
• Dupont1 (Panel 2) - Développeur iOS
• Dupont2 (Panel 3) - Documentation/i18n"
        AUTHORIZED_RECIPIENTS="nestor@moulinsart.local, tintin@moulinsart.local, dupont1@moulinsart.local, dupont2@moulinsart.local"
        ;;
    haddock|rastapopoulos|tournesol1|tournesol2)
        TEAM_NAME="Équipe Haddock"
        SESSION_NAME="haddock-agents"
        TEAM_DIR="$BASE_DIR/haddock-equipe"
        TEAM_MEMBERS="• Haddock (Panel 0) - Capitaine
• Rastapopoulos (Panel 1) - Sécurité
• Tournesol1 (Panel 2) - Scientifique
• Tournesol2 (Panel 3) - Ingénieur"
        AUTHORIZED_RECIPIENTS="haddock@moulinsart.local, rastapopoulos@moulinsart.local, tournesol1@moulinsart.local, tournesol2@moulinsart.local"
        ;;
    *)
        echo "❌ Agent inconnu: $AGENT_NAME"
        echo "   Agents valides: nestor, tintin, dupont1, dupont2, haddock, rastapopoulos, tournesol1, tournesol2"
        exit 1
        ;;
esac

# Mapping panels
case "$AGENT_NAME" in
    nestor|haddock) PANEL_NUMBER="0" ;;
    tintin|rastapopoulos) PANEL_NUMBER="1" ;;
    dupont1|tournesol1) PANEL_NUMBER="2" ;;
    dupont2|tournesol2) PANEL_NUMBER="3" ;;
esac

AGENT_EMAIL="${AGENT_NAME}@moulinsart.local"
OUTPUT_FILE="~/moulinsart/agents/$AGENT_NAME/CLAUDE.md"
INSTRUCTIONS_FILE="$TEAM_DIR/$AGENT_NAME"

echo "🎯 Génération briefing pour $AGENT_NAME..."
echo "   Équipe: $TEAM_NAME"
echo "   Session: $SESSION_NAME (Panel $PANEL_NUMBER)"
echo "   Email: $AGENT_EMAIL"

# Vérifier que les fichiers existent
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template manquant: $TEMPLATE_FILE"
    exit 1
fi

if [ ! -f "$INSTRUCTIONS_FILE" ]; then
    echo "❌ Instructions manquantes: $INSTRUCTIONS_FILE"
    exit 1
fi

# Lire les instructions spécifiques
MISSION_INSTRUCTIONS=$(cat "$INSTRUCTIONS_FILE")

# Créer le répertoire agent si nécessaire
mkdir -p "~/moulinsart/agents/$AGENT_NAME"

# Générer le CLAUDE.md personnalisé via remplacement par étapes
cp "$TEMPLATE_FILE" "$OUTPUT_FILE.tmp"

# Remplacements simples
sed -i '' "s/{AGENT_NAME}/$AGENT_NAME/g" "$OUTPUT_FILE.tmp"
sed -i '' "s/{TEAM_NAME}/$TEAM_NAME/g" "$OUTPUT_FILE.tmp"
sed -i '' "s/{SESSION_NAME}/$SESSION_NAME/g" "$OUTPUT_FILE.tmp"
sed -i '' "s/{PANEL_NUMBER}/$PANEL_NUMBER/g" "$OUTPUT_FILE.tmp"
sed -i '' "s/{AGENT_EMAIL}/$AGENT_EMAIL/g" "$OUTPUT_FILE.tmp"

# Remplacements complexes avec un fichier temporaire
echo "$TEAM_MEMBERS" > /tmp/team_members.txt
echo "$AUTHORIZED_RECIPIENTS" > /tmp/auth_recipients.txt
echo "$MISSION_INSTRUCTIONS" > /tmp/mission_instructions.txt

# Utiliser awk pour les remplacements multilignes
awk '
    /\{TEAM_MEMBERS\}/ {
        while ((getline line < "/tmp/team_members.txt") > 0) print line;
        close("/tmp/team_members.txt");
        next
    }
    /\{AUTHORIZED_RECIPIENTS\}/ {
        while ((getline line < "/tmp/auth_recipients.txt") > 0) print line;
        close("/tmp/auth_recipients.txt");
        next
    }
    /\{MISSION_INSTRUCTIONS\}/ {
        while ((getline line < "/tmp/mission_instructions.txt") > 0) print line;
        close("/tmp/mission_instructions.txt");
        next
    }
    { print }
' "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE"

# Nettoyer
rm -f "$OUTPUT_FILE.tmp" /tmp/team_members.txt /tmp/auth_recipients.txt /tmp/mission_instructions.txt

echo "✅ CLAUDE.md généré: $OUTPUT_FILE"

# Vérifications système
echo ""
echo "🔍 Vérifications système:"

# 1. Oracle Server
if curl -s http://localhost:3001/health >/dev/null 2>&1; then
    echo "  ✅ Oracle Server actif"
else
    echo "  ❌ Oracle Server inactif"
fi

# 2. Session TMUX
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "  ✅ Session TMUX $SESSION_NAME active"
else
    echo "  ❌ Session TMUX $SESSION_NAME inactive"
fi

# 3. Mail Server
if nc -z localhost 1025 2>/dev/null; then
    echo "  ✅ Mail Server SMTP actif (port 1025)"
else
    echo "  ❌ Mail Server SMTP inactif"
fi

# 4. Emails récents
RECENT_EMAILS=$(curl -s "http://localhost:1080/mailbox/$AGENT_NAME" 2>/dev/null | wc -l)
echo "  📧 $RECENT_EMAILS emails dans votre boîte"

echo ""
echo "🎯 Briefing terminé pour $AGENT_NAME"
echo "   👀 Lisez votre CLAUDE.md: cat $OUTPUT_FILE"
echo "   📧 Vos mails: curl http://localhost:1080/mailbox/$AGENT_NAME"
echo "   🚀 Session TMUX: tmux attach-session -t $SESSION_NAME"
echo ""
echo "📋 INSTRUCTION POUR $AGENT_NAME:"
echo "   Lisez maintenant votre CLAUDE.md et exécutez vos tâches selon les instructions."