#!/bin/bash

# Script simple pour lancer les services Moulinsart
# Oracle, Mail Server et Client Web uniquement

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Path vers Bun
BUN_PATH="~/.bun/bin/bun"
PROJECT_DIR="~/moulinsart/oracle-observability"

echo -e "${GREEN}=== DEMARRAGE SERVICES MOULINSART ===${NC}"
echo ""

# Arrêter les processus existants
echo "Arrêt des processus existants..."
pkill -f "bun.*server/index.ts" 2>/dev/null
pkill -f "bun.*mail-server" 2>/dev/null
pkill -f "vite" 2>/dev/null
sleep 2

# Vérifier que le projet existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}[ERROR] Dossier projet introuvable: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# 1. Oracle Server
echo -e "${YELLOW}[1/3] Démarrage Oracle Server...${NC}"
if [ -f "server/index.ts" ]; then
    nohup "$BUN_PATH" run server/index.ts > /tmp/oracle.log 2>&1 &
    echo "  → Oracle lancé (logs: /tmp/oracle.log)"
else
    echo -e "${RED}  → server/index.ts introuvable${NC}"
fi

# 2. Mail Server
echo -e "${YELLOW}[2/3] Démarrage Mail Server...${NC}"
if [ -f "server/mail-server.ts" ]; then
    nohup "$BUN_PATH" run server/mail-server.ts > /tmp/mail.log 2>&1 &
    echo "  → Mail Server lancé (logs: /tmp/mail.log)"
else
    echo -e "${RED}  → server/mail-server.ts introuvable${NC}"
fi

# 3. Client Web
echo -e "${YELLOW}[3/3] Démarrage Client Web...${NC}"
if [ -d "client" ]; then
    cd client
    nohup "$BUN_PATH" run dev > /tmp/web.log 2>&1 &
    echo "  → Client Web lancé (logs: /tmp/web.log)"
    cd ..
else
    echo -e "${RED}  → Dossier client introuvable${NC}"
fi

# Attendre un peu pour que les services démarrent
sleep 3

echo ""
echo -e "${GREEN}=== SERVICES DEMARRES ===${NC}"
echo "  • Oracle Server: http://localhost:3001"
echo "  • Mail Server: http://localhost:1080"
echo "  • Dashboard: http://localhost:5175"
echo ""
echo "Pour arrêter les services, utilisez: ./stop-services.sh"
echo "Pour voir les logs: tail -f /tmp/{oracle,mail,web}.log"