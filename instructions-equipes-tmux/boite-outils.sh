#!/bin/bash
# 🧰 Boîte à Outils TMUX Teams
# Actions communes pour tous les agents

AGENT_NAME="$USER"  # ou passé en paramètre
BASE_DIR="~/moulinsart/instructions-equipes-tmux"

show_menu() {
    echo "🧰 BOÎTE À OUTILS TMUX TEAMS"
    echo "================================"
    echo "1) 🔄 Reset briefing complet"
    echo "2) 📧 Consulter mes mails"
    echo "3) ✉️  Envoyer un email"
    echo "4) 🖥️  Voir ma session TMUX"
    echo "5) 👥 Contacter mon équipe"
    echo "6) 🏥 Diagnostics système"
    echo "7) 📋 Relire mon CLAUDE.md"
    echo "8) 🚀 Attacher à ma session TMUX"
    echo "9) ❌ Quitter"
    echo ""
    read -p "Choisissez une action (1-9): " choice
}

reset_briefing() {
    echo "🔄 Reset briefing pour $AGENT_NAME..."
    if [ -f "$BASE_DIR/reset-briefing.sh" ]; then
        "$BASE_DIR/reset-briefing.sh" "$AGENT_NAME"
    else
        echo "❌ Script de reset introuvable"
    fi
}

check_emails() {
    echo "📧 Consultation des mails de $AGENT_NAME:"
    echo "========================================"
    curl -s "http://localhost:1080/mailbox/$AGENT_NAME" | tail -10 || echo "❌ Impossible de récupérer les mails"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

send_email() {
    echo "✉️ Envoi d'email depuis $AGENT_NAME:"
    echo "===================================="
    read -p "Destinataire: " recipient
    read -p "Sujet: " subject
    echo "Message (terminez par une ligne vide):"
    message=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        message="${message}${line}\n"
    done

    if [ -f "~/moulinsart/send-mail.sh" ]; then
        echo -e "$message" | ~/moulinsart/send-mail.sh "$recipient" "$subject"
    else
        echo "❌ Script d'envoi email introuvable"
    fi
    read -p "Appuyez sur Entrée pour continuer..."
}

show_tmux_session() {
    echo "🖥️ Informations session TMUX:"
    echo "============================"

    # Déterminer l'équipe
    case "$AGENT_NAME" in
        nestor|tintin|dupont1|dupont2) SESSION="nestor-agents" ;;
        haddock|rastapopoulos|tournesol1|tournesol2) SESSION="haddock-agents" ;;
        *) SESSION="unknown" ;;
    esac

    echo "Agent: $AGENT_NAME"
    echo "Session: $SESSION"

    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "✅ Session active"
        echo ""
        echo "Panels de l'équipe:"
        tmux list-panes -t "$SESSION:agents" 2>/dev/null || echo "❌ Impossible de lister les panels"
    else
        echo "❌ Session inactive"
    fi

    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

contact_team() {
    echo "👥 Contacter votre équipe:"
    echo "========================"

    case "$AGENT_NAME" in
        nestor|tintin|dupont1|dupont2)
            echo "Équipe Nestor - Destinataires disponibles:"
            echo "• nestor@moulinsart.local"
            echo "• tintin@moulinsart.local"
            echo "• dupont1@moulinsart.local"
            echo "• dupont2@moulinsart.local"
            SESSION="nestor-agents"
            ;;
        haddock|rastapopoulos|tournesol1|tournesol2)
            echo "Équipe Haddock - Destinataires disponibles:"
            echo "• haddock@moulinsart.local"
            echo "• rastapopoulos@moulinsart.local"
            echo "• tournesol1@moulinsart.local"
            echo "• tournesol2@moulinsart.local"
            SESSION="haddock-agents"
            ;;
        *)
            echo "❌ Équipe inconnue pour $AGENT_NAME"
            return
            ;;
    esac

    echo ""
    echo "Options de contact:"
    echo "1) Envoyer email à un équipier"
    echo "2) Envoyer commande TMUX à un équipier"
    echo "3) Retour"

    read -p "Choix (1-3): " contact_choice
    case "$contact_choice" in
        1) send_email ;;
        2) send_tmux_command "$SESSION" ;;
        3) return ;;
    esac
}

send_tmux_command() {
    local session="$1"
    echo ""
    echo "🖥️ Envoi commande TMUX:"
    echo "Panel 0 = Leader, Panel 1 = Membre 1, Panel 2 = Membre 2, Panel 3 = Membre 3"
    read -p "Panel destination (0-3): " panel
    read -p "Commande à envoyer: " command

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux send-keys -t "$session:agents.$panel" "$command" C-m
        echo "✅ Commande envoyée au panel $panel"
    else
        echo "❌ Session $session inactive"
    fi

    read -p "Appuyez sur Entrée pour continuer..."
}

system_diagnostics() {
    echo "🏥 Diagnostics système:"
    echo "====================="

    # Oracle Server
    if curl -s http://localhost:3001/health >/dev/null 2>&1; then
        echo "✅ Oracle Server (port 3001) - ACTIF"
    else
        echo "❌ Oracle Server (port 3001) - INACTIF"
    fi

    # Mail Server
    if nc -z localhost 1025 2>/dev/null; then
        echo "✅ Mail Server SMTP (port 1025) - ACTIF"
    else
        echo "❌ Mail Server SMTP (port 1025) - INACTIF"
    fi

    # Mail API
    if nc -z localhost 1080 2>/dev/null; then
        echo "✅ Mail API (port 1080) - ACTIF"
    else
        echo "❌ Mail API (port 1080) - INACTIF"
    fi

    # Sessions TMUX
    echo ""
    echo "Sessions TMUX:"
    tmux ls 2>/dev/null | grep -E "(nestor|haddock)-agents" || echo "❌ Aucune session d'équipe active"

    # Mes mails
    echo ""
    MAIL_COUNT=$(curl -s "http://localhost:1080/mailbox/$AGENT_NAME" 2>/dev/null | wc -l)
    echo "📧 $MAIL_COUNT emails dans votre boîte"

    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

read_claude_md() {
    echo "📋 Votre CLAUDE.md:"
    echo "=================="

    CLAUDE_FILE="~/moulinsart/agents/$AGENT_NAME/CLAUDE.md"

    if [ -f "$CLAUDE_FILE" ]; then
        cat "$CLAUDE_FILE"
    else
        echo "❌ CLAUDE.md introuvable pour $AGENT_NAME"
        echo "Exécutez d'abord l'action 1 (Reset briefing)"
    fi

    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
}

attach_tmux() {
    case "$AGENT_NAME" in
        nestor|tintin|dupont1|dupont2) SESSION="nestor-agents" ;;
        haddock|rastapopoulos|tournesol1|tournesol2) SESSION="haddock-agents" ;;
        *)
            echo "❌ Équipe inconnue pour $AGENT_NAME"
            read -p "Appuyez sur Entrée pour continuer..."
            return
            ;;
    esac

    echo "🚀 Connexion à la session TMUX $SESSION..."

    if tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "Attachement à la session... (Ctrl+B puis D pour détacher)"
        sleep 2
        tmux attach-session -t "$SESSION"
    else
        echo "❌ Session $SESSION inactive"
        echo "Contactez l'administrateur système"
        read -p "Appuyez sur Entrée pour continuer..."
    fi
}

# Main loop
while true; do
    clear
    echo "👤 Agent connecté: $AGENT_NAME"
    echo ""
    show_menu

    case "$choice" in
        1) reset_briefing ;;
        2) check_emails ;;
        3) send_email ;;
        4) show_tmux_session ;;
        5) contact_team ;;
        6) system_diagnostics ;;
        7) read_claude_md ;;
        8) attach_tmux ;;
        9) echo "👋 Au revoir !"; exit 0 ;;
        *) echo "❌ Choix invalide"; sleep 2 ;;
    esac
done