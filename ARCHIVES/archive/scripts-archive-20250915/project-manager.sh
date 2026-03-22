#!/bin/bash

# 🚀 Gestionnaire de Projets Multi-Équipes Moulinsart
# Permet de créer et gérer plusieurs projets avec leurs propres équipes d'agents

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
BASE_DIR="~/moulinsart"
PROJECTS_DIR="$BASE_DIR/projects"
TEMPLATES_DIR="$BASE_DIR/templates"
ORACLE_DIR="$BASE_DIR/oracle-observability"

# Créer les dossiers nécessaires
mkdir -p "$PROJECTS_DIR"
mkdir -p "$TEMPLATES_DIR"

# Fonction pour afficher le header
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}${BOLD}🚀 GESTIONNAIRE DE PROJETS MOULINSART${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction pour créer un nouveau projet
create_project() {
    show_header
    echo -e "${GREEN}📝 Création d'un nouveau projet${NC}"
    echo ""
    
    # Demander le nom du projet
    read -p "Nom du projet (ex: ios-app): " PROJECT_NAME
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${RED}❌ Le nom du projet est requis${NC}"
        return 1
    fi
    
    PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
    PROJECT_DOMAIN="${PROJECT_NAME}.local"
    SESSION_NAME="moulinsart-${PROJECT_NAME}"
    
    # Vérifier si le projet existe déjà
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${RED}❌ Le projet $PROJECT_NAME existe déjà${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}📧 Domaine email: ${BOLD}@${PROJECT_DOMAIN}${NC}"
    echo -e "${BLUE}📺 Session tmux: ${BOLD}${SESSION_NAME}${NC}"
    echo ""
    
    # Demander les noms des agents
    echo -e "${YELLOW}👥 Noms des 4 agents de l'équipe:${NC}"
    read -p "1. Chef d'orchestre [nestor]: " AGENT1
    AGENT1=${AGENT1:-nestor}
    
    read -p "2. QA/Testeur [tintin]: " AGENT2
    AGENT2=${AGENT2:-tintin}
    
    read -p "3. Développeur 1 [dupont1]: " AGENT3
    AGENT3=${AGENT3:-dupont1}
    
    read -p "4. Développeur 2 [dupont2]: " AGENT4
    AGENT4=${AGENT4:-dupont2}
    
    # Demander le type de projet
    echo ""
    echo -e "${YELLOW}📦 Type de projet:${NC}"
    echo "1) iOS (Swift)"
    echo "2) Web (React/Node)"
    echo "3) Python (API/Script)"
    echo "4) Custom"
    read -p "Choix [1-4]: " PROJECT_TYPE
    
    case $PROJECT_TYPE in
        1) TYPE_NAME="ios" ;;
        2) TYPE_NAME="web" ;;
        3) TYPE_NAME="python" ;;
        4) TYPE_NAME="custom" ;;
        *) TYPE_NAME="custom" ;;
    esac
    
    echo ""
    echo -e "${GREEN}🔨 Création du projet...${NC}"
    
    # Créer la structure du projet
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/$AGENT1"
    mkdir -p "$PROJECT_DIR/$AGENT2"
    mkdir -p "$PROJECT_DIR/$AGENT3"
    mkdir -p "$PROJECT_DIR/$AGENT4"
    
    # Créer le fichier de configuration
    cat > "$PROJECT_DIR/config.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "domain": "$PROJECT_DOMAIN",
  "session": "$SESSION_NAME",
  "type": "$TYPE_NAME",
  "created": "$(date -Iseconds)",
  "agents": {
    "agent1": {
      "name": "$AGENT1",
      "email": "${AGENT1}@${PROJECT_DOMAIN}",
      "role": "Chef d'orchestre"
    },
    "agent2": {
      "name": "$AGENT2",
      "email": "${AGENT2}@${PROJECT_DOMAIN}",
      "role": "QA/Testeur"
    },
    "agent3": {
      "name": "$AGENT3",
      "email": "${AGENT3}@${PROJECT_DOMAIN}",
      "role": "Développeur 1"
    },
    "agent4": {
      "name": "$AGENT4",
      "email": "${AGENT4}@${PROJECT_DOMAIN}",
      "role": "Développeur 2"
    }
  }
}
EOF
    
    # Créer les CLAUDE.md selon le type
    create_claude_md_files "$PROJECT_DIR" "$TYPE_NAME" "$AGENT1" "$AGENT2" "$AGENT3" "$AGENT4" "$PROJECT_NAME"
    
    echo -e "${GREEN}✅ Projet créé: $PROJECT_DIR${NC}"
    echo ""
    
    # Demander si on lance la session tmux
    read -p "Lancer la session tmux maintenant? [o/N]: " LAUNCH_NOW
    if [[ "$LAUNCH_NOW" =~ ^[Oo]$ ]]; then
        launch_project "$PROJECT_NAME"
    fi
}

# Fonction pour créer les fichiers CLAUDE.md
create_claude_md_files() {
    local PROJECT_DIR=$1
    local TYPE=$2
    local AGENT1=$3
    local AGENT2=$4
    local AGENT3=$5
    local AGENT4=$6
    local PROJECT=$7
    
    # CLAUDE.md pour le chef d'orchestre
    cat > "$PROJECT_DIR/$AGENT1/CLAUDE.md" <<EOF
# 🎩 $AGENT1 - Chef d'Orchestre

## Ton Identité
Tu es **$AGENT1**, le chef d'orchestre du projet $PROJECT.

## Ta Mission
- Recevoir et analyser les requirements
- Coordonner le travail de l'équipe
- Distribuer les tâches aux autres agents
- Valider le travail final

## Ton Équipe
- $AGENT2: QA/Testeur
- $AGENT3: Développeur principal
- $AGENT4: Développeur support

## Communication
Utilise les emails pour communiquer:
- Ta boîte: ${AGENT1}@${PROJECT}.local
- Pour voir tes emails: curl http://localhost:1080/api/mailbox/${AGENT1}@${PROJECT}.local
EOF
    
    # CLAUDE.md pour le QA
    cat > "$PROJECT_DIR/$AGENT2/CLAUDE.md" <<EOF
# 🧪 $AGENT2 - QA/Testeur

## Ton Identité
Tu es **$AGENT2**, responsable QA du projet $PROJECT.

## Ta Mission
- Tester toutes les fonctionnalités
- Valider la qualité du code
- Reporter les bugs trouvés
- Confirmer que tout fonctionne

## Communication
- Ta boîte: ${AGENT2}@${PROJECT}.local
- Email du chef: ${AGENT1}@${PROJECT}.local
EOF
    
    # CLAUDE.md pour le dev 1
    cat > "$PROJECT_DIR/$AGENT3/CLAUDE.md" <<EOF
# 💻 $AGENT3 - Développeur Principal

## Ton Identité
Tu es **$AGENT3**, développeur principal du projet $PROJECT.

## Ta Mission
- Implémenter les fonctionnalités principales
- Écrire du code de qualité
- Collaborer avec $AGENT4 sur le développement
- Répondre aux demandes de $AGENT1

## Communication
- Ta boîte: ${AGENT3}@${PROJECT}.local
- Email du chef: ${AGENT1}@${PROJECT}.local
EOF
    
    # CLAUDE.md pour le dev 2
    cat > "$PROJECT_DIR/$AGENT4/CLAUDE.md" <<EOF
# 🔧 $AGENT4 - Développeur Support

## Ton Identité
Tu es **$AGENT4**, développeur support du projet $PROJECT.

## Ta Mission
- Assister $AGENT3 dans le développement
- Rechercher les meilleures pratiques
- Documenter le code
- Optimiser les performances

## Communication
- Ta boîte: ${AGENT4}@${PROJECT}.local
- Email du chef: ${AGENT1}@${PROJECT}.local
EOF
}

# Fonction pour lancer un projet
launch_project() {
    local PROJECT_NAME=$1
    local PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
    local CONFIG_FILE="$PROJECT_DIR/config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Projet $PROJECT_NAME non trouvé${NC}"
        return 1
    fi
    
    # Lire la configuration
    SESSION_NAME=$(grep '"session"' "$CONFIG_FILE" | cut -d'"' -f4)
    AGENT1=$(grep -A2 '"agent1"' "$CONFIG_FILE" | grep '"name"' | cut -d'"' -f4)
    AGENT2=$(grep -A2 '"agent2"' "$CONFIG_FILE" | grep '"name"' | cut -d'"' -f4)
    AGENT3=$(grep -A2 '"agent3"' "$CONFIG_FILE" | grep '"name"' | cut -d'"' -f4)
    AGENT4=$(grep -A2 '"agent4"' "$CONFIG_FILE" | grep '"name"' | cut -d'"' -f4)
    
    echo -e "${GREEN}🚀 Lancement du projet $PROJECT_NAME${NC}"
    echo -e "Session: ${BOLD}$SESSION_NAME${NC}"
    
    # Vérifier si la session existe déjà
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}⚠️ La session existe déjà${NC}"
        read -p "Voulez-vous l'attacher? [o/N]: " ATTACH
        if [[ "$ATTACH" =~ ^[Oo]$ ]]; then
            tmux attach -t "$SESSION_NAME"
        fi
        return
    fi
    
    # Créer la session tmux avec 4 panels
    echo "• Création de la session tmux..."
    tmux new-session -d -s "$SESSION_NAME" -n "agents"
    
    # Créer la disposition 2x2
    tmux split-window -t "$SESSION_NAME:agents" -h
    tmux split-window -t "$SESSION_NAME:agents.0" -v
    tmux split-window -t "$SESSION_NAME:agents.2" -v
    
    # Configurer chaque panel
    echo "• Configuration des agents..."
    
    # Panel 0 - Agent 1 (Chef)
    tmux send-keys -t "$SESSION_NAME:agents.0" "cd '$PROJECT_DIR/$AGENT1'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.0" "clear" C-m
    tmux send-keys -t "$SESSION_NAME:agents.0" "echo '🎩 $AGENT1 - Chef d\\'orchestre'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.0" "echo '📧 ${AGENT1}@${PROJECT_NAME}.local'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.0" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME:agents.0" "claude --dangerously-skip-permissions" C-m
    
    # Panel 1 - Agent 2 (QA)
    tmux send-keys -t "$SESSION_NAME:agents.1" "cd '$PROJECT_DIR/$AGENT2'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.1" "clear" C-m
    tmux send-keys -t "$SESSION_NAME:agents.1" "echo '🧪 $AGENT2 - QA/Testeur'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.1" "echo '📧 ${AGENT2}@${PROJECT_NAME}.local'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.1" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME:agents.1" "claude --dangerously-skip-permissions" C-m
    
    # Panel 2 - Agent 3 (Dev1)
    tmux send-keys -t "$SESSION_NAME:agents.2" "cd '$PROJECT_DIR/$AGENT3'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.2" "clear" C-m
    tmux send-keys -t "$SESSION_NAME:agents.2" "echo '💻 $AGENT3 - Développeur'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.2" "echo '📧 ${AGENT3}@${PROJECT_NAME}.local'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.2" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME:agents.2" "claude --dangerously-skip-permissions" C-m
    
    # Panel 3 - Agent 4 (Dev2)
    tmux send-keys -t "$SESSION_NAME:agents.3" "cd '$PROJECT_DIR/$AGENT4'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.3" "clear" C-m
    tmux send-keys -t "$SESSION_NAME:agents.3" "echo '🔧 $AGENT4 - Support'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.3" "echo '📧 ${AGENT4}@${PROJECT_NAME}.local'" C-m
    tmux send-keys -t "$SESSION_NAME:agents.3" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME:agents.3" "claude --dangerously-skip-permissions" C-m
    
    # Appliquer le layout 2x2
    tmux select-layout -t "$SESSION_NAME:agents" tiled
    
    echo -e "${GREEN}✅ Session lancée!${NC}"
    echo ""
    echo "Pour attacher: tmux attach -t $SESSION_NAME"
    
    read -p "Attacher maintenant? [o/N]: " ATTACH_NOW
    if [[ "$ATTACH_NOW" =~ ^[Oo]$ ]]; then
        tmux attach -t "$SESSION_NAME"
    fi
}

# Fonction pour lister les projets
list_projects() {
    show_header
    echo -e "${BLUE}📂 Projets existants:${NC}"
    echo ""
    
    if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A $PROJECTS_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}Aucun projet trouvé${NC}"
        return
    fi
    
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            PROJECT_NAME=$(basename "$project_dir")
            CONFIG_FILE="$project_dir/config.json"
            
            if [ -f "$CONFIG_FILE" ]; then
                DOMAIN=$(grep '"domain"' "$CONFIG_FILE" | cut -d'"' -f4)
                SESSION=$(grep '"session"' "$CONFIG_FILE" | cut -d'"' -f4)
                TYPE=$(grep '"type"' "$CONFIG_FILE" | cut -d'"' -f4)
                
                # Vérifier si la session est active
                if tmux has-session -t "$SESSION" 2>/dev/null; then
                    STATUS="${GREEN}● Active${NC}"
                else
                    STATUS="${RED}○ Inactive${NC}"
                fi
                
                echo -e "${BOLD}$PROJECT_NAME${NC} [$TYPE]"
                echo -e "  Domain: @$DOMAIN"
                echo -e "  Session: $SESSION $STATUS"
                echo ""
            fi
        fi
    done
}

# Fonction pour arrêter un projet
stop_project() {
    echo -e "${YELLOW}Arrêt d'un projet${NC}"
    echo ""
    
    read -p "Nom du projet à arrêter: " PROJECT_NAME
    SESSION_NAME="moulinsart-${PROJECT_NAME}"
    
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        echo -e "${GREEN}✅ Session $SESSION_NAME arrêtée${NC}"
    else
        echo -e "${RED}❌ Session $SESSION_NAME non trouvée${NC}"
    fi
}

# Création de projet via API (appelé depuis le serveur web)
create_project_api() {
    local PROJECT_NAME="$1"
    local PROJECT_TYPE="$2"
    local AGENT1="$3"
    local AGENT2="$4"
    local AGENT3="$5"
    local AGENT4="$6"
    
    # Validation
    if [ -z "$PROJECT_NAME" ] || [ -z "$AGENT1" ] || [ -z "$AGENT2" ] || [ -z "$AGENT3" ] || [ -z "$AGENT4" ]; then
        echo "Erreur: Tous les paramètres sont requis"
        exit 1
    fi
    
    # Créer le dossier du projet
    PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
    if [ -d "$PROJECT_DIR" ]; then
        echo "Erreur: Le projet $PROJECT_NAME existe déjà"
        exit 1
    fi
    
    mkdir -p "$PROJECT_DIR"
    
    # Créer la configuration
    cat > "$PROJECT_DIR/config.json" << EOF
{
  "name": "$PROJECT_NAME",
  "domain": "${PROJECT_NAME}.local",
  "type": "$PROJECT_TYPE",
  "session": "moulinsart-${PROJECT_NAME}",
  "agents": {
    "nestor": "$AGENT1",
    "tintin": "$AGENT2",
    "dupont1": "$AGENT3",
    "dupont2": "$AGENT4"
  },
  "emails": {
    "${AGENT1}": "${AGENT1}@${PROJECT_NAME}.local",
    "${AGENT2}": "${AGENT2}@${PROJECT_NAME}.local",
    "${AGENT3}": "${AGENT3}@${PROJECT_NAME}.local",
    "${AGENT4}": "${AGENT4}@${PROJECT_NAME}.local"
  }
}
EOF
    
    # Copier le template approprié
    local TEMPLATE_DIR="$BASE_DIR/templates/$PROJECT_TYPE"
    if [ ! -d "$TEMPLATE_DIR" ]; then
        TEMPLATE_DIR="$BASE_DIR/templates/custom"
    fi
    
    # Créer les CLAUDE.md pour chaque agent
    for agent_role in nestor tintin dupont1 dupont2; do
        agent_dir="$PROJECT_DIR/$agent_role"
        mkdir -p "$agent_dir"
        
        # Obtenir le nom personnalisé
        case $agent_role in
            nestor) agent_name="$AGENT1" ;;
            tintin) agent_name="$AGENT2" ;;
            dupont1) agent_name="$AGENT3" ;;
            dupont2) agent_name="$AGENT4" ;;
        esac
        
        # Copier et personnaliser le template
        if [ -f "$TEMPLATE_DIR/CLAUDE_${agent_role}.md" ]; then
            sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{AGENT_NAME}}/$agent_name/g; s/{{DOMAIN}}/${PROJECT_NAME}.local/g" \
                "$TEMPLATE_DIR/CLAUDE_${agent_role}.md" > "$agent_dir/CLAUDE.md"
        else
            # Template par défaut
            cat > "$agent_dir/CLAUDE.md" << EOF
# 🎭 Agent: $agent_name
## Projet: $PROJECT_NAME
## Email: ${agent_name}@${PROJECT_NAME}.local

### Instructions
- Tu es $agent_name dans le projet $PROJECT_NAME
- Communique via email avec ton équipe
- Domaine: @${PROJECT_NAME}.local
EOF
        fi
    done
    
    echo "✅ Projet $PROJECT_NAME créé avec succès"
    echo "Agents: $AGENT1, $AGENT2, $AGENT3, $AGENT4"
    echo "Domaine: ${PROJECT_NAME}.local"
    exit 0
}

# Menu principal
main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}Menu Principal:${NC}"
        echo ""
        echo "1) 🆕 Créer un nouveau projet"
        echo "2) 🚀 Lancer un projet existant"
        echo "3) 📋 Lister les projets"
        echo "4) 🛑 Arrêter un projet"
        echo "5) 🔄 Basculer vers un projet"
        echo "6) 🗑️  Supprimer un projet"
        echo ""
        echo "0) Quitter"
        echo ""
        read -p "Choix: " choice
        
        case $choice in
            1) create_project ;;
            2) 
                read -p "Nom du projet: " PROJECT_NAME
                launch_project "$PROJECT_NAME"
                ;;
            3) list_projects ; read -p "Appuyez sur Entrée..." ;;
            4) stop_project ; read -p "Appuyez sur Entrée..." ;;
            5) 
                read -p "Nom du projet: " PROJECT_NAME
                SESSION="moulinsart-${PROJECT_NAME}"
                if tmux has-session -t "$SESSION" 2>/dev/null; then
                    tmux attach -t "$SESSION"
                else
                    echo -e "${RED}Session non trouvée${NC}"
                    read -p "Appuyez sur Entrée..."
                fi
                ;;
            6)
                read -p "Nom du projet à supprimer: " PROJECT_NAME
                if [ -d "$PROJECTS_DIR/$PROJECT_NAME" ]; then
                    read -p "Confirmer suppression de $PROJECT_NAME? [o/N]: " CONFIRM
                    if [[ "$CONFIRM" =~ ^[Oo]$ ]]; then
                        rm -rf "$PROJECTS_DIR/$PROJECT_NAME"
                        echo -e "${GREEN}✅ Projet supprimé${NC}"
                    fi
                fi
                read -p "Appuyez sur Entrée..."
                ;;
            0) exit 0 ;;
            *) echo -e "${RED}Option invalide${NC}" ; sleep 1 ;;
        esac
    done
}

# Gérer les arguments de ligne de commande
if [ "$1" = "create-api" ]; then
    # Mode API: créer un projet avec les paramètres fournis
    shift
    create_project_api "$@"
else
    # Mode interactif: lancer le menu principal
    main_menu
fi