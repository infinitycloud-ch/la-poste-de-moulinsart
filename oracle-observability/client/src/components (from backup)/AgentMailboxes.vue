<template>
  <div class="mailboxes-container">
    <h2 class="mailboxes-title">📮 Boîtes Mail des Agents</h2>
    
    <div class="projects-container">
      <!-- Section Moulinsart -->
      <div class="project-section">
        <div class="project-header">
          <h3 class="project-title">🎩 Projet Moulinsart</h3>
          <button @click="toggleProject('moulinsart')" class="project-toggle-btn" :title="projectsVisible.moulinsart ? 'Masquer' : 'Afficher'">
            {{ projectsVisible.moulinsart ? '📂 ⬆️' : '📁 ⬇️' }}
          </button>
        </div>
        <div v-show="projectsVisible.moulinsart" class="mailboxes-grid">
          <div v-for="agent in moulinsartAgents" :key="agent.name" class="mailbox-card">
            <div class="mailbox-header" :class="agent.colorClass">
              <span class="agent-icon">{{ agent.icon }}</span>
              <span class="agent-name">{{ agent.name }}</span>
              <span class="email-count">{{ agent.emails.length }} emails</span>
              <button @click="showTmuxModalForAgent(agent, 'moulinsart-agents')" class="notify-btn" title="Envoyer message TMUX">
                🔔
              </button>
              <button @click="refreshMailbox(agent)" class="refresh-btn" title="Rafraîchir">
                🔄
              </button>
            </div>
            
            <div class="mailbox-content">
              <div v-if="agent.loading" class="loading">
                Chargement...
              </div>
              
              <div v-else-if="!getReceivedEmails(agent).length && !getSentEmails(agent).length" class="no-emails">
                📭 Boîte mail vide
              </div>
              
              <div v-else class="emails-sections">
                <!-- Emails Reçus -->
                <div v-if="getReceivedEmails(agent).length > 0" class="email-section">
                  <h4 class="section-title">📥 Reçus ({{ getReceivedEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getReceivedEmails(agent)" :key="email.id" 
                         class="email-item received"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">De: {{ email.from }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Emails Envoyés -->
                <div v-if="getSentEmails(agent).length > 0" class="email-section">
                  <h4 class="section-title">📤 Envoyés ({{ getSentEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getSentEmails(agent)" :key="email.id" 
                         class="email-item sent"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">À: {{ email.to || email.recipients }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Emails Archivés -->
                <div v-if="getArchivedEmails(agent).length > 0" class="email-section archived">
                  <h4 class="section-title">📦 Archivés ({{ getArchivedEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getArchivedEmails(agent)" :key="email.id" 
                         class="email-item archived"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">{{ email.from ? 'De: ' + email.from : 'À: ' + (email.to || email.recipients) }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="mailbox-actions">
              <button @click="openMailbox(agent)" class="action-btn open">
                📂 Ouvrir JSON
              </button>
              <button @click="archiveEmails(agent)" class="action-btn archive">
                📦 Archiver
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Section Manitoba -->
      <div class="project-section">
        <div class="project-header">
          <h3 class="project-title">🌾 Projet Manitoba</h3>
          <button @click="toggleProject('manitoba')" class="project-toggle-btn" :title="projectsVisible.manitoba ? 'Masquer' : 'Afficher'">
            {{ projectsVisible.manitoba ? '📂 ⬆️' : '📁 ⬇️' }}
          </button>
        </div>
        <div v-show="projectsVisible.manitoba" class="mailboxes-grid">
          <div v-for="agent in manitobaAgents" :key="agent.name" class="mailbox-card">
            <div class="mailbox-header" :class="agent.colorClass">
              <span class="agent-icon">{{ agent.icon }}</span>
              <span class="agent-name">{{ agent.name }}</span>
              <span class="email-count">{{ agent.emails.length }} emails</span>
              <button @click="showTmuxModalForAgent(agent, 'manitoba-agents')" class="notify-btn" title="Envoyer message TMUX">
                🔔
              </button>
              <button @click="refreshMailbox(agent)" class="refresh-btn" title="Rafraîchir">
                🔄
              </button>
            </div>
            
            <div class="mailbox-content">
              <div v-if="agent.loading" class="loading">
                Chargement...
              </div>
              
              <div v-else-if="!getReceivedEmails(agent).length && !getSentEmails(agent).length" class="no-emails">
                📭 Boîte mail vide
              </div>
              
              <div v-else class="emails-sections">
                <!-- Emails Reçus -->
                <div v-if="getReceivedEmails(agent).length > 0" class="email-section">
                  <h4 class="section-title">📥 Reçus ({{ getReceivedEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getReceivedEmails(agent)" :key="email.id" 
                         class="email-item received"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">De: {{ email.from }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Emails Envoyés -->
                <div v-if="getSentEmails(agent).length > 0" class="email-section">
                  <h4 class="section-title">📤 Envoyés ({{ getSentEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getSentEmails(agent)" :key="email.id" 
                         class="email-item sent"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">À: {{ email.to || email.recipients }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Emails Archivés -->
                <div v-if="getArchivedEmails(agent).length > 0" class="email-section archived">
                  <h4 class="section-title">📦 Archivés ({{ getArchivedEmails(agent).length }})</h4>
                  <div class="emails-list">
                    <div v-for="email in getArchivedEmails(agent)" :key="email.id" 
                         class="email-item archived"
                         :class="{ expanded: selectedEmail === email }">
                      <div class="email-header">
                        <span class="email-from">{{ email.from ? 'De: ' + email.from : 'À: ' + (email.to || email.recipients) }}</span>
                        <span class="email-date">{{ formatDate(email.timestamp) }}</span>
                      </div>
                      <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
                      <div v-if="selectedEmail === email" class="email-body">
                        <pre>{{ email.body }}</pre>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="mailbox-actions">
              <button @click="openMailbox(agent)" class="action-btn open">
                📂 Ouvrir JSON
              </button>
              <button @click="archiveEmails(agent)" class="action-btn archive">
                📦 Archiver
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="mailboxes-grid" style="display: none;">
      <!-- Mailbox de chaque agent -->
      <div v-for="agent in agents" :key="agent.name" class="mailbox-card">
        <div class="mailbox-header" :class="agent.colorClass">
          <span class="agent-icon">{{ agent.icon }}</span>
          <span class="agent-name">{{ agent.name }}</span>
          <span class="email-count">{{ agent.emails.length }} emails</span>
          <button @click="notifyAgent(agent)" class="notify-btn" title="Envoyer notification">
            🔔
          </button>
          <button @click="refreshMailbox(agent)" class="refresh-btn" title="Rafraîchir">
            🔄
          </button>
        </div>
        
        <div class="mailbox-content">
          <div v-if="agent.loading" class="loading">
            Chargement...
          </div>
          
          <div v-else-if="agent.emails.length === 0" class="no-emails">
            📭 Boîte mail vide
          </div>
          
          <div v-else class="emails-list">
            <div v-for="email in agent.emails" :key="email.id" 
                 class="email-item"
                 :class="{ expanded: selectedEmail === email }">
              <div class="email-header">
                <span class="email-from">De: {{ email.from }}</span>
                <span class="email-date">{{ formatDate(email.timestamp) }}</span>
              </div>
              <div class="email-subject" @click="selectEmail(agent, email)">{{ email.subject }}</div>
              <div v-if="selectedEmail === email" class="email-body">
                <pre>{{ email.body }}</pre>
              </div>
            </div>
          </div>
        </div>
        
        <div class="mailbox-actions">
          <button @click="openMailbox(agent)" class="action-btn open">
            📂 Ouvrir JSON
          </button>
          <button @click="clearMailbox(agent)" class="action-btn clear">
            🗑️ Vider
          </button>
        </div>
      </div>
    </div>
    
    <!-- Modal de sélection de commande TMUX -->
    <div v-if="showTmuxModal" class="modal-overlay" @click.self="closeTmuxModal">
      <div class="modal-content tmux-modal">
        <div class="modal-header">
          <h3>🖥️ Choisir un Message TMUX pour {{ selectedAgent?.name }}</h3>
          <button @click="closeTmuxModal" class="close-btn">×</button>
        </div>
        <div class="modal-body">
          <div class="tmux-commands-list">
            <div 
              v-for="cmd in tmuxCommands" 
              :key="cmd.id" 
              @click="sendTmuxCommand(cmd)"
              class="tmux-command-item"
            >
              <span class="cmd-icon">{{ cmd.icon || '💬' }}</span>
              <div class="cmd-content">
                <div class="cmd-name">{{ cmd.name }}</div>
                <div class="cmd-preview">{{ cmd.message }}</div>
              </div>
              <span class="cmd-category">{{ cmd.category }}</span>
            </div>
          </div>
          <div class="quick-message">
            <h4>📝 Message Rapide:</h4>
            <textarea 
              v-model="quickMessage" 
              rows="4" 
              placeholder="Tapez un message personnalisé..."
            ></textarea>
            <button @click="sendQuickTmuxMessage" class="btn-send-quick">
              🚀 Envoyer Message Rapide
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modal de composition d'email -->
    <div v-if="showComposeModal" class="modal-overlay" @click.self="closeCompose">
      <div class="modal-content">
        <div class="modal-header">
          <h3>📧 Nouveau Message</h3>
          <button @click="closeCompose" class="close-btn">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>De:</label>
            <input v-model="newEmail.from" placeholder="commandant@moulinsart.local" />
          </div>
          <div class="form-group">
            <label>À:</label>
            <input v-model="newEmail.to" readonly />
          </div>
          <div class="form-group">
            <label>Sujet:</label>
            <input v-model="newEmail.subject" placeholder="Sujet du message" />
          </div>
          <div class="form-group">
            <label>Message:</label>
            <textarea v-model="newEmail.body" rows="10" placeholder="Votre message..."></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="sendEmail" class="btn-send">🚀 Envoyer</button>
          <button @click="closeCompose" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const moulinsartAgents = ref([
  { 
    name: 'Nestor',
    email: 'nestor@moulinsart.local',
    icon: '🎩',
    colorClass: 'nestor',
    emails: [],
    loading: false
  },
  { 
    name: 'Tintin',
    email: 'tintin@moulinsart.local',
    icon: '🚀',
    colorClass: 'tintin',
    emails: [],
    loading: false
  },
  { 
    name: 'Dupont1',
    email: 'dupont1@moulinsart.local',
    icon: '🎨',
    colorClass: 'dupont1',
    emails: [],
    loading: false
  },
  { 
    name: 'Dupont2',
    email: 'dupont2@moulinsart.local',
    icon: '🔍',
    colorClass: 'dupont2',
    emails: [],
    loading: false
  }
])

const manitobaAgents = ref([
  { 
    name: 'Haddock',
    email: 'haddock@manitoba.local',
    icon: '⚓',
    colorClass: 'haddock',
    emails: [],
    loading: false
  },
  { 
    name: 'Rastapopoulos',
    email: 'rastapopoulos@manitoba.local',
    icon: '🧔',
    colorClass: 'rastapopoulos',
    emails: [],
    loading: false
  },
  { 
    name: 'Tournesol1',
    email: 'tournesol1@manitoba.local',
    icon: '🧪',
    colorClass: 'tournesol1',
    emails: [],
    loading: false
  },
  { 
    name: 'Tournesol2',
    email: 'tournesol2@manitoba.local',
    icon: '🔬',
    colorClass: 'tournesol2',
    emails: [],
    loading: false
  }
])

// Compatibilité avec l'ancien code
const agents = ref([...moulinsartAgents.value, ...manitobaAgents.value])

// Stockage des emails archivés (en mémoire pour l'instant)
const archivedEmails = ref({})

const selectedEmail = ref(null)
const showComposeModal = ref(false)
const showTmuxModal = ref(false)
const selectedAgent = ref(null)
const selectedSession = ref('')
const quickMessage = ref('')
const tmuxCommands = ref([])
const projectsVisible = ref({
  moulinsart: true,
  manitoba: true
})
const newEmail = ref({
  from: 'commandant@moulinsart.local',
  to: '',
  subject: '',
  body: ''
})

let refreshInterval = null

// Charger les emails d'un agent
const refreshMailbox = async (agent) => {
  agent.loading = true
  try {
    const response = await fetch(`http://localhost:1080/api/mailbox/${agent.email}`)
    if (response.ok) {
      const data = await response.json()
      agent.emails = data.emails || []
    }
  } catch (err) {
    console.error(`Erreur chargement mailbox ${agent.name}:`, err)
    agent.emails = []
  } finally {
    agent.loading = false
  }
}

// Basculer la visibilité d'un projet spécifique
const toggleProject = (projectName) => {
  projectsVisible.value[projectName] = !projectsVisible.value[projectName]
}

// Rafraîchir toutes les boîtes
const refreshAllMailboxes = async () => {
  // Ne pas rafraîchir si un email est sélectionné (pour éviter qu'il se ferme)
  if (selectedEmail.value) {
    return
  }
  
  for (const agent of [...moulinsartAgents.value, ...manitobaAgents.value]) {
    await refreshMailbox(agent)
  }
}

// Sélectionner un email
const selectEmail = (agent, email) => {
  if (selectedEmail.value === email) {
    selectedEmail.value = null
  } else {
    selectedEmail.value = email
    email.read = true
  }
}

// Copier le contenu de l'email
const copyEmail = (email) => {
  const content = `De: ${email.from}
À: ${email.to || ''}
Date: ${email.timestamp}
Sujet: ${email.subject}

${email.body}`
  
  navigator.clipboard.writeText(content).then(() => {
    console.log('📋 Email copié dans le presse-papiers')
  }).catch(err => {
    console.error('Erreur lors de la copie:', err)
  })
}

// Composer un email
const composeEmail = (agent) => {
  newEmail.value = {
    from: 'commandant@moulinsart.local',
    to: agent.email,
    subject: '',
    body: ''
  }
  showComposeModal.value = true
}

// Fermer la modal
const closeCompose = () => {
  showComposeModal.value = false
}

// Envoyer l'email
const sendEmail = async () => {
  try {
    const response = await fetch('http://localhost:1080/api/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(newEmail.value)
    })
    
    if (response.ok) {
      console.log('📧 Email envoyé')
      closeCompose()
      // Rafraîchir la boîte du destinataire
      const targetAgent = agents.value.find(a => a.email === newEmail.value.to)
      if (targetAgent) {
        setTimeout(() => refreshMailbox(targetAgent), 1000)
      }
    }
  } catch (err) {
    console.error('Erreur envoi email:', err)
  }
}

// Ouvrir la mailbox dans un nouvel onglet (JSON)
const openMailbox = (agent) => {
  window.open(`http://localhost:1080/api/mailbox/${agent.email}`, '_blank')
}

// Ouvrir le modal TMUX pour un agent
const showTmuxModalForAgent = async (agent, sessionName = 'moulinsart-agents') => {
  selectedAgent.value = agent
  selectedSession.value = sessionName
  quickMessage.value = ''
  
  // Charger les commandes TMUX disponibles
  await loadTmuxCommands()
  
  showTmuxModal.value = true
}

// Charger les commandes TMUX depuis l'API
const loadTmuxCommands = async () => {
  try {
    // Forcer le rechargement sans cache
    const response = await fetch('http://localhost:3001/api/tmux-commands?t=' + Date.now())
    if (response.ok) {
      const data = await response.json()
      tmuxCommands.value = data.commands || []
      console.log('Commandes TMUX rechargées:', tmuxCommands.value.length)
    }
  } catch (err) {
    console.error('Erreur chargement commandes TMUX:', err)
    // Commandes par défaut si l'API échoue
    tmuxCommands.value = [
      {
        id: 1,
        name: 'Réveil Simple',
        icon: '🔔',
        category: 'Réveil',
        message: '🔔 RÉVEIL AGENT\\n━━━━━━━━━━━━━━━━━━━━\\n📧 Vérifie tes emails!\\n\\ncurl http://localhost:1080/api/mailbox/{email}'
      },
      {
        id: 2,
        name: 'Debug Mode',
        icon: '🐛',
        category: 'Debug',
        message: '🐛 MODE DEBUG ACTIVÉ\\n━━━━━━━━━━━━━━━━━━━━\\nAffiche les logs détaillés\\ntail -f /tmp/oracle.log'
      },
      {
        id: 3,
        name: 'Pause',
        icon: '⏸️',
        category: 'Workflow',
        message: '⏸️ PAUSE DEMANDÉE\\n━━━━━━━━━━━━━━━━━━━━\\nMets ton travail en pause\\nAttends de nouvelles instructions'
      }
    ]
  }
}

// Fermer le modal TMUX
const closeTmuxModal = () => {
  showTmuxModal.value = false
  selectedAgent.value = null
  selectedSession.value = ''
  quickMessage.value = ''
}

// Envoyer une commande TMUX prédéfinie
const sendTmuxCommand = async (command) => {
  if (!selectedAgent.value || !selectedSession.value) return
  
  // Remplacer les variables dans le message
  let message = command.message
    .replace(/{agent}/g, selectedAgent.value.name)
    .replace(/{email}/g, selectedAgent.value.email)
    .replace(/{time}/g, new Date().toLocaleTimeString('fr-FR'))
    .replace(/{date}/g, new Date().toLocaleDateString('fr-FR'))
  
  await executeTmuxCommand(message)
  closeTmuxModal()
}

// Envoyer un message TMUX rapide
const sendQuickTmuxMessage = async () => {
  if (!quickMessage.value || !selectedAgent.value || !selectedSession.value) return
  
  await executeTmuxCommand(quickMessage.value)
  closeTmuxModal()
}

// Exécuter la commande TMUX
const executeTmuxCommand = async (message) => {
  const agent = selectedAgent.value
  const sessionName = selectedSession.value
  
  // Déterminer le numéro du panel selon le projet
  let panelNumber
  
  if (sessionName === 'moulinsart-agents') {
    switch(agent.name.toLowerCase()) {
      case 'nestor': panelNumber = 0; break;
      case 'tintin': panelNumber = 1; break;
      case 'dupont1': panelNumber = 2; break;
      case 'dupont2': panelNumber = 3; break;
      default: return;
    }
  } else if (sessionName === 'manitoba-agents') {
    switch(agent.name.toLowerCase()) {
      case 'haddock': panelNumber = 0; break;
      case 'rastapopoulos': panelNumber = 1; break;
      case 'tournesol1': panelNumber = 2; break;
      case 'tournesol2': panelNumber = 3; break;
      default: return;
    }
  }
  
  // Préparer le message pour tmux (gérer les retours à la ligne)
  const lines = message.split('\\n')
  let bashCommand = `tmux send-keys -t ${sessionName}:agents.${panelNumber} C-m`
  
  for (const line of lines) {
    if (line.trim()) {
      bashCommand += ` && tmux send-keys -t ${sessionName}:agents.${panelNumber} "echo '${line}'" C-m`
    }
  }
  
  bashCommand += ` && tmux send-keys -t ${sessionName}:agents.${panelNumber} C-m`
  
  // Envoyer via l'API
  try {
    const response = await fetch('http://localhost:3001/api/exec', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ command: bashCommand })
    })
    
    if (response.ok) {
      console.log(`🖥️ Message TMUX envoyé à ${agent.name} (${sessionName})`)
    }
  } catch (err) {
    console.error('Erreur envoi message TMUX:', err)
  }
}

// Envoyer une notification manuelle à un agent (ancienne fonction, gardée pour compatibilité)
const notifyAgent = async (agent, sessionName = 'moulinsart-agents') => {
  // Déterminer le numéro du panel selon le projet
  let panelNumber
  
  if (sessionName === 'moulinsart-agents') {
    switch(agent.name.toLowerCase()) {
      case 'nestor': panelNumber = 0; break;
      case 'tintin': panelNumber = 1; break;
      case 'dupont1': panelNumber = 2; break;
      case 'dupont2': panelNumber = 3; break;
      default: return;
    }
  } else if (sessionName === 'manitoba-agents') {
    switch(agent.name.toLowerCase()) {
      case 'haddock': panelNumber = 0; break;
      case 'rastapopoulos': panelNumber = 1; break;
      case 'tournesol1': panelNumber = 2; break;
      case 'tournesol2': panelNumber = 3; break;
      default: return;
    }
  }
  
  // Envoyer la notification via tmux
  // Envoyer directement via bash
  try {
    const bashCommand = `tmux send-keys -t ${session}:agents.${panelNumber} C-m && tmux send-keys -t ${session}:agents.${panelNumber} "echo '🔔 RÉVEIL MANUEL'" C-m && tmux send-keys -t ${session}:agents.${panelNumber} "echo '📧 Vérifie tes emails: curl http://localhost:1080/api/mailbox/${agent.email}'" C-m && tmux send-keys -t ${session}:agents.${panelNumber} C-m`
    
    const response = await fetch('http://localhost:3001/api/exec', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ command: bashCommand })
    })
    
    if (response.ok) {
      console.log(`🔔 Notification envoyée à ${agent.name} (${session})`)
    }
  } catch (err) {
    console.error('Erreur envoi notification:', err)
    // Fallback: essayer via un event
    try {
      await fetch('http://localhost:3001/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'notification',
          agent: agent.name,
          message: `Réveil manuel pour ${agent.name}`
        })
      })
    } catch (e) {
      console.error('Fallback échoué:', e)
    }
  }
}


// Séparer les emails reçus, envoyés et archivés
const getReceivedEmails = (agent) => {
  const archived = archivedEmails.value[agent.email] || []
  return agent.emails.filter(email => 
    email.to && email.to.includes(agent.email) && !archived.find(a => a.id === email.id)
  ).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
}

const getSentEmails = (agent) => {
  const archived = archivedEmails.value[agent.email] || []
  return agent.emails.filter(email => 
    email.from && email.from.includes(agent.email) && !archived.find(a => a.id === email.id)
  ).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
}

const getArchivedEmails = (agent) => {
  return archivedEmails.value[agent.email] || []
}

// Archiver tous les emails actifs
const archiveEmails = (agent) => {
  if (!archivedEmails.value[agent.email]) {
    archivedEmails.value[agent.email] = []
  }
  
  // Archiver tous les emails non archivés
  const toArchive = agent.emails.filter(email => {
    const archived = archivedEmails.value[agent.email]
    return !archived.find(a => a.id === email.id)
  })
  
  if (toArchive.length > 0) {
    archivedEmails.value[agent.email].push(...toArchive)
    console.log(`📦 ${toArchive.length} emails archivés pour ${agent.name}`)
  }
}

// Formater la date
const formatDate = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  return date.toLocaleTimeString('fr-FR', { 
    hour: '2-digit', 
    minute: '2-digit' 
  })
}

// Lifecycle
onMounted(() => {
  refreshAllMailboxes()
  // Rafraîchir toutes les 5 secondes
  refreshInterval = setInterval(refreshAllMailboxes, 5000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.mailboxes-container {
  padding: 0;
  background: transparent;
  height: auto;
  overflow: visible;
  margin-bottom: 12px;
}

.mailboxes-title {
  margin: 0 0 15px 0;
  color: #ff6b6b;
  font-family: 'Comic Sans MS', cursive;
  text-shadow: 1px 1px 0px #333;
  font-size: 1.3em;
}

.projects-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.project-section {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  padding: 15px;
  border: 2px solid rgba(255, 107, 107, 0.3);
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 2px solid rgba(74, 144, 226, 0.3);
}

.project-title {
  margin: 0;
  color: #4a90e2;
  font-family: 'Comic Sans MS', cursive;
  text-shadow: 1px 1px 0px #333;
  font-size: 1.1em;
  flex: 1;
  text-align: center;
}

.project-toggle-btn {
  background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
  color: white;
  border: 2px solid #333;
  border-radius: 15px;
  padding: 6px 12px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.8em;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.project-toggle-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.3);
  background: linear-gradient(135deg, #357abd 0%, #4a90e2 100%);
}

.mailboxes-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.mailbox-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow: hidden;
}

.mailbox-header {
  padding: 8px 12px;
  color: white;
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: bold;
  font-size: 0.9em;
}

/* Couleurs Moulinsart */
.mailbox-header.nestor { background: #10B981; }
.mailbox-header.tintin { background: #3B82F6; }
.mailbox-header.dupont1 { background: #FBBF24; color: #333; }
.mailbox-header.dupont2 { background: #8B5CF6; }

/* Couleurs Manitoba */
.mailbox-header.haddock { background: #1565C0; }
.mailbox-header.rastapopoulos { background: #D32F2F; }
.mailbox-header.tournesol1 { background: #388E3C; }
.mailbox-header.tournesol2 { background: #7B1FA2; }

.agent-icon { font-size: 1.2em; }
.agent-name { flex: 1; }
.email-count {
  background: rgba(255,255,255,0.3);
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 0.8em;
}

.refresh-btn, .notify-btn {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.2em;
  opacity: 0.8;
  transition: opacity 0.2s;
}

.refresh-btn:hover, .notify-btn:hover { opacity: 1; }

.mailbox-content {
  height: calc(400px * var(--scale-factor, 1));
  overflow-y: auto;
  padding: calc(8px * var(--scale-factor, 1));
}

.loading, .no-emails {
  text-align: center;
  color: #666;
  padding: 20px;
}

.emails-sections {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.email-section {
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  overflow: hidden;
  background: #fafafa;
}

.section-title {
  margin: 0;
  padding: 8px 12px;
  background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
  color: white;
  font-size: 0.85em;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 6px;
}

.emails-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px;
}

.email-item {
  padding: calc(5px * var(--scale-factor, 1)) calc(7px * var(--scale-factor, 1));
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: calc(3px * var(--scale-factor, 1));
}

.email-item:hover {
  background: #f0f0f0;
}

.email-item.unread {
  background: #e3f2fd;
  border-color: #2196f3;
  font-weight: bold;
}

.email-item.received {
  border-left: 4px solid #4CAF50;
  background: #f1f8e9;
}

.email-item.sent {
  border-left: 4px solid #2196F3;
  background: #e3f2fd;
}

.email-item.archived {
  border-left: 4px solid #9E9E9E;
  background: #f5f5f5;
  opacity: 0.8;
}

.email-section.archived .section-title {
  background: linear-gradient(135deg, #757575 0%, #616161 100%);
}

.email-header {
  display: flex;
  justify-content: space-between;
  font-size: calc(0.75em * var(--scale-factor, 1));
  color: #666;
  margin-bottom: calc(2px * var(--scale-factor, 1));
}

.email-subject {
  color: #333;
  font-weight: 500;
  font-size: calc(0.85em * var(--scale-factor, 1));
  cursor: pointer;
  padding: calc(2px * var(--scale-factor, 1)) 0;
  line-height: 1.3;
}

.email-item.expanded {
  background: #f5f5f5;
  border-color: #999;
}

.email-body {
  margin-top: 6px;
  padding-top: 6px;
  border-top: 1px solid #e0e0e0;
}

.email-body pre {
  color: #555;
  font-size: 0.8em;
  white-space: pre-wrap;
  margin: 0;
  font-family: inherit;
  max-height: 200px;
  overflow-y: auto;
}

.mailbox-actions {
  padding: 10px;
  background: #f9f9f9;
  display: flex;
  gap: 10px;
}

.action-btn {
  flex: 1;
  padding: 8px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.action-btn.open {
  background: #2196F3;
  color: white;
}

.action-btn.archive {
  background: #9C27B0;
  color: white;
}

.action-btn:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 10px;
  width: 600px;
  max-width: 90%;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 15px 20px;
  background: #2196f3;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 1.5em;
  cursor: pointer;
  opacity: 0.8;
}

.close-btn:hover { opacity: 1; }

.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
  color: #555;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-group textarea {
  resize: vertical;
  font-family: inherit;
}

.modal-footer {
  padding: 15px 20px;
  background: #f5f5f5;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-send, .btn-cancel {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.btn-send {
  background: #4CAF50;
  color: white;
}

.btn-cancel {
  background: #ccc;
  color: #333;
}

.btn-send:hover,
.btn-cancel:hover {
  opacity: 0.9;
}

/* TMUX Modal Styles */
.tmux-modal .modal-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.tmux-commands-list {
  max-height: 300px;
  overflow-y: auto;
  margin-bottom: 20px;
}

.tmux-command-item {
  display: flex;
  align-items: center;
  padding: 12px;
  margin-bottom: 8px;
  background: #f5f5f5;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.tmux-command-item:hover {
  background: #e8f4fd;
  transform: translateX(5px);
  box-shadow: 3px 3px 0px #333;
}

.cmd-icon {
  font-size: 1.5em;
  margin-right: 12px;
}

.cmd-content {
  flex: 1;
}

.cmd-name {
  font-weight: bold;
  color: #333;
  margin-bottom: 4px;
}

.cmd-preview {
  font-size: 0.85em;
  color: #666;
  font-family: monospace;
  max-height: 300px;
  overflow-y: auto;
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.4;
}

.cmd-category {
  background: #4a90e2;
  color: white;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
}

.quick-message {
  padding: 15px;
  background: #f9f9f9;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.quick-message h4 {
  margin: 0 0 10px 0;
  color: #333;
}

.quick-message textarea {
  width: 100%;
  padding: 10px;
  border: 2px solid #333;
  border-radius: 6px;
  font-family: 'Courier New', monospace;
  resize: vertical;
}

.btn-send-quick {
  margin-top: 10px;
  padding: 10px 20px;
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
}

.btn-send-quick:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}
</style>