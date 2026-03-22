<template>
  <div class="sprint-dashboard">
    <!-- Header avec sélection de projet -->
    <div class="dashboard-header">
      <h2>🏃 Sprint Management Dashboard</h2>
      <div class="project-selector">
        <select v-model="selectedProject" @change="loadProjectData" class="project-select">
          <option value="">-- Select Project --</option>
          <option v-for="project in projects" :key="project.id" :value="project.id">
            {{ project.id }} - {{ project.name }}
          </option>
        </select>
        <button @click="showAttachPRD = true" class="btn-attach-prd">📎 Attacher PRD</button>
        <button @click="showCreateProject = true" class="btn-create-project">📁 Nouveau Projet</button>
        <button @click="showDeleteProject = true" class="btn-delete-project" v-if="selectedProject">🗑️ Supprimer</button>
        <button @click="syncProjects" class="btn-sync-projects" :disabled="syncInProgress">
          {{ syncInProgress ? '🔄 Sync...' : '🔄 Sync DB' }}
        </button>

        <!-- WebSocket Status -->
        <div class="ws-status">
          <span class="ws-indicator" :class="{ connected: wsConnected }">
            {{ wsConnected ? '🟢' : '🔴' }}
          </span>
          <span class="ws-label">
            WebSocket {{ wsConnected ? 'LIVE' : 'OFF' }}
          </span>
        </div>

      </div>
    </div>

    <!-- Dashboard unifié avec 3 panneaux -->
    <div class="unified-dashboard">
      <!-- Panneau 1: Liste des Sprints -->
      <div class="liquid-glass-panel sprints-panel">
        <div class="panel-header">
          <h3>📊 Sprints</h3>
          <span class="panel-badge">{{ sprints.length }} sprint(s)</span>
        </div>
        <div class="sprints-list">
          <div
            v-for="sprint in sprints"
            :key="sprint.name"
            class="sprint-item"
            :class="{ active: selectedSprint === sprint.name }"
            @click="selectSprint(sprint.name)"
            @contextmenu.prevent="showSprintContextMenu($event, sprint)"
          >
            <div class="sprint-info">
              <div class="sprint-name">{{ sprint.name }}</div>
              <div class="sprint-description">{{ sprint.description }}</div>
            </div>
            <div class="sprint-stats">
              <div class="progress-mini">
                <div class="progress-fill" :style="{width: sprint.progress + '%'}"></div>
              </div>
              <div class="sprint-metrics">
                <span class="task-count">{{ sprint.tasks.length }} tâches</span>
                <span class="progress-percent">{{ sprint.progress }}%</span>
              </div>
              <div class="sprint-agents">
                <AgentAvatar
                  v-for="agent in sprint.agents"
                  :key="agent"
                  :agent="agent"
                  size="medium"
                  class="agent-mini"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Panneau 2: Kanban du Sprint Sélectionné -->
      <div class="liquid-glass-panel kanban-panel">
        <div class="panel-header">
          <div class="kanban-header-content">
            <h3>📋 {{ selectedSprint || 'Sélectionnez un Sprint' }}</h3>
            <div v-if="selectedSprint" class="sprint-progress-header">
              <div class="progress-info">
                <span class="progress-text">{{ currentSprintProgress.progress }}% Complete</span>
                <span class="tasks-counter">{{ currentSprintProgress.done }}/{{ currentSprintProgress.total }}</span>
              </div>
              <div class="progress-bar-header">
                <div class="progress-fill" :style="{width: currentSprintProgress.progress + '%'}"></div>
              </div>
            </div>
          </div>
          <div class="kanban-controls">
            <span v-if="selectedSprint" class="panel-badge">{{ currentSprintTasks.length }} tâches</span>
            <button v-if="agentFilterActive" @click="resetAgentFilter" class="reset-filter-btn">
              🔄 Réinitialiser filtre
            </button>
          </div>
        </div>
        <div v-if="selectedSprint" class="kanban-board">
          <div
            v-for="column in boardColumns"
            :key="column.key"
            class="kanban-column"
          >
            <div class="column-header">
              <span class="column-icon">{{ column.icon }}</span>
              <span class="column-title">{{ column.title }}</span>
              <span class="task-count">{{ getTasksByStatus(column.key).length }}</span>
            </div>
            <div class="column-content">
              <div
                v-for="task in getTasksByStatus(column.key)"
                :key="task.id"
                :data-task-id="task.id"
                class="task-card"
                :class="{ highlighted: highlightedTask === task.id }"
                @click="openTaskDetail(task)"
              >
                <div class="task-header">
                  <span class="task-priority" :class="task.priority">{{ task.priority }}</span>
                  <div class="task-agent-badge">
                    <AgentAvatar :agent="task.assigned_to" size="medium" />
                  </div>
                </div>
                <div class="task-title">{{ task.title }}</div>
                <div class="task-progress">
                  {{ task.completed_checkboxes }}/{{ task.total_checkboxes }} ✓
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="empty-state">
          <div class="empty-icon">🎯</div>
          <div class="empty-text">Sélectionnez un sprint pour voir son Kanban</div>
        </div>
      </div>

      <!-- Panneau 3: Workload Agents (filtré par sprint) -->
      <div class="liquid-glass-panel workload-panel">
        <div class="panel-header">
          <h3>👥 Agent Workload</h3>
          <span v-if="selectedSprint" class="panel-badge">{{ selectedSprint }}</span>
        </div>
        <div v-if="selectedSprint && currentSprintAgents.length > 0" class="agent-filters">
          <div class="filter-header">
            <span class="filter-title">Filtrer par agent:</span>
          </div>
          <div class="filter-checkboxes">
            <label
              v-for="agent in currentSprintAgents"
              :key="agent.name"
              class="agent-filter-checkbox"
              :style="{ borderColor: getAgentColor(agent.name) }"
            >
              <input
                type="checkbox"
                :checked="isAgentFiltered(agent.name)"
                @change="toggleAgentFilter(agent.name)"
              />
              <AgentAvatar :agent="agent.name" size="medium" class="agent-filter-icon" />
              <span class="agent-filter-name" :style="{ color: getAgentColor(agent.name) }">
                {{ agent.name }}
              </span>
              <span class="agent-filter-count">{{ agent.tasks.length }}</span>
            </label>
          </div>
        </div>
        <div class="workload-content">
          <div v-if="selectedSprint" class="agents-list">
            <div
              v-for="agent in currentSprintAgents"
              :key="agent.name"
              class="agent-workload-item"
              :style="{ borderLeft: `4px solid ${getAgentColor(agent.name)}` }"
            >
              <div class="agent-header">
                <div class="agent-info" @click="filterByAgent(agent.name)">
                  <AgentAvatar :agent="agent.name" size="large" class="agent-icon" />
                  <span class="agent-name" :style="{ color: getAgentColor(agent.name) }">{{ agent.name }}</span>
                </div>
                <span class="task-count" :style="{ backgroundColor: getAgentColor(agent.name) }">{{ agent.tasks.length }}</span>
              </div>
              <div class="agent-tasks">
                <div
                  v-for="task in agent.tasks"
                  :key="task.id"
                  class="workload-task"
                  @click="highlightTaskInKanban(task)"
                >
                  <span class="task-status" :class="task.status.toLowerCase()">
                    {{ task.status }}
                  </span>
                  <span class="task-name">{{ task.title.substring(0, 25) }}...</span>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="empty-state">
            <div class="empty-icon">👥</div>
            <div class="empty-text">Sélectionnez un sprint pour voir la répartition des agents</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Menu contextuel pour sprints -->
    <div
      v-if="contextMenu.show"
      class="context-menu"
      :style="{ top: contextMenu.y + 'px', left: contextMenu.x + 'px' }"
      @click.stop
    >
      <div class="context-menu-item delete" @click="deleteSprint">
        🗑️ Supprimer Sprint
      </div>
      <div class="context-menu-item" @click="clearSprintTasks">
        🧹 Vider Tâches
      </div>
      <div class="context-menu-item" @click="hideContextMenu">
        ❌ Annuler
      </div>
    </div>

    <!-- Modal pour attacher PRD -->
    <AttachPRDModal
      v-if="showAttachPRD"
      @close="showAttachPRD = false"
      @attached="onPRDAttached"
    />

    <!-- Modal pour créer projet -->
    <div v-if="showCreateProject" class="modal-overlay" @click="showCreateProject = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>📁 Nouveau Projet</h3>
          <button @click="showCreateProject = false" class="close-btn">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Nom du projet :</label>
            <input
              v-model="newProjectName"
              type="text"
              placeholder="Entrez le nom du projet"
              @keyup.enter="createProject"
              autofocus
            />
          </div>
          <div class="form-group">
            <label>Contenu PRD (optionnel) :</label>
            <textarea
              v-model="newProjectPRD"
              placeholder="Collez le contenu du PRD ici..."
              rows="6"
            ></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="showCreateProject = false" class="btn-cancel">Annuler</button>
          <button @click="createProject" class="btn-create" :disabled="!newProjectName.trim()">Créer</button>
        </div>
      </div>
    </div>

    <!-- Modal pour supprimer projet -->
    <div v-if="showDeleteProject" class="modal-overlay" @click="showDeleteProject = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>🗑️ Supprimer Projet</h3>
          <button @click="showDeleteProject = false" class="close-btn">×</button>
        </div>
        <div class="modal-body">
          <p>Êtes-vous sûr de vouloir supprimer le projet <strong>{{ getSelectedProjectName() }}</strong> ?</p>
          <p class="warning">⚠️ Cette action supprimera complètement le dossier du projet.</p>
        </div>
        <div class="modal-footer">
          <button @click="showDeleteProject = false" class="btn-cancel">Annuler</button>
          <button @click="deleteProject" class="btn-delete">Supprimer</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import AttachPRDModal from './AttachPRDModal.vue'
import CreateProjectModal from './CreateProjectModal.vue'
import AgentAvatar from './AgentAvatar.vue'
import LiquidGlass from '@zaosoula/liquid-glass-vue'

export default {
  name: 'SprintDashboard',
  components: {
    AttachPRDModal,
    CreateProjectModal,
    AgentAvatar,
    LiquidGlass
  },
  setup() {
    const projects = ref([])
    const selectedProject = ref('')
    const tasks = ref([])
    const currentView = ref('sprints')
    const selectedSprint = ref('')
    const showAttachPRD = ref(false)
    const showCreateProject = ref(false)
    const showDeleteProject = ref(false)
    const newProjectName = ref('')
    const newProjectPRD = ref('')
    const highlightedTask = ref(null)
    const filteredAgents = ref(new Set())
    const agentFilterActive = ref(false)
    const syncInProgress = ref(false)

    // Auto-refresh functionality
    const autoRefreshEnabled = ref(false)
    let refreshInterval = null

    // WebSocket connection
    let websocket = null
    const wsConnected = ref(false)

    // Context menu
    const contextMenu = ref({
      show: false,
      x: 0,
      y: 0,
      sprint: null
    })

    const boardColumns = [
      { key: 'TODO', title: 'To Do', icon: '📋', color: '#f8f9fa' },
      { key: 'IN_PROGRESS', title: 'In Progress', icon: '🚀', color: '#fff3cd' },
      { key: 'DONE', title: 'Done', icon: '✅', color: '#d4edda' }
    ]

    // Computed properties
    const sprints = computed(() => {
      const sprintMap = new Map()

      tasks.value.forEach(task => {
        const sprintName = task.sprint || 'Sprint 1'
        if (!sprintMap.has(sprintName)) {
          sprintMap.set(sprintName, {
            name: sprintName,
            description: getSprintDescription(sprintName),
            tasks: [],
            progress: 0,
            agents: new Set()
          })
        }
        const sprint = sprintMap.get(sprintName)
        sprint.tasks.push(task)
        if (task.assigned_to) sprint.agents.add(task.assigned_to)
      })

      // Calculate progress for each sprint
      sprintMap.forEach(sprint => {
        const doneTasks = sprint.tasks.filter(task => task.status === 'DONE').length
        sprint.progress = sprint.tasks.length > 0 ? Math.round((doneTasks / sprint.tasks.length) * 100) : 0
        sprint.agents = Array.from(sprint.agents)
      })

      return Array.from(sprintMap.values())
    })

    const currentSprintTasks = computed(() => {
      let sprintTasks = tasks.value.filter(task => (task.sprint || 'Sprint 1') === selectedSprint.value)

      // Apply agent filter if active
      if (agentFilterActive.value && filteredAgents.value.size > 0) {
        sprintTasks = sprintTasks.filter(task => filteredAgents.value.has(task.assigned_to))
      }

      return sprintTasks
    })

    const currentSprintAgents = computed(() => {
      if (!selectedSprint.value) return []

      const agentMap = new Map()

      currentSprintTasks.value.forEach(task => {
        if (!task.assigned_to) return

        const agentName = task.assigned_to
        if (!agentMap.has(agentName)) {
          agentMap.set(agentName, {
            name: agentName,
            tasks: []
          })
        }

        agentMap.get(agentName).tasks.push(task)
      })

      return Array.from(agentMap.values())
    })

    const totalTasks = computed(() => tasks.value.length)

    const currentSprintProgress = computed(() => {
      if (!selectedSprint.value) return { progress: 0, total: 0, done: 0 }

      const sprintTasks = tasks.value.filter(task => (task.sprint || 'Sprint 1') === selectedSprint.value)
      const doneTasks = sprintTasks.filter(task => task.status === 'DONE').length
      const progress = sprintTasks.length > 0 ? Math.round((doneTasks / sprintTasks.length) * 100) : 0

      return {
        progress,
        total: sprintTasks.length,
        done: doneTasks
      }
    })

    const agentWorkload = computed(() => {
      const agentMap = new Map()

      tasks.value.forEach(task => {
        if (!task.assigned_to) return

        const agentName = task.assigned_to
        if (!agentMap.has(agentName)) {
          agentMap.set(agentName, {
            name: agentName,
            totalTasks: 0,
            sprints: new Map()
          })
        }

        const agent = agentMap.get(agentName)
        agent.totalTasks++

        const sprintName = task.sprint || 'Sprint 1'
        if (!agent.sprints.has(sprintName)) {
          agent.sprints.set(sprintName, {
            sprint: sprintName,
            tasks: []
          })
        }
        agent.sprints.get(sprintName).tasks.push(task)
      })

      // Convert Maps to Arrays
      const result = Array.from(agentMap.values())
      result.forEach(agent => {
        agent.sprints = Array.from(agent.sprints.values())
      })

      return result
    })

    // Methods
    const loadProjects = async () => {
      try {
        console.log('Loading projects...')
        const controller = new AbortController()
        const timeoutId = setTimeout(() => controller.abort(), 5000)

        const response = await fetch('http://localhost:3001/api/projects', {
          signal: controller.signal
        })
        clearTimeout(timeoutId)
        console.log('Response status:', response.status)

        if (response.ok) {
          const data = await response.json()
          console.log('Received projects:', data)
          projects.value = data.projects || data

          // Auto-select first project if only one
          if (!selectedProject.value && projects.value.length > 0) {
            selectedProject.value = projects.value[0].id
            loadProjectData()
          }
        } else {
          console.error('Failed to load projects:', response.status, response.statusText)
          alert(`Erreur chargement projets: ${response.status} ${response.statusText}`)
        }
      } catch (error) {
        console.error('Error loading projects:', error)
        if (error.name === 'AbortError') {
          alert('Timeout: Le chargement des projets a pris trop de temps')
        } else {
          alert('Erreur réseau lors du chargement des projets: ' + (error.message || 'Erreur inconnue'))
        }
      }
    }

    const loadProjectData = async () => {
      if (!selectedProject.value) {
        tasks.value = []
        return
      }

      try {
        const response = await fetch(`http://localhost:3001/api/tasks?project_id=${selectedProject.value}`)
        if (response.ok) {
          tasks.value = await response.json()
        }
      } catch (error) {
        console.error('Error loading tasks:', error)
      }
    }

    const selectSprint = (sprintName) => {
      selectedSprint.value = sprintName
      currentView.value = 'kanban'
    }

    const backToSprints = () => {
      currentView.value = 'sprints'
      selectedSprint.value = ''
    }

    const getTasksByStatus = (status) => {
      return currentSprintTasks.value.filter(task => task.status === status)
    }

    const getSprintDescription = (sprintName) => {
      const descriptions = {
        'Sprint 1': 'MVP - Architecture et fonctionnalités de base',
        'Sprint 2': 'Intégration et tests complets',
        'Sprint 3': 'Optimisation et déploiement'
      }
      return descriptions[sprintName] || 'Sprint de développement'
    }

    const getProjectName = () => {
      const project = projects.value.find(p => p.id == selectedProject.value)
      return project ? project.name : ''
    }

    const getAgentIcon = (agent) => {
      const icons = {
        'nestor': '🎩',
        'tintin': '🚀',
        'dupont1': '🎨',
        'dupont2': '🔍'
      }
      return icons[agent] || '👤'
    }

    const getAgentColor = (agent) => {
      const colors = {
        'dupont1': '#2196F3',    // Bleu
        'dupont2': '#4CAF50',    // Vert
        'tintin': '#FF9800',     // Orange
        'nestor': '#9C27B0'      // Violet
      }
      return colors[agent] || '#757575'
    }

    const getAgentColorLight = (agent) => {
      const colors = {
        'dupont1': '#E3F2FD',    // Bleu clair
        'dupont2': '#E8F5E8',    // Vert clair
        'tintin': '#FFF3E0',     // Orange clair
        'nestor': '#F3E5F5'      // Violet clair
      }
      return colors[agent] || '#F5F5F5'
    }

    const openTaskDetail = (task) => {
      // TODO: Implement task detail modal
      console.log('Open task detail:', task)
    }

    const highlightTaskInKanban = (task) => {
      highlightedTask.value = task.id
      // Scroll to the task in kanban
      setTimeout(() => {
        const taskElement = document.querySelector(`[data-task-id="${task.id}"]`)
        if (taskElement) {
          taskElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      }, 100)
      // Remove highlight after 3 seconds
      setTimeout(() => {
        highlightedTask.value = null
      }, 3000)
    }

    const filterByAgent = (agent) => {
      agentFilterActive.value = true
      filteredAgents.value = new Set([agent])
    }

    const toggleAgentFilter = (agent) => {
      if (filteredAgents.value.has(agent)) {
        filteredAgents.value.delete(agent)
      } else {
        filteredAgents.value.add(agent)
      }
      agentFilterActive.value = filteredAgents.value.size > 0
    }

    const resetAgentFilter = () => {
      agentFilterActive.value = false
      filteredAgents.value = new Set()
    }

    const isAgentFiltered = (agent) => {
      return filteredAgents.value.has(agent)
    }

    const onPRDAttached = () => {
      showAttachPRD.value = false
      loadProjects()
      loadProjectData()
    }

    const onProjectCreated = (project) => {
      console.log('Projet créé:', project)
      showCreateProject.value = false
      loadProjects()
      // Sélectionner automatiquement le nouveau projet
      selectedProject.value = project.id
      loadProjectData()
    }

    const createProject = async () => {
      if (!newProjectName.value.trim()) return

      try {
        // Utiliser directement le nom du projet (propre)
        const folderName = newProjectName.value.trim().replace(/[^a-zA-Z0-9\-_]/g, '_').toLowerCase()

        const response = await fetch('http://localhost:3001/api/projects/create-simple', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: newProjectName.value.trim(),
            folder_name: folderName,
            prd_content: newProjectPRD.value || `# PRD - ${newProjectName.value}\n\n## Description\n\nNouveau projet créé le ${new Date().toLocaleDateString()}\n`
          })
        })

        if (response.ok) {
          const result = await response.json()
          console.log('Projet créé:', result)

          // Reset form
          newProjectName.value = ''
          newProjectPRD.value = ''
          showCreateProject.value = false

          // Recharger la liste des projets
          await loadProjects()

          // Sélectionner le nouveau projet s'il existe
          if (result.project?.id) {
            selectedProject.value = result.project.id
            await loadProjectData()
          }
        } else {
          const error = await response.json()
          alert('Erreur lors de la création du projet: ' + (error.error || 'Erreur inconnue'))
        }
      } catch (error) {
        console.error('Erreur:', error)
        alert('Erreur lors de la création du projet: ' + error.message)
      }
    }

    const getSelectedProjectName = () => {
      const project = projects.value.find(p => p.id === selectedProject.value)
      return project ? project.name : 'Projet sélectionné'
    }

    const deleteProject = async () => {
      if (!selectedProject.value) return

      try {
        // Ajouter un timeout de 10 secondes
        const controller = new AbortController()
        const timeoutId = setTimeout(() => controller.abort(), 10000)

        const response = await fetch(`http://localhost:3001/api/projects/${selectedProject.value}`, {
          method: 'DELETE',
          signal: controller.signal,
          headers: {
            'Content-Type': 'application/json'
          }
        })

        clearTimeout(timeoutId)

        if (response.ok) {
          console.log('Projet supprimé')
          showDeleteProject.value = false
          selectedProject.value = ''
          tasks.value = []
          await loadProjects()
        } else {
          const error = await response.json()
          alert('Erreur lors de la suppression: ' + (error.error || 'Erreur inconnue'))
        }
      } catch (error) {
        console.error('Erreur:', error)
        if (error.name === 'AbortError') {
          alert('Timeout: La suppression a pris trop de temps')
        } else {
          alert('Erreur lors de la suppression: ' + (error.message || 'Erreur réseau'))
        }
      }
    }

    // WebSocket functions
    const connectWebSocket = () => {
      try {
        websocket = new WebSocket('ws://localhost:3001/ws')

        websocket.onopen = () => {
          console.log('🔌 WebSocket connecté!')
          wsConnected.value = true
        }

        websocket.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            console.log('📨 WebSocket message:', data)

            // Si c'est une mise à jour de tâche, recharger
            if (data.type === 'task_updated' || data.type === 'task_created' || data.type === 'task_deleted') {
              console.log('🔄 Rechargement automatique via WebSocket')
              loadProjectData()
            }
          } catch (err) {
            console.error('❌ Erreur parsing WebSocket:', err)
          }
        }

        websocket.onclose = () => {
          console.log('🔌 WebSocket déconnecté')
          wsConnected.value = false
          // Reconnection automatique après 3 secondes
          setTimeout(connectWebSocket, 3000)
        }

        websocket.onerror = (error) => {
          console.error('❌ Erreur WebSocket:', error)
          wsConnected.value = false
        }
      } catch (err) {
        console.error('❌ Impossible de créer WebSocket:', err)
      }
    }

    // Auto-refresh toggle function (garde en fallback)
    const toggleAutoRefresh = () => {
      if (autoRefreshEnabled.value) {
        // Start auto-refresh every 5 seconds
        refreshInterval = setInterval(() => {
          console.log('🔄 Auto-refreshing tasks...')
          loadProjectData()
        }, 5000)
      } else {
        // Stop auto-refresh
        if (refreshInterval) {
          clearInterval(refreshInterval)
          refreshInterval = null
        }
      }
    }

    onMounted(() => {
      loadProjects()
      connectWebSocket()
    })

    // Fonctions menu contextuel
    const showSprintContextMenu = (event, sprint) => {
      contextMenu.value = {
        show: true,
        x: event.clientX,
        y: event.clientY,
        sprint: sprint
      }
    }

    const hideContextMenu = () => {
      contextMenu.value.show = false
    }

    const deleteSprint = async () => {
      const sprint = contextMenu.value.sprint
      if (!sprint) return

      const confirmed = confirm(`⚠️ Supprimer définitivement le sprint "${sprint.name}" et toutes ses tâches ?`)
      if (!confirmed) {
        hideContextMenu()
        return
      }

      try {
        // Supprimer toutes les tâches du sprint
        const response = await fetch(`http://localhost:3001/api/tasks/sprint/${encodeURIComponent(sprint.name)}`, {
          method: 'DELETE'
        })

        if (response.ok) {
          console.log(`🗑️ Sprint "${sprint.name}" supprimé`)
          loadProjectData() // Recharger les données
        } else {
          alert('❌ Erreur lors de la suppression du sprint')
        }
      } catch (err) {
        console.error('Erreur suppression sprint:', err)
        alert('❌ Erreur lors de la suppression')
      }

      hideContextMenu()
    }

    const clearSprintTasks = async () => {
      const sprint = contextMenu.value.sprint
      if (!sprint) return

      const confirmed = confirm(`🧹 Vider toutes les tâches du sprint "${sprint.name}" ?`)
      if (!confirmed) {
        hideContextMenu()
        return
      }

      try {
        const response = await fetch(`http://localhost:3001/api/tasks/sprint/${encodeURIComponent(sprint.name)}/clear`, {
          method: 'DELETE'
        })

        if (response.ok) {
          console.log(`🧹 Tâches du sprint "${sprint.name}" vidées`)
          loadProjectData()
        } else {
          alert('❌ Erreur lors du vidage des tâches')
        }
      } catch (err) {
        console.error('Erreur vidage tâches:', err)
        alert('❌ Erreur lors du vidage')
      }

      hideContextMenu()
    }

    const syncProjects = async () => {
      if (syncInProgress.value) return

      try {
        syncInProgress.value = true
        console.log('🔄 Synchronisation des projets...')

        const response = await fetch('http://localhost:3001/api/projects/sync', {
          method: 'POST'
        })

        if (response.ok) {
          const result = await response.json()
          console.log('✅ Synchronisation terminée:', result.report)

          // Afficher un résumé à l'utilisateur
          let message = 'Synchronisation terminée:\n'
          if (result.report.added.length > 0) {
            message += `• ${result.report.added.length} projet(s) ajouté(s)\n`
          }
          if (result.report.removed.length > 0) {
            message += `• ${result.report.removed.length} projet(s) supprimé(s)\n`
          }
          if (result.report.errors.length > 0) {
            message += `• ${result.report.errors.length} erreur(s)\n`
          }
          if (result.report.added.length === 0 && result.report.removed.length === 0) {
            message += '• Aucun changement nécessaire'
          }

          alert(message)

          // Recharger les projets
          await loadProjects()
        } else {
          const error = await response.json()
          alert('Erreur lors de la synchronisation: ' + (error.error || 'Erreur inconnue'))
        }
      } catch (error) {
        console.error('Erreur:', error)
        alert('Erreur lors de la synchronisation: ' + error.message)
      } finally {
        syncInProgress.value = false
      }
    }

    // Cacher menu contextuel si clic ailleurs
    const handleClickOutside = () => {
      hideContextMenu()
    }

    onMounted(() => {
      loadProjects()
      connectWebSocket()
      document.addEventListener('click', handleClickOutside)
    })

    onUnmounted(() => {
      // Nettoyer les connexions
      if (refreshInterval) {
        clearInterval(refreshInterval)
      }
      if (websocket) {
        websocket.close()
      }
      document.removeEventListener('click', handleClickOutside)
    })

    return {
      projects,
      selectedProject,
      tasks,
      currentView,
      selectedSprint,
      showAttachPRD,
      showCreateProject,
      showDeleteProject,
      newProjectName,
      newProjectPRD,
      highlightedTask,
      filteredAgents,
      agentFilterActive,
      boardColumns,
      sprints,
      currentSprintTasks,
      currentSprintAgents,
      currentSprintProgress,
      totalTasks,
      agentWorkload,
      loadProjectData,
      selectSprint,
      backToSprints,
      getTasksByStatus,
      getProjectName,
      getAgentIcon,
      getAgentColor,
      getAgentColorLight,
      openTaskDetail,
      highlightTaskInKanban,
      filterByAgent,
      toggleAgentFilter,
      resetAgentFilter,
      isAgentFiltered,
      onPRDAttached,
      onProjectCreated,
      createProject,
      deleteProject,
      getSelectedProjectName,
      autoRefreshEnabled,
      toggleAutoRefresh,
      wsConnected,
      contextMenu,
      showSprintContextMenu,
      hideContextMenu,
      deleteSprint,
      clearSprintTasks,
      syncProjects,
      syncInProgress
    }
  }
}
</script>

<style scoped>
.sprint-dashboard {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid #eee;
}

.dashboard-header h2 {
  margin: 0;
  color: #333;
}

.project-selector {
  display: flex;
  gap: 15px;
  align-items: center;
  background: rgba(255, 255, 255, 0.2) !important;
  backdrop-filter: blur(15px) saturate(180%) contrast(115%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) contrast(115%) !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  border-radius: 18px !important;
  padding: 8px 20px !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08) !important;
}

.refresh-controls {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 15px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 2px solid #e0e0e0;
}

.refresh-switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
}

.refresh-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: 0.4s;
  border-radius: 24px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #4a90e2;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.refresh-label {
  font-size: 14px;
  color: #555;
  font-weight: 500;
}

.refresh-status {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
  margin-left: 8px;
}

.refresh-status {
  background: #4CAF50;
  color: white;
}

.refresh-status.off {
  background: #ccc;
  color: #666;
}

.ws-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 15px !important;
  background: rgba(255, 255, 255, 0.18) !important;
  backdrop-filter: blur(10px) saturate(160%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(160%) !important;
  border-radius: 12px !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
}

.ws-indicator {
  font-size: 16px;
  animation: pulse 2s infinite;
}

.ws-indicator.connected {
  animation: none;
}

.ws-label {
  font-size: 14px;
  font-weight: bold;
  color: #666;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.context-menu {
  position: fixed;
  background: rgba(255, 255, 255, 0.28) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
  border-radius: 16px !important;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2), 0 6px 20px rgba(0, 0, 0, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  z-index: 1000;
  min-width: 180px;
  overflow: hidden;
  animation: fadeInScale 0.25s cubic-bezier(0.23, 1, 0.32, 1);
}

.context-menu-item {
  padding: 12px 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  background: rgba(255, 255, 255, 0.05) !important;
}

.context-menu-item:last-child {
  border-bottom: none;
}

.context-menu-item:hover {
  background: rgba(255, 255, 255, 0.2) !important;
  backdrop-filter: blur(12px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(12px) saturate(180%) !important;
  transform: translateX(6px) scale(1.02) !important;
  border-radius: 8px !important;
  margin: 2px 4px !important;
}

.context-menu-item.delete {
  color: #dc3545 !important;
}

.context-menu-item.delete:hover {
  background: rgba(220, 53, 69, 0.15) !important;
  backdrop-filter: blur(15px) saturate(200%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(200%) !important;
  color: #b02a37 !important;
}

@keyframes fadeInScale {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.project-select {
  padding: 10px 15px !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
  border-radius: 12px !important;
  font-size: 14px !important;
  background: rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px) saturate(160%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(160%) !important;
  color: #333 !important;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
  transition: all 0.3s ease !important;
}

.project-select:hover {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.4) !important;
}

.btn-attach-prd, .btn-create-project, .btn-delete-project, .btn-sync-projects {
  padding: 10px 20px !important;
  color: white !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 12px !important;
  cursor: pointer !important;
  font-weight: bold !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
  backdrop-filter: blur(10px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(180%) !important;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1) !important;
}

.btn-attach-prd {
  background: rgba(102, 126, 234, 0.8) !important;
}

.btn-create-project {
  background: rgba(16, 185, 129, 0.8) !important;
}

.btn-delete-project {
  background: rgba(220, 53, 69, 0.8) !important;
}

.btn-sync-projects {
  background: rgba(156, 39, 176, 0.8) !important;
}

.btn-sync-projects:disabled {
  background: rgba(108, 117, 125, 0.8) !important;
  cursor: not-allowed !important;
  opacity: 0.6 !important;
}

.btn-attach-prd:hover, .btn-create-project:hover, .btn-delete-project:hover, .btn-sync-projects:hover:not(:disabled) {
  transform: translateY(-2px) scale(1.02) !important;
  backdrop-filter: blur(15px) saturate(200%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(200%) !important;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
}

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
}

.view-header h3 {
  margin: 0;
  color: #333;
}

/* Dashboard unifié avec 3 panneaux - PROPORTIONS ÉQUILIBRÉES */
.unified-dashboard {
  display: flex !important;
  flex-direction: row !important;
  gap: 25px !important;
  height: calc(100vh - 200px) !important;
  margin-top: 20px !important;
  padding: 0 15px !important;
}

.sprints-panel {
  flex: 0 0 280px !important;
  min-width: 280px !important;
}

.kanban-panel {
  flex: 1 !important;
  min-width: 500px !important;
  max-width: calc(100vw - 680px) !important;
}

.workload-panel {
  flex: 0 0 320px !important;
  min-width: 320px !important;
}

/* Apple Liquid Glass Effect - WORKING NOW */
.liquid-glass-panel {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 20px !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
  min-height: 400px !important;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
  position: relative !important;
}

.liquid-glass-panel::before {
  content: '' !important;
  position: absolute !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.02) 50%,
    rgba(255, 255, 255, 0.05) 75%,
    rgba(255, 255, 255, 0.1) 100%
  ) !important;
  border-radius: 20px !important;
  pointer-events: none !important;
}

.liquid-glass-panel:hover {
  background: rgba(255, 255, 255, 0.35) !important;
  backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  -webkit-backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  border: 0.5px solid rgba(255, 255, 255, 0.3) !important;
  box-shadow:
    0 16px 64px rgba(0, 0, 0, 0.15),
    0 4px 16px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.6) !important;
  transform: translateY(-2px) scale(1.005) !important;
}

/* Legacy panel class for compatibility */
.panel {
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 400px;
}


.panel-header {
  background: rgba(0, 0, 0, 0.12);
  backdrop-filter: blur(15px) saturate(150%);
  -webkit-backdrop-filter: blur(15px) saturate(150%);
  color: white;
  padding: 15px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.panel-header h3 {
  margin: 0;
  font-size: 16px;
}

.panel-badge {
  background: rgba(255, 255, 255, 0.2);
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
}

/* Panneau 1: Liste des Sprints */
.sprints-panel {
  min-width: 300px;
}

.sprints-list {
  flex: 1;
  overflow-y: auto;
  padding: 15px;
}

.sprint-item {
  background: rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(12px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(12px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 12px !important;
  padding: 15px !important;
  margin-bottom: 10px !important;
  cursor: pointer !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08) !important;
}

.sprint-item:hover {
  transform: translateY(-2px) scale(1.01);
  background: rgba(255, 255, 255, 0.75);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 6px 30px rgba(0, 0, 0, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.sprint-item.active {
  background: rgba(33, 150, 243, 0.1);
  backdrop-filter: blur(20px) saturate(190%);
  -webkit-backdrop-filter: blur(20px) saturate(190%);
  border: 1px solid rgba(33, 150, 243, 0.3);
  box-shadow: 0 8px 32px rgba(33, 150, 243, 0.2);
}

.sprint-info {
  margin-bottom: 12px;
}

.sprint-name {
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 4px;
}

.sprint-description {
  font-size: 12px;
  color: #5a6c7d;
}

.sprint-stats {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 60px;
}

.progress-mini {
  width: 100%;
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.1);
}

.sprint-metrics {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #5a6c7d;
}

.sprint-agents {
  display: flex;
  gap: 3px;
  align-items: center;
  min-height: 32px;
}

.agent-mini {
  flex-shrink: 0;
}

/* Panneau 2: Kanban */
.kanban-panel {
  min-width: 600px;
}

.kanban-header-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
  flex: 1;
}

.sprint-progress-header {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.progress-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.progress-text {
  color: rgba(255, 255, 255, 0.9);
  font-weight: bold;
}

.tasks-counter {
  color: rgba(255, 255, 255, 0.7);
}

.progress-bar-header {
  width: 100%;
  height: 6px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 3px;
  overflow: hidden;
}

.kanban-controls {
  display: flex;
  align-items: center;
  gap: 10px;
}

.reset-filter-btn {
  padding: 6px 12px;
  background: #FF5722;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 11px;
  font-weight: bold;
  transition: all 0.2s ease;
}

.reset-filter-btn:hover {
  background: #E64A19;
  transform: translateY(-1px);
}

/* Panneau 3: Workload */
.workload-panel {
  min-width: 300px;
}

.agent-filters {
  padding: 15px;
  border-bottom: 1px solid #dee2e6;
  background: #f8f9fa;
}

.filter-header {
  margin-bottom: 10px;
}

.filter-title {
  font-size: 12px;
  font-weight: bold;
  color: #2c3e50;
}

.filter-checkboxes {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.agent-filter-checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: white;
}

.agent-filter-checkbox:hover {
  background: #f8f9fa;
  transform: translateX(2px);
}

.agent-filter-checkbox input[type="checkbox"] {
  margin: 0;
}

.agent-filter-icon {
  font-size: 14px;
}

.agent-filter-name {
  font-size: 12px;
  font-weight: bold;
  flex: 1;
}

.agent-filter-count {
  background: #dee2e6;
  color: #666;
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 10px;
  font-weight: bold;
}

.workload-content {
  flex: 1;
  overflow-y: auto;
  padding: 15px;
}

.agents-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.agent-workload-item {
  background: rgba(255, 255, 255, 0.12) !important;
  backdrop-filter: blur(12px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(12px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 10px !important;
  padding: 15px !important;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
}

.agent-workload-item:hover {
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);
  transform: translateY(-1px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.agent-workload-item .agent-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #dee2e6;
}

.agent-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.agent-info:hover {
  background: rgba(0, 0, 0, 0.05);
}

.agent-icon {
  font-size: 16px;
}

.agent-name {
  font-weight: bold;
  color: #2c3e50;
}

.task-count {
  background: #667eea;
  color: white;
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 11px;
}

.agent-tasks {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.workload-task {
  display: flex;
  gap: 8px;
  align-items: center;
  padding: 8px 12px;
  font-size: 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  margin: 2px 0;
}

.workload-task:hover {
  background: rgba(0, 0, 0, 0.05);
  transform: translateX(4px);
}

.task-status {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 9px;
  font-weight: bold;
  min-width: 50px;
  text-align: center;
  text-transform: uppercase;
}

.task-name {
  color: #5a6c7d;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* État vide */
.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: #5a6c7d;
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 10px;
  opacity: 0.5;
}

.empty-text {
  text-align: center;
  max-width: 200px;
}

/* Vue Sprints - Ancien code gardé pour compatibilité */
.sprints-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.sprint-card {
  background: white;
  border: 2px solid #333;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.sprint-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0,0,0,0.1);
}

.sprint-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.sprint-header h4 {
  margin: 0;
  color: #333;
}

.sprint-badge {
  background: #667eea;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
}

.sprint-description {
  color: #666;
  margin-bottom: 15px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 5px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #28a745, #20c997);
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 12px;
  color: #666;
}

.sprint-agents {
  display: flex;
  gap: 8px;
  margin-top: 15px;
}

.agent-chip {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  padding: 4px 8px;
  border-radius: 16px;
  font-size: 12px;
}

/* Vue Kanban */
.kanban-board {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.kanban-column {
  background: rgba(255, 255, 255, 0.18) !important;
  backdrop-filter: blur(15px) saturate(190%) contrast(115%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(190%) contrast(115%) !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  border-radius: 16px !important;
  overflow: hidden !important;
  box-shadow: 0 6px 25px rgba(0, 0, 0, 0.08) !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

.kanban-column:hover {
  background: rgba(255, 255, 255, 0.28) !important;
  backdrop-filter: blur(20px) saturate(210%) contrast(125%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(210%) contrast(125%) !important;
  transform: translateY(-2px) !important;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12) !important;
}

.column-header {
  background: rgba(51, 51, 51, 0.85) !important;
  backdrop-filter: blur(12px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(12px) saturate(180%) !important;
  color: white !important;
  padding: 15px !important;
  display: flex !important;
  justify-content: space-between !important;
  align-items: center !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
}

.column-content {
  padding: 15px;
  min-height: 400px;
}

.task-card {
  background: rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 10px !important;
  padding: 15px !important;
  margin-bottom: 10px !important;
  cursor: pointer !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08) !important;
}

.task-card:hover {
  transform: translateY(-1px) scale(1.005);
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.task-card.highlighted {
  border: 2px solid #FF5722;
  box-shadow: 0 0 20px rgba(255, 87, 34, 0.3);
  transform: scale(1.02);
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.task-priority {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: bold;
  text-transform: uppercase;
}

.task-priority.high { background: #ffebee; color: #c62828; }
.task-priority.medium { background: #fff3e0; color: #ef6c00; }
.task-priority.low { background: #f3e5f5; color: #7b1fa2; }

.task-agent-badge {
  display: flex;
  align-items: center;
  justify-content: center;
}

.task-agent-icon {
  font-size: 12px;
}

.task-title {
  font-weight: bold;
  margin-bottom: 8px;
  color: #2c3e50;
}

.task-progress {
  font-size: 12px;
  color: #5a6c7d;
}

/* Vue Workload */
.workload-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 20px;
}

.agent-card {
  background: white;
  border: 2px solid #333;
  border-radius: 12px;
  padding: 20px;
}

.agent-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.agent-header h4 {
  margin: 0;
  color: #333;
}

.total-tasks {
  background: #667eea;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
}

.sprint-workload {
  margin-bottom: 20px;
}

.sprint-name {
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.workload-task {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.task-status {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: bold;
  min-width: 60px;
  text-align: center;
}

.task-status.todo { background: #e3f2fd; color: #1976d2; }
.task-status.in_progress { background: #fff8e1; color: #f57c00; }
.task-status.done { background: #e8f5e8; color: #388e3c; }

/* Consistent status colors for all panels */
.task-status {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 9px;
  font-weight: bold;
  min-width: 50px;
  text-align: center;
  text-transform: uppercase;
}

.task-name {
  font-size: 12px;
  color: #666;
}

/* Navigation - Liquid Glass */
.view-navigation {
  position: fixed;
  bottom: 30px;
  right: 30px;
  display: flex;
  gap: 10px;
}

.nav-btn {
  padding: 12px 20px !important;
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(15px) saturate(180%) contrast(115%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) contrast(115%) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
  border-radius: 25px !important;
  cursor: pointer !important;
  font-weight: bold !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1) !important;
  color: #333 !important;
}

.nav-btn:hover {
  transform: translateY(-3px) scale(1.02) !important;
  background: rgba(255, 255, 255, 0.35) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(125%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(125%) !important;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.15) !important;
  border: 1px solid rgba(255, 255, 255, 0.4) !important;
}

.nav-btn.active {
  background: rgba(51, 51, 51, 0.85) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
  color: white !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
}

.btn-back {
  padding: 8px 16px;
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  cursor: pointer;
}

.btn-back:hover {
  background: #e9ecef;
}

.btn-delete-project {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.2s;
  margin-left: 8px;
}

.btn-delete-project:hover {
  background-color: #c82333;
}

/* Modal Styles - Liquid Glass */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6) !important;
  backdrop-filter: blur(8px) !important;
  -webkit-backdrop-filter: blur(8px) !important;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.3s ease-out;
}

.modal-content {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(25px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(25px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
  border-radius: 20px !important;
  box-shadow: 0 16px 50px rgba(0, 0, 0, 0.2), 0 8px 25px rgba(0, 0, 0, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  max-width: 500px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
  animation: slideUp 0.4s cubic-bezier(0.23, 1, 0.32, 1);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15) !important;
  background: rgba(255, 255, 255, 0.1) !important;
  backdrop-filter: blur(15px) !important;
  -webkit-backdrop-filter: blur(15px) !important;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(20px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #999;
}

.close-btn:hover {
  color: #333;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #333;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px 16px !important;
  background: rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(10px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  border-radius: 12px !important;
  font-size: 14px;
  box-sizing: border-box;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
  color: #333 !important;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none !important;
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(15px) saturate(200%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(200%) !important;
  border: 1px solid rgba(102, 126, 234, 0.4) !important;
  box-shadow: 0 4px 20px rgba(102, 126, 234, 0.15) !important;
}

.form-group textarea {
  resize: vertical;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.modal-footer {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  padding: 20px;
  border-top: 1px solid #eee;
}

.btn-cancel {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-cancel:hover {
  background-color: #5a6268;
}

.btn-create {
  background-color: #28a745;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-create:hover:not(:disabled) {
  background-color: #218838;
}

.btn-create:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.btn-delete {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-delete:hover {
  background-color: #c82333;
}

.warning {
  color: #856404;
  background-color: #fff3cd;
  border: 1px solid #ffeaa7;
  padding: 10px;
  border-radius: 4px;
  margin-top: 10px;
}
</style>