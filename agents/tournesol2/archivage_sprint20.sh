#!/bin/bash

# SCRIPT ARCHIVAGE SPRINT 20 - CERTIFICATION ARCHITECTURE MONO-OS
# Auteur: TOURNESOL2
# Date: 3 octobre 2025
# Mission: Sprint 20 Protocole Colis Scellé

# Configuration
SPRINT="Sprint 20"
MISSION_ID="MISSION_VOL_SOLO"
CID="1759523897"
DATE_EXEC=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_DIR="./archives/sprint20_certification"
WORK_DIR="/tmp/sprint20_work"

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction log
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction erreur
error() {
    echo -e "${RED}[ERREUR] $1${NC}" >&2
    exit 1
}

# Fonction succès
success() {
    echo -e "${GREEN}[SUCCÈS] $1${NC}"
}

# Fonction warning
warning() {
    echo -e "${YELLOW}[ATTENTION] $1${NC}"
}

# Vérifier les prérequis
check_prerequisites() {
    log "Vérification des prérequis..."

    # Vérifier si sprint20_proof.log existe
    if [ ! -f "sprint20_proof.log" ]; then
        error "Fichier sprint20_proof.log non trouvé. Mission pas encore exécutée?"
    fi

    # Vérifier si rapport QA existe (pattern flexible)
    RAPPORT_QA=$(find . -name "*rapport*validation*" -o -name "*qa*sprint20*" -o -name "*rastapopoulos*sprint20*" | head -1)
    if [ -z "$RAPPORT_QA" ]; then
        error "Rapport validation QA non trouvé. RASTAPOPOULOS a-t-il terminé l'analyse?"
    fi

    success "Prérequis validés"
}

# Lire le verdict depuis le rapport QA
get_verdict() {
    log "Lecture du verdict depuis le rapport QA..."

    # Rechercher SUCCÈS ou ÉCHEC dans le rapport
    if grep -i -q "succès\|success\|validé\|ok\|réussi" "$RAPPORT_QA"; then
        if ! grep -i -q "échec\|failed\|erreur\|error\|ko" "$RAPPORT_QA"; then
            echo "SUCCES"
            return
        fi
    fi

    if grep -i -q "échec\|failed\|erreur\|error\|ko" "$RAPPORT_QA"; then
        echo "ECHEC"
        return
    fi

    # Verdict indéterminé
    echo "INDETERMINE"
}

# Générer métadonnées mission
generate_metadata() {
    local verdict=$1
    log "Génération des métadonnées mission..."

    cat > "$WORK_DIR/metadonnees_mission.json" << EOF
{
  "mission_id": "$MISSION_ID",
  "sprint": "$SPRINT",
  "date_execution": "$(date +%Y-%m-%d)",
  "timestamp_archivage": "$(date -Iseconds)",
  "agent_executeur": "mono-os",
  "protocol": "Colis Scelle",
  "cid": "$CID",
  "verdict": "$verdict",
  "equipe": "TMUX",
  "certificateur": "RASTAPOPOULOS",
  "archiviste": "TOURNESOL2",
  "fichiers": {
    "log_preuve": "sprint20_proof.log",
    "rapport_qa": "$(basename "$RAPPORT_QA")",
    "taille_log": "$(stat -f%z sprint20_proof.log 2>/dev/null || stat -c%s sprint20_proof.log 2>/dev/null || echo 'N/A')",
    "checksum_log": "$(shasum -a 256 sprint20_proof.log | cut -d' ' -f1)"
  }
}
EOF

    success "Métadonnées générées"
}

# Archivage en cas de succès
archive_success() {
    log "Procédure d'archivage SUCCÈS..."

    # Créer répertoire archives
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$WORK_DIR"

    # Copier les fichiers
    cp "sprint20_proof.log" "$WORK_DIR/"
    cp "$RAPPORT_QA" "$WORK_DIR/rapport_validation_qa.md"

    # Générer résumé certification
    cat > "$WORK_DIR/certification_succes.md" << EOF
# CERTIFICATION SUCCÈS - SPRINT 20

**Mission:** $MISSION_ID
**Protocol:** Colis Scellé
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**CID:** $CID

## Résumé

La mission de certification de l'architecture mono-os a été **RÉUSSIE**.
L'agent mono-os a exécuté avec succès toutes les instructions de la mission VOL_SOLO
selon le protocole Colis Scellé.

## Validation QA

Rapport de validation par RASTAPOPOULOS confirme le SUCCÈS de la mission.
Tous les critères de certification ont été satisfaits.

## Archivage

Documents archivés le $(date +"%Y-%m-%d %H:%M:%S") par TOURNESOL2.
Archive: sprint20_certification_SUCCES_$DATE_EXEC.tar.gz

---
**CERTIFICATION VALIDÉE - ARCHITECTURE MONO-OS PRODUCTION READY**
EOF

    # Générer métadonnées
    generate_metadata "SUCCES"

    # Créer archive
    cd "$WORK_DIR"
    tar -czf "$ARCHIVE_DIR/sprint20_certification_SUCCES_$DATE_EXEC.tar.gz" *
    cd - > /dev/null

    # Nettoyer
    rm -rf "$WORK_DIR"

    success "Archivage SUCCÈS terminé: $ARCHIVE_DIR/sprint20_certification_SUCCES_$DATE_EXEC.tar.gz"

    # Notification
    log "Notification RASTAPOPOULOS..."
    echo "ARCHIVÉ - Sprint 20 Certification SUCCÈS - Archive: sprint20_certification_SUCCES_$DATE_EXEC.tar.gz"
}

# Transmission en cas d'échec
transmit_failure() {
    log "Procédure de transmission ÉCHEC..."

    mkdir -p "$WORK_DIR"

    # Copier les fichiers
    cp "sprint20_proof.log" "$WORK_DIR/"
    cp "$RAPPORT_QA" "$WORK_DIR/rapport_validation_qa.md"

    # Analyser les causes d'échec
    cat > "$WORK_DIR/analyse_echec_postmortem.md" << EOF
# ANALYSE POST-MORTEM - ÉCHEC SPRINT 20

**Mission:** $MISSION_ID
**Protocol:** Colis Scellé
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**CID:** $CID

## Résumé Échec

La mission de certification de l'architecture mono-os a **ÉCHOUÉ**.
Analyse post-mortem requise pour identifier les causes racines.

## Analyse Log Technique

$(log "Analyse automatique du log d'échec...")
$(grep -i "error\|fail\|exception\|timeout" sprint20_proof.log | head -10 || echo "Aucune erreur explicite détectée dans le log")

## Rapport QA

Le rapport de validation QA de RASTAPOPOULOS indique un ÉCHEC.
Voir rapport_validation_qa.md pour détails techniques.

## Recommandations Immédiates

1. Révision du code agent mono-os
2. Validation des instructions MISSION_VOL_SOLO
3. Test protocole Colis Scellé en environnement isolé
4. Vérification intégrité base Oracle

---
**TRANSMISSION À ARCHITECTE REQUISE**
EOF

    # Générer recommandations
    cat > "$WORK_DIR/recommandations_correctifs.md" << EOF
# RECOMMANDATIONS CORRECTIFS - SPRINT 20

## Actions Correctives Prioritaires

### 1. Diagnostic Technique
- [ ] Analyser sprint20_proof.log ligne par ligne
- [ ] Vérifier logs système mono-os
- [ ] Contrôler intégrité Oracle MISSION_VOL_SOLO

### 2. Tests de Régression
- [ ] Re-exécuter MISSION_VOL_SOLO en mode debug
- [ ] Valider protocole Colis Scellé isolément
- [ ] Tester agent mono-os sur mission simple

### 3. Validation Architecture
- [ ] Audit architecture mono-os complète
- [ ] Revue code critique agent autonome
- [ ] Validation environnement d'exécution

## Équipe de Correction Suggérée

- **Architecte mono-os** (lead)
- **TOURNESOL1** (exécution)
- **NESTOR** (Oracle)
- **RASTAPOPOULOS** (QA)

---
**CORRECTION URGENTE REQUISE AVANT DÉPLOIEMENT PRODUCTION**
EOF

    # Générer métadonnées
    generate_metadata "ECHEC"

    success "Dossier post-mortem préparé: $WORK_DIR"

    # Notification pour transmission
    log "Notification HADDOCK pour escalade Architecte..."
    echo "TRANSMIS - Sprint 20 Certification ÉCHEC - Dossier post-mortem: $WORK_DIR"
    echo "ESCALADE ARCHITECTE REQUISE"
}

# Main
main() {
    log "Démarrage script archivage Sprint 20..."

    check_prerequisites

    VERDICT=$(get_verdict)
    log "Verdict détecté: $VERDICT"

    case $VERDICT in
        "SUCCES")
            archive_success
            ;;
        "ECHEC")
            transmit_failure
            ;;
        "INDETERMINE")
            error "Verdict indéterminé dans le rapport QA. Vérification manuelle requise."
            ;;
        *)
            error "Verdict non reconnu: $VERDICT"
            ;;
    esac

    success "Script archivage Sprint 20 terminé"
}

# Exécuter seulement si lancé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi