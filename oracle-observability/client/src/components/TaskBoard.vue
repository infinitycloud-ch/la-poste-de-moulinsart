<template>
  <div class="task-board">
    <div class="board-header">
      <h2>🎯 Task Management Dashboard</h2>
      <div class="board-controls">
        <select v-model="selectedProject" @change="loadTasks" class="project-filter">
          <option value="">All Projects</option>
          <option v-for="project in projects" :key="project.id" :value="project.id">
            {{ project.name }}
          </option>
        </select>
        <select v-model="agentFilter" @change="loadTasks" class="agent-filter">
          <option value="">All Agents</option>
          <option value="nestor">🎩 Nestor</option>
          <option value="tintin">🚀 Tintin</option>
          <option value="dupont1">🎨 Dupont1</option>
          <option value="dupont2">🔍 Dupont2</option>
        </select>
        <button @click="showAttachPRD = true" class="btn-attach-prd">
          📎 Attacher PRD
        </button>
      </div>
    </div>

    <!-- Kanban Board -->
    <div class="kanban-board">
      <div class="kanban-column" v-for="status in boardColumns" :key="status.key">
        <div class="column-header" :style="{ backgroundColor: status.color }">
          <h3>{{ status.icon }} {{ status.title }}</h3>
          <span class="task-count">{{ getTaskCountByStatus(status.key) }}</span>
        </div>
        
        <div 
          class="column-content"
          @drop="onDrop($event, status.key)"
          @dragover.prevent
          @dragenter.prevent
        >
          <TaskCardCompact
            v-for="task in getTasksByStatus(status.key)"
            :key="task.id"
            :task="task"
            :draggable="true"
            @dragstart="onDragStart($event, task)"
            @update-status="updateTaskStatus"
            @validate="showValidationModal"
            @view-details="showTaskDetails"
          />
          
          <div v-if="getTasksByStatus(status.key).length === 0" class="empty-column">
            <div class="empty-icon">📭</div>
            <p>No tasks in {{ status.title }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Task Statistics -->
    <div class="task-statistics">
      <div class="stat-card">
        <h4>📊 Overview</h4>
        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-number">{{ taskStats.total_tasks }}</span>
            <span class="stat-label">Total Tasks</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">{{ taskStats.validation_queue_size }}</span>
            <span class="stat-label">Pending Validation</span>
          </div>
          <div class="stat-item">
            <span class="stat-number">{{ taskStats.overdue_tasks }}</span>
            <span class="stat-label">Overdue</span>
          </div>
        </div>
      </div>
      
      <div class="stat-card">
        <h4>👥 Agent Workload</h4>
        <div class="agent-stats">
          <div v-for="agent in agentStats" :key="agent.assigned_to" class="agent-stat">
            <span class="agent-icon">{{ getAgentIcon(agent.assigned_to) }}</span>
            <span class="agent-name">{{ agent.assigned_to }}</span>
            <span class="agent-count">{{ agent.count }}</span>
          </div>
        </div>
      </div>

      <div class="stat-card prd-card" v-if="currentProjectPRD">
        <h4>📋 PRD Attaché</h4>
        <div class="prd-info">
          <div class="prd-summary">
            <strong>{{ getProjectName(selectedProject) }}</strong>
            <div class="prd-content-preview">
              {{ currentProjectPRD.substring(0, 200) }}...
            </div>
          </div>
          <div class="prd-status">
            📎 PRD attaché - Disponible pour Nestor via MCP
          </div>
        </div>
      </div>
    </div>

    <!-- Attach PRD Modal -->
    <AttachPRDModal
      v-if="showAttachPRD"
      :projects="allProjects"
      @close="showAttachPRD = false"
      @attached="onPRDAttached"
    />

    <!-- Task Details Modal -->
    <TaskDetailsModal
      v-if="showTaskDetailsModal"
      :task="selectedTask"
      @close="showTaskDetailsModal = false"
      @updated="onTaskUpdated"
    />

    <!-- Validation Modal -->
    <ValidationModal
      v-if="showValidation"
      :task="taskToValidate"
      @close="showValidation = false"
      @validated="onTaskValidated"
    />
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import TaskCardCompact from './TaskCardCompact.vue'
import AttachPRDModal from './AttachPRDModal.vue'
import TaskDetailsModal from './TaskDetailsModal.vue'
import ValidationModal from './ValidationModal.vue'

export default {
  name: 'TaskBoard',
  components: {
    TaskCardCompact,
    AttachPRDModal,
    TaskDetailsModal,
    ValidationModal
  },
  setup() {
    const tasks = ref([])
    const projects = ref([])
    const allProjects = ref([])
    const taskStats = ref({})
    const currentProjectPRD = ref('')
    const selectedProject = ref('')
    const agentFilter = ref('')
    const showAttachPRD = ref(false)
    const showTaskDetailsModal = ref(false)
    const showValidation = ref(false)
    const selectedTask = ref(null)
    const taskToValidate = ref(null)
    const draggedTask = ref(null)

    const boardColumns = [
      { key: 'TODO', title: 'To Do', icon: '📋', color: '#f8f9fa' },
      { key: 'IN_PROGRESS', title: 'In Progress', icon: '🚀', color: '#fff3cd' },
      { key: 'DONE', title: 'Done', icon: '✅', color: '#d4edda' }
    ]

    const agentStats = computed(() => {
      return taskStats.value.tasks_by_agent || []
    })

    const loadTasks = async () => {
      try {
        const params = new URLSearchParams()
        if (selectedProject.value) params.append('project_id', selectedProject.value)
        if (agentFilter.value) params.append('assigned_to', agentFilter.value)

        const response = await fetch(`http://localhost:3001/api/tasks?${params}`)
        if (response.ok) {
          tasks.value = await response.json()
        }

        // Load PRD for selected project
        if (selectedProject.value) {
          loadProjectPRD(selectedProject.value)
        } else {
          currentProjectPRD.value = ''
        }
      } catch (error) {
        console.error('Error loading tasks:', error)
      }
    }

    const loadProjectPRD = async (projectId) => {
      try {
        const response = await fetch(`http://localhost:3001/api/projects/${projectId}`)
        if (response.ok) {
          const data = await response.json()
          currentProjectPRD.value = data.project?.prd || ''
        }
      } catch (error) {
        console.error('Error loading project PRD:', error)
        currentProjectPRD.value = ''
      }
    }

    const loadProjects = async () => {
      try {
        // Load only projects with PRDs for display
        const response = await fetch('http://localhost:3001/api/projects')
        if (response.ok) {
          const data = await response.json()
          projects.value = data.projects || data

          // Auto-select the first project with PRD if none selected
          if (!selectedProject.value && projects.value.length > 0) {
            selectedProject.value = projects.value[0].id
            // Reload tasks for the auto-selected project
            loadTasks()
          }
        }

        // Load projects WITHOUT PRD for the attachment modal
        const withoutPRDResponse = await fetch('http://localhost:3001/api/projects?without_prd=true')
        if (withoutPRDResponse.ok) {
          const withoutPRDData = await withoutPRDResponse.json()
          allProjects.value = withoutPRDData.projects || withoutPRDData
        }
      } catch (error) {
        console.error('Error loading projects:', error)
      }
    }

    const loadTaskStats = async () => {
      try {
        const response = await fetch('http://localhost:3001/api/tasks/stats')
        if (response.ok) {
          taskStats.value = await response.json()
        }
      } catch (error) {
        console.error('Error loading task stats:', error)
      }
    }

    const getTasksByStatus = (status) => {
      return tasks.value.filter(task => task.status === status)
    }

    const getTaskCountByStatus = (status) => {
      return getTasksByStatus(status).length
    }

    const getAgentIcon = (agentName) => {
      const icons = {
        nestor: '🎩',
        tintin: '🚀',
        dupont1: '🎨',
        dupont2: '🔍'
      }
      return icons[agentName] || '👤'
    }

    const onDragStart = (event, task) => {
      draggedTask.value = task
      event.dataTransfer.effectAllowed = 'move'
    }

    const onDrop = async (event, newStatus) => {
      event.preventDefault()
      
      if (!draggedTask.value) return
      
      if (draggedTask.value.status === newStatus) return

      // Validation rules - can't move to DONE without all required checkboxes
      if (newStatus === 'DONE') {
        const requiredCheckboxes = draggedTask.value.checkboxes?.filter(cb => cb.required && !cb.completed) || []
        if (requiredCheckboxes.length > 0) {
          alert(`Cannot move to DONE: ${requiredCheckboxes.length} required validation(s) incomplete:\n${requiredCheckboxes.map(cb => '• ' + cb.label).join('\n')}`)
          return
        }
      }

      await updateTaskStatus(draggedTask.value.id, newStatus, 'drag-drop')
      draggedTask.value = null
    }

    const updateTaskStatus = async (taskId, newStatus, source = 'manual') => {
      try {
        const response = await fetch(`http://localhost:3001/api/tasks/${taskId}/status`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            status: newStatus, 
            updated_by: 'dashboard',
            notes: `Status updated via ${source}`
          })
        })

        if (response.ok) {
          await loadTasks()
          await loadTaskStats()
        }
      } catch (error) {
        console.error('Error updating task status:', error)
      }
    }

    const showTaskDetails = (task) => {
      selectedTask.value = task
      showTaskDetailsModal.value = true
    }

    const showValidationModal = (task) => {
      taskToValidate.value = task
      showValidation.value = true
    }

    const onPRDAttached = () => {
      showAttachPRD.value = false
      loadProjects()
      loadTasks()
      loadTaskStats()
    }

    const getProjectName = (projectId) => {
      const project = projects.value.find(p => p.id == projectId)
      return project ? project.name : 'Projet inconnu'
    }


    const onTaskUpdated = () => {
      showTaskDetailsModal.value = false
      loadTasks()
      loadTaskStats()
    }

    const onTaskValidated = () => {
      showValidation.value = false
      loadTasks()
      loadTaskStats()
    }

    // Setup WebSocket for real-time updates
    const setupWebSocket = () => {
      const ws = new WebSocket('ws://localhost:3001/ws')
      
      ws.onmessage = (event) => {
        const message = JSON.parse(event.data)
        
        if (['task_created', 'task_status_updated', 'task_validated'].includes(message.type)) {
          loadTasks()
          loadTaskStats()
        }
      }
    }

    onMounted(() => {
      loadTasks()
      loadProjects()
      loadTaskStats()
      setupWebSocket()
      
      // Refresh data every 30 seconds
      setInterval(() => {
        loadTaskStats()
      }, 30000)
    })

    return {
      tasks,
      projects,
      allProjects,
      taskStats,
      selectedProject,
      agentFilter,
      showAttachPRD,
      showTaskDetailsModal,
      showValidation,
      selectedTask,
      taskToValidate,
      currentProjectPRD,
      boardColumns,
      agentStats,
      loadTasks,
      getTasksByStatus,
      getTaskCountByStatus,
      getAgentIcon,
      onDragStart,
      onDrop,
      updateTaskStatus,
      showTaskDetails,
      showValidation,
      showValidationModal,
      onPRDAttached,
      onTaskUpdated,
      onTaskValidated,
      getProjectName
    }
  }
}
</script>

<style scoped>
.task-board {
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: 100vh;
}

.board-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding: 20px;
  background: white;
  border-radius: 15px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  border: 3px solid #333;
}

.board-header h2 {
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  margin: 0;
  font-size: 1.8em;
  text-shadow: 2px 2px 0px #fff;
}

.board-controls {
  display: flex;
  gap: 15px;
  align-items: center;
}

.project-filter,
.agent-filter {
  padding: 8px 15px;
  border: 2px solid #333;
  border-radius: 10px;
  background: white;
  font-weight: bold;
  cursor: pointer;
}

.btn-create-task,
.btn-create-prd,
.btn-split-prd {
  padding: 10px 20px;
  background: linear-gradient(145deg, #4CAF50, #45a049);
  color: white;
  border: 3px solid #333;
  border-radius: 12px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s ease;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.btn-create-task:hover,
.btn-create-prd:hover,
.btn-split-prd:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2);
}

.btn-create-prd {
  background: linear-gradient(145deg, #9c27b0, #7b1fa2);
}

.btn-split-prd {
  background: linear-gradient(145deg, #2196F3, #1976D2);
}

.kanban-board {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 30px;
}

.kanban-column {
  background: white;
  border-radius: 8px;
  border: 1px solid #ddd;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  overflow: hidden;
  min-height: 400px;
}

.column-header {
  padding: 8px 12px;
  border-bottom: 1px solid #ddd;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.column-header h3 {
  margin: 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.2em;
}

.task-count {
  background: #333;
  color: white;
  padding: 4px 8px;
  border-radius: 50%;
  font-size: 0.9em;
  font-weight: bold;
  min-width: 24px;
  text-align: center;
}

.column-content {
  padding: 8px;
  min-height: 300px;
}

.empty-column {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

.empty-icon {
  font-size: 3em;
  margin-bottom: 10px;
}

.task-statistics {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.stat-card {
  background: white;
  padding: 20px;
  border-radius: 15px;
  border: 3px solid #333;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.stat-card h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.3em;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.stat-item {
  text-align: center;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 10px;
  border: 2px solid #333;
}

.stat-number {
  display: block;
  font-size: 2em;
  font-weight: bold;
  color: #ff6b6b;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 0.9em;
  color: #666;
  font-weight: bold;
}

.agent-stats {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.agent-stat {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 2px solid #333;
}

.agent-icon {
  font-size: 1.2em;
}

.agent-name {
  flex: 1;
  font-weight: bold;
  text-transform: capitalize;
}

.agent-count {
  background: #ff6b6b;
  color: white;
  padding: 4px 8px;
  border-radius: 50%;
  font-weight: bold;
  min-width: 24px;
  text-align: center;
}

/* PRD Card Styles */
.prd-card {
  min-width: 350px;
}

.prd-info {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.prd-summary strong {
  color: #333;
  font-size: 1.1em;
  display: block;
  margin-bottom: 10px;
}

.prd-content-preview {
  background: #f8f9fa;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 12px;
  font-family: 'Courier New', monospace;
  font-size: 0.85em;
  line-height: 1.4;
  color: #666;
  white-space: pre-wrap;
  max-height: 120px;
  overflow-y: auto;
}

.prd-status {
  background: linear-gradient(145deg, #28a745, #20c997);
  color: white;
  border: 2px solid #333;
  border-radius: 8px;
  padding: 12px 16px;
  font-weight: bold;
  text-align: center;
  align-self: flex-start;
}
</style>