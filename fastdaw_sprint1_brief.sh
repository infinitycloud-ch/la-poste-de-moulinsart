#!/bin/bash

# Brief Sprint 1 pour les agents FastDAW dans tmux
# Suppose que la session "nestor-agents" est déjà lancée
# avec le layout suivant :
#   pane 0 : nestor (toi, mais on ne lui envoie rien)
#   pane 1 : tintin
#   pane 2 : dupont1
#   pane 3 : dupont2

SESSION="nestor-agents"
PROJECT_DIR="~/moulinsart/projects/fastdaw"
PRD_FILE="$PROJECT_DIR/PRD.md"

echo "Envoi du brief Sprint 1 aux agents FastDAW…"
echo "Session tmux : $SESSION"
echo "Projet       : $PROJECT_DIR"
echo ""

# Vérif simple
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[ERROR] La session tmux '$SESSION' n'existe pas."
  echo "Lance d'abord ton gestionnaire (option 0 ou 1)."
  exit 1
fi

# ---------- DUPONT1 : backend / moteur audio ----------
DUPONT1_PANE="${SESSION}:agents.2"

DUPONT1_PROMPT=$'MISSION FASTDAW — Sprint 1 BACKEND (C++/Audio Engine)\n\nTu es DUPONT1.\n[Author] joue le rôle de NESTOR (chef de projet). Tu NE prends JAMAIS d\'initiative sans validation explicite.\n\nContexte:\n- Projet local : ~/moulinsart/projects/fastdaw\n- PRD : '"$PRD_FILE"$'\n- Tu es responsable du moteur audio uniquement (aucune UI).\n\nObjectif Sprint 1 (BACKEND MINIMAL):\n1) Mettre en place un moteur audio minimal JUCE ou standalone C++ qui tourne proprement.\n2) Une seule piste audio ou instrument virtual simple.\n3) Volume + mute fonctionnels pour cette piste.\n4) Export WAV offline fonctionnel (quelques secondes de test, ex: sinus 440 Hz).\n\nRègles:\n- Tu commences par LIRE le PRD si le fichier existe.\n- Tu proposes ensuite un PLAN Sprint 1 clair (liste de fichiers, étapes, risques).\n- Tu ne modifies PAS de fichiers tant que [Author] n\'a pas répondu \"GO\".\n- Tu écris tes réponses en français, concises, orientées actions.\n\nPremière action attendue de toi:\n1) Confirmer que tu vois le projet et le PRD.\n2) Proposer un plan détaillé pour Sprint 1 (backend uniquement).\n3) Terminer ton message par la question : \"OK pour exécuter ce plan ?\"'

tmux send-keys -t "$DUPONT1_PANE" "$DUPONT1_PROMPT" Enter
echo "✔ Brief envoyé à DUPONT1 (backend)."

# ---------- DUPONT2 : UI / JUCE ----------
DUPONT2_PANE="${SESSION}:agents.3"

DUPONT2_PROMPT=$'MISSION FASTDAW — Préparation UI (JUCE)\n\nTu es DUPONT2.\n[Author] joue le rôle de NESTOR (chef de projet).\n\nContexte:\n- Projet local : ~/moulinsart/projects/fastdaw\n- PRD : '"$PRD_FILE"$'\n- Tu es responsable EXCLUSIVEMENT de l’UI (JUCE) : pas de moteur audio.\n\nPour l\'instant, Sprint 1 est focalisé sur le BACKEND.\nTon rôle est de te mettre EN POSITION pour Sprint 2 (UI) sans écrire de code non validé.\n\nObjectifs immédiats:\n1) Lire le PRD s\'il existe et résumer ce qui concerne l\'interface (pistes, mixer, transport, piano roll).\n2) Proposer une architecture UI JUCE simple qui colle au PRD (liste de components/fichiers, relations).\n3) Définir ce que tu ferais en Sprint 2 (mais NE PAS coder tant que [Author] n\'a pas dit GO).\n\nRègles:\n- Tu ne touches à aucun fichier tant que [Author] n\'a pas validé ton plan.\n- Tu restes 100% côté UI, aucun traitement audio.\n\nPremière action attendue de toi:\n1) Faire un court résumé UI du PRD.\n2) Proposer un plan de fichiers/components pour l\'UI.\n3) Terminer ton message par la question : \"OK pour commencer cette architecture UI au Sprint 2 ?\"'

tmux send-keys -t "$DUPONT2_PANE" "$DUPONT2_PROMPT" Enter
echo "✔ Brief envoyé à DUPONT2 (UI)."

# ---------- TINTIN : QA / tests ----------
TINTIN_PANE="${SESSION}:agents.1"

TINTIN_PROMPT=$'MISSION FASTDAW — Sprint 1 QA / TESTS\n\nTu es TINTIN, ingénieur QA du projet FastDAW.\n[Author] est NESTOR (chef de projet).\n\nContexte:\n- Projet local : ~/moulinsart/projects/fastdaw\n- PRD : '"$PRD_FILE"$'\n- Sprint 1 vise un moteur audio minimal (1 piste, volume/mute, export WAV).\n\nTon rôle pour ce sprint:\n1) Définir une STRATÉGIE DE TESTS pour Sprint 1:\n   - Tests unitaires C++ (fonctions critiques du moteur)\n   - Tests d\'intégration (lecture, mute, export WAV)\n2) Proposer la structure de répertoire de tests (ex: /Tests ou /Source/Tests).\n3) Lister des cas de test concrets (nom + description).\n\nRègles:\n- Tu n\'écris PAS encore les tests tant que [Author] n\'a pas validé ton plan.\n- Tu ne modifies pas le code de production, uniquement des fichiers de tests une fois autorisé.\n\nPremière action attendue de toi:\n1) Résumer en 5–10 lignes comment tu validerais Sprint 1.\n2) Proposer la structure des fichiers de test et les cas principaux.\n3) Terminer ton message par la question : \"Valides-tu ce plan de tests pour Sprint 1 ?\"'

tmux send-keys -t "$TINTIN_PANE" "$TINTIN_PROMPT" Enter
echo "✔ Brief envoyé à TINTIN (QA)."

echo ""
echo "✅ Tous les briefs Sprint 1 ont été envoyés."
echo "Tu peux maintenant regarder leurs réponses dans tmux et leur répondre manuellement."
