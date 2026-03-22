#!/bin/bash

# 📮 LA POSTE DE MOULINSART - Script de démarrage simple
# 
# Ce script lance les services essentiels et l'UI:
# - Oracle Observability (API + WebSocket)
# - Mail Server (SMTP + Web)
# - Client Web (Vite) sur 5175

echo "📮 Démarrage de La Poste de Moulinsart..."
echo ""

# Couleurs pour le terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que Bun est installé
if ! command -v bun &> /dev/null; then
    echo "❌ Bun n'est pas installé. Installez-le avec: curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

# Fonction pour tuer les processus sur un port
kill_port() {
    local port=$1
    local pids=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$pids" ]; then
        echo "⚠️  Arrêt des processus sur le port $port..."
        echo "$pids" | xargs kill -9 2>/dev/null
        sleep 1
    fi
}

# Arrêter les processus existants
echo -e "${YELLOW}🛑 Arrêt des services existants...${NC}"
echo ""

# Tuer les processus Bun/Node existants
pkill -f "bun.*server/index.ts" 2>/dev/null
pkill -f "bun.*server/mail-server" 2>/dev/null
pkill -f "bun.*dev" 2>/dev/null
pkill -f "vite" 2>/dev/null

# Forcer l'arrêt sur les ports spécifiques
kill_port 3001  # Oracle API
kill_port 1025  # SMTP
kill_port 1080  # Mail Web
kill_port 5175  # Client Vue

echo -e "${GREEN}✅ Ports libérés${NC}"
echo ""
sleep 2

# Se placer dans le bon répertoire
cd ~/moulinsart/oracle-observability

echo -e "${BLUE}1. Démarrage du serveur Oracle (port 3001)...${NC}"
nohup bun run server/index.ts > /tmp/oracle.log 2>&1 &
ORACLE_PID=$!
sleep 3

# Vérifier que Oracle a démarré
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo -e "${GREEN}   ✓ Oracle démarré${NC}"
else
    echo -e "${YELLOW}   ⚠ Oracle en cours de démarrage...${NC}"
fi

echo -e "${BLUE}2. Démarrage du serveur Mail (SMTP:1025, Web:1080)...${NC}"
nohup bun run server/mail-server.ts > /tmp/mail.log 2>&1 &
MAIL_PID=$!
sleep 3

# Vérifier que Mail a démarré
if curl -s http://localhost:1080/api/mailboxes > /dev/null 2>&1; then
    echo -e "${GREEN}   ✓ Mail Server démarré${NC}"
else
    echo -e "${YELLOW}   ⚠ Mail Server en cours de démarrage...${NC}"
fi

echo -e "${BLUE}3. Démarrage du client Web (port 5175)...${NC}"
cd client
nohup bun run dev > /tmp/client.log 2>&1 &
CLIENT_PID=$!
cd ..
sleep 5

# Vérifier que le client a démarré
if lsof -i :5175 > /dev/null 2>&1; then
    echo -e "${GREEN}   ✓ Client Vue démarré${NC}"
else
    echo -e "${YELLOW}   ⚠ Client Vue en cours de démarrage...${NC}"
fi

echo ""
echo -e "${GREEN}✅ La Poste de Moulinsart est opérationnelle!${NC}"
echo ""
echo "📡 Services disponibles:"
echo "   • Oracle API: http://localhost:3001"
echo "   • Oracle Health: http://localhost:3001/health"
echo "   • Mail Web: http://localhost:1080"
echo "   • WebSocket: ws://localhost:3001/ws"
echo "   • Dashboard: http://localhost:5175"
echo ""
echo -e "${YELLOW}📌 Vérification finale des services:${NC}"
echo -n "   Oracle (3001): "
curl -s http://localhost:3001/health > /dev/null 2>&1 && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
echo -n "   Mail (1080): "
curl -s http://localhost:1080/api/mailboxes > /dev/null 2>&1 && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
echo -n "   Client (5175): "
lsof -i :5175 > /dev/null 2>&1 && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
echo ""
echo "Processus lancés:"
echo "   • Oracle PID: $ORACLE_PID"
echo "   • Mail PID: $MAIL_PID"
echo "   • Client PID: $CLIENT_PID"
echo ""
echo "Pour arrêter les services: Ctrl+C"
echo ""
echo -e "${YELLOW}📝 Logs disponibles:${NC}"
echo "   • Oracle: /tmp/oracle.log"
echo "   • Mail: /tmp/mail.log"
echo "   • Client: /tmp/client.log"
echo ""

# Attendre que l'utilisateur arrête avec Ctrl+C
trap "echo ''; echo 'Arrêt des services...'; kill $ORACLE_PID $MAIL_PID $CLIENT_PID 2>/dev/null; exit" INT TERM

# Garder le script actif
wait