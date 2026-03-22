<template>
  <div class="agent-control">
    <div class="header">
      <h2>🎮 Contrôle des Agents</h2>
      <div class="actions">
        <button @click="refreshStatus" class="btn-refresh">🔄 Rafraîchir</button>
        <button @click="openManager" class="btn-manager">🎮 Gestionnaire Terminal</button>
        <button @click="stopAll" class="btn-stop-all">🛑 Arrêter Tous</button>
      </div>
    </div>
    
    <div class="agents-grid">
      <div v-for="agent in agents" :key="agent.name" class="agent-card" :class="{ running: agent.running }">
        <div class="agent-header">
          <span class="agent-icon">{{ agent.icon }}</span>
          <h3>{{ agent.title }}</h3>
          <span class="status-indicator" :class="{ active: agent.running }">
            {{ agent.running ? '🟢' : '🔴' }}
          </span>
        </div>
        
        <div class="agent-info">
          <p><strong>Email:</strong> {{ agent.email }}</p>
          <p><strong>Répertoire:</strong> {{ agent.directory }}</p>
          <p><strong>Status:</strong> {{ agent.running ? 'En cours' : 'Arrêté' }}</p>
        </div>
        
        <div class="agent-actions">
          <button 
            v-if="!agent.running" 
            @click="launchAgent(agent.name)"
            class="btn-launch">
            🚀 Lancer
          </button>
          <button 
            v-else 
            @click="stopAgent(agent.name)"
            class="btn-stop">
            ⏹️ Arrêter
          </button>
        </div>
      </div>
    </div>
    
    <div v-if="loading" class="loading">⏳ Chargement...</div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

interface Agent {
  name: string
  title: string
  icon: string
  email: string
  directory: string
  running: boolean
}

const agents = ref<Agent[]>([
  {
    name: 'nestor',
    title: 'NESTOR - Chef d\'Orchestre',
    icon: '🎩',
    email: 'nestor@moulinsart.local',
    directory: '/Users/studio_m3/moulinsart/agents/nestor',
    running: false
  },
  {
    name: 'tintin',
    title: 'TINTIN - QA Lead',
    icon: '🚀',
    email: 'tintin@moulinsart.local',
    directory: '/Users/studio_m3/moulinsart/agents/tintin',
    running: false
  },
  {
    name: 'dupont1',
    title: 'DUPONT1 - Développeur Swift',
    icon: '🎨',
    email: 'dupont1@moulinsart.local',
    directory: '/Users/studio_m3/moulinsart/agents/dupont1',
    running: false
  },
  {
    name: 'dupont2',
    title: 'DUPONT2 - Recherche & Docs',
    icon: '🔍',
    email: 'dupont2@moulinsart.local',
    directory: '/Users/studio_m3/moulinsart/agents/dupont2',
    running: false
  }
])

const loading = ref(false)
let refreshInterval: number | null = null

const refreshStatus = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/agents/status')
    if (response.ok) {
      const statuses = await response.json()
      
      agents.value.forEach(agent => {
        if (statuses[agent.name]) {
          agent.running = statuses[agent.name].running
          if (statuses[agent.name].email) {
            agent.email = statuses[agent.name].email
          }
          if (statuses[agent.name].directory) {
            agent.directory = statuses[agent.name].directory
          }
        }
      })
    }
  } catch (error) {
    console.error('Erreur lors de la récupération du statut:', error)
  }
}

const launchAgent = async (agentName: string) => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:3001/api/agents/launch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ agent: agentName })
    })
    
    if (response.ok) {
      // Attendre un peu avant de rafraîchir le statut
      setTimeout(() => {
        refreshStatus()
        loading.value = false
      }, 2000)
    } else {
      loading.value = false
    }
  } catch (error) {
    console.error('Erreur lors du lancement:', error)
    loading.value = false
  }
}

const stopAgent = async (agentName: string) => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:3001/api/agents/stop', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ agent: agentName })
    })
    
    if (response.ok) {
      // Rafraîchir le statut immédiatement
      await refreshStatus()
    }
  } catch (error) {
    console.error('Erreur lors de l\'arrêt:', error)
  } finally {
    loading.value = false
  }
}

const launchAll = async () => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:3001/api/agents/launch-tmux', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })
    
    if (response.ok) {
      // Attendre un peu avant de rafraîchir le statut
      setTimeout(() => {
        refreshStatus()
        loading.value = false
      }, 3000)
    } else {
      loading.value = false
    }
  } catch (error) {
    console.error('Erreur lors du lancement tmux:', error)
    loading.value = false
  }
}

const stopAll = async () => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:3001/api/agents/stop-all', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })
    
    if (response.ok) {
      // Rafraîchir le statut après un délai
      setTimeout(() => {
        refreshStatus()
        loading.value = false
      }, 1000)
    } else {
      loading.value = false
    }
  } catch (error) {
    console.error('Erreur lors de l\'arrêt de tous les agents:', error)
    loading.value = false
  }
}

const openManager = async () => {
  loading.value = true
  try {
    const response = await fetch('http://localhost:3001/api/agents/open-manager', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    })
    
    if (response.ok) {
      // Le gestionnaire va s'ouvrir dans Terminal
      console.log('🎮 Gestionnaire Moulinsart ouvert')
      // Rafraîchir le statut après un délai
      setTimeout(() => {
        refreshStatus()
        loading.value = false
      }, 2000)
    } else {
      loading.value = false
    }
  } catch (error) {
    console.error('Erreur lors de l\'ouverture du gestionnaire:', error)
    loading.value = false
  }
}

onMounted(() => {
  refreshStatus()
  // Rafraîchir toutes les 5 secondes
  refreshInterval = setInterval(refreshStatus, 5000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.agent-control {
  background: white;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 2px solid #e0e0e0;
}

.header h2 {
  margin: 0;
  color: #2c3e50;
  font-size: 24px;
}

.actions {
  display: flex;
  gap: 10px;
}

.actions button {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-refresh {
  background: #3498db;
  color: white;
}

.btn-refresh:hover {
  background: #2980b9;
}

.btn-launch-all {
  background: #27ae60;
  color: white;
}

.btn-launch-all:hover {
  background: #229954;
}

.btn-manager {
  background: #f39c12;
  color: white;
  font-weight: bold;
}

.btn-manager:hover {
  background: #e67e22;
  transform: scale(1.05);
}

.btn-stop-all {
  background: #e74c3c;
  color: white;
}

.btn-stop-all:hover {
  background: #c0392b;
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.agent-card {
  background: #f8f9fa;
  border: 2px solid #dee2e6;
  border-radius: 10px;
  padding: 15px;
  transition: all 0.3s;
}

.agent-card.running {
  background: #d4edda;
  border-color: #28a745;
}

.agent-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid #dee2e6;
}

.agent-icon {
  font-size: 24px;
}

.agent-header h3 {
  flex: 1;
  margin: 0;
  font-size: 16px;
  color: #495057;
}

.status-indicator {
  font-size: 16px;
}

.status-indicator.active {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.agent-info {
  margin-bottom: 15px;
}

.agent-info p {
  margin: 5px 0;
  font-size: 13px;
  color: #6c757d;
  word-break: break-word;
}

.agent-info strong {
  color: #495057;
}

.agent-actions {
  display: flex;
  gap: 10px;
}

.agent-actions button {
  flex: 1;
  padding: 8px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-launch {
  background: #28a745;
  color: white;
}

.btn-launch:hover {
  background: #218838;
}

.btn-stop {
  background: #dc3545;
  color: white;
}

.btn-stop:hover {
  background: #c82333;
}

.loading {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(0,0,0,0.8);
  color: white;
  padding: 20px 40px;
  border-radius: 10px;
  font-size: 18px;
  z-index: 1000;
}
</style>