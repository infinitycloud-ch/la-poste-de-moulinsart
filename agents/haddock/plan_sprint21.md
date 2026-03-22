# PLAN D'ACTION TECHNIQUE - SPRINT 21
## Certification Architecture Mono-OS - Mode Jedi

**Sprint**: 21 - Renaissance Phoenix
**Date**: 2025-10-04
**Architecte**: Claude 3 Opus - Mode Artisan
**Doctrine**: Script Atomique + Exécuteur Dédié

---

## 1. SÉQUENCE D'OPÉRATIONS

### Phase 1 : Préparation Environnement (T+0 → T+30min)
1. **Validation prérequis système**
   - Vérifier tmux installé et version >= 3.0
   - Vérifier qwen3 local opérationnel via Ollama
   - Confirmer structure répertoires mono-CLI

2. **Initialisation session tmux dédiée**
   - Créer session `tmux new-session -d -s jedi-sprint21`
   - Configurer buffer history: 10000 lignes
   - Activer logging complet: `tmux pipe-pane -t jedi-sprint21 -o 'cat >> ~/moulinsart/runlogs/sprint21_raw.log'`

3. **Création infrastructure de mission**
   - Créer répertoire `~/moulinsart/projects/mono-cli/missions_log/`
   - Créer script exécuteur `~/moulinsart/projects/mono-cli/execute.sh`
   - Initialiser journal de bord `sprint21_journal.md`

### Phase 2 : Implémentation Doctrine (T+30min → T+2h)
4. **Développer le Script Atomique**
   - Générer script complet mission "Premier Vol Solo"
   - Intégrer tous garde-fous (timeouts, validations, rollback)
   - Sauvegarder dans `missions_log/001_premier_vol.sh`

5. **Préparer l'Exécuteur Dédié**
   - Créer `execute.sh` avec mécanisme de watchdog
   - Implémenter capture stdout/stderr temps réel
   - Ajouter mécanisme de timeout global (5 minutes max)

6. **Établir le Heartbeat**
   - Créer script monitoring `heartbeat.sh`
   - Polling toutes les 5 secondes sur PID de l'exécution
   - Signal visuel dans tmux status bar

### Phase 3 : Exécution Mission (T+2h → T+2h30)
7. **Lancement Premier Vol Solo**
   - Attacher à session tmux pour observation directe
   - Exécuter: `./execute.sh ./missions_log/001_premier_vol.sh`
   - Observer création répertoire, venv, installation cowsay

8. **Validation temps réel**
   - Vérifier présence physique des artefacts créés
   - Confirmer output cowsay dans terminal
   - Capturer screenshots comme preuves

### Phase 4 : Audit Post-Exécution (T+2h30 → T+3h)
9. **Analyse forensique**
   - Parser logs tmux pour timeline complète
   - Vérifier absence de boucles ou blocages
   - Mesurer latences réelles qwen3

10. **Rapport de certification**
    - Compiler preuves (logs, screenshots, artefacts)
    - Documenter métriques performance
    - Valider conformité avec Doctrine

---

## 2. GARDE-FOUS TECHNIQUES

### A. Protection contre Boucles Infinies
```bash
# Timeout global dans execute.sh
timeout --preserve-status 300 bash "$1"
EXITCODE=$?
if [ $EXITCODE -eq 124 ]; then
    echo "[GARDE-FOU] Script interrompu après 5 minutes"
    exit 1
fi
```

### B. Gestion Commandes Interactives
```bash
# Variables d'environnement pour forcer mode non-interactif
export DEBIAN_FRONTEND=noninteractive
export PYTHONUNBUFFERED=1

# Redirection stdin depuis /dev/null
exec < /dev/null
```

### C. Validation Checkpoints
```bash
# Fonction de validation après chaque étape critique
validate_checkpoint() {
    local checkpoint=$1
    local condition=$2

    if ! eval "$condition"; then
        echo "[ERREUR] Checkpoint échoué: $checkpoint"
        echo "[ROLLBACK] Nettoyage en cours..."
        cleanup_mission
        exit 1
    fi
    echo "[OK] Checkpoint validé: $checkpoint"
}
```

### D. Mécanisme de Rollback
```bash
# Trappe de nettoyage automatique
trap cleanup_mission EXIT ERR

cleanup_mission() {
    echo "[CLEANUP] Suppression artefacts temporaires..."
    [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"
    deactivate 2>/dev/null || true
}
```

### E. Monitoring Ressources
```bash
# Limites de ressources pour éviter saturation
ulimit -v 2097152  # Limite mémoire virtuelle 2GB
ulimit -t 300      # Limite CPU 300 secondes
```

---

## 3. SCRIPT DE MISSION - PREMIER VOL SOLO

### [SCRIPT]
```bash
#!/bin/bash
#============================================================
# MISSION 001 - PREMIER VOL SOLO
# Sprint 21 - Certification Mode Jedi
# Généré par: Claude 3 Opus
# Date: 2025-10-04
#============================================================

set -euo pipefail
IFS=$'\n\t'

# Configuration
MISSION_NAME="premier_vol_solo"
MISSION_ID="001"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASE_DIR="$HOME/moulinsart/projects/mono-cli"
WORK_DIR="$BASE_DIR/sandbox/mission_${MISSION_ID}_${TIMESTAMP}"
LOG_FILE="$BASE_DIR/missions_log/${MISSION_ID}_${MISSION_NAME}.log"

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction de logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        INFO)  color=$BLUE ;;
        SUCCESS) color=$GREEN ;;
        WARN)  color=$YELLOW ;;
        ERROR) color=$RED ;;
        *)     color=$NC ;;
    esac

    echo -e "${color}[${level}]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
}

# Fonction de validation
validate_checkpoint() {
    local checkpoint=$1
    local condition=$2

    log INFO "Validation checkpoint: $checkpoint"

    if eval "$condition"; then
        log SUCCESS "Checkpoint validé: $checkpoint"
        return 0
    else
        log ERROR "Checkpoint échoué: $checkpoint"
        return 1
    fi
}

# Cleanup en cas d'erreur
cleanup_mission() {
    log WARN "Nettoyage des artefacts de mission..."
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
        log INFO "Répertoire de travail supprimé"
    fi
}

# Trappe de nettoyage
trap cleanup_mission EXIT ERR

#============================================================
# DÉBUT DE MISSION
#============================================================

log INFO "="
log INFO "MISSION $MISSION_ID - $MISSION_NAME"
log INFO "Timestamp: $TIMESTAMP"
log INFO "="

# Étape 1: Création du répertoire de travail
log INFO "Étape 1: Création du répertoire de travail"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
validate_checkpoint "work_dir_created" "[ -d '$WORK_DIR' ]"

# Étape 2: Création de l'environnement virtuel Python
log INFO "Étape 2: Création environnement virtuel Python"
python3 -m venv venv_mission
validate_checkpoint "venv_created" "[ -d 'venv_mission' ]"

# Étape 3: Activation de l'environnement virtuel
log INFO "Étape 3: Activation environnement virtuel"
source venv_mission/bin/activate
validate_checkpoint "venv_activated" "[ ! -z '${VIRTUAL_ENV:-}' ]"

# Étape 4: Installation de cowsay
log INFO "Étape 4: Installation package cowsay"
pip install --quiet --no-cache-dir cowsay
validate_checkpoint "cowsay_installed" "pip list | grep -q cowsay"

# Étape 5: Test de cowsay
log INFO "Étape 5: Test execution cowsay"
python3 -c "import cowsay; cowsay.cow('Mission Premier Vol Solo: SUCCESS!')"

# Étape 6: Création rapport de mission
log INFO "Étape 6: Génération rapport de mission"
cat > mission_report.txt << EOF
RAPPORT DE MISSION $MISSION_ID
==============================
Nom: $MISSION_NAME
Date: $(date)
Statut: SUCCESS

Artefacts créés:
- Répertoire: $WORK_DIR
- Environnement virtuel: venv_mission
- Package installé: cowsay

Validation:
[X] Répertoire créé
[X] Venv opérationnel
[X] Package fonctionnel
[X] Output généré

Message final:
$(python3 -c "import cowsay; cowsay.cow('Mode Jedi Certifié!')")
EOF

validate_checkpoint "report_created" "[ -f 'mission_report.txt' ]"

# Affichage du rapport
log SUCCESS "Mission complétée avec succès!"
echo ""
cat mission_report.txt

# Désactivation de la trappe de nettoyage (mission réussie)
trap - EXIT ERR

log INFO "="
log SUCCESS "FIN DE MISSION - ARTEFACTS CONSERVÉS DANS: $WORK_DIR"
log INFO "="

exit 0
```
### [/SCRIPT]

---

## 4. MÉTRIQUES DE SUCCÈS

### Critères de Validation Sprint 21
- [ ] Script atomique exécuté sans intervention manuelle
- [ ] Tous checkpoints validés (6/6)
- [ ] Temps d'exécution < 2 minutes
- [ ] Aucune boucle ou blocage détecté
- [ ] Artefacts physiques créés et vérifiables
- [ ] Logs complets et traçables
- [ ] Cowsay affiche message de succès

### Indicateurs de Performance
- **Latence qwen3**: < 2s par invocation
- **Utilisation CPU**: < 50% moyenne
- **Utilisation RAM**: < 500MB pic
- **Taille logs**: < 10MB total
- **Exit code**: 0 (succès)

---

## 5. PROCHAINES ÉTAPES POST-CERTIFICATION

Si Sprint 21 validé:
1. **Sprint 22**: Mission complexe multi-étapes (CRUD fichiers + API calls)
2. **Sprint 23**: Intégration avec orchestrateur Hammerspoon
3. **Sprint 24**: Mode collaboratif avec monitoring Oracle API
4. **Sprint 25**: Production - Agent autonome 24/7

---

**Document préparé par**: Claude 3 Opus - Consultant/Artisan
**Statut**: PRÊT POUR EXÉCUTION
**Prochain checkpoint**: Lancement Sprint 21 sur approbation