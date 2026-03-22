# 🎩 Tutoriel MCP pour Nestor - Gestion des PRD

## 🎯 Objectif
Ce tutoriel explique à Nestor comment utiliser les commandes MCP pour récupérer un PRD et le splitter en tâches pour les différents agents.

## 🔄 Workflow PRD (Manuel)
1. **Information de [Author]** : Tu es informé qu'un PRD est attaché à un projet
2. **Récupération PRD** : Tu utilises les APIs MCP pour récupérer le contenu du PRD
3. **Analyse et splitting** : Tu analyses le PRD et crées les tâches appropriées
4. **Assignment manuel** : Tu assignes manuellement chaque tâche aux agents appropriés
5. **Notifications tmux** : Les agents reçoivent automatiquement leurs nouvelles tâches
6. **Suivi temps réel** : Tout le monde voit les tâches se déplacer (TODO → IN_PROGRESS → DONE)

## 📡 API Endpoints MCP Disponibles

### 1. Récupérer le PRD d'un projet
```bash
curl -X GET http://localhost:3001/api/mcp/projects/{PROJECT_ID}/prd
```

**Réponse :**
```json
{
  "project_name": "Nom du projet",
  "prd_content": "Contenu complet du PRD..."
}
```

### 2. Créer une tâche
```bash
curl -X POST http://localhost:3001/api/mcp/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Titre de la tâche",
    "description": "Description détaillée",
    "project_id": 1,
    "assigned_to": "tintin",
    "priority": "high",
    "estimated_hours": 8,
    "tags": "ios,swift,ui",
    "checkboxes": [
      {"label": "Interface utilisateur créée", "required": true},
      {"label": "Tests unitaires écrits", "required": true}
    ]
  }'
```

**Réponse :**
```json
{
  "success": true,
  "task_id": 42,
  "message": "Task \"Titre de la tâche\" created and assigned to tintin"
}
```

## 🧠 Guide d'analyse PRD

### Étapes d'analyse :
1. **Identifier les features principales** du PRD
2. **Décomposer en tâches atomiques** (1-3 jours max)
3. **Assigner selon les compétences** :
   - 🚀 **Tintin** : QA, tests, validation
   - 🎨 **Dupont1** : Développement Swift/iOS
   - 🔍 **Dupont2** : Recherche, documentation, analyse

### Patterns de tâches typiques :

#### Pour les features UI/UX :
```json
{
  "title": "Créer l'interface [Feature Name]",
  "assigned_to": "dupont1",
  "priority": "high",
  "checkboxes": [
    {"label": "Mockups créés", "required": true},
    {"label": "Interface implémentée", "required": true},
    {"label": "Tests sur 3+ langues", "required": true}
  ]
}
```

#### Pour les tests et validation :
```json
{
  "title": "Tests et validation [Feature Name]",
  "assigned_to": "tintin",
  "priority": "medium",
  "checkboxes": [
    {"label": "Tests unitaires écrits", "required": true},
    {"label": "Tests d'intégration OK", "required": true},
    {"label": "Validation multi-langues", "required": true}
  ]
}
```

#### Pour la recherche et doc :
```json
{
  "title": "Documentation et recherche [Feature Name]",
  "assigned_to": "dupont2",
  "priority": "low",
  "checkboxes": [
    {"label": "Recherche des solutions", "required": true},
    {"label": "Documentation mise à jour", "required": true},
    {"label": "Exemples de code fournis", "required": true}
  ]
}
```

## 🎯 Exemples pratiques

### Exemple 1 : PRD pour une app de expenses
```bash
# 1. Récupérer le PRD
curl -X GET http://localhost:3001/api/mcp/projects/1/prd

# 2. Créer les tâches basées sur l'analyse
curl -X POST http://localhost:3001/api/mcp/tasks -d '{
  "title": "Créer l'\''écran de scan de reçus",
  "description": "Implémenter la fonctionnalité de scan OCR pour les reçus",
  "project_id": 1,
  "assigned_to": "dupont1",
  "priority": "high",
  "estimated_hours": 16,
  "tags": "ios,ocr,camera"
}'

curl -X POST http://localhost:3001/api/mcp/tasks -d '{
  "title": "Tests automatisés du scan OCR",
  "description": "Créer une suite de tests pour valider la précision OCR",
  "project_id": 1,
  "assigned_to": "tintin",
  "priority": "medium",
  "estimated_hours": 8,
  "tags": "testing,ocr,automation"
}'
```

## 💡 Conseils pour Nestor

### 🎯 Bonnes pratiques :
1. **Toujours lire le PRD complet** avant de créer les tâches
2. **Créer des tâches atomiques** : 1 feature = plusieurs petites tâches
3. **Équilibrer la charge** entre les agents
4. **Prioriser logiquement** : UI d'abord, puis tests, puis documentation
5. **Ajouter des checkboxes spécifiques** selon le type de tâche

### ⚠️ Pièges à éviter :
- Tâches trop grosses (>3 jours)
- Oublier les validations multilingues
- Ne pas assigner de tests à Tintin
- Créer des dépendances circulaires

### 🔄 Processus recommandé :
1. Lire le PRD et identifier les features
2. Dessiner un plan mental des dépendances
3. Créer les tâches dans l'ordre logique :
   - Infrastructure/architecture (Dupont1)
   - Features core (Dupont1)
   - Tests et validation (Tintin)
   - Documentation (Dupont2)
   - Polish et optimisation (Dupont1)

## 🛠️ Templates de tâches

### Template Feature Development
```bash
curl -X POST http://localhost:3001/api/mcp/tasks -d '{
  "title": "Développer [FEATURE_NAME]",
  "description": "[DESCRIPTION_DETAILLEE]",
  "project_id": [PROJECT_ID],
  "assigned_to": "dupont1",
  "priority": "high",
  "estimated_hours": [ESTIMATION],
  "tags": "ios,swift,feature",
  "checkboxes": [
    {"label": "Code implémenté", "required": true},
    {"label": "Interface utilisateur terminée", "required": true},
    {"label": "Build réussi", "required": true},
    {"label": "Tests manuels OK", "required": true}
  ]
}'
```

### Template QA Testing
```bash
curl -X POST http://localhost:3001/api/mcp/tasks -d '{
  "title": "Tests QA [FEATURE_NAME]",
  "description": "Tests complets et validation pour [FEATURE_NAME]",
  "project_id": [PROJECT_ID],
  "assigned_to": "tintin",
  "priority": "medium",
  "estimated_hours": [ESTIMATION],
  "tags": "testing,qa,validation",
  "checkboxes": [
    {"label": "Tests unitaires écrits", "required": true},
    {"label": "Tests d'\''intégration OK", "required": true},
    {"label": "Tests multilingues (FR/EN/ES)", "required": true},
    {"label": "Rapport de test créé", "required": true}
  ]
}'
```

### Template Research & Documentation
```bash
curl -X POST http://localhost:3001/api/mcp/tasks -d '{
  "title": "Recherche et documentation [FEATURE_NAME]",
  "description": "Recherche des meilleures pratiques et documentation",
  "project_id": [PROJECT_ID],
  "assigned_to": "dupont2",
  "priority": "low",
  "estimated_hours": [ESTIMATION],
  "tags": "research,documentation",
  "checkboxes": [
    {"label": "Recherche technologique terminée", "required": true},
    {"label": "Documentation technique écrite", "required": true},
    {"label": "Exemples de code fournis", "required": true},
    {"label": "Guide utilisateur mis à jour", "required": true}
  ]
}'
```

## 🚀 Script automatisé exemple

Voici un exemple de script que tu peux adapter :

```bash
#!/bin/bash
# nestor-prd-splitter.sh

PROJECT_ID=$1
BASE_URL="http://localhost:3001/api/mcp"

echo "🎩 Nestor - Récupération du PRD pour projet $PROJECT_ID"

# Récupérer le PRD
PRD_RESPONSE=$(curl -s "$BASE_URL/projects/$PROJECT_ID/prd")
PROJECT_NAME=$(echo $PRD_RESPONSE | jq -r '.project_name')
PRD_CONTENT=$(echo $PRD_RESPONSE | jq -r '.prd_content')

echo "📋 PRD récupéré pour: $PROJECT_NAME"
echo "📝 Contenu: ${PRD_CONTENT:0:100}..."

# Analyser et créer les tâches
# (Tu adaptes cette partie selon le contenu du PRD)

echo "✅ Tâches créées avec succès!"
```

## 📞 Support et aide

Si tu as des questions ou des problèmes :
1. Vérifier que le serveur Oracle est bien sur le port 3001
2. Tester les endpoints avec curl avant d'utiliser dans le code
3. Regarder les logs du serveur en cas d'erreur
4. Les réponses d'API incluent toujours un message d'erreur explicite

**Remember:** Tu es le chef d'orchestre ! 🎩✨