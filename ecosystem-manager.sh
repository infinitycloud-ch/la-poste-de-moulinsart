#!/bin/bash

# ================================================================
# ECOSYSTEM MANAGER - Moulinsart Agents & MonoCLI
# ================================================================
# Version: v1.0
# Auteur: HADDOCK
# Description: Interface unifiee pour gerer l'ecosysteme complet
# ================================================================

set -e

# Configuration
API_BASE="http://localhost:3001/api"
MAIL_BASE="http://localhost:1080/api"
DASHBOARD_URL="http://localhost:5175"
MONO_CLI_PATH="~/moulinsart/mono-cli"
RUNLOGS_PATH="~/moulinsart/runlogs"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ================================================================
# FONCTIONS UTILITAIRES
# ================================================================

print_header() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}    MOULINSART ECOSYSTEM MANAGER v1.0 - HADDOCK${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${YELLOW}Dashboard: ${DASHBOARD_URL}${NC}"
    echo -e "${YELLOW}Oracle API: ${API_BASE}${NC}"
    echo -e "${YELLOW}Mail Server: ${MAIL_BASE}${NC}"
    echo ""
}

check_services() {
    echo -e "${BLUE}[INFO]${NC} Verification des services..."

    # Check Oracle API
    if curl -s "${API_BASE}/tasks" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Oracle API: OK"
    else
        echo -e "${RED}✗${NC} Oracle API: DOWN"
    fi

    # Check Mail Server
    if curl -s "${MAIL_BASE}/mailbox/haddock@moulinsart.local" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Mail Server: OK"
    else
        echo -e "${RED}✗${NC} Mail Server: DOWN"
    fi

    # Check Dashboard
    if curl -s "${DASHBOARD_URL}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Dashboard: OK"
    else
        echo -e "${RED}✗${NC} Dashboard: DOWN"
    fi

    echo ""
}

# ================================================================
# GESTION SPRINTS & TACHES
# ================================================================

show_current_sprint() {
    echo -e "${PURPLE}[SPRINT]${NC} Sprint actuel:"
    echo ""

    # Recuperer les taches en cours
    TASKS=$(curl -s "${API_BASE}/tasks?project_id=22" | jq -r '.[] | select(.status != "DONE") | "\(.id) | \(.title) | \(.assigned_to) | \(.status) | \(.sprint)"')

    if [ -z "$TASKS" ]; then
        echo -e "${YELLOW}Aucune tache en cours${NC}"
    else
        echo -e "${WHITE}ID | TITLE | AGENT | STATUS | SPRINT${NC}"
        echo "================================================================"
        echo "$TASKS" | while IFS='|' read -r id title agent status sprint; do
            case $status in
                "TODO") color=$YELLOW ;;
                "IN_PROGRESS") color=$BLUE ;;
                *) color=$WHITE ;;
            esac
            echo -e "${color}${id} | ${title} | ${agent} | ${status} | ${sprint}${NC}"
        done
    fi
    echo ""
}

show_task_details() {
    read -p "ID de la tache: " task_id
    echo ""

    TASK_JSON=$(curl -s "${API_BASE}/tasks/${task_id}")

    if [ "$TASK_JSON" = "null" ] || [ -z "$TASK_JSON" ]; then
        echo -e "${RED}[ERROR]${NC} Tache ${task_id} non trouvee"
        return
    fi

    echo -e "${WHITE}Details de la tache #${task_id}:${NC}"
    echo "================================================================"
    echo "$TASK_JSON" | jq -r '
        "ID: " + (.id | tostring) + "\n" +
        "Titre: " + .title + "\n" +
        "Description: " + (.description // "N/A") + "\n" +
        "Agent: " + .assigned_to + "\n" +
        "Status: " + .status + "\n" +
        "Priorite: " + .priority + "\n" +
        "Sprint: " + (.sprint // "N/A") + "\n" +
        "Projet: " + (.project_id | tostring)
    '
    echo ""
}

update_task_status() {
    read -p "ID de la tache: " task_id
    echo "Status possibles: TODO, IN_PROGRESS, DONE"
    read -p "Nouveau status: " new_status

    # Validation
    if [[ ! "$new_status" =~ ^(TODO|IN_PROGRESS|DONE)$ ]]; then
        echo -e "${RED}[ERROR]${NC} Status invalide. Utiliser: TODO, IN_PROGRESS, DONE"
        return
    fi

    # Mise a jour
    RESPONSE=$(curl -s -X PUT "${API_BASE}/tasks/${task_id}" \
        -H "Content-Type: application/json" \
        -d "{\"status\": \"${new_status}\"}")

    if echo "$RESPONSE" | jq -e '.id' >/dev/null 2>&1; then
        echo -e "${GREEN}[SUCCESS]${NC} Tache #${task_id} mise a jour: ${new_status}"
    else
        echo -e "${RED}[ERROR]${NC} Echec mise a jour tache #${task_id}"
    fi
    echo ""
}

# ================================================================
# GESTION MONOCLI
# ================================================================

mono_status() {
    echo -e "${PURPLE}[MONOCLI]${NC} Status MonoCLI:"
    echo ""

    cd "$MONO_CLI_PATH"
    source venv/bin/activate 2>/dev/null || echo -e "${YELLOW}Warning: venv non active${NC}"

    echo -e "${WHITE}Version:${NC}"
    mono --version 2>/dev/null || echo -e "${RED}MonoCLI non installe${NC}"

    echo ""
    echo -e "${WHITE}Backends disponibles:${NC}"
    echo "- Groq Cloud (recommande)"
    echo "- Ollama (local)"
    echo "- MLX Framework (Apple Silicon)"
    echo ""
}

mono_health_check() {
    echo -e "${PURPLE}[MONOCLI]${NC} Health check des backends:"
    echo ""

    cd "$MONO_CLI_PATH"
    source venv/bin/activate 2>/dev/null || true

    # Test Groq
    echo -e "${WHITE}Groq Cloud:${NC}"
    mono health --backend groq 2>/dev/null || echo -e "${RED}✗ Groq: DOWN${NC}"

    # Test Ollama
    echo -e "${WHITE}Ollama Local:${NC}"
    mono health --backend ollama 2>/dev/null || echo -e "${RED}✗ Ollama: DOWN${NC}"

    echo ""
}

mono_interactive() {
    echo -e "${PURPLE}[MONOCLI]${NC} Session interactive MonoCLI"
    echo "Backends: groq, ollama, mlx"
    read -p "Backend: " backend

    cd "$MONO_CLI_PATH"
    source venv/bin/activate

    echo -e "${GREEN}[INFO]${NC} Lancement chat interactif avec $backend..."
    echo -e "${YELLOW}Commandes: /reset, /save, /quit${NC}"
    echo ""

    mono chat --backend "$backend"
}

mono_benchmark() {
    echo -e "${PURPLE}[MONOCLI]${NC} Benchmark performance"
    read -p "Backend (groq/ollama/mlx): " backend

    cd "$MONO_CLI_PATH"
    source venv/bin/activate

    echo -e "${GREEN}[INFO]${NC} Benchmark en cours..."
    mono bench --backend "$backend" --json
    echo ""
}

# ================================================================
# GESTION EMAILS
# ================================================================

check_mailbox() {
    echo "Agents: haddock, tournesol1, tournesol2, rastapopoulos"
    read -p "Agent: " agent

    echo -e "${PURPLE}[MAIL]${NC} Mailbox ${agent}@moulinsart.local:"
    echo ""

    MAILS=$(curl -s "${MAIL_BASE}/mailbox/${agent}@moulinsart.local")

    if [ "$MAILS" = "[]" ] || [ -z "$MAILS" ]; then
        echo -e "${YELLOW}Mailbox vide${NC}"
    else
        echo "$MAILS" | jq -r '.[] | "From: " + .from + " | Subject: " + .subject + " | Date: " + .date'
    fi
    echo ""
}

send_mission_email() {
    echo -e "${PURPLE}[MAIL]${NC} Envoi email mission"
    echo "Agents: tournesol1, tournesol2, rastapopoulos"
    read -p "Destinataire: " agent
    read -p "Sprint: " sprint_name

    CID=$(date +%s)
    SUBJECT="MISSION ${sprint_name} CID=${CID}"
    BODY="Merci de repondre par: OK RECU"

    echo -e "${GREEN}[INFO]${NC} Envoi email..."
    ./send-mail.sh "${agent}@moulinsart.local" "$SUBJECT" "$BODY"

    echo -e "${GREEN}[SUCCESS]${NC} Email envoye avec CID: $CID"
    echo ""
}

# ================================================================
# GESTION LOGS & RUNLOGS
# ================================================================

show_runlogs() {
    echo -e "${PURPLE}[LOGS]${NC} Runlogs disponibles:"
    echo ""

    ls -la "$RUNLOGS_PATH"/*.md 2>/dev/null | while read -r line; do
        echo "$line"
    done
    echo ""
}

view_runlog() {
    echo -e "${PURPLE}[LOGS]${NC} Affichage runlog"
    ls "$RUNLOGS_PATH"/*.md 2>/dev/null | xargs -I {} basename {}
    echo ""
    read -p "Fichier runlog: " filename

    if [ -f "$RUNLOGS_PATH/$filename" ]; then
        echo -e "${WHITE}=== $filename ===${NC}"
        echo ""
        cat "$RUNLOGS_PATH/$filename"
    else
        echo -e "${RED}[ERROR]${NC} Fichier non trouve: $filename"
    fi
    echo ""
}

# ================================================================
# OUTILS SYSTEME
# ================================================================

open_dashboard() {
    echo -e "${GREEN}[INFO]${NC} Ouverture dashboard dans navigateur..."
    open "$DASHBOARD_URL" 2>/dev/null || \
    xdg-open "$DASHBOARD_URL" 2>/dev/null || \
    echo -e "${YELLOW}Ouvrir manuellement: ${DASHBOARD_URL}${NC}"
}

launch_tmux_monitoring() {
    echo -e "${GREEN}[INFO]${NC} Lancement monitoring tmux..."

    # Creer session tmux avec fenetres multiples
    tmux new-session -d -s ecosystem-monitor

    # Fenetre 1: Dashboard logs
    tmux rename-window -t ecosystem-monitor:0 'dashboard'
    tmux send-keys -t ecosystem-monitor:0 "curl -s ${API_BASE}/tasks?project_id=22 | jq" Enter

    # Fenetre 2: Mail monitoring
    tmux new-window -t ecosystem-monitor -n 'mail'
    tmux send-keys -t ecosystem-monitor:1 "watch -n 5 'curl -s ${MAIL_BASE}/mailbox/haddock@moulinsart.local | jq length'" Enter

    # Fenetre 3: MonoCLI ready
    tmux new-window -t ecosystem-monitor -n 'monocli'
    tmux send-keys -t ecosystem-monitor:2 "cd ${MONO_CLI_PATH} && source venv/bin/activate" Enter

    # Attacher session
    tmux attach-session -t ecosystem-monitor
}

system_backup() {
    echo -e "${GREEN}[INFO]${NC} Sauvegarde systeme..."

    BACKUP_DIR="/tmp/moulinsart-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Sauvegarder runlogs
    cp -r "$RUNLOGS_PATH" "$BACKUP_DIR/"

    # Sauvegarder config MonoCLI
    cp "$HOME/.mono/mono.yaml" "$BACKUP_DIR/" 2>/dev/null || true

    # Export tasks JSON
    curl -s "${API_BASE}/tasks?project_id=22" > "$BACKUP_DIR/tasks-export.json"

    echo -e "${GREEN}[SUCCESS]${NC} Sauvegarde complete: $BACKUP_DIR"
    echo ""
}

# ================================================================
# MENU PRINCIPAL
# ================================================================

show_menu() {
    echo -e "${WHITE}=== MENU PRINCIPAL ===${NC}"
    echo ""
    echo -e "${CYAN}SPRINTS & TACHES:${NC}"
    echo "  1. Afficher sprint actuel"
    echo "  2. Details d'une tache"
    echo "  3. Mettre a jour status tache"
    echo ""
    echo -e "${CYAN}MONOCLI:${NC}"
    echo "  4. Status MonoCLI"
    echo "  5. Health check backends"
    echo "  6. Session interactive"
    echo "  7. Benchmark performance"
    echo ""
    echo -e "${CYAN}EMAILS:${NC}"
    echo "  8. Verifier mailbox"
    echo "  9. Envoyer email mission"
    echo ""
    echo -e "${CYAN}LOGS & MONITORING:${NC}"
    echo " 10. Lister runlogs"
    echo " 11. Afficher runlog"
    echo " 12. Ouvrir dashboard"
    echo " 13. Monitoring tmux"
    echo ""
    echo -e "${CYAN}SYSTEME:${NC}"
    echo " 14. Verification services"
    echo " 15. Sauvegarde systeme"
    echo ""
    echo -e "${RED} 0. Quitter${NC}"
    echo ""
}

# ================================================================
# BOUCLE PRINCIPALE
# ================================================================

main() {
    while true; do
        print_header
        check_services
        show_menu

        read -p "Choix: " choice
        echo ""

        case $choice in
            1) show_current_sprint ;;
            2) show_task_details ;;
            3) update_task_status ;;
            4) mono_status ;;
            5) mono_health_check ;;
            6) mono_interactive ;;
            7) mono_benchmark ;;
            8) check_mailbox ;;
            9) send_mission_email ;;
            10) show_runlogs ;;
            11) view_runlog ;;
            12) open_dashboard ;;
            13) launch_tmux_monitoring ;;
            14) check_services ;;
            15) system_backup ;;
            0)
                echo -e "${GREEN}[INFO]${NC} Au revoir!"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Choix invalide"
                ;;
        esac

        echo ""
        read -p "Appuyer sur Entree pour continuer..."
    done
}

# ================================================================
# POINT D'ENTREE
# ================================================================

# Verification dependances
command -v curl >/dev/null 2>&1 || { echo -e "${RED}[ERROR]${NC} curl requis"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}[ERROR]${NC} jq requis"; exit 1; }
command -v tmux >/dev/null 2>&1 || { echo -e "${RED}[ERROR]${NC} tmux requis"; exit 1; }

# Lancement
main "$@"