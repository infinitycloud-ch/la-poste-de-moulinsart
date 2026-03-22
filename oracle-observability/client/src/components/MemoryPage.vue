<template>
  <div class="memory-page">
    <div class="memory-header">
      <h1>📚 Mémoires & Résumés</h1>
      <div class="header-status">
        <span class="status-indicator" :class="{ online: wsConnected }">
          {{ wsConnected ? '🟢 WebSocket' : '🔴 Déconnecté' }}
        </span>
      </div>
    </div>

    <!-- Bannière Workflow Permanente -->
    <div class="workflow-banner-permanent">
      <!-- Fusée qui traverse la bannière -->
      <div class="rocket-container">
        <div class="rocket" :class="getRocketPosition()">
          <img src="/fusee.png" alt="🚀" class="rocket-image" />
        </div>
        <!-- Fumée de départ statique -->
        <div class="rocket-smoke"></div>
        <!-- Traînée dynamique pendant le vol -->
        <div v-if="workflowSteps.length > 0" class="rocket-trail" :class="getRocketPosition()"></div>
      </div>

      <div class="workflow-pipeline-static">
        <div class="workflow-step-static" :class="{ 'step-running': workflowSteps.length > 0 && workflowSteps[0]?.status === 'running', 'step-completed': workflowSteps.length > 0 && workflowSteps[0]?.status === 'completed' }">
          <div class="step-icon-static">🧠</div>
          <div class="step-label-static">Génération Mémoire</div>
        </div>
        <div class="connector-static" :class="{ 'connector-active': workflowSteps.length > 0 && workflowSteps[0]?.status === 'completed' }">→</div>

        <div class="workflow-step-static" :class="{ 'step-running': workflowSteps.length > 0 && workflowSteps[1]?.status === 'running', 'step-completed': workflowSteps.length > 0 && workflowSteps[1]?.status === 'completed' }">
          <div class="step-icon-static">📝</div>
          <div class="step-label-static">PROJECT_MEMORY</div>
        </div>
        <div class="connector-static" :class="{ 'connector-active': workflowSteps.length > 0 && workflowSteps[1]?.status === 'completed' }">→</div>

        <div class="workflow-step-static" :class="{ 'step-running': workflowSteps.length > 0 && workflowSteps[2]?.status === 'running', 'step-completed': workflowSteps.length > 0 && workflowSteps[2]?.status === 'completed' }">
          <div class="step-icon-static">🤖</div>
          <div class="step-label-static">CLAUDE.md Agents</div>
        </div>
        <div class="connector-static" :class="{ 'connector-active': workflowSteps.length > 0 && workflowSteps[2]?.status === 'completed' }">→</div>

        <div class="workflow-step-static" :class="{ 'step-running': workflowSteps.length > 0 && workflowSteps[3]?.status === 'running', 'step-completed': workflowSteps.length > 0 && workflowSteps[3]?.status === 'completed' }">
          <div class="step-icon-static">🗑️</div>
          <div class="step-label-static">Purge Mails</div>
        </div>
      </div>

      <div class="system-status">
        <span class="status-item">⚡ Agents: {{ wsConnected ? '39' : '0' }}</span>
        <span class="status-item">🗄️ SQLite WAL</span>
        <span class="status-item">🔗 Oracle Server</span>
        <div v-if="currentWorkflowMessage" class="workflow-message">{{ currentWorkflowMessage }}</div>
      </div>
    </div>


    <div class="memory-layout">
      <!-- Panneau A - Contexte Projet/Sprint -->
      <div class="context-panel" :style="{ width: contextWidth + 'px' }">
        <div class="panel-header">
          <h3>🎯 Contexte</h3>
        </div>

        <div class="project-selector">
          <label>Projet:</label>
          <select v-model="selectedProjectId" @change="onProjectChange">
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.id }} · {{ project.name }}
            </option>
          </select>
        </div>

        <div class="sprint-selector">
          <label>Sprint:</label>
          <select v-model="selectedSprint" @change="onSprintChange">
            <option v-for="sprint in availableSprints" :key="sprint" :value="sprint">
              {{ sprint }}
            </option>
          </select>
        </div>

        <div class="sprint-stats">
          <div class="stat-card todo">
            <span class="stat-label">TODO</span>
            <span class="stat-value">{{ sprintStats.todo }}</span>
          </div>
          <div class="stat-card in-progress">
            <span class="stat-label">IN_PROGRESS</span>
            <span class="stat-value">{{ sprintStats.inProgress }}</span>
          </div>
          <div class="stat-card done">
            <span class="stat-label">DONE</span>
            <span class="stat-value">{{ sprintStats.done }}</span>
          </div>
        </div>

        <!-- Mode Full Checkbox -->
        <div class="full-mode-section">
          <label class="full-mode-checkbox">
            <input type="checkbox" v-model="fullModeEnabled" class="checkbox-input" />
            <span class="label-text">📋 Mode Full - Tous les sprints manquants</span>
          </label>
          <div class="full-mode-description" v-if="fullModeEnabled">
            <span>🔍 Détectera automatiquement les sprints manquants et les ajoutera aux agents</span>
          </div>
        </div>

        <div class="action-buttons">
          <button
            @click="runCompleteWorkflow"
            :disabled="runningWorkflow"
            class="btn-workflow"
          >
            {{ runningWorkflow ? '⏳ Workflow en cours...' : (fullModeEnabled ? '🚀 Workflow Full (Tous Sprints)' : '🚀 Workflow Complet') }}
          </button>
          <button
            @click="generateMemory"
            :disabled="generatingMemory || runningWorkflow"
            class="btn-primary"
          >
            {{ generatingMemory ? '⏳ Génération...' : '🧠 Générer Mémoire Sprint' }}
          </button>
          <button
            @click="purgeMails"
            :disabled="purgingMails || runningWorkflow"
            class="btn-danger"
          >
            {{ purgingMails ? '⏳ Purge...' : '🗑️ Purger Mails Sprint' }}
          </button>
        </div>


        <div v-if="lastAction" class="action-status" :class="lastAction.type">
          <strong>{{ lastAction.type === 'success' ? '✅' : '❌' }}</strong>
          {{ lastAction.message }}
        </div>
      </div>

      <!-- Barre de redimensionnement 1 -->
      <div class="resize-bar"
           @mousedown="startResize($event, 'left')"
           title="Glisser pour redimensionner">
        <div class="resize-handle"></div>
      </div>

      <!-- Panneau B - Timeline & Evidence -->
      <div class="timeline-panel">
        <div class="panel-header">
          <h3>📅 Timeline & Evidence</h3>
          <div class="timeline-filters">
            <button
              v-for="agent in agentFilters"
              :key="agent.name"
              @click="toggleAgentFilter(agent.name)"
              class="filter-btn"
              :class="{ active: agent.active }"
            >
              <AgentAvatar :agent="agent.name" size="small" />
              {{ agent.name }}
            </button>
          </div>
        </div>

        <div class="timeline-container" ref="timelineContainer">
          <div v-if="loadingTimeline" class="loading-timeline">
            🔄 Chargement timeline...
          </div>

          <div v-else-if="filteredTimelineEvents.length === 0" class="empty-timeline">
            📭 Aucun événement pour ce sprint
          </div>

          <div v-else class="timeline">
            <div
              v-for="event in filteredTimelineEvents"
              :key="event.id"
              class="timeline-event"
              :class="event.type"
              @click="selectEvent(event)"
            >
              <div class="event-time">{{ formatTime(event.timestamp) }}</div>
              <div class="event-icon">{{ getEventIcon(event.type) }}</div>
              <div class="event-content">
                <div class="event-title">{{ event.title }}</div>
                <div class="event-meta">{{ event.agent }} - {{ event.type }}</div>
              </div>
              <div v-if="event.expandable" class="event-expand">📝</div>
            </div>
          </div>
        </div>

        <div v-if="selectedEvent" class="event-detail">
          <div class="detail-header">
            <h4>{{ getEventIcon(selectedEvent.type) }} Détail Événement</h4>
            <button @click="selectedEvent = null" class="close-detail">×</button>
          </div>
          <div class="detail-content">
            <pre>{{ selectedEvent.detail || selectedEvent.description || 'Aucun détail' }}</pre>
          </div>
        </div>
      </div>

      <!-- Barre de redimensionnement 2 -->
      <div class="resize-bar"
           @mousedown="startResize($event, 'right')"
           title="Glisser pour redimensionner">
        <div class="resize-handle"></div>
      </div>

      <!-- Panneau C - Mémoire & Exports -->
      <div class="export-panel" :style="{ width: exportWidth + 'px' }">
        <div class="panel-header">
          <h3>💾 Mémoire & Exports</h3>
        </div>

        <div class="memory-layers">
          <div class="layer layer-1" :class="{ active: activeLayers.has(1) }" @click="toggleLayer(1)">
            <h4>📋 Layer 1 - Journal Brut <span class="layer-toggle">{{ activeLayers.has(1) ? '▼' : '▶' }}</span></h4>
            <div v-if="activeLayers.has(1)" class="layer-content">
              <div v-if="memoryData.journal" class="journal-content">
                <pre>{{ memoryData.journal }}</pre>
              </div>
              <div v-else class="no-memory">Générer mémoire d'abord</div>
            </div>
          </div>

          <div class="layer layer-2" :class="{ active: activeLayers.has(2) }" @click="toggleLayer(2)">
            <h4>📊 Layer 2 - Résumé Structuré <span class="layer-toggle">{{ activeLayers.has(2) ? '▼' : '▶' }}</span></h4>
            <div v-if="activeLayers.has(2)" class="layer-content">
              <div v-if="memoryData.summary" class="summary-content">
                <div class="summary-section">
                  <strong>🎯 Objectifs:</strong>
                  <ul><li v-for="goal in memoryData.summary.goals" :key="goal">{{ goal }}</li></ul>
                </div>
                <div class="summary-section">
                  <strong>✅ Tâches DONE:</strong>
                  <ul><li v-for="task in memoryData.summary.done_tasks" :key="task.id">#{{ task.id }} - {{ task.title }}</li></ul>
                </div>
                <div class="summary-section">
                  <strong>⚠️ Problèmes:</strong>
                  <ul><li v-for="issue in memoryData.summary.issues" :key="issue">{{ issue }}</li></ul>
                </div>
                <div class="summary-section">
                  <strong>🔍 DoD:</strong>
                  <span :class="{ 'dod-complete': memoryData.summary.dod.all_done }">
                    {{ memoryData.summary.dod.all_done ? '✅ Complet' : '⏳ En cours' }}
                  </span>
                </div>
              </div>
              <div v-else class="no-memory">Générer mémoire d'abord</div>
            </div>
          </div>

          <div class="layer layer-3" :class="{ active: activeLayers.has(3) }" @click="toggleLayer(3)">
            <h4>🔧 Layer 3 - Vérité Opérationnelle <span class="layer-toggle">{{ activeLayers.has(3) ? '▼' : '▶' }}</span></h4>
            <div v-if="activeLayers.has(3)" class="layer-content">
              <div v-if="memoryData.ground_truth" class="truth-content">
                <div class="truth-section">
                  <strong>🔌 Ports:</strong>
                  <ul>
                    <li v-for="(port, service) in memoryData.ground_truth.ports" :key="service">
                      {{ service }}: {{ port }}
                    </li>
                  </ul>
                </div>
                <div class="truth-section">
                  <strong>📋 Règles:</strong>
                  <ul><li v-for="rule in memoryData.ground_truth.rules" :key="rule">{{ rule }}</li></ul>
                </div>
                <div class="truth-section">
                  <strong>📁 Chemins:</strong>
                  <ul><li v-for="path in memoryData.ground_truth.paths" :key="path">{{ path }}</li></ul>
                </div>
              </div>
              <div v-else class="no-memory">Générer mémoire d'abord</div>
            </div>
          </div>
        </div>

        <div class="layer layer-4" :class="{ active: activeLayers.has(4) }" @click="toggleLayer(4)">
          <h4>📋 Layer 4 - PROJECT_MEMORY <span class="layer-toggle">{{ activeLayers.has(4) ? '▼' : '▶' }}</span></h4>
          <div v-if="activeLayers.has(4)" class="layer-content">
            <div v-if="projectMemoryContent" class="project-memory-content">
              <pre>{{ projectMemoryContent }}</pre>
            </div>
            <div v-else class="no-memory">
              <p>Exécuter le workflow complet pour générer PROJECT_MEMORY.md</p>
              <button
                @click="loadProjectMemoryFromFile"
                class="load-btn"
                :disabled="!selectedProjectId || !selectedSprint"
              >
                📖 Charger PROJECT_MEMORY existant
              </button>
            </div>
          </div>
        </div>

        <div class="export-actions">
          <button
            @click="exportZip"
            :disabled="!memoryData.summary"
            class="export-btn"
          >
            📦 Exporter ZIP
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import AgentAvatar from './AgentAvatar.vue'

// États réactifs
const wsConnected = ref(false)
const projects = ref([])
const selectedProjectId = ref(22) // Par défaut MonoCLI
const selectedSprint = ref('Sprint 7')
const availableSprints = ref([])
const sprintStats = ref({ todo: 0, inProgress: 0, done: 0 })
const timelineEvents = ref([])
const selectedEvent = ref(null)
const activeLayers = ref(new Set([1]))
const memoryData = ref({})
const projectMemoryContent = ref('')
const lastAction = ref(null)
const generatingMemory = ref(false)
const purgingMails = ref(false)
const loadingTimeline = ref(false)

// Variables pour le workflow complet
const runningWorkflow = ref(false)
const workflowSteps = ref([])
const currentWorkflowMessage = ref('')
const fullModeEnabled = ref(false)

// Largeurs des panneaux - utilisation directe pour flexbox
const contextWidth = ref(300)
const exportWidth = ref(350)
// Timeline prend l'espace restant dynamiquement

// Variables pour le redimensionnement
const isResizing = ref(false)
const resizeType = ref('')
const startX = ref(0)
const startWidthLeft = ref(0)
const startWidthRight = ref(0)

// Filtres agents
const agentFilters = ref([
  { name: 'commandant', icon: '👨‍✈️', active: true },
  { name: 'haddock', icon: '⚓', active: true },
  { name: 'tournesol1', icon: '🧪', active: true },
  { name: 'tournesol2', icon: '🔬', active: true },
  { name: 'rastapopoulos', icon: '🧔', active: true },
  { name: 'nestor', icon: '🎩', active: true },
  { name: 'tintin', icon: '🚀', active: true },
  { name: 'dupont1', icon: '🎨', active: true },
  { name: 'dupont2', icon: '🔍', active: true }
])

// WebSocket
let ws = null

// Computed
const filteredTimelineEvents = computed(() => {
  const activeAgents = agentFilters.value.filter(f => f.active).map(f => f.name)
  return timelineEvents.value.filter(event => activeAgents.includes(event.agent))
})

// Pas besoin de gridStyle pour flexbox - utilisation directe des widths

// Méthodes
const connectWebSocket = () => {
  ws = new WebSocket('ws://localhost:3001/ws')

  ws.onopen = () => {
    wsConnected.value = true
    console.log('📡 WebSocket connecté')
  }

  ws.onclose = () => {
    wsConnected.value = false
    console.log('📡 WebSocket déconnecté')
    // Reconnecter après 3 secondes
    setTimeout(connectWebSocket, 3000)
  }

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data)
      if (data.type === 'event') {
        // Mise à jour live des stats et timeline
        loadSprintStats()
        loadTimeline()
      }
    } catch (err) {
      console.error('Erreur WebSocket:', err)
    }
  }
}

const loadProjects = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/projects')
    if (response.ok) {
      projects.value = await response.json()
    }
  } catch (err) {
    console.error('Erreur chargement projets:', err)
  }
}

const loadSprintsForProject = async (projectId) => {
  if (!projectId) return

  try {
    const response = await fetch(`http://localhost:3001/api/projects/${projectId}/sprints`)
    if (response.ok) {
      const data = await response.json()
      availableSprints.value = data.sprints || []

      // Reset sprint selection if current sprint is not available for this project
      if (availableSprints.value.length > 0 && !availableSprints.value.includes(selectedSprint.value)) {
        selectedSprint.value = availableSprints.value[0]
      }
    } else {
      availableSprints.value = []
    }
  } catch (err) {
    console.error('Erreur chargement sprints:', err)
    availableSprints.value = []
  }
}

const loadSprintStats = async () => {
  if (!selectedProjectId.value || !selectedSprint.value) return

  try {
    const response = await fetch(`http://localhost:3001/api/tasks?project_id=${selectedProjectId.value}`)
    if (response.ok) {
      const tasks = await response.json()
      const sprintTasks = tasks.filter(t => t.sprint === selectedSprint.value)

      sprintStats.value = {
        todo: sprintTasks.filter(t => t.status === 'TODO').length,
        inProgress: sprintTasks.filter(t => t.status === 'IN_PROGRESS').length,
        done: sprintTasks.filter(t => t.status === 'DONE').length
      }
    }
  } catch (err) {
    console.error('Erreur stats sprint:', err)
  }
}

const loadTimeline = async () => {
  if (!selectedProjectId.value || !selectedSprint.value) return

  loadingTimeline.value = true
  try {
    // Charger tâches du sprint
    const tasksResponse = await fetch(`http://localhost:3001/api/tasks?project_id=${selectedProjectId.value}`)
    const tasks = tasksResponse.ok ? await tasksResponse.json() : []
    const sprintTasks = tasks.filter(t => t.sprint === selectedSprint.value)

    // Charger emails des agents (simulation)
    // TODO: Implémenter récupération emails par période

    // Construire timeline
    const events = []

    sprintTasks.forEach(task => {
      events.push({
        id: `task-${task.id}`,
        type: 'task_creation',
        timestamp: task.created_at,
        title: `Tâche créée: ${task.title}`,
        agent: task.assigned_to || 'system',
        detail: `ID: ${task.id}\nStatus: ${task.status}\nPriorité: ${task.priority}`,
        expandable: true
      })

      if (task.status === 'DONE') {
        events.push({
          id: `task-done-${task.id}`,
          type: 'task_completion',
          timestamp: task.updated_at,
          title: `Tâche terminée: ${task.title}`,
          agent: task.assigned_to || 'system',
          detail: `ID: ${task.id}\nComplétée le ${task.updated_at}`,
          expandable: true
        })
      }
    })


    // Trier par timestamp
    timelineEvents.value = events.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))

  } catch (err) {
    console.error('Erreur timeline:', err)
  } finally {
    loadingTimeline.value = false
  }
}

const generateMemory = async () => {
  generatingMemory.value = true
  lastAction.value = null

  try {
    const response = await fetch('http://localhost:3001/api/memory/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        sprint: selectedSprint.value
      })
    })

    if (response.ok) {
      const result = await response.json()
      memoryData.value = result
      lastAction.value = { type: 'success', message: 'Mémoire générée avec succès' }
      console.log('🧠 Mémoire générée:', result)
    } else {
      lastAction.value = { type: 'error', message: 'Erreur génération mémoire' }
    }
  } catch (err) {
    console.error('Erreur génération mémoire:', err)
    lastAction.value = { type: 'error', message: err.message }
  } finally {
    generatingMemory.value = false
  }
}

const purgeMails = async () => {
  if (!confirm(`Purger les mails du ${selectedSprint.value} ? Cette action est irréversible.`)) return

  purgingMails.value = true
  lastAction.value = null

  try {
    const response = await fetch('http://localhost:3001/api/memory/purge-mails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        sprint: selectedSprint.value
      })
    })

    if (response.ok) {
      lastAction.value = { type: 'success', message: 'Mails purgés avec succès' }
    } else {
      lastAction.value = { type: 'error', message: 'Erreur purge mails' }
    }
  } catch (err) {
    console.error('Erreur purge mails:', err)
    lastAction.value = { type: 'error', message: err.message }
  } finally {
    purgingMails.value = false
  }
}

// Workflow complet
const runCompleteWorkflow = async () => {
  if (runningWorkflow.value) return

  runningWorkflow.value = true

  // Déterminer les sprints à traiter
  let sprintsToProcess = []

  if (fullModeEnabled.value) {
    // Mode Full: détecter sprints manquants
    currentWorkflowMessage.value = '🔍 Détection des sprints manquants...'

    // Récupérer tous les sprints disponibles du projet
    const availableSprintsSet = new Set(availableSprints.value)

    // Récupérer sprints déjà présents dans CLAUDE.md (via API ou parsing)
    try {
      const existingSprintsResponse = await fetch(`http://localhost:3001/api/memory/existing-sprints?project_id=${selectedProjectId.value}`)
      const existingSprintsData = existingSprintsResponse.ok ? await existingSprintsResponse.json() : {existing_sprints: []}
      const existingSprints = existingSprintsData.existing_sprints || []

      // Convertir les numéros de sprints en format "Sprint N"
      const existingSprintNames = existingSprints.map(num => `Sprint ${num}`)
      const existingSprintsSet = new Set(existingSprintNames)

      // Calculer sprints manquants RÉCENTS seulement (après le plus haut existant)
      const maxExistingSprint = Math.max(...existingSprints, 0);
      const allMissingSprints = availableSprints.value.filter(sprint => !existingSprintsSet.has(sprint))

      // Ne traiter que les sprints APRÈS le plus haut existant (sprints récents)
      sprintsToProcess = allMissingSprints.filter(sprint => {
        const sprintNumber = parseInt(sprint.match(/Sprint (\d+)/)?.[1] || '0')
        return sprintNumber > maxExistingSprint
      })

      console.log(`🔍 Mode Full: Sprint max existant=${maxExistingSprint}, ${sprintsToProcess.length} sprints récents à traiter:`, sprintsToProcess)
    } catch (err) {
      console.error('Erreur détection sprints:', err)
      sprintsToProcess = [selectedSprint.value] // Fallback sur sprint sélectionné
    }
  } else {
    // Mode Normal: seulement le sprint sélectionné
    sprintsToProcess = [selectedSprint.value]
  }

  if (sprintsToProcess.length === 0) {
    currentWorkflowMessage.value = '✅ Aucun sprint manquant à traiter!'
    lastAction.value = { type: 'success', message: 'Tous les sprints sont déjà à jour' }
    runningWorkflow.value = false
    return
  }

  // Initialiser les étapes du workflow
  workflowSteps.value = [
    { id: 'memory', icon: '🧠', label: `Génération Mémoire (${sprintsToProcess.length} sprint${sprintsToProcess.length > 1 ? 's' : ''})`, status: 'pending' },
    { id: 'project', icon: '📝', label: 'Écriture PROJECT_MEMORY', status: 'pending' },
    { id: 'claude', icon: '🤖', label: 'Mise à jour CLAUDE.md', status: 'pending' },
    { id: 'purge', icon: '🗑️', label: 'Purge Mails Sprint', status: 'pending' }
  ]

  try {
    // Traitement en boucle pour chaque sprint
    for (let i = 0; i < sprintsToProcess.length; i++) {
      const currentSprint = sprintsToProcess[i];
      const sprintIndex = i + 1;
      const totalSprints = sprintsToProcess.length;

      console.log(`🔄 Traitement Sprint ${sprintIndex}/${totalSprints}: ${currentSprint}`);

      // Étape 1: Génération mémoire
      workflowSteps.value[0].status = 'running'
      currentWorkflowMessage.value = `Génération mémoire ${currentSprint} (${sprintIndex}/${totalSprints})...`

      const memoryResponse = await fetch('http://localhost:3001/api/memory/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: selectedProjectId.value,
          sprint: currentSprint  // ✅ Utilise le sprint actuel de la boucle
        })
      })

      if (!memoryResponse.ok) {
        console.warn(`⚠️ Génération mémoire échouée pour ${currentSprint}, continuation avec données par défaut`)
        memoryData.value = {
          summary: { goals: [], done_tasks: [], issues: [], dod: { all_done: false } },
          ground_truth: { ports: {}, rules: [], paths: [] },
          journal: `Génération mémoire échouée pour ${currentSprint} - Continuation workflow`
        }
      } else {
        const memoryResult = await memoryResponse.json()
        memoryData.value = memoryResult
      }
      workflowSteps.value[0].status = 'completed'

      // Petit délai pour voir l'animation
      await new Promise(resolve => setTimeout(resolve, 800))

      // Étape 2: Écriture PROJECT_MEMORY
      workflowSteps.value[1].status = 'running'
      currentWorkflowMessage.value = `Écriture PROJECT_MEMORY ${currentSprint} (${sprintIndex}/${totalSprints})...`

      const projectResponse = await fetch('http://localhost:3001/api/memory/write-project', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: selectedProjectId.value,
          sprint: currentSprint,  // ✅ Utilise le sprint actuel
          data: memoryData.value
        })
      })

      if (!projectResponse.ok) {
        console.warn(`⚠️ Écriture PROJECT_MEMORY échouée pour ${currentSprint}, continuation workflow`)
      }
      workflowSteps.value[1].status = 'completed'

      await new Promise(resolve => setTimeout(resolve, 800))

      // Étape 3: Écriture CLAUDE_MEMORY
      workflowSteps.value[2].status = 'running'
      currentWorkflowMessage.value = `Mise à jour CLAUDE.md ${currentSprint} (${sprintIndex}/${totalSprints})...`

      const claudeResponse = await fetch('http://localhost:3001/api/memory/write-agents', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: selectedProjectId.value,
          sprint: currentSprint,  // ✅ Utilise le sprint actuel
          data: memoryData.value
        })
      })

      if (!claudeResponse.ok) {
        console.warn(`⚠️ Mise à jour CLAUDE.md échouée pour ${currentSprint}, continuation workflow`)
      }
    workflowSteps.value[2].status = 'completed'

      await new Promise(resolve => setTimeout(resolve, 800))

      // Étape 4: Purge des mails
      workflowSteps.value[3].status = 'running'
      currentWorkflowMessage.value = `Purge mails ${currentSprint} (${sprintIndex}/${totalSprints})...`

      const purgeResponse = await fetch('http://localhost:3001/api/memory/purge-mails', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: selectedProjectId.value,
          sprint: currentSprint  // ✅ Utilise le sprint actuel
        })
      })

      if (!purgeResponse.ok) {
        console.warn(`⚠️ Purge mails échouée pour ${currentSprint}, continuation workflow`)
      }
      workflowSteps.value[3].status = 'completed'

      console.log(`✅ Sprint ${currentSprint} traité avec succès (${sprintIndex}/${totalSprints})`);
    } // Fin de la boucle for

    currentWorkflowMessage.value = '✅ Workflow Mode Full terminé avec succès!'
    lastAction.value = { type: 'success', message: `Workflow complet terminé: ${sprintsToProcess.length} sprints traités` }

    // Recharger le PROJECT_MEMORY depuis le fichier pour l'afficher
    await loadProjectMemoryFromFile()

    // Activer automatiquement tous les layers including PROJECT_MEMORY
    activeLayers.value = new Set([1, 2, 3, 4])

  } catch (error) {
    console.error('Erreur workflow:', error)
    currentWorkflowMessage.value = `❌ Erreur: ${error.message}`
    lastAction.value = { type: 'error', message: `Workflow échoué: ${error.message}` }

    // Marquer l'étape courante comme erreur
    const currentStep = workflowSteps.value.find(s => s.status === 'running')
    if (currentStep) currentStep.status = 'error'

  } finally {
    runningWorkflow.value = false

    // Garder la visualisation pendant 5 secondes puis la masquer
    setTimeout(() => {
      workflowSteps.value = []
      currentWorkflowMessage.value = ''
    }, 5000)
  }
}

// Fonction pour recharger le PROJECT_MEMORY depuis le fichier
const loadProjectMemoryFromFile = async () => {
  try {
    const response = await fetch(`http://localhost:3001/api/memory/read-project?project_id=${selectedProjectId.value}&sprint=${selectedSprint.value}`)
    if (response.ok) {
      const data = await response.json()
      memoryData.value = data

      // Convertir les données en format texte pour affichage
      if (data.summary) {
        projectMemoryContent.value = `# PROJECT_MEMORY - ${selectedSprint.value}

## 🎯 Objectifs
${data.summary.goals.map(g => `• ${g}`).join('\n')}

## ✅ Tâches Terminées
${data.summary.done_tasks.map(t => `• #${t.id} - ${t.title}`).join('\n')}

## ⚠️ Problèmes Identifiés
${data.summary.issues.map(i => `• ${i}`).join('\n')}

## 🔍 Definition of Done
Status: ${data.summary.dod.all_done ? '✅ Complet' : '⏳ En cours'}

## 🔧 Vérité Opérationnelle
### Ports:
${Object.entries(data.ground_truth?.ports || {}).map(([service, port]) => `• ${service}: ${port}`).join('\n')}

### Chemins:
${data.ground_truth?.paths?.map(p => `• ${p}`).join('\n') || ''}

### Règles:
${data.ground_truth?.rules?.map(r => `• ${r}`).join('\n') || ''}`
      }

      console.log('📖 PROJECT_MEMORY rechargé:', data)
    }
  } catch (error) {
    console.error('Erreur lecture PROJECT_MEMORY:', error)
  }
}

const writeProjectMemory = async () => {
  if (!memoryData.value.summary) return

  try {
    const response = await fetch('http://localhost:3001/api/memory/write-project', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        sprint: selectedSprint.value,
        data: memoryData.value
      })
    })

    if (response.ok) {
      lastAction.value = { type: 'success', message: 'PROJECT_MEMORY.md écrit' }
    } else {
      lastAction.value = { type: 'error', message: 'Erreur écriture fichier' }
    }
  } catch (err) {
    console.error('Erreur écriture:', err)
    lastAction.value = { type: 'error', message: err.message }
  }
}

const writeAgentMemory = async () => {
  if (!memoryData.value.summary) return

  try {
    const response = await fetch('http://localhost:3001/api/memory/write-agents', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        sprint: selectedSprint.value,
        data: memoryData.value
      })
    })

    if (response.ok) {
      lastAction.value = { type: 'success', message: 'CLAUDE_MEMORY.md écrits' }
    } else {
      lastAction.value = { type: 'error', message: 'Erreur écriture agents' }
    }
  } catch (err) {
    console.error('Erreur écriture agents:', err)
    lastAction.value = { type: 'error', message: err.message }
  }
}

const exportZip = async () => {
  if (!memoryData.value.summary) return

  try {
    const response = await fetch('http://localhost:3001/api/memory/export-zip', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        sprint: selectedSprint.value,
        data: memoryData.value
      })
    })

    if (response.ok) {
      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `memory_${selectedProjectId.value}_${selectedSprint.value}.zip`
      a.click()
      window.URL.revokeObjectURL(url)

      lastAction.value = { type: 'success', message: 'ZIP exporté avec succès' }
    } else {
      lastAction.value = { type: 'error', message: 'Erreur export ZIP' }
    }
  } catch (err) {
    console.error('Erreur export ZIP:', err)
    lastAction.value = { type: 'error', message: err.message }
  }
}

// Event handlers
const onProjectChange = async () => {
  await loadSprintsForProject(selectedProjectId.value)
  loadSprintStats()
  loadTimeline()
}

const onSprintChange = () => {
  loadSprintStats()
  loadTimeline()
  memoryData.value = {} // Reset memory data
  activeLayers.value = new Set([1])
}

const toggleAgentFilter = (agentName) => {
  const filter = agentFilters.value.find(f => f.name === agentName)
  if (filter) filter.active = !filter.active
}

const selectEvent = (event) => {
  selectedEvent.value = selectedEvent.value === event ? null : event
}

const toggleLayer = (layer) => {
  if (activeLayers.value.has(layer)) {
    activeLayers.value.delete(layer)
  } else {
    activeLayers.value.add(layer)
  }
  // Forcer la réactivité
  activeLayers.value = new Set(activeLayers.value)
}

const formatTime = (timestamp) => {
  return new Date(timestamp).toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getEventIcon = (type) => {
  const icons = {
    task_creation: '📝',
    task_completion: '✅',
    task_update: '📋',
    email: '📧',
    commit: '💾',
    system: '⚙️'
  }
  return icons[type] || '📌'
}

// Lifecycle
onMounted(async () => {
  connectWebSocket()
  await loadProjects()
  await loadSprintsForProject(selectedProjectId.value)
  loadSprintStats()
  loadTimeline()
})

onUnmounted(() => {
  if (ws) ws.close()
})

const startResize = (event, type) => {
  isResizing.value = true
  resizeType.value = type
  startX.value = event.clientX

  if (type === 'left') {
    startWidthLeft.value = contextWidth.value
  } else if (type === 'right') {
    startWidthRight.value = exportWidth.value
  }

  document.addEventListener('mousemove', handleResize)
  document.addEventListener('mouseup', stopResize)
  document.body.style.cursor = 'col-resize'
  event.preventDefault()
}

const handleResize = (event) => {
  if (!isResizing.value) return

  const deltaX = event.clientX - startX.value

  if (resizeType.value === 'left') {
    const newContextWidth = Math.max(200, Math.min(500, startWidthLeft.value + deltaX))
    contextWidth.value = newContextWidth
  } else if (resizeType.value === 'right') {
    const newExportWidth = Math.max(250, Math.min(600, startWidthRight.value - deltaX))
    exportWidth.value = newExportWidth
  }
}

const stopResize = () => {
  isResizing.value = false
  resizeType.value = ''
  document.removeEventListener('mousemove', handleResize)
  document.removeEventListener('mouseup', stopResize)
  document.body.style.cursor = 'default'
}

// Fonctions pour les descriptions et résultats du workflow banner
const getStepDescription = (stepId) => {
  const descriptions = {
    memory: 'Analyse des tâches terminées et génération de la synthèse intelligente...',
    project: 'Écriture du fichier PROJECT_MEMORY.md avec contexte complet...',
    claude: 'Distribution des mémoires aux agents via mise à jour CLAUDE.md...',
    purge: 'Nettoyage automatique des emails du sprint terminé...'
  }
  return descriptions[stepId] || 'Traitement en cours...'
}

const getStepResult = (stepId) => {
  const results = {
    memory: 'Mémoire générée avec succès',
    project: 'PROJECT_MEMORY.md écrit',
    claude: 'Agents mis à jour',
    purge: 'Emails purgés'
  }
  return results[stepId] || 'Terminé'
}

// Fonction pour déterminer la position de la fusée selon l'avancement du workflow
const getRocketPosition = () => {
  if (!workflowSteps.value.length) return 'rocket-start'

  // Compter les étapes terminées
  const completedSteps = workflowSteps.value.filter(s => s.status === 'completed').length
  const currentRunningStep = workflowSteps.value.findIndex(s => s.status === 'running')

  if (currentRunningStep === 0 || (completedSteps === 0 && currentRunningStep !== -1)) return 'rocket-step-1'
  if (currentRunningStep === 1 || completedSteps === 1) return 'rocket-step-2'
  if (currentRunningStep === 2 || completedSteps === 2) return 'rocket-step-3'
  if (currentRunningStep === 3 || completedSteps >= 3) return 'rocket-step-4'

  return 'rocket-start'
}

// Watchers
watch([selectedProjectId, selectedSprint], () => {
  loadSprintStats()
  loadTimeline()
})
</script>

<style scoped>
.memory-page {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #0f1419 0%, #1a2332 50%, #2d3748 100%);
  color: #e2e8f0;
  position: relative;
}

.memory-page::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background:
    radial-gradient(circle at 20% 80%, rgba(255,255,255,0.1) 1px, transparent 1px),
    radial-gradient(circle at 80% 20%, rgba(255,255,255,0.08) 1px, transparent 1px),
    radial-gradient(circle at 40% 40%, rgba(255,255,255,0.06) 1px, transparent 1px);
  background-size: 200px 200px, 300px 300px, 400px 400px;
  pointer-events: none;
}

.memory-header {
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(90deg, rgba(15,20,25,0.8) 0%, rgba(45,55,72,0.6) 100%);
  border-bottom: 1px solid rgba(226,232,240,0.1);
  backdrop-filter: blur(10px);
  position: relative;
  z-index: 1;
}

.memory-header h1 {
  margin: 0;
  font-size: 2em;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}


.status-indicator {
  padding: 8px 15px;
  border-radius: 20px;
  font-weight: bold;
  background: rgba(255,0,0,0.2);
}

.status-indicator.online {
  background: rgba(0,255,0,0.2);
}

.memory-layout {
  flex: 1;
  display: flex;
  padding: 20px;
  height: calc(100vh - 140px);
  gap: 0;
  width: 100%;
  overflow: hidden;
}

.context-panel, .timeline-panel, .export-panel {
  background: linear-gradient(145deg, rgba(26,35,50,0.7) 0%, rgba(45,55,72,0.8) 100%);
  border: 1px solid rgba(148,163,184,0.2);
  border-radius: 15px;
  padding: 20px;
  backdrop-filter: blur(15px);
  overflow-y: auto;
  box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  position: relative;
  z-index: 1;
  margin: 0 10px;
}

/* Fusée seulement sur le panneau central */
.timeline-panel {
  background-image: url('/lunefusee.png');
  background-size: cover;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
}

/* Rendre tout le contenu du timeline transparent */
.timeline-panel .panel-header,
.timeline-panel h3,
.timeline-panel .timeline-filters,
.timeline-panel .loading-timeline,
.timeline-panel .empty-timeline {
  background: transparent;
  color: #333;
  text-shadow: 1px 1px 2px rgba(255,255,255,0.8);
}

.context-panel {
  flex-shrink: 0;
  min-width: 200px;
  max-width: 500px;
}

.timeline-panel {
  flex: 1;
  min-width: 400px;
}

.export-panel {
  flex-shrink: 0;
  min-width: 250px;
  max-width: 600px;
}

.resize-bar {
  width: 6px;
  background: rgba(148,163,184,0.3);
  cursor: col-resize;
  position: relative;
  z-index: 10;
  margin: 0 2px;
  border-radius: 3px;
  transition: background 0.2s ease;
}

.resize-bar:hover {
  background: rgba(59,130,246,0.6);
}

.resize-handle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 20px;
  height: 40px;
  background: rgba(148,163,184,0.5);
  border-radius: 10px;
  transition: all 0.2s ease;
}

.resize-bar:hover .resize-handle {
  background: rgba(59,130,246,0.8);
  box-shadow: 0 2px 8px rgba(59,130,246,0.3);
}

.context-panel::before, .timeline-panel::before, .export-panel::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, transparent 49%, rgba(148,163,184,0.1) 50%, transparent 51%);
  background-size: 20px 20px;
  pointer-events: none;
  opacity: 0.3;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 2px solid rgba(255,255,255,0.2);
}

.panel-header h3 {
  margin: 0;
  font-size: 1.2em;
}

/* Context Panel Styles */
.project-selector, .sprint-selector {
  margin-bottom: 15px;
}

.project-selector label, .sprint-selector label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

.project-selector select, .sprint-selector select {
  width: 100%;
  padding: 8px;
  border-radius: 5px;
  border: none;
  background: rgba(255,255,255,0.9);
  color: #333;
}

.sprint-stats {
  display: grid;
  grid-template-columns: 1fr;
  gap: 10px;
  margin: 20px 0;
}

.stat-card {
  padding: 10px;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
}

.stat-card.todo { background: rgba(255,193,7,0.3); }
.stat-card.in-progress { background: rgba(0,123,255,0.3); }
.stat-card.done { background: rgba(40,167,69,0.3); }

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 20px 0;
}

.btn-primary, .btn-danger {
  padding: 12px 15px;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6, #1e40af);
  color: #e2e8f0;
  border: 1px solid rgba(59,130,246,0.3);
  box-shadow: 0 4px 12px rgba(59,130,246,0.2);
}

.btn-danger {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  color: #e2e8f0;
  border: 1px solid rgba(239,68,68,0.3);
  box-shadow: 0 4px 12px rgba(239,68,68,0.2);
}

.btn-primary:hover, .btn-danger:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
}

.btn-primary:disabled, .btn-danger:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.action-status {
  padding: 10px;
  border-radius: 5px;
  margin-top: 10px;
}

.action-status.success { background: rgba(40,167,69,0.2); }
.action-status.error { background: rgba(220,53,69,0.2); }

/* Timeline Panel Styles */
.timeline-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
}

.filter-btn {
  padding: 4px 8px;
  border: 1px solid rgba(0,0,0,0.3);
  background: rgba(255,255,255,0.2);
  color: #333;
  border-radius: 15px;
  cursor: pointer;
  font-size: 0.8em;
  transition: all 0.2s ease;
  text-shadow: 1px 1px 2px rgba(255,255,255,0.9);
}

.filter-btn.active {
  background: rgba(255,255,255,0.9);
  border-color: rgba(0,0,0,0.5);
  color: #333;
}

.timeline-container {
  height: 60%;
  overflow-y: auto;
  margin-bottom: 20px;
}

.loading-timeline, .empty-timeline {
  text-align: center;
  padding: 40px;
  opacity: 0.7;
}

.timeline {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.timeline-event {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(148,163,184,0.2);
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  color: #333;
  text-shadow: 1px 1px 2px rgba(255,255,255,0.9);
}

.timeline-event:hover {
  background: rgba(255, 255, 255, 0.95);
  border-color: rgba(148,163,184,0.5);
  transform: translateX(5px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}

.timeline-event.email {
  border-left: 3px solid #3b82f6;
}

.timeline-event.task_creation {
  border-left: 3px solid #10b981;
}

.timeline-event.task_completion {
  border-left: 3px solid #f59e0b;
}

.timeline-event.memory_event {
  border-left: 3px solid #8b5cf6;
}

.timeline-event.prompt {
  border-left: 3px solid #06b6d4;
}

.timeline-event.notification {
  border-left: 3px solid #f97316;
}

.event-time {
  font-size: 0.8em;
  opacity: 0.7;
  min-width: 80px;
}

.event-icon {
  font-size: 1.2em;
  min-width: 30px;
}

.event-content {
  flex: 1;
}

.event-title {
  font-weight: bold;
  margin-bottom: 2px;
}

.event-meta {
  font-size: 0.8em;
  opacity: 0.7;
}

.event-expand {
  font-size: 0.8em;
  opacity: 0.5;
}

.event-detail {
  background: rgba(0,0,0,0.3);
  border-radius: 8px;
  padding: 15px;
  margin-top: 10px;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  font-weight: bold;
}

.close-detail {
  background: none;
  border: none;
  color: white;
  font-size: 1.2em;
  cursor: pointer;
  opacity: 0.7;
}

.detail-content pre {
  font-size: 0.9em;
  white-space: pre-wrap;
  word-break: break-word;
  margin: 0;
}

/* Export Panel Styles */
.memory-layers {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: 20px;
}

.layer {
  background: linear-gradient(135deg, rgba(15,23,42,0.7) 0%, rgba(30,41,59,0.8) 100%);
  border: 1px solid rgba(148,163,184,0.2);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}

.layer.active {
  background: linear-gradient(135deg, rgba(30,41,59,0.9) 0%, rgba(51,65,85,1) 100%);
  border-color: rgba(59,130,246,0.4);
  box-shadow: 0 4px 16px rgba(59,130,246,0.2);
}

.layer h4 {
  margin: 0;
  padding: 12px;
  border-bottom: 1px solid rgba(255,255,255,0.2);
  font-size: 1em;
}

.layer-content {
  padding: 15px;
  max-height: 200px;
  overflow-y: auto;
}

.layer-content pre {
  font-size: 0.8em;
  white-space: pre-wrap;
  margin: 0;
}

.summary-section, .truth-section {
  margin-bottom: 15px;
}

.summary-section strong, .truth-section strong {
  display: block;
  margin-bottom: 5px;
}

.summary-section ul, .truth-section ul {
  margin: 0;
  padding-left: 20px;
}

.dod-complete {
  color: #28a745;
  font-weight: bold;
}

.no-memory {
  opacity: 0.5;
  text-align: center;
  padding: 20px;
}

.export-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.export-btn {
  padding: 10px 12px;
  border: 1px solid rgba(255,255,255,0.3);
  background: rgba(255,255,255,0.1);
  color: white;
  border-radius: 5px;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.2s ease;
}

.export-btn:hover:not(:disabled) {
  background: rgba(255,255,255,0.2);
  transform: translateY(-1px);
}

.export-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.project-memory-content {
  max-height: 300px;
  overflow-y: auto;
  font-size: 0.85em;
}

.project-memory-content pre {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
}

.load-btn {
  padding: 8px 12px;
  border: 1px solid rgba(59,130,246,0.4);
  background: rgba(59,130,246,0.1);
  color: #3b82f6;
  border-radius: 5px;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.2s ease;
  margin-top: 10px;
}

.load-btn:hover:not(:disabled) {
  background: rgba(59,130,246,0.2);
  transform: translateY(-1px);
}

.load-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Styles pour le bouton workflow */
.btn-workflow {
  padding: 12px 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.95em;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.btn-workflow:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
}

.btn-workflow:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

/* Bannière Workflow Permanente - Plus sobre */
.workflow-banner-permanent {
  margin: 20px;
  background: linear-gradient(90deg, rgba(30,41,59,0.8) 0%, rgba(45,55,72,0.9) 100%);
  border: 1px solid rgba(148,163,184,0.3);
  border-radius: 12px;
  padding: 20px;
  backdrop-filter: blur(10px);
  position: relative;
  overflow: hidden;
}

/* Fusée qui traverse la bannière */
.rocket-container {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  z-index: 10;
}

.rocket {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  transition: all 2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  filter: drop-shadow(0 0 10px rgba(255, 215, 0, 0.8));
  animation: rocketPulse 1s ease-in-out infinite alternate;
}

.rocket-image {
  height: 60px;
  width: auto;
  display: block;
}

.rocket-smoke {
  position: absolute;
  left: -30px;
  top: 50%;
  transform: translateY(-50%);
  width: 60px;
  height: 20px;
  background: radial-gradient(ellipse at right, rgba(255, 255, 255, 0.6) 0%, rgba(200, 200, 200, 0.4) 50%, transparent 80%);
  border-radius: 50%;
  animation: smokeFloat 3s ease-in-out infinite;
  opacity: 0.7;
}

.rocket-trail {
  position: absolute;
  top: 50%;
  height: 4px;
  background: linear-gradient(90deg, transparent, rgba(255, 165, 0, 0.9), rgba(255, 69, 0, 0.7), rgba(255, 0, 0, 0.5), transparent);
  transform: translateY(-50%);
  transition: all 2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  border-radius: 2px;
  box-shadow: 0 0 15px rgba(255, 165, 0, 0.6);
}

/* Positions de la fusée selon l'étape */
.rocket.rocket-start {
  left: -50px;
}

.rocket-trail.rocket-start {
  left: -50px;
  width: 0;
}

.rocket.rocket-step-1 {
  left: 15%;
}

.rocket-trail.rocket-step-1 {
  left: -50px;
  width: calc(15% + 80px);
}

.rocket.rocket-step-2 {
  left: 35%;
}

.rocket-trail.rocket-step-2 {
  left: -50px;
  width: calc(35% + 80px);
}

.rocket.rocket-step-3 {
  left: 60%;
}

.rocket-trail.rocket-step-3 {
  left: -50px;
  width: calc(60% + 80px);
}

.rocket.rocket-step-4 {
  left: 85%;
}

.rocket-trail.rocket-step-4 {
  left: -50px;
  width: calc(85% + 80px);
}

@keyframes rocketPulse {
  0% {
    transform: translateY(-50%) scale(1);
  }
  100% {
    transform: translateY(-50%) scale(1.05);
  }
}

@keyframes smokeFloat {
  0% {
    transform: translateY(-50%) scale(1);
    opacity: 0.7;
  }
  50% {
    transform: translateY(-50%) scale(1.2);
    opacity: 0.4;
  }
  100% {
    transform: translateY(-50%) scale(1);
    opacity: 0.7;
  }
}

.workflow-pipeline-static {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin-bottom: 15px;
}

.workflow-step-static {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 120px;
}

.step-icon-static {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(59,130,246,0.2);
  border: 2px solid rgba(59,130,246,0.4);
  font-size: 1.5em;
  margin-bottom: 8px;
  color: #e2e8f0;
  transition: all 0.4s ease;
}

.workflow-step-static.step-running .step-icon-static {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  border-color: #ffd700;
  color: #333;
  animation: pulseStatic 2s infinite;
  box-shadow: 0 0 20px rgba(255, 215, 0, 0.6);
}

.workflow-step-static.step-completed .step-icon-static {
  background: linear-gradient(135deg, #4ade80, #22c55e);
  border-color: #4ade80;
  color: white;
  box-shadow: 0 0 15px rgba(74, 222, 128, 0.4);
}

.step-label-static {
  font-size: 0.85em;
  color: rgba(255,255,255,0.8);
  text-align: center;
  font-weight: 500;
  transition: all 0.3s ease;
}

.workflow-step-static.step-running .step-label-static {
  color: #ffd700;
  font-weight: 600;
}

.workflow-step-static.step-completed .step-label-static {
  color: #4ade80;
  font-weight: 600;
}

.connector-static {
  color: rgba(148,163,184,0.6);
  font-size: 1.5em;
  margin: 0 10px;
  transition: all 0.3s ease;
}

.connector-static.connector-active {
  color: #4ade80;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.6);
}

@keyframes pulseStatic {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 0 20px rgba(255, 215, 0, 0.6);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 0 30px rgba(255, 215, 0, 0.8);
  }
}

.system-status {
  display: flex;
  justify-content: center;
  gap: 30px;
  padding-top: 15px;
  border-top: 1px solid rgba(148,163,184,0.2);
}

.status-item {
  font-size: 0.9em;
  color: rgba(255,255,255,0.7);
  padding: 4px 12px;
  background: rgba(255,255,255,0.05);
  border-radius: 15px;
  border: 1px solid rgba(255,255,255,0.1);
}

.workflow-message {
  font-size: 0.95em;
  color: #ffd700;
  font-weight: 600;
  text-align: center;
  margin-top: 10px;
  padding: 8px 16px;
  background: rgba(255,215,0,0.1);
  border-radius: 15px;
  border: 1px solid rgba(255,215,0,0.3);
}

/* Bannière Workflow Active - Plus spectaculaire quand en cours */
.workflow-banner-active {
  margin: 20px;
  background: linear-gradient(135deg, rgba(15,20,25,0.95) 0%, rgba(30,41,59,0.95) 50%, rgba(45,55,72,0.95) 100%);
  border: 2px solid rgba(255,215,0,0.4);
  border-radius: 20px;
  padding: 30px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.4), 0 0 20px rgba(255,215,0,0.3);
  backdrop-filter: blur(20px);
  position: relative;
  overflow: hidden;
  animation: workflowGlow 3s ease-in-out infinite alternate;
}

@keyframes workflowGlow {
  0% {
    box-shadow: 0 20px 40px rgba(0,0,0,0.4), 0 0 20px rgba(255,215,0,0.3);
  }
  100% {
    box-shadow: 0 20px 40px rgba(0,0,0,0.4), 0 0 30px rgba(255,215,0,0.5);
  }
}

.workflow-pipeline-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 40px 0;
  overflow-x: auto;
  padding: 20px 0;
  min-height: 120px;
}

.workflow-step-banner {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 200px;
  position: relative;
  transition: all 0.4s ease;
}

.step-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.step-icon-banner {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.1);
  border: 3px solid rgba(255, 255, 255, 0.3);
  font-size: 2.5em;
  transition: all 0.4s ease;
  margin-bottom: 15px;
  position: relative;
  z-index: 2;
}

.workflow-step-banner.active .step-icon-banner {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  border-color: #ffd700;
  color: #333;
  animation: pulseEnhanced 2s infinite;
  box-shadow: 0 0 30px rgba(255, 215, 0, 0.8);
}

.workflow-step-banner.completed .step-icon-banner {
  background: linear-gradient(135deg, #4ade80, #22c55e);
  border-color: #4ade80;
  color: white;
  box-shadow: 0 0 20px rgba(74, 222, 128, 0.6);
}

.workflow-step-banner.error .step-icon-banner {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  border-color: #ef4444;
  color: white;
  animation: shake 0.5s ease-in-out;
}

.step-info {
  text-align: center;
  min-height: 60px;
}

.step-label-banner {
  font-size: 1em;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.workflow-step-banner.active .step-label-banner {
  color: #ffd700;
  text-shadow: 0 0 10px rgba(255, 215, 0, 0.8);
}

.workflow-step-banner.completed .step-label-banner {
  color: #4ade80;
}

.workflow-step-banner.error .step-label-banner {
  color: #ef4444;
}

.step-description, .step-result, .step-error {
  font-size: 0.85em;
  color: rgba(255, 255, 255, 0.7);
  line-height: 1.4;
  max-width: 180px;
}

.step-result {
  color: #4ade80;
  font-weight: 600;
}

.step-error {
  color: #ef4444;
  font-weight: 600;
}

.step-progress-banner {
  position: absolute;
  bottom: -15px;
  left: 50%;
  transform: translateX(-50%);
  width: 100px;
  height: 4px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 2px;
  overflow: hidden;
}

.progress-bar-banner {
  height: 100%;
  background: linear-gradient(90deg, #ffd700, #ffed4e);
  animation: progressSlideEnhanced 2s ease-in-out infinite;
}

.progress-glow {
  position: absolute;
  top: -2px;
  left: -10px;
  width: 20px;
  height: 8px;
  background: radial-gradient(ellipse, rgba(255, 215, 0, 0.8) 0%, transparent 70%);
  animation: glowMove 2s ease-in-out infinite;
}

.step-connector-banner {
  position: absolute;
  top: 40px;
  right: -100px;
  width: 200px;
  display: flex;
  align-items: center;
  opacity: 0.3;
  transition: all 0.4s ease;
  z-index: 1;
}

.step-connector-banner.active {
  opacity: 1;
}

.connector-line-banner {
  flex: 1;
  height: 3px;
  background: rgba(255, 255, 255, 0.3);
  transition: all 0.4s ease;
  position: relative;
}

.step-connector-banner.active .connector-line-banner {
  background: linear-gradient(90deg, #4ade80, #22c55e);
  box-shadow: 0 0 10px rgba(74, 222, 128, 0.6);
}

.connector-data-flow {
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  transform: translateY(-50%);
  height: 3px;
  overflow: hidden;
}

.data-particle {
  position: absolute;
  width: 8px;
  height: 3px;
  background: linear-gradient(90deg, transparent, #4ade80, transparent);
  animation: dataParticle 3s linear infinite;
}

.data-particle:nth-child(2) {
  animation-delay: 1s;
}

.data-particle:nth-child(3) {
  animation-delay: 2s;
}

.connector-arrow-banner {
  color: rgba(255, 255, 255, 0.3);
  font-size: 1.8em;
  margin-left: 10px;
  transition: all 0.4s ease;
}

.step-connector-banner.active .connector-arrow-banner {
  color: #4ade80;
  text-shadow: 0 0 10px rgba(74, 222, 128, 0.8);
}

.workflow-status-banner {
  text-align: center;
  padding: 20px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 15px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.status-text {
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
  font-size: 1.1em;
  margin-bottom: 15px;
}

.system-metrics {
  display: flex;
  justify-content: center;
  gap: 30px;
  flex-wrap: wrap;
}

.metric {
  background: rgba(255, 255, 255, 0.1);
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 0.9em;
  color: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

/* Animations améliorées */
@keyframes pulseEnhanced {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 0 30px rgba(255, 215, 0, 0.8);
  }
  50% {
    transform: scale(1.1);
    box-shadow: 0 0 50px rgba(255, 215, 0, 1);
  }
}

@keyframes progressSlideEnhanced {
  0% {
    transform: translateX(-120%);
  }
  100% {
    transform: translateX(120%);
  }
}

@keyframes glowMove {
  0% {
    left: -10px;
  }
  100% {
    left: 110px;
  }
}

@keyframes dataParticle {
  0% {
    left: -10px;
    opacity: 0;
  }
  20% {
    opacity: 1;
  }
  80% {
    opacity: 1;
  }
  100% {
    left: 210px;
    opacity: 0;
  }
}

@keyframes dataFlow {
  0% {
    transform: translateX(0);
  }
  100% {
    transform: translateX(50px);
  }
}

@keyframes shake {
  0%, 100% {
    transform: translateX(0);
  }
  25% {
    transform: translateX(-5px);
  }
  75% {
    transform: translateX(5px);
  }
}

/* Animations */
@keyframes pulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 215, 0, 0.7);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 0 0 10px rgba(255, 215, 0, 0);
  }
}

@keyframes progressSlide {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

/* Responsive adjustments */
@media (max-width: 1200px) {
  .memory-layout {
    grid-template-columns: 25% 50% 25%;
  }
}

@media (max-width: 900px) {
  .memory-layout {
    grid-template-columns: 1fr;
    grid-template-rows: auto auto 1fr;
  }

  .context-panel, .export-panel {
    height: auto;
  }
}

/* Styles pour Mode Full */
.full-mode-section {
  margin: 16px 0;
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.full-mode-checkbox {
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: 14px;
  color: #e2e8f0;
}

.checkbox-input {
  margin-right: 10px;
  transform: scale(1.4);
  accent-color: #667eea;
  cursor: pointer;
}

.checkbox-input:checked {
  background-color: #667eea;
  border-color: #667eea;
}

.full-mode-description {
  margin-top: 8px;
  padding: 8px 12px;
  background: rgba(102, 126, 234, 0.1);
  border-radius: 6px;
  font-size: 12px;
  color: #a0aec0;
  border-left: 3px solid #667eea;
}
</style>