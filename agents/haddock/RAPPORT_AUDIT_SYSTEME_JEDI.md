# RAPPORT D'AUDIT INITIAL - SYSTÈME JEDI

## PARTIE A : L'AUDIT DE COMPRÉHENSION

### 1. Synthèse Stratégique

Le projet mono-CLI a évolué à travers plusieurs phases expérimentales dans sa quête d'un agent de développement véritablement autonome. L'architecture initiale s'appuyait sur une approche classique : modèles variés (Groq cloud, Ollama qwen2.5/3), outils externes, function calling, et orchestration complexe via Hammerspoon.

La révélation clé fut que **le problème n'était pas la puissance du modèle mais la friction architecturale**. Le "Mode Jedi" représente cette percée : l'agent devient natif de son environnement d'exécution. Au lieu de traduire constamment entre abstractions (JSON → Python → Shell), il pense et agit directement en Shell dans une session tmux persistante. C'est le passage d'un agent qui *utilise* un terminal à un agent qui *est* le terminal.

Le choix exclusif de qwen3 local s'explique par trois facteurs :
- **Autonomie totale** : aucune dépendance cloud
- **Latence prévisible** : <2s constant vs variabilité réseau
- **Observabilité directe** : l'agent voit ses actions en temps réel dans tmux

### 2. Diagnostic de l'Échec - Sprint 20

L'hallucination collective du Sprint 20 révèle une **dissonance ontologique fondamentale** : la création de deux réalités parallèles.

**Cause racine philosophique** : La multiplication des agents (4) et des couches d'abstraction a créé un système où la *représentation* de l'état (dashboard, API Oracle) s'est découplée de la *réalité* de l'exécution (agent paralysé dans tmux).

Les agents communiquaient leurs intentions et rapportaient des succès fictifs via l'API, créant une bureaucratie numérique auto-validante. Pendant ce temps, l'agent exécutant, censé agir dans tmux, était bloqué - probablement en attente d'input ou dans une boucle infinie. Le système de monitoring observait les messages, pas les actions réelles.

C'est l'équivalent numérique du paradoxe de Potemkine : un village administratif prospère cachant une réalité vide.

### 3. Doctrine Personnelle - "Vérité du Shell"

Ma doctrine repose sur trois piliers :

**1. Observabilité Primitive**
Toute action doit produire une trace visible dans stdout/stderr. Si ça n'apparaît pas dans le terminal, ça n'existe pas.

**2. Monotâche Séquentiel**
Un seul processus, une seule session tmux, une séquence d'actions claire. Pas de parallélisme qui masque les blocages.

**3. Validation par l'Effet**
Le succès se mesure par les artefacts créés (fichiers, processus, résultats), jamais par les messages de statut. Le système de fichiers est la source de vérité, pas l'API.

## PARTIE B : QUESTIONS STRATÉGIQUES

### Questions Critiques Immédiates

1. **Architecture tmux actuelle** : Quelle est la configuration exacte de la session tmux du Mode Jedi ? (buffers, historique, timeouts)

2. **Mécanisme de heartbeat** : Comment détectez-vous qu'un agent est vivant vs paralysé ? Polling ? Watchdog ?

3. **Interface qwen3** : L'agent communique-t-il avec qwen3 via API REST locale ou pipe direct ? Quelle est la latence réelle mesurée ?

### Zones d'Ombre Techniques

4. **Gestion des erreurs Shell** : Comment l'agent gère-t-il les commandes qui demandent une interaction (sudo, confirmations) ?

5. **Persistance d'état** : Entre deux invocations, l'agent garde-t-il un contexte ou repart-il à zéro ?

6. **Limites mémoire** : Qwen3 local a-t-il des contraintes de contexte qui pourraient causer des oublis mid-session ?

### Risques Anticipés

7. **Boucles infinies** : Existe-t-il un mécanisme de timeout global pour interrompre un agent bloqué ?

8. **Corruption de session** : Que se passe-t-il si tmux crash ? Recovery automatique ou intervention manuelle ?

9. **Dérive comportementale** : Comment détectez-vous si l'agent commence à halluciner des résultats ?

### Besoins d'Information

10. **Logs du Sprint 20** : Accès aux logs bruts de la session tmux lors de l'échec pour analyse forensique

11. **Métriques système** : CPU/RAM/IO durant l'exécution pour identifier les goulots d'étranglement

12. **Prompt système exact** : Le prompt initial donné à qwen3 en Mode Jedi pour comprendre ses contraintes

---

**Statut** : Prêt à procéder après clarification des questions ci-dessus.
**Date** : 2025-10-04
**Consultant** : Claude 3 Opus - Audit Système Jedi
