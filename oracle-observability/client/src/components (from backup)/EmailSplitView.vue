<template>
  <div class="email-split-view">
    <!-- Header with search/filter controls -->
    <div class="split-header">
      <h2 class="split-title">📧 Traffic Email Temps Réel</h2>
      
      <div class="controls">
        <div class="search-filter">
          <input 
            v-model="searchQuery" 
            placeholder="🔍 Rechercher..." 
            class="search-input"
          >
          
          <select v-model="agentFilter" class="agent-filter">
            <option value="">Tous les agents</option>
            <option value="nestor">🎩 Nestor</option>
            <option value="tintin">🚀 Tintin</option>
            <option value="dupont1">🎨 Dupont 1</option>
            <option value="dupont2">🔍 Dupont 2</option>
          </select>
        </div>
        
        <div class="status-indicator">
          <span :class="{ connected: isConnected }" class="connection-status">
            {{ isConnected ? '🟢 Live' : '🔴 Offline' }}
          </span>
          <span class="email-count">{{ totalEmails }} emails</span>
        </div>
      </div>
    </div>

    <!-- Split panels -->
    <div class="split-container">
      <!-- Left Panel: Sent Emails -->
      <div class="panel sent-panel">
        <div class="panel-header">
          <h3>📤 Emails Envoyés</h3>
          <span class="panel-count">{{ filteredSentEmails.length }}</span>
        </div>
        
        <div class="panel-content">
          <div v-if="loading" class="loading">
            ⏳ Chargement des emails...
          </div>
          
          <div v-else-if="filteredSentEmails.length === 0" class="empty-panel">
            <div class="empty-icon">📭</div>
            <p>Aucun email envoyé</p>
          </div>
          
          <div v-else class="emails-list">
            <TransitionGroup name="email-fade" tag="div">
              <div 
                v-for="email in filteredSentEmails" 
                :key="email.id"
                class="email-card"
                :class="getAgentClass(email.from)"
                @click="selectEmail(email)"
              >
                <div class="email-header">
                  <div class="email-from">
                    {{ getAgentIcon(email.from) }} {{ getAgentName(email.from) }}
                  </div>
                  <div class="email-time">{{ formatTime(email.timestamp) }}</div>
                </div>
                
                <div class="email-to">
                  → {{ getAgentIcon(email.to) }} {{ getAgentName(email.to) }}
                </div>
                
                <div class="email-subject" :title="email.subject">
                  {{ truncateText(email.subject, 50) }}
                </div>
                
                <div class="email-preview">
                  {{ truncateText(email.body, 100) }}
                </div>
              </div>
            </TransitionGroup>
          </div>
        </div>
      </div>

      <!-- Right Panel: Received Emails -->
      <div class="panel received-panel">
        <div class="panel-header">
          <h3>📥 Emails Reçus</h3>
          <span class="panel-count">{{ filteredReceivedEmails.length }}</span>
        </div>
        
        <div class="panel-content">
          <div v-if="loading" class="loading">
            ⏳ Chargement des emails...
          </div>
          
          <div v-else-if="filteredReceivedEmails.length === 0" class="empty-panel">
            <div class="empty-icon">📬</div>
            <p>Aucun email reçu</p>
          </div>
          
          <div v-else class="emails-list">
            <TransitionGroup name="email-fade" tag="div">
              <div 
                v-for="email in filteredReceivedEmails" 
                :key="email.id"
                class="email-card"
                :class="getAgentClass(email.to)"
                @click="selectEmail(email)"
              >
                <div class="email-header">
                  <div class="email-from">
                    {{ getAgentIcon(email.from) }} {{ getAgentName(email.from) }}
                  </div>
                  <div class="email-time">{{ formatTime(email.timestamp) }}</div>
                </div>
                
                <div class="email-to">
                  → {{ getAgentIcon(email.to) }} {{ getAgentName(email.to) }}
                </div>
                
                <div class="email-subject" :title="email.subject">
                  {{ truncateText(email.subject, 50) }}
                </div>
                
                <div class="email-preview">
                  {{ truncateText(email.body, 100) }}
                </div>
              </div>
            </TransitionGroup>
          </div>
        </div>
      </div>
    </div>

    <!-- Email Detail Modal -->
    <div v-if="selectedEmail" class="modal-overlay" @click.self="closeEmailModal">
      <div class="modal-content">
        <div class="modal-header" :class="getAgentClass(selectedEmail.from)">
          <h3>{{ getAgentIcon(selectedEmail.from) }} Email de {{ getAgentName(selectedEmail.from) }}</h3>
          <button @click="closeEmailModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div class="email-details">
            <div class="detail-row">
              <strong>De:</strong> {{ getAgentIcon(selectedEmail.from) }} {{ selectedEmail.from }}
            </div>
            <div class="detail-row">
              <strong>À:</strong> {{ getAgentIcon(selectedEmail.to) }} {{ selectedEmail.to }}
            </div>
            <div class="detail-row">
              <strong>Date:</strong> {{ formatFullDate(selectedEmail.timestamp) }}
            </div>
            <div class="detail-row">
              <strong>Sujet:</strong> {{ selectedEmail.subject }}
            </div>
          </div>
          
          <div class="email-content">
            <h4>Message:</h4>
            <pre class="email-body">{{ selectedEmail.body }}</pre>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="copyEmailToClipboard" class="btn-copy">📋 Copier</button>
          <button @click="closeEmailModal" class="btn-close">Fermer</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

// Reactive state
const emails = ref([])
const loading = ref(true)
const isConnected = ref(false)
const selectedEmail = ref(null)
const searchQuery = ref('')
const agentFilter = ref('')

// WebSocket connection
let ws = null
let refreshInterval = null

// Agent configuration with colors and icons
const agents = {
  'nestor@moulinsart.local': { 
    name: 'Nestor', 
    icon: '🎩', 
    colorClass: 'nestor-color',
    color: '#9333ea' // purple
  },
  'tintin@moulinsart.local': { 
    name: 'Tintin', 
    icon: '🚀', 
    colorClass: 'tintin-color',
    color: '#3b82f6' // blue
  },
  'dupont1@moulinsart.local': { 
    name: 'Dupont 1', 
    icon: '🎨', 
    colorClass: 'dupont1-color',
    color: '#10b981' // green
  },
  'dupont2@moulinsart.local': { 
    name: 'Dupont 2', 
    icon: '🔍', 
    colorClass: 'dupont2-color',
    color: '#f97316' // orange
  }
}

// Helper functions
const getAgentInfo = (email) => {
  return agents[email] || { name: email, icon: '👤', colorClass: 'unknown-color', color: '#6b7280' }
}

const getAgentName = (email) => getAgentInfo(email).name
const getAgentIcon = (email) => getAgentInfo(email).icon
const getAgentClass = (email) => getAgentInfo(email).colorClass

const isAgentEmail = (email) => {
  return Object.keys(agents).includes(email)
}

const truncateText = (text, maxLength) => {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

const formatTime = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  return date.toLocaleTimeString('fr-FR', { 
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  })
}

const formatFullDate = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  return date.toLocaleString('fr-FR', { 
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit', 
    minute: '2-digit',
    second: '2-digit'
  })
}

// Computed properties for filtering
const allEmails = computed(() => {
  return [...emails.value].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
})

const sentEmails = computed(() => {
  return allEmails.value.filter(email => isAgentEmail(email.from))
})

const receivedEmails = computed(() => {
  return allEmails.value.filter(email => isAgentEmail(email.to))
})

const filteredSentEmails = computed(() => {
  return sentEmails.value.filter(email => {
    // Search filter
    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      if (!email.subject?.toLowerCase().includes(query) && 
          !email.body?.toLowerCase().includes(query) &&
          !email.from?.toLowerCase().includes(query)) {
        return false
      }
    }
    
    // Agent filter
    if (agentFilter.value) {
      const targetEmail = `${agentFilter.value}@moulinsart.local`
      if (email.from !== targetEmail && email.to !== targetEmail) {
        return false
      }
    }
    
    return true
  })
})

const filteredReceivedEmails = computed(() => {
  return receivedEmails.value.filter(email => {
    // Search filter
    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      if (!email.subject?.toLowerCase().includes(query) && 
          !email.body?.toLowerCase().includes(query) &&
          !email.to?.toLowerCase().includes(query)) {
        return false
      }
    }
    
    // Agent filter
    if (agentFilter.value) {
      const targetEmail = `${agentFilter.value}@moulinsart.local`
      if (email.from !== targetEmail && email.to !== targetEmail) {
        return false
      }
    }
    
    return true
  })
})

const totalEmails = computed(() => {
  return emails.value.length
})

// Functions
const selectEmail = (email) => {
  selectedEmail.value = email
}

const closeEmailModal = () => {
  selectedEmail.value = null
}

const copyEmailToClipboard = () => {
  if (!selectedEmail.value) return
  
  const content = `De: ${selectedEmail.value.from}
À: ${selectedEmail.value.to}
Date: ${formatFullDate(selectedEmail.value.timestamp)}
Sujet: ${selectedEmail.value.subject}

${selectedEmail.value.body}`
  
  navigator.clipboard.writeText(content).then(() => {
    console.log('📋 Email copié dans le presse-papiers')
  }).catch(err => {
    console.error('Erreur lors de la copie:', err)
  })
}

const fetchEmails = async () => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:1080/api/emails')
    if (response.ok) {
      const data = await response.json()
      emails.value = data.emails || []
    }
  } catch (err) {
    console.error('Erreur lors du chargement des emails:', err)
  } finally {
    loading.value = false
  }
}

const connectWebSocket = () => {
  ws = new WebSocket('ws://localhost:3001/ws')
  
  ws.onopen = () => {
    console.log('EmailSplitView WebSocket connected')
    isConnected.value = true
  }
  
  ws.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data)
      
      if (message.type === 'email') {
        // Add new email to the list
        const newEmail = {
          ...message.data,
          id: Date.now() + Math.random(),
          timestamp: message.timestamp || new Date().toISOString()
        }
        emails.value.unshift(newEmail)
        
        // Keep only the latest 200 emails
        if (emails.value.length > 200) {
          emails.value = emails.value.slice(0, 200)
        }
      }
    } catch (err) {
      console.error('Failed to parse WebSocket message:', err)
    }
  }
  
  ws.onerror = (error) => {
    console.error('EmailSplitView WebSocket error:', error)
  }
  
  ws.onclose = () => {
    console.log('EmailSplitView WebSocket disconnected')
    isConnected.value = false
    
    // Attempt to reconnect after 3 seconds
    setTimeout(() => {
      connectWebSocket()
    }, 3000)
  }
}

// Lifecycle
onMounted(() => {
  fetchEmails()
  connectWebSocket()
  
  // Refresh emails every 10 seconds as fallback
  refreshInterval = setInterval(fetchEmails, 10000)
})

onUnmounted(() => {
  if (ws) {
    ws.close()
  }
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.email-split-view {
  height: 100%;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #ffefd5 0%, #ffe4b5 100%);
  padding: 20px;
}

.split-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 15px;
  background: white;
  border-radius: 12px;
  border: 3px solid #333;
  box-shadow: 4px 4px 0px #333;
}

.split-title {
  margin: 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.8em;
  text-shadow: 2px 2px 0px rgba(255,107,107,0.3);
}

.controls {
  display: flex;
  align-items: center;
  gap: 20px;
}

.search-filter {
  display: flex;
  gap: 10px;
  align-items: center;
}

.search-input {
  padding: 8px 12px;
  border: 2px solid #333;
  border-radius: 20px;
  font-size: 0.9em;
  width: 200px;
  background: #fff;
}

.search-input:focus {
  outline: none;
  border-color: #ff6b6b;
  box-shadow: 0 0 5px rgba(255, 107, 107, 0.3);
}

.agent-filter {
  padding: 8px 12px;
  border: 2px solid #333;
  border-radius: 20px;
  font-size: 0.9em;
  background: #fff;
  cursor: pointer;
}

.status-indicator {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
}

.connection-status {
  padding: 5px 10px;
  border-radius: 15px;
  font-weight: bold;
  font-size: 0.85em;
}

.connection-status.connected {
  background: #4caf50;
  color: white;
}

.connection-status:not(.connected) {
  background: #f44336;
  color: white;
}

.email-count {
  background: #ffd93d;
  padding: 3px 8px;
  border: 2px solid #333;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
  color: #333;
}

.split-container {
  flex: 1;
  display: flex;
  gap: 20px;
  overflow: hidden;
}

.panel {
  flex: 1;
  background: white;
  border-radius: 12px;
  border: 3px solid #333;
  box-shadow: 4px 4px 0px #333;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.panel-header {
  padding: 15px;
  background: linear-gradient(135deg, #ff6b6b 0%, #ffd93d 100%);
  border-bottom: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.panel-header h3 {
  margin: 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.3em;
  text-shadow: 1px 1px 0px rgba(255,255,255,0.5);
}

.panel-count {
  background: rgba(255,255,255,0.8);
  padding: 5px 10px;
  border-radius: 15px;
  font-weight: bold;
  color: #333;
  border: 2px solid #333;
}

.panel-content {
  flex: 1;
  overflow-y: auto;
  padding: 15px;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 1.1em;
}

.empty-panel {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.empty-icon {
  font-size: 4em;
  margin-bottom: 20px;
}

.emails-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.email-card {
  background: #f9f9f9;
  border: 2px solid #333;
  border-radius: 10px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 2px 2px 0px rgba(0,0,0,0.2);
}

.email-card:hover {
  transform: translateY(-2px);
  box-shadow: 4px 4px 8px rgba(0,0,0,0.3);
}

/* Agent color classes */
.nestor-color {
  border-left: 6px solid #9333ea;
}

.nestor-color:hover {
  background: rgba(147, 51, 234, 0.1);
}

.tintin-color {
  border-left: 6px solid #3b82f6;
}

.tintin-color:hover {
  background: rgba(59, 130, 246, 0.1);
}

.dupont1-color {
  border-left: 6px solid #10b981;
}

.dupont1-color:hover {
  background: rgba(16, 185, 129, 0.1);
}

.dupont2-color {
  border-left: 6px solid #f97316;
}

.dupont2-color:hover {
  background: rgba(249, 115, 22, 0.1);
}

.unknown-color {
  border-left: 6px solid #6b7280;
}

.unknown-color:hover {
  background: rgba(107, 114, 128, 0.1);
}

.email-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.email-from {
  font-weight: bold;
  color: #333;
  font-size: 0.9em;
}

.email-time {
  font-size: 0.8em;
  color: #666;
  font-family: 'Courier New', monospace;
}

.email-to {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 8px;
}

.email-subject {
  font-weight: bold;
  color: #333;
  margin-bottom: 8px;
  font-size: 1em;
}

.email-preview {
  color: #666;
  font-size: 0.85em;
  line-height: 1.4;
}

/* Modal styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 15px;
  border: 3px solid #333;
  box-shadow: 0 10px 50px rgba(0, 0, 0, 0.5);
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 20px;
  border-bottom: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 12px 12px 0 0;
}

.modal-header.nestor-color {
  background: linear-gradient(135deg, #9333ea, #a855f7);
  color: white;
}

.modal-header.tintin-color {
  background: linear-gradient(135deg, #3b82f6, #60a5fa);
  color: white;
}

.modal-header.dupont1-color {
  background: linear-gradient(135deg, #10b981, #34d399);
  color: white;
}

.modal-header.dupont2-color {
  background: linear-gradient(135deg, #f97316, #fb923c);
  color: white;
}

.modal-header.unknown-color {
  background: linear-gradient(135deg, #6b7280, #9ca3af);
  color: white;
}

.modal-header h3 {
  margin: 0;
  font-family: 'Comic Sans MS', cursive;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2em;
  cursor: pointer;
  color: inherit;
  padding: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  transform: scale(1.2);
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
}

.email-details {
  background: #f9f9f9;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
  border: 2px solid #333;
}

.detail-row {
  margin-bottom: 8px;
  font-size: 0.95em;
}

.detail-row strong {
  color: #333;
  margin-right: 8px;
}

.email-content h4 {
  color: #333;
  margin-bottom: 10px;
  font-family: 'Comic Sans MS', cursive;
}

.email-body {
  background: #f5f5f5;
  border: 2px solid #333;
  padding: 15px;
  border-radius: 8px;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
  line-height: 1.6;
  white-space: pre-wrap;
  max-height: 300px;
  overflow-y: auto;
  margin: 0;
}

.modal-footer {
  padding: 20px;
  border-top: 3px solid #333;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn-copy,
.btn-close {
  padding: 10px 20px;
  border: 3px solid #333;
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s;
}

.btn-copy {
  background: #4caf50;
  color: white;
}

.btn-close {
  background: #ccc;
  color: #333;
}

.btn-copy:hover,
.btn-close:hover {
  transform: scale(1.05);
}

/* Animations */
.email-fade-enter-active,
.email-fade-leave-active {
  transition: all 0.5s ease;
}

.email-fade-enter-from,
.email-fade-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 12px;
  height: 12px;
}

::-webkit-scrollbar-track {
  background: rgba(0,0,0,0.1);
  border-radius: 6px;
}

::-webkit-scrollbar-thumb {
  background: #ff6b6b;
  border-radius: 6px;
  border: 2px solid #333;
}

::-webkit-scrollbar-thumb:hover {
  background: #ff5252;
}
</style>