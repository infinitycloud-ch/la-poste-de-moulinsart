# 🔧 WORKFLOW MonoCLI - EXPLICATION COMPLÈTE
**TOURNESOL1 - Équipe TMUX**

## 🎯 VUE D'ENSEMBLE

MonoCLI utilise un système sophistiqué de **planification séquentielle** avec **détection automatique** des objectifs complexes et **exécution autonome** d'outils.

## 🚀 DÉMARRAGE DU WORKFLOW

### 1. **Initialisation (main.py:185-200)**

Quand `--tools` est activé, MonoCLI initialise :

```python
# Détection backend compatible
if tools and backend in ['groq', 'ollama', 'panda']:
    # Import des composants
    from mono.adapters.tools import ToolExecutor
    from mono.adapters.tools.sequential_executor import SequentialExecutor

    # Initialisation
    tool_executor = ToolExecutor()           # Exécuteur d'outils individuels
    sequential_executor = SequentialExecutor()  # Planificateur séquentiel
    available_tools = tool_executor.get_tools_for_llm()  # 10 outils MonoCLI
```

### 2. **Chargement des Outils (tools.json)**

Le système charge **10 outils MonoCLI** depuis `tools.json` :
```json
{
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "mono_create",
        "description": "Create a file or directory with optional content",
        "parameters": { "path": "string", "content": "string", "directory": "boolean" }
      }
    }
    // + 9 autres outils: mono_edit, mono_read, mono_delete, etc.
  ]
}
```

## 🧠 DÉTECTION AUTOMATIQUE D'OBJECTIFS COMPLEXES

### 3. **Analyse de l'Objectif (main.py:241-262)**

MonoCLI analyse automatiquement si un objectif nécessite la **planification séquentielle** :

```python
def _is_complex_objective(self, user_input: str) -> bool:
    """Détecte si l'objectif nécessite une planification"""
    complex_indicators = [
        "créer", "crée", "développe", "implémente", "génère",
        "application", "projet", "script", "fichier", "code",
        "plusieurs", "étapes", "complet", "système"
    ]

    # Si 2+ indicateurs → Objectif complexe
    return count >= 2
```

**Exemples d'objectifs complexes :**
- ✅ "Crée une application CLI Python compteur de mots"
- ✅ "Développe un script de backup automatique"
- ✅ "Implémente un système de gestion de fichiers"

**Objectifs simples :**
- ❌ "Bonjour, comment ça va ?"
- ❌ "Quelle est la date ?"

## 🎯 WORKFLOWS PARALLÈLES

### A. **WORKFLOW PLANIFICATION SÉQUENTIELLE** (Objectifs complexes)

#### 4a. **Génération du Plan (main.py:262-280)**

```python
if self._is_complex_objective(user_input):
    click.echo("🧠 Objectif complexe détecté - Génération du plan...")

    # 1. Génération du plan via LLM
    plan_response = adapter.chat_stream_with_tools(planning_messages, available_tools, model)

    # 2. Extraction du plan JSON
    plan = sequential_executor.extract_plan_from_response(plan_response)

    # 3. Exécution séquentielle
    execution_result = sequential_executor.execute_plan(plan)
```

#### 4b. **Format du Plan Généré**

Le LLM génère un plan structuré :
```json
{
  "objective": "Créer une application CLI Python compteur de mots",
  "steps": [
    {
      "tool": "mono_create",
      "arguments": {"path": "app", "directory": true},
      "description": "Créer le répertoire de l'application"
    },
    {
      "tool": "mono_create",
      "arguments": {"path": "app/main.py", "content": "# Code Python..."},
      "description": "Créer le fichier principal"
    }
  ]
}
```

#### 4c. **Exécution Séquentielle (sequential_executor.py)**

```python
def execute_plan(self, plan):
    for step_num, step in enumerate(steps, 1):
        click.echo(f"▶ Étape {step_num}: {step['description']}")

        # Exécution de l'outil
        result = self.tool_executor.execute_tool_call({
            'name': step['tool'],
            'arguments': step['arguments']
        })

        if result['success']:
            click.echo(f"  ✅ Succès: {result['result']}")
        else:
            click.echo(f"  ❌ ÉCHEC: {result['error']}")
            return {"success": False, "error": result['error']}
```

### B. **WORKFLOW NORMAL** (Conversations simples)

#### 4b. **Mode Streaming avec Tools Disponibles**

```python
elif tools and tool_executor:
    # Streaming de la réponse avec support tools
    for chunk in adapter.chat_stream_with_tools(messages, available_tools, model):
        if chunk.get('type') == 'content':
            # Affichage en temps réel
            click.echo(chunk.get('data', ''), nl=False)
        elif chunk.get('type') == 'tool_call':
            # Buffer des appels d'outils
            tool_calls_buffer.append(chunk.get('data', {}))

    # Exécution des outils si demandés
    if tool_calls_buffer:
        for tool_call in tool_calls_buffer:
            result = tool_executor.execute_tool_call(tool_call)
```

## 🛠️ SYSTÈME D'OUTILS

### 5. **Exécuteur d'Outils (ToolExecutor)**

```python
class ToolExecutor:
    def execute_tool_call(self, tool_call):
        tool_name = tool_call.get('name', '')

        if tool_name == 'mono_create':
            return self._create_file_or_directory(arguments)
        elif tool_name == 'mono_edit':
            return self._edit_file(arguments)
        # ... autres outils
```

### 6. **10 Outils MonoCLI Disponibles**

1. **`mono_create`** - Créer fichiers/répertoires
2. **`mono_edit`** - Modifier fichiers
3. **`mono_read`** - Lire fichiers
4. **`mono_delete`** - Supprimer
5. **`mono_list`** - Lister répertoires
6. **`mono_move`** - Déplacer/renommer
7. **`mono_copy`** - Copier
8. **`mono_search`** - Rechercher dans fichiers
9. **`mono_execute`** - Exécuter commandes
10. **`mono_analyze`** - Analyser code

## 📡 BACKENDS ET COMPATIBILITÉ

### 7. **Support par Backend**

| Backend | Tools Support | Format | Caractéristiques |
|---------|---------------|--------|-------------------|
| **Groq** | ✅ Natif | OpenAI Function Calling | Ultra rapide |
| **PANDA** | ✅ Via API | Format unifié | 4 modèles locaux |
| **Ollama** | ✅ Simulé | Prompt engineering | Local, gratuit |
| **MLX** | ❌ | - | Complexité API |

### 8. **Communication avec PANDA Portal**

```python
class PandaPortalAdapter:
    def chat_stream_with_tools(self, messages, tools, model):
        payload = {
            "model": self._resolve_model(model),  # qwen3 → deepresearch:latest
            "messages": messages,
            "tools": tools  # 10 outils MonoCLI
        }

        response = requests.post(f"{self.base_url}/api/chat/unified", json=payload)

        # Parsing response PANDA format
        data = response.json()
        content = data.get('response', '') or data.get('content', '')
```

## 🔄 SCRATCHPAD ET MÉMOIRE

### 9. **Système de Scratchpad**

```python
class SequentialExecutor:
    def __init__(self):
        self.scratchpad = ""  # Mémoire d'exécution

    def _log_to_scratchpad(self, message):
        self.scratchpad += f"{message}\\n"

    # Chaque étape est tracée:
    # "🎯 PLAN D'EXÉCUTION: Créer app CLI"
    # "📋 2 étapes à réaliser"
    # "▶ Étape 1: Créer répertoire → ✅ Succès"
```

## ⚡ OPTIMISATIONS

### 10. **Plans de Fallback**

Si l'extraction du plan JSON échoue :

```python
# Plan de fallback robuste pour Ollama
fallback_plan = {
    "objective": user_input,
    "steps": [
        {"tool": "mono_create", "arguments": {"path": "app", "directory": True}},
        {"tool": "mono_create", "arguments": {"path": "app/main.py", "content": "# Application simple\\nprint(\\"Hello World\\")"}}
    ]
}
```

### 11. **Gestion d'Erreurs**

- **Échec étape** → Arrêt du plan + message d'erreur
- **Backend indisponible** → Fallback désactivé
- **JSON invalide** → Plan de fallback

## 🎉 RÉSULTAT

Le workflow MonoCLI permet :

1. **Détection automatique** d'objectifs complexes
2. **Planification intelligente** en étapes
3. **Exécution autonome** avec 10 outils
4. **Compatibilité multi-backend** (Groq, PANDA, Ollama)
5. **Mémoire scratchpad** pour traçabilité
6. **Fallback robuste** en cas d'erreur

**L'utilisateur dit simplement "Crée une app" et MonoCLI génère, planifie et exécute automatiquement !** 🚀