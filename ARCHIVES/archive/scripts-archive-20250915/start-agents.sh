#!/bin/bash

# 🚀 Script de démarrage complet du système Moulinsart
# Lance les agents et attache automatiquement la session tmux

echo "🎬 Démarrage du système Moulinsart..."
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier si tmux est installé
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux n'est pas installé. Installez-le avec: brew install tmux${NC}"
    exit 1
fi

# Nettoyer les sessions existantes
echo "🧹 Nettoyage des sessions existantes..."
tmux kill-session -t moulinsart-agents 2>/dev/null

# Lancer le script de création de la session tmux
echo -e "${BLUE}📦 Création de la session tmux avec les 4 agents...${NC}"
~/moulinsart/launch-agents-tmux.sh &

# Attendre que la session soit créée
echo -e "${YELLOW}⏳ Attente de la création de la session...${NC}"
sleep 3

# Vérifier que la session existe
if tmux has-session -t moulinsart-agents 2>/dev/null; then
    echo -e "${GREEN}✅ Session créée avec succès!${NC}"
    echo ""
    echo "📌 Attachement à la session tmux..."
    echo ""
    echo "Raccourcis utiles:"
    echo "  • Ctrl+B puis flèches : Naviguer entre les panels"
    echo "  • Ctrl+B puis Z : Zoom/dézoom sur un panel"
    echo "  • Ctrl+B puis D : Détacher (garder en arrière-plan)"
    echo "  • Ctrl+B puis [ : Mode scroll dans un panel"
    echo ""
    sleep 2
    
    # Attacher à la session
    tmux attach -t moulinsart-agents
else
    echo -e "${RED}❌ Erreur: La session n'a pas pu être créée${NC}"
    exit 1
fi