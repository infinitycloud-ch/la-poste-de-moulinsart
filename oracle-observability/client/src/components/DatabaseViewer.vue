<template>
  <div class="database-viewer">
    <div class="viewer-header">
      <h3>🗄️ Base de Données des Événements</h3>
      <div class="view-toggle">
        <button @click="viewMode = 'live'" :class="{ active: viewMode === 'live' }">
          📡 Feed Live
        </button>
        <button @click="viewMode = 'database'" :class="{ active: viewMode === 'database' }">
          🗂️ Base de Données
        </button>
        <button @click="viewMode = 'tmux'" :class="{ active: viewMode === 'tmux' }">
          🖥️ Messages TMUX
        </button>
      </div>
    </div>

    <!-- Mode Live Feed (existant) -->
    <div v-if="viewMode === 'live'" class="live-feed">
      <!-- Contrôles de pagination discrets -->
      <div class="pagination-icons">
        <button @click="livePreviousPage" :disabled="liveCurrentPage === 0" class="pagination-icon">
          ⬅️
        </button>
        <button @click="liveNextPage" :disabled="liveCurrentPage >= totalPages - 1" class="pagination-icon">
          ➡️
        </button>
      </div>

      <TransitionGroup name="event-slide" tag="div">
        <div
          v-for="event in paginatedEvents"
          :key="event.id || event.timestamp"
          class="event-card"
          :class="getEventClass(event)"
        >
          <div class="event-header">
            <span class="event-type">{{ getEventIcon(event.type) }} {{ event.type }}</span>
            <span class="event-time">{{ formatTime(event.timestamp) }}</span>
          </div>
          <div v-if="event.agent" class="event-agent">
            <span class="agent-badge">{{ getAgentIcon(event.agent) }} {{ event.agent }}</span>
          </div>
          <div class="event-content">
            <div v-if="event.data" class="event-data">
              {{ formatEventData(event.data) }}
            </div>
            <div v-if="event.project" class="event-project">
              📁 {{ event.project }}
            </div>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- Mode TMUX Commands -->
    <div v-else-if="viewMode === 'tmux'" class="tmux-mode">
      <TmuxCommands ref="tmuxCommandsRef" />
    </div>

    <!-- Mode Database avec filtres -->
    <div v-else class="database-mode">
      <!-- Filtres -->
      <div class="filters-panel">
        <div class="filter-row">
          <div class="filter-group">
            <label>🤖 Agent:</label>
            <select v-model="filters.agent" @change="fetchEvents">
              <option value="all">Tous</option>
              <option v-for="agent in availableFilters.agents" :key="agent" :value="agent">
                {{ getAgentIcon(agent) }} {{ agent }}
              </option>
            </select>
          </div>

          <div class="filter-group">
            <label>📌 Type:</label>
            <select v-model="filters.type" @change="fetchEvents">
              <option value="all">Tous</option>
              <option v-for="type in availableFilters.types" :key="type" :value="type">
                {{ type }}
              </option>
            </select>
          </div>

          <div class="filter-group">
            <label>📁 Projet:</label>
            <select v-model="filters.project" @change="fetchEvents">
              <option value="all">Tous</option>
              <option v-for="project in availableFilters.projects" :key="project" :value="project">
                {{ project }}
              </option>
            </select>
          </div>
        </div>

        <div class="filter-row">
          <div class="filter-group search-group">
            <label>🔍 Recherche:</label>
            <input 
              v-model="filters.search" 
              @input="debounceSearch"
              type="text" 
              placeholder="Rechercher dans les événements..."
            />
          </div>

          <div class="filter-group">
            <label>📅 Date début:</label>
            <input 
              v-model="filters.startDate" 
              @change="fetchEvents"
              type="datetime-local"
            />
          </div>

          <div class="filter-group">
            <label>📅 Date fin:</label>
            <input 
              v-model="filters.endDate" 
              @change="fetchEvents"
              type="datetime-local"
            />
          </div>
        </div>

        <div class="filter-actions">
          <button @click="resetFilters" class="btn-reset">🔄 Réinitialiser</button>
          <button @click="fetchEvents" class="btn-refresh">🔄 Rafraîchir</button>
          <span class="event-count">{{ dbEvents.length }} événements</span>
        </div>
      </div>

      <!-- Table des événements -->
      <div class="events-table-container">
        <table class="events-table">
          <thead>
            <tr>
              <th @click="sortBy('id')" class="sortable">
                ID {{ getSortIcon('id') }}
              </th>
              <th @click="sortBy('timestamp')" class="sortable">
                Date/Heure {{ getSortIcon('timestamp') }}
              </th>
              <th @click="sortBy('agent')" class="sortable">
                Agent {{ getSortIcon('agent') }}
              </th>
              <th @click="sortBy('type')" class="sortable">
                Type {{ getSortIcon('type') }}
              </th>
              <th @click="sortBy('project')" class="sortable">
                Projet {{ getSortIcon('project') }}
              </th>
              <th>Données</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="event in sortedEvents" :key="event.id" @click="showEventDetails(event)">
              <td class="event-id">{{ event.id }}</td>
              <td class="event-timestamp">{{ formatDateTime(event.timestamp) }}</td>
              <td class="event-agent">
                <span v-if="event.agent" class="agent-badge-small">
                  {{ getAgentIcon(event.agent) }} {{ event.agent }}
                </span>
              </td>
              <td class="event-type">
                <span class="type-badge" :class="'type-' + event.type">
                  {{ getEventIcon(event.type) }} {{ event.type }}
                </span>
              </td>
              <td class="event-project">{{ event.project || '-' }}</td>
              <td class="event-data">
                <span class="data-preview">{{ truncateData(event.data) }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="pagination">
        <button @click="previousPage" :disabled="currentPage === 1">◀ Précédent</button>
        <span>Page {{ currentPage }} / {{ dbTotalPages }}</span>
        <button @click="nextPage" :disabled="currentPage === dbTotalPages">Suivant ▶</button>
        <select v-model="itemsPerPage" @change="fetchEvents">
          <option value="20">20 par page</option>
          <option value="50">50 par page</option>
          <option value="100">100 par page</option>
          <option value="500">500 par page</option>
        </select>
      </div>
    </div>

    <!-- Modal détails événement -->
    <div v-if="selectedEvent" class="event-modal" @click.self="selectedEvent = null">
      <div class="event-modal-content">
        <div class="modal-header">
          <h3>📋 Détails de l'Événement #{{ selectedEvent.id }}</h3>
          <button @click="selectedEvent = null" class="close-btn">×</button>
        </div>
        <div class="modal-body">
          <div class="detail-row">
            <strong>Date/Heure:</strong> {{ formatDateTime(selectedEvent.timestamp) }}
          </div>
          <div class="detail-row">
            <strong>Agent:</strong> {{ selectedEvent.agent || 'N/A' }}
          </div>
          <div class="detail-row">
            <strong>Type:</strong> {{ selectedEvent.type }}
          </div>
          <div class="detail-row">
            <strong>Projet:</strong> {{ selectedEvent.project || 'N/A' }}
          </div>
          <div class="detail-row">
            <strong>Source:</strong> {{ selectedEvent.source || 'N/A' }}
          </div>
          <div class="detail-row full-width">
            <strong>Données:</strong>
            <pre class="data-json">{{ formatJson(selectedEvent.data) }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import TmuxCommands from './TmuxCommands.vue'

interface Event {
  id: number
  timestamp: string
  type: string
  agent?: string
  project?: string
  source?: string
  // Peut être une string (depuis la DB) ou un objet (depuis WebSocket)
  data?: any
}

// Props
const props = defineProps<{
  liveEvents: Event[]
}>()

// State
const viewMode = ref<'live' | 'database' | 'tmux'>('live')
const dbEvents = ref<Event[]>([])
const selectedEvent = ref<Event | null>(null)
const currentPage = ref(1)
const itemsPerPage = ref(50)
const sortField = ref<string>('id')
const sortOrder = ref<'asc' | 'desc'>('desc')
const searchTimeout = ref<number | null>(null)

// Pagination pour Live Events
const liveCurrentPage = ref(0)
const liveEventsPerPage = 5

const filters = ref({
  agent: 'all',
  type: 'all',
  project: 'all',
  search: '',
  startDate: '',
  endDate: ''
})

const availableFilters = ref({
  agents: [] as string[],
  types: [] as string[],
  projects: [] as string[]
})

// Computed
const dbTotalPages = computed(() => Math.ceil(dbEvents.value.length / itemsPerPage.value))

const sortedEvents = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  const end = start + itemsPerPage.value

  const sorted = [...dbEvents.value].sort((a, b) => {
    const aVal = a[sortField.value as keyof Event] || ''
    const bVal = b[sortField.value as keyof Event] || ''

    if (sortOrder.value === 'asc') {
      return aVal > bVal ? 1 : -1
    } else {
      return aVal < bVal ? 1 : -1
    }
  })

  return sorted.slice(start, end)
})

// Pagination pour Live Events
const totalPages = computed(() => Math.ceil(props.liveEvents.length / liveEventsPerPage))

const paginatedEvents = computed(() => {
  const start = liveCurrentPage.value * liveEventsPerPage
  const end = start + liveEventsPerPage
  return props.liveEvents.slice(start, end)
})

// Methods pour pagination Live Events
const livePreviousPage = () => {
  if (liveCurrentPage.value > 0) {
    liveCurrentPage.value--
  }
}

const liveNextPage = () => {
  if (liveCurrentPage.value < totalPages.value - 1) {
    liveCurrentPage.value++
  }
}

// Methods
const fetchEvents = async () => {
  try {
    const params = new URLSearchParams({
      limit: '1000',
      ...Object.fromEntries(
        Object.entries(filters.value).filter(([_, v]) => v && v !== 'all')
      )
    })
    
    const response = await fetch(`http://localhost:3001/api/events?${params}`)
    const data = await response.json()
    
    dbEvents.value = data.events || []
    availableFilters.value = data.filters || { agents: [], types: [], projects: [] }
    currentPage.value = 1
  } catch (error) {
    console.error('Erreur lors de la récupération des événements:', error)
  }
}

const debounceSearch = () => {
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value)
  }
  searchTimeout.value = setTimeout(() => {
    fetchEvents()
  }, 500) as unknown as number
}

const resetFilters = () => {
  filters.value = {
    agent: 'all',
    type: 'all',
    project: 'all',
    search: '',
    startDate: '',
    endDate: ''
  }
  fetchEvents()
}

const sortBy = (field: string) => {
  if (sortField.value === field) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortField.value = field
    sortOrder.value = 'desc'
  }
}

const getSortIcon = (field: string) => {
  if (sortField.value !== field) return '↕️'
  return sortOrder.value === 'asc' ? '↑' : '↓'
}

const previousPage = () => {
  if (currentPage.value > 1) currentPage.value--
}

const nextPage = () => {
  if (currentPage.value < dbTotalPages.value) currentPage.value++
}

const showEventDetails = (event: Event) => {
  selectedEvent.value = event
}

const getEventClass = (event: Event) => {
  return `event-type-${event.type}`
}

const getEventIcon = (type: string) => {
  const icons: Record<string, string> = {
    'prompt': '💬',
    'email': '📧',
    'command': '⚡',
    'error': '❌',
    'success': '✅',
    'info': 'ℹ️',
    'warning': '⚠️',
    'stop': '⏹️'
  }
  return icons[type] || '📌'
}

const getAgentIcon = (agent: string) => {
  const icons: Record<string, string> = {
    'nestor': '🎩',
    'tintin': '🚀',
    'dupont1': '🎨',
    'dupont2': '🔍',
    'claude': '🤖'
  }
  return icons[agent?.toLowerCase()] || '👤'
}

const formatTime = (timestamp: string) => {
  return new Date(timestamp).toLocaleTimeString('fr-FR')
}

const formatDateTime = (timestamp: string) => {
  return new Date(timestamp).toLocaleString('fr-FR')
}

const formatEventData = (data: any) => {
  try {
    const parsed = typeof data === 'string' ? JSON.parse(data) : (data || {})
    const base = parsed.content || parsed.message || parsed.body || parsed.text || parsed
    const str = typeof base === 'string' ? base : JSON.stringify(base)
    return str.length > 100 ? str.substring(0, 100) + '...' : str
  } catch {
    const str = typeof data === 'string' ? data : JSON.stringify(data || '')
    return str.substring(0, 100)
  }
}

const truncateData = (data: any) => {
  try {
    const parsed = typeof data === 'string' ? JSON.parse(data) : (data || {})
    const str = parsed.content || parsed.message || JSON.stringify(parsed)
    return str.length > 50 ? str.substring(0, 50) + '...' : str
  } catch {
    const str = typeof data === 'string' ? data : JSON.stringify(data || '')
    return str.substring(0, 50) || '-'
  }
}

const formatJson = (data: any) => {
  try {
    const parsed = typeof data === 'string' ? JSON.parse(data) : (data || {})
    return JSON.stringify(parsed, null, 2)
  } catch {
    return typeof data === 'string' ? data : JSON.stringify(data || 'N/A', null, 2)
  }
}

// Lifecycle
onMounted(() => {
  fetchEvents()
})

// Watch for view mode changes
watch(viewMode, (newMode) => {
  if (newMode === 'database') {
    fetchEvents()
  }
})
</script>

<style scoped>
.database-viewer {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
}

.viewer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background: white;
  border-bottom: 2px solid #ddd;
}

.viewer-header h3 {
  margin: 0;
  color: #2c3e50;
}

.view-toggle {
  display: flex;
  gap: 5px;
}

.view-toggle button {
  padding: 8px 16px;
  border: 1px solid #ddd;
  background: white;
  cursor: pointer;
  transition: all 0.3s;
  border-radius: 5px;
}

.view-toggle button.active {
  background: #3498db;
  color: white;
  border-color: #3498db;
}

/* Live Feed Styles */
.live-feed {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background-image: url('/images/moulinsart.png');
  background-size: contain;
  background-position: center bottom;
  background-repeat: no-repeat;
  background-attachment: local;
  position: relative;
}

/* Pagination Icons Discrets */
.pagination-icons {
  position: absolute;
  top: 10px;
  left: 10px;
  display: flex;
  gap: 5px;
  z-index: 10;
}

.pagination-icon {
  width: 30px;
  height: 30px;
  background: transparent;
  border: none;
  font-size: 16px;
  cursor: pointer;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s;
  opacity: 0.6;
}

.pagination-icon:hover:not(:disabled) {
  opacity: 1;
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.pagination-icon:disabled {
  opacity: 0.3;
  cursor: not-allowed;
  transform: none;
}


.event-card {
  background: rgba(255, 255, 255, 0.03);
  border-radius: calc(6px * var(--scale-factor, 1));
  padding: calc(10px * var(--scale-factor, 1));
  margin-bottom: calc(8px * var(--scale-factor, 1));
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  transition: all 0.3s;
  backdrop-filter: blur(1px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.event-card:hover {
  transform: translateX(5px);
  box-shadow: 0 2px 6px rgba(0,0,0,0.1);
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(2px);
}

.event-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: calc(6px * var(--scale-factor, 1));
}

.event-type {
  font-weight: 600;
  color: #2c3e50;
  font-size: calc(0.95em * var(--scale-factor, 1));
}

.event-time {
  color: #7f8c8d;
  font-size: calc(0.85em * var(--scale-factor, 1));
}

.event-agent {
  margin-bottom: 8px;
}

.agent-badge {
  display: inline-block;
  padding: 3px 8px;
  background: rgba(232, 244, 253, 0.2);
  border-radius: 12px;
  font-size: 0.85em;
  color: #2980b9;
  border: 1px solid rgba(41, 128, 185, 0.2);
}

.event-content {
  color: #34495e;
  font-size: calc(0.9em * var(--scale-factor, 1));
  line-height: calc(1.4 * var(--scale-factor, 1));
}

.event-data {
  margin-bottom: calc(4px * var(--scale-factor, 1));
  padding: calc(6px * var(--scale-factor, 1));
  background: rgba(248, 249, 250, 0.1);
  border-radius: calc(4px * var(--scale-factor, 1));
  font-family: monospace;
  font-size: calc(0.85em * var(--scale-factor, 1));
  max-height: calc(80px * var(--scale-factor, 1));
  overflow-y: auto;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.event-project {
  color: #7f8c8d;
  font-size: 0.85em;
}

/* TMUX Mode Styles */
.tmux-mode {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background-image: url('/images/moulinsart.png');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: local;
}

/* Database Mode Styles */
.database-mode {
  flex: 1;
  display: flex;
  flex-direction: column;
  background-image: url('/images/moulinsart.png');
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
  background-attachment: local;
  opacity: 0.8;
}

.filters-panel {
  background: white;
  padding: 20px;
  border-bottom: 1px solid #ddd;
}

.filter-row {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
  flex: 1;
  min-width: 150px;
}

.filter-group.search-group {
  flex: 2;
}

.filter-group label {
  font-size: 0.9em;
  color: #666;
  font-weight: 600;
}

.filter-group select,
.filter-group input {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.filter-actions {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-top: 10px;
}

.btn-reset, .btn-refresh {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s;
}

.btn-reset {
  background: #95a5a6;
  color: white;
}

.btn-reset:hover {
  background: #7f8c8d;
}

.btn-refresh {
  background: #3498db;
  color: white;
}

.btn-refresh:hover {
  background: #2980b9;
}

.event-count {
  margin-left: auto;
  color: #666;
  font-weight: 600;
}

/* Table Styles */
.events-table-container {
  flex: 1;
  overflow: auto;
  background: white;
}

.events-table {
  width: 100%;
  border-collapse: collapse;
}

.events-table thead {
  position: sticky;
  top: 0;
  background: #34495e;
  color: white;
  z-index: 10;
}

.events-table th {
  padding: 12px;
  text-align: left;
  font-weight: 600;
  user-select: none;
  white-space: nowrap;
}

.events-table th.sortable {
  cursor: pointer;
}

.events-table th.sortable:hover {
  background: #2c3e50;
}

.events-table tbody tr {
  border-bottom: 1px solid #ecf0f1;
  cursor: pointer;
  transition: background 0.2s;
}

.events-table tbody tr:hover {
  background: #f8f9fa;
}

.events-table td {
  padding: 10px 12px;
  font-size: 0.9em;
}

.event-id {
  font-weight: 600;
  color: #7f8c8d;
}

.event-timestamp {
  white-space: nowrap;
}

.agent-badge-small {
  display: inline-block;
  padding: 2px 6px;
  background: #e8f4fd;
  border-radius: 8px;
  font-size: 0.85em;
}

.type-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.85em;
  font-weight: 600;
}

.type-badge.type-prompt {
  background: #d4edda;
  color: #155724;
}

.type-badge.type-email {
  background: #fff3cd;
  color: #856404;
}

.type-badge.type-error {
  background: #f8d7da;
  color: #721c24;
}

.data-preview {
  color: #666;
  font-family: monospace;
  font-size: 0.85em;
}

/* Pagination */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 15px;
  padding: 15px;
  background: white;
  border-top: 1px solid #ddd;
}

.pagination button {
  padding: 6px 12px;
  border: 1px solid #ddd;
  background: white;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.3s;
}

.pagination button:hover:not(:disabled) {
  background: #3498db;
  color: white;
}

.pagination button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination select {
  padding: 6px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

/* Modal */
.event-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.event-modal-content {
  background: white;
  border-radius: 10px;
  width: 90%;
  max-width: 800px;
  max-height: 80vh;
  overflow: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #ddd;
}

.modal-header h3 {
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 28px;
  cursor: pointer;
  color: #666;
}

.modal-body {
  padding: 20px;
}

.detail-row {
  margin-bottom: 15px;
}

.detail-row strong {
  display: inline-block;
  width: 120px;
  color: #2c3e50;
}

.detail-row.full-width {
  margin-top: 20px;
}

.detail-row.full-width strong {
  display: block;
  margin-bottom: 10px;
}

.data-json {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 5px;
  overflow-x: auto;
  font-family: monospace;
  font-size: 0.9em;
  line-height: 1.5;
}

/* Animations */
.event-slide-enter-active {
  transition: all 0.5s ease;
}

.event-slide-enter-from {
  transform: translateX(-100px);
  opacity: 0;
}

.event-slide-move {
  transition: transform 0.5s;
}
</style>