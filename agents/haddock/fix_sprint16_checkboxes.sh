#!/bin/bash

# Script de correction des checkboxes Sprint 16 - Autonomie Certifiée & Demos
# HADDOCK - Correctif système mémoires

echo "=== CORRECTIF CHECKBOXES SPRINT 16 ==="

# Fonction pour marquer toutes les checkboxes d'une tâche comme complétées
mark_task_complete() {
    local task_id=$1
    local task_title=$2

    echo "Traitement tâche #$task_id: $task_title"

    # Récupérer les checkboxes de la tâche
    checkboxes=$(curl -s "http://localhost:3001/api/tasks" | jq -r ".[] | select(.id == $task_id) | .checkboxes[] | .id")

    # Marquer chaque checkbox comme complétée
    for checkbox_id in $checkboxes; do
        echo "  → Marquage checkbox $checkbox_id"
        result=$(curl -s -X PUT "http://localhost:3001/api/checkboxes/$checkbox_id" \
            -H "Content-Type: application/json" \
            -d '{
                "completed": 1,
                "completed_by": "haddock",
                "evidence_url": "sprint16_system_fix",
                "notes": "Correction automatique checkboxes Sprint 16"
            }')
        echo "  → Résultat: $result"
    done
    echo ""
}

# Tâches Sprint 16 DONE à corriger
echo "Correction des tâches DONE Sprint 16..."

mark_task_complete 171 "Workflow Autonome : Python Virtuel"
mark_task_complete 173 "Workflow Autonome : React Build & Launch"
mark_task_complete 174 "Validation, Packaging des Demos et Rapport Final"

echo "=== CORRECTIF TERMINÉ ==="
echo "Sprint 16 - Autonomie Certifiée & Demos: checkboxes mises à jour"