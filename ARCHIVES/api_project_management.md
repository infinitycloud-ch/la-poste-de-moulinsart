# 📡 API MOULINSART ORACLE - DOCUMENTATION AGENTS V2
## 🚀 SPRINT MANAGEMENT DASHBOARD OPTIMISÉ

## 🎯 BASE URL
```
http://localhost:3001/api
```

## 🔐 AUTHENTIFICATION
Aucune authentification requise - réseau local uniquement

---

## 📋 GESTION DES PROJETS

### 📊 Lister tous les projets avec PRD
```bash
GET /api/projects
```

**Réponse:**
```json
[
  {
    "id": 20,
    "name": "InfinityCloud CLI prd",
    "path": "InfinityCloud_CLI_prd.md",
    "created_at": "2025-09-21 20:05:37",
    "last_active": "2025-09-21 20:05:37",
    "prd": "InfinityCloud_CLI_prd.md"
  }
]
```

### 🔍 Obtenir un projet spécifique
```bash
GET /api/projects/{id}
```

### ➕ Créer un nouveau projet avec PRD
```bash
POST /api/projects
Content-Type: application/json

{
  "name": "Nom du projet",
  "path": "fichier.md",
  "prd": "contenu_du_prd.md",
  "prd_content": "Contenu markdown du PRD..."
}
```

---

## 🎯 GESTION DES SPRINTS

### 📊 Structure Sprint
Chaque tâche appartient à un sprint. Le dashboard utilise le système de sprints pour organiser le travail en cycles.

**Sprints par défaut:**
- `Sprint 1` : MVP - Architecture et fonctionnalités de base
- `Sprint 2` : Intégration et tests complets
- `Sprint 3` : Optimisation et déploiement

---

## 📝 GESTION DES TÂCHES - FORMAT SPRINT DASHBOARD

### 📋 Lister les tâches d'un projet
```bash
GET /api/projects/{project_id}/tasks
```

### ➕ Créer une nouvelle tâche (NOUVEAU FORMAT)
```bash
POST /api/tasks
Content-Type: application/json

{
  "title": "Implémenter fonction de login",
  "description": "Créer le système d'authentification avec JWT",
  "project_id": 20,
  "status": "TODO",
  "priority": "high",
  "assigned_to": "dupont1",
  "sprint": "Sprint 1"
}
```

**⚠️ IMPORTANT - NOUVEAUX STATUTS DASHBOARD:**
- **Statuts:** `TODO`, `IN_PROGRESS`, `DONE` (en MAJUSCULES)
- **Priorités:** `low`, `medium`, `high`, `urgent`
- **Agents:** `nestor`, `tintin`, `dupont1`, `dupont2`
- **Sprints:** `Sprint 1`, `Sprint 2`, `Sprint 3`

### ✏️ Mettre à jour une tâche
```bash
PUT /api/tasks/{task_id}
Content-Type: application/json

{
  "status": "IN_PROGRESS",
  "assigned_to": "tintin",
  "sprint": "Sprint 1",
  "notes": "Travail en cours, 50% terminé"
}
```

### 🗑️ Supprimer une tâche
```bash
DELETE /api/tasks/{task_id}
```

---

## 🤖 WORKFLOW NESTOR - DIVISION PRD EN SPRINTS

### 🎯 Workflow recommandé pour Nestor

1. **Récupérer le projet et PRD**
2. **Analyser et diviser en sprints logiques**
3. **Créer les tâches avec répartition sprint**
4. **Assigner selon les compétences**

### 🎩 NESTOR - Pattern de création optimisé Sprint Dashboard

```bash
# 1. Récupérer le projet
PROJECT_ID=20
curl http://localhost:3001/api/projects/$PROJECT_ID

# 2. Créer tâches Sprint 1 (MVP)
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Setup architecture base",
    "description": "Initialiser structure projet avec dépendances essentielles",
    "project_id": 20,
    "status": "TODO",
    "priority": "high",
    "assigned_to": "dupont1",
    "sprint": "Sprint 1"
  }'

curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Système authentification",
    "description": "Implémentation JWT et gestion sessions",
    "project_id": 20,
    "status": "TODO",
    "priority": "high",
    "assigned_to": "dupont2",
    "sprint": "Sprint 1"
  }'

# 3. Créer tâches Sprint 2 (Intégration)
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tests intégration",
    "description": "Tests end-to-end et validation fonctionnelle",
    "project_id": 20,
    "status": "TODO",
    "priority": "medium",
    "assigned_to": "tintin",
    "sprint": "Sprint 2"
  }'

# 4. Créer tâches Sprint 3 (Déploiement)
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Déploiement production",
    "description": "Configuration serveurs et mise en production",
    "project_id": 20,
    "status": "TODO",
    "priority": "low",
    "assigned_to": "nestor",
    "sprint": "Sprint 3"
  }'
```

---

## 🎨 GESTION PAR AGENTS - SPÉCIALISATIONS

### 🎩 NESTOR - Chef d'orchestre
```bash
# Voir vue globale projet
curl "http://localhost:3001/api/projects/20/tasks"

# Superviser tous les sprints
curl "http://localhost:3001/api/tasks?project_id=20"
```

### 🚀 TINTIN - QA Lead
```bash
# Voir mes tâches
curl "http://localhost:3001/api/tasks?assigned_to=tintin"

# Focus Sprint 2 (tests)
curl "http://localhost:3001/api/tasks?assigned_to=tintin&sprint=Sprint 2"

# Marquer test terminé
curl -X PUT http://localhost:3001/api/tasks/15 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "DONE",
    "notes": "Tests passés - validation OK"
  }'
```

### 🎨 DUPONT1 - Développeur Swift
```bash
# Voir mes tâches développement
curl "http://localhost:3001/api/tasks?assigned_to=dupont1"

# Commencer tâche Sprint 1
curl -X PUT http://localhost:3001/api/tasks/12 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "IN_PROGRESS",
    "notes": "Développement architecture en cours"
  }'
```

### 🔍 DUPONT2 - Research & Backend
```bash
# Voir mes tâches recherche
curl "http://localhost:3001/api/tasks?assigned_to=dupont2"

# Terminer recherche
curl -X PUT http://localhost:3001/api/tasks/13 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "DONE",
    "notes": "Documentation API terminée"
  }'
```

---

## 🎯 DASHBOARD SPRINT MANAGEMENT - FONCTIONNALITÉS

### 🖥️ Interface Unifiée 3 Panneaux
Le dashboard offre une vue en temps réel avec :

1. **Panneau Sprint (20%)** : Liste sprints + progression
2. **Panneau Kanban (60%)** : TODO/IN_PROGRESS/DONE du sprint sélectionné
3. **Panneau Workload (20%)** : Répartition agents + filtres

### 🎨 Code Couleur Agents
- 🎩 **Nestor** : Violet (#9C27B0)
- 🚀 **Tintin** : Orange (#FF9800)
- 🎨 **Dupont1** : Bleu (#2196F3)
- 🔍 **Dupont2** : Vert (#4CAF50)

### 🔄 Interactions Dashboard
- **Clic tâche Workload** → Highlight + scroll Kanban
- **Clic nom agent** → Filtre temporaire Kanban
- **Cases à cocher** → Multi-filtrage agents
- **Progression temps réel** → Mise à jour automatique

---

## 🔄 RÈGLES D'INTERACTION SPRINT DASHBOARD

### ✅ FAIRE
- **Utiliser statuts MAJUSCULES** : `TODO`, `IN_PROGRESS`, `DONE`
- **Assigner sprint logique** : Sprint 1 = MVP, Sprint 2 = Tests, Sprint 3 = Deploy
- **Respecter code couleur agents** dans communications
- **Mettre à jour régulièrement** le statut des tâches
- **Utiliser priorités cohérentes** selon l'urgence sprint

### ❌ NE PAS FAIRE
- **Statuts minuscules** : ~~`todo`~~ → `TODO`
- **Sprints incohérents** : Respecter la logique MVP→Tests→Deploy
- **Agents inexistants** : Seulement nestor, tintin, dupont1, dupont2
- **Oublier le sprint** : Toujours spécifier le sprint de la tâche

---

## 📊 MÉTRIQUES ET SUIVI

### 🎯 Progression Sprint
```bash
# Voir progression Sprint 1
curl "http://localhost:3001/api/tasks?sprint=Sprint 1"

# Compter tâches terminées
curl "http://localhost:3001/api/tasks?sprint=Sprint 1&status=DONE"
```

### 👥 Charge Agents
```bash
# Workload Dupont1
curl "http://localhost:3001/api/tasks?assigned_to=dupont1&status=IN_PROGRESS"

# Toutes tâches Tintin
curl "http://localhost:3001/api/tasks?assigned_to=tintin"
```

---

## 🚨 GESTION D'ERREURS

### Codes de retour
- `200` : Succès
- `404` : Ressource non trouvée
- `400` : Données invalides (mauvais statut/sprint/agent)
- `409` : Conflit (projet existe déjà)
- `500` : Erreur serveur

### Exemple d'erreur statut
```json
{
  "error": "Invalid status. Use: TODO, IN_PROGRESS, DONE",
  "code": 400
}
```

---

## 📞 SUPPORT ET MONITORING

### Health Check
```bash
curl http://localhost:3001/health
```

### Interface Web Dashboard
```
http://localhost:5175 - Sprint Dashboard
http://localhost:1080 - Mail Web Interface
```

### 🎯 Objectif Final
Un système Sprint Management complet où :
- **Nestor** orchestre la division PRD → Sprints → Tâches
- **Agents** travaillent sur leurs tâches assignées par sprint
- **Dashboard** offre vue temps réel avec navigation fluide
- **API** maintient cohérence données et interactions

---

## 🚀 READY FOR NESTOR

Cette API est optimisée pour le nouveau **Sprint Management Dashboard** avec :
✅ Statuts harmonisés (TODO/IN_PROGRESS/DONE)
✅ Système sprints intégré
✅ Code couleur agents
✅ Interactions dashboard fluides
✅ Métriques temps réel

**Nestor peut maintenant utiliser cette API pour créer des projets organisés en sprints avec tâches assignées selon les compétences de chaque agent.**
