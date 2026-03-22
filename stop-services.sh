#!/bin/bash

# Script pour arrêter les services Moulinsart

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}=== ARRET SERVICES MOULINSART ===${NC}"
echo ""

echo "Arrêt des processus..."
pkill -f "bun.*server/index.ts" 2>/dev/null && echo "  → Oracle Server arrêté"
pkill -f "bun.*mail-server" 2>/dev/null && echo "  → Mail Server arrêté"
pkill -f "vite" 2>/dev/null && echo "  → Client Web arrêté"

# Nettoyer les logs
echo ""
echo "Nettoyage des logs..."
> /tmp/oracle.log
> /tmp/mail.log
> /tmp/web.log

echo ""
echo -e "${GREEN}Services arrêtés avec succès${NC}"