# 📡 API MOULINSART ORACLE - DOCUMENTATION AGENTS

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

**Exemple:**
```bash
curl http://localhost:3001/api/projects/20
```

**Réponse:**
```json
{
  "project": {
    "id": 20,
    "name": "InfinityCloud CLI prd",
    "path": "InfinityCloud_CLI_prd.md",
    "prd": "InfinityCloud_CLI_prd.md",
    "created_at": "2025-09-21 20:05:37",
    "last_active": "2025-09-21 20:05:37"
  }
}
```

---

## 📝 GESTION DES TÂCHES

### 📋 Lister les tâches d'un projet
```bash
GET /api/projects/{project_id}/tasks
```

**Exemple:**
```bash
curl http://localhost:3001/api/projects/20/tasks
```

### ➕ Créer une nouvelle tâche
```bash
POST /api/tasks
Content-Type: application/json

{
  "title": "Implémenter fonction de login",
  "description": "Créer le système d'authentification avec JWT",
  "project_id": 20,
  "status": "todo",
  "priority": "high",
  "assigned_to": "dupont1"
}
```

**Statuts possibles:** `todo`, `in_progress`, `done`, `blocked`
**Priorités:** `low`, `medium`, `high`, `urgent`

### ✏️ Mettre à jour une tâche
```bash
PUT /api/tasks/{task_id}
Content-Type: application/json

{
  "status": "in_progress",
  "assigned_to": "tintin",
  "notes": "Travail en cours, 50% terminé"
}
```

### 🗑️ Supprimer une tâche
```bash
DELETE /api/tasks/{task_id}
```

---

## 🤖 WORKFLOW NESTOR - DIVISION PRD EN TÂCHES

### 🎯 API spéciale pour Nestor
```bash
POST /api/projects/{project_id}/split-prd
Content-Type: application/json

{
  "agent": "nestor",
  "action": "split_to_tasks"
}
```

**Utilisation par Nestor:**
1. Récupérer le projet et son PRD
2. Analyser le contenu du PRD
3. Créer les tâches avec l'API POST /api/tasks
4. Assigner aux agents appropriés

---

## 📊 EXEMPLES PRATIQUES POUR AGENTS

### 🎩 NESTOR - Créer des tâches depuis un PRD
```bash
# 1. Récupérer le projet
PROJECT_ID=20
curl http://localhost:3001/api/projects/$PROJECT_ID

# 2. Créer les tâches
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Setup base architecture",
    "description": "Initialiser la structure du projet CLI",
    "project_id": 20,
    "status": "todo",
    "priority": "high",
    "assigned_to": "dupont1"
  }'

curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Implement login system",
    "description": "Système d authentification JWT",
    "project_id": 20,
    "status": "todo",
    "priority": "medium",
    "assigned_to": "dupont2"
  }'
```

### 🚀 TINTIN - Gérer ses tâches
```bash
# Voir mes tâches
curl "http://localhost:3001/api/tasks?assigned_to=tintin"

# Commencer une tâche
curl -X PUT http://localhost:3001/api/tasks/15 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in_progress",
    "notes": "Démarrage du développement"
  }'

# Terminer une tâche
curl -X PUT http://localhost:3001/api/tasks/15 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "done",
    "notes": "Implémentation terminée et testée"
  }'
```

### 🎨 DUPONT1 & 🔍 DUPONT2 - Même pattern
```bash
# Récupérer ses tâches assignées
curl "http://localhost:3001/api/tasks?assigned_to=dupont1"
curl "http://localhost:3001/api/tasks?assigned_to=dupont2"

# Mettre à jour le statut
curl -X PUT http://localhost:3001/api/tasks/{task_id} \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'
```

---

## 🔄 RÈGLES D'INTERACTION

### ✅ FAIRE
- Toujours vérifier le `status` de la réponse HTTP
- Mettre à jour `last_active` du projet quand vous travaillez dessus
- Utiliser des descriptions claires pour les tâches
- Assigner les tâches selon les compétences (dupont1=Swift, dupont2=Research, tintin=QA)

### ❌ NE PAS FAIRE
- Ne jamais modifier directement la base de données
- Ne pas créer de tâches sans `project_id`
- Ne pas utiliser de statuts personnalisés
- Ne pas oublier de mettre à jour le statut des tâches

---

## 🚨 GESTION D'ERREURS

### Codes de retour
- `200` : Succès
- `404` : Ressource non trouvée
- `400` : Données invalides
- `409` : Conflit (projet existe déjà)
- `500` : Erreur serveur

### Exemple d'erreur
```json
{
  "error": "Project not found",
  "code": 404
}
```

---

## 📞 SUPPORT
En cas de problème, contacter l'Oracle ou vérifier les logs :
```bash
curl http://localhost:3001/health
```