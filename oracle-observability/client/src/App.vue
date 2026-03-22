<template>
  <div id="oracle-app">
    <!-- Modal Documentation Technique -->
    <TechDocsModal :isOpen="showTechDocsModal" @close="showTechDocsModal = false" />

    <!-- Visualiseur Markdown -->
    <DocsViewer :isOpen="showDocsViewer" @close="showDocsViewer = false" />

    <!-- Modal Configuration Tmux -->
    <TmuxConfigModal :isVisible="showTmuxConfigModal" @close="showTmuxConfigModal = false" />

    <!-- Modal Purge Sélective des Emails -->
    <div v-if="showPurgeModal" class="modal-overlay" @click.self="showPurgeModal = false">
      <div class="modal-content purge-modal">
        <div class="modal-header">
          <h2>🗑️ Sélection des Équipes à Purger</h2>
          <button @click="showPurgeModal = false" class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <div class="purge-form">
            <div class="purge-options">
              <div class="option-group">
                <label class="checkbox-label">
                  <input type="checkbox" v-model="purgeOptions.moulinsart" />
                  <span class="checkmark"></span>
                  <span class="option-title">🎩 Équipe TMUX Nestor</span>
                </label>
                <div class="option-details">
                  Nestor, Tintin, Dupont1, Dupont2
                </div>
              </div>
              <div class="option-group">
                <label class="checkbox-label">
                  <input type="checkbox" v-model="purgeOptions.equipeTmux" />
                  <span class="checkmark"></span>
                  <span class="option-title">⚓ Équipe TMUX Haddock</span>
                </label>
                <div class="option-details">
                  Haddock, Rastapopoulos, Tournesol1, Tournesol2
                </div>
              </div>
            </div>
            <div class="warning-message">
              ⚠️ <strong>ATTENTION:</strong> Cette action supprimera définitivement tous les emails des équipes sélectionnées.
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="executePurge" class="btn-purge" :disabled="!purgeOptions.moulinsart && !purgeOptions.equipeTmux">
            🗑️ Purger les Équipes Sélectionnées
          </button>
          <button @click="showPurgeModal = false" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
    <!-- Modal pour composer l'email initial -->
    <div v-if="showEmailModal" class="modal-overlay" @click.self="showEmailModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h2>📧 Composer l'Email Initial pour Nestor</h2>
          <button @click="showEmailModal = false" class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <div class="email-form">
            <div class="form-group">
              <label>De:</label>
              <input v-model="emailForm.from" type="email" placeholder="commandant@moulinsart.local" />
            </div>
            <div class="form-group">
              <label>À:</label>
              <input v-model="emailForm.to" type="email" readonly />
            </div>
            <div class="form-group">
              <label>Sujet:</label>
              <input v-model="emailForm.subject" type="text" placeholder="Sujet de la mission" />
            </div>
            <div class="form-group">
              <label>Message:</label>
              <textarea v-model="emailForm.body" rows="15" placeholder="Instructions pour Nestor..."></textarea>
            </div>
            <div class="template-buttons">
              <button @click="loadTemplate('test')" class="btn-template">🧪 Template Test</button>
              <button @click="loadTemplate('ios')" class="btn-template">🍎 Template iOS</button>
              <button @click="loadTemplate('custom')" class="btn-template">✨ Template Custom</button>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="sendInitialEmail" class="btn-send">🚀 Envoyer l'Email</button>
          <button @click="showEmailModal = false" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
    <!-- Header -->
    <header>
      <h1>
        <img src="/src/assets/images/moulinsart.png" alt="Château de Moulinsart" class="castle-logo" />
        La Poste de Moulinsart
        <span class="status" :class="{ connected: isConnected }"></span>
      </h1>
      <div class="header-controls">
        <!-- Ligne 1: Navigation et Zoom -->
        <div class="controls-row primary-row">
          <div class="zoom-controls">
            <button @click="decreaseZoom" class="zoom-btn" title="Réduire">➖</button>
            <span class="zoom-level">{{ Math.round(zoomLevel * 100) }}%</span>
            <button @click="increaseZoom" class="zoom-btn" title="Agrandir">➕</button>
            <button @click="resetZoom" class="zoom-btn" title="Réinitialiser">🔄</button>
          </div>
          <div class="view-buttons">
            <button @click="switchView('workflow')" class="header-btn view-toggle" :class="{ active: currentView === 'workflow' }">
              📮 Console La Poste de Moulinsart
            </button>
            <button @click="switchView('memories')" class="header-btn view-toggle" :class="{ active: currentView === 'memories' }">
              📚 Mémoires
            </button>
            <button @click="switchView('briefing')" class="header-btn view-toggle" :class="{ active: currentView === 'briefing' }">
              🎩 Briefing TMUX
            </button>
          </div>
          <div class="utility-buttons">
            <button @click="showTechDocsModal = true" class="header-btn">🏗️ Architecture</button>
            <button @click="showTmuxConfigModal = true" class="header-btn">⚙️ Tmux Config</button>
            <button @click="showDocsViewer = true" class="header-btn">📋 Docs</button>
          </div>
        </div>

        <!-- Ligne 2: AGENTIC MODE Buttons -->
        <div class="controls-row agentic-row">
          <div class="agentic-buttons">
            <button @click="startOrbiteSilence" class="header-btn agentic-btn tmux-haddock-btn" :class="{ active: orbiteActive }" :disabled="startingOrbite">
              <span class="btn-icon">{{ startingOrbite ? '⏳' : (orbiteActive ? '🔥' : '⚡') }}</span>
              <span class="btn-text">{{ startingOrbite ? 'ACTIVATING...' : (orbiteActive ? 'TMUX HADDOCK ON' : 'TMUX HADDOCK') }}</span>
              <span v-if="orbiteActive" class="status-indicator">●</span>
            </button>
            <button @click="startTriggerNestor" class="header-btn agentic-btn tmux-nestor-btn" :class="{ active: nestorActive }" :disabled="startingNestor">
              <span class="btn-icon">{{ startingNestor ? '⏳' : (nestorActive ? '🔥' : '⚡') }}</span>
              <span class="btn-text">{{ startingNestor ? 'ACTIVATING...' : (nestorActive ? 'TMUX NESTOR ON' : 'TMUX NESTOR') }}</span>
              <span v-if="nestorActive" class="status-indicator">●</span>
            </button>
          </div>
          <div class="service-controls">
            <span class="service-status" :class="{ online: mailServerStatus }">
              📧 Mail: {{ mailServerStatus ? 'ON' : 'OFF' }}
            </span>
            <button @click="restartMailServer" class="btn-service" :disabled="restartingMail" title="Redémarrer le serveur mail">
              {{ restartingMail ? '⏳' : '🔄' }} Mail
            </button>
            <button @click="resetAllEmails" class="btn-reset-emails btn-danger" title="⚠️ DANGER: Vider définitivement toutes les boîtes mail">
              🗑️ Vider Emails
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="main-content">
      <!-- Console La Poste de Moulinsart (Two Panel Layout) -->
      <div v-if="currentView === 'workflow'" class="workflow-view two-panel-layout">
        <!-- Panneau Gauche: Boîtes Mail des Agents -->
        <div class="left-panel" :style="{ width: leftPanelWidth + '%' }">
          <AgentMailboxes />
        </div>

        <!-- Barre de redimensionnement -->
        <div
          class="resize-bar"
          @mousedown="startResize"
          :style="{ left: leftPanelWidth + '%' }"
        >
          <span>⋮</span>
        </div>

        <!-- Panneau Droite: Split Feed + Sprint Dashboard -->
        <div class="right-panel split-right-panel" :style="{ width: (100 - leftPanelWidth) + '%' }">
          <!-- Feed des événements (partie haute) -->
          <div class="events-section" :style="{ flex: topPanelHeight + ' 1 0%' }">
            <DatabaseViewer :liveEvents="events" />
          </div>

          <!-- Séparateur horizontal -->
          <div class="horizontal-separator" @mousedown="startVerticalResize">
          </div>

          <!-- Sprint Dashboard (partie basse) -->
          <div class="sprint-section" :style="{ flex: (100 - topPanelHeight) + ' 1 0%' }">
            <SprintDashboard />
          </div>
        </div>
      </div>

      <!-- Page Mémoires & Résumés (Vue Archiviste) -->
      <div v-if="currentView === 'memories'" class="memories-view">
        <MemoryPage />
      </div>

      <div v-if="currentView === 'briefing'" class="briefing-view">
        <BriefingConsole />
      </div>
    </main>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, reactive, nextTick } from 'vue'
import AgentMailboxes from './components/AgentMailboxes.vue'
import DatabaseViewer from './components/DatabaseViewer.vue'
// import ProjectCreator from './components/ProjectCreator.vue'
import TechDocsModal from './components/TechDocsModal.vue'
import DocsViewer from './components/DocsViewer.vue'
import SprintDashboard from './components/SprintDashboard.vue'
import EmailSplitView from './components/EmailSplitView.vue'
import TmuxConfigModal from './components/TmuxConfigModal.vue'
import CommandantMailbox from './components/CommandantMailbox.vue'
import MemoryPage from './components/MemoryPage.vue'
import BriefingConsole from './components/BriefingConsole.vue'

export default {
  name: 'MoulinsartOracle',
  components: {
    AgentMailboxes,
    DatabaseViewer,
    // ProjectCreator,
    TechDocsModal,
    DocsViewer,
    SprintDashboard,
    EmailSplitView,
    TmuxConfigModal,
    CommandantMailbox,
    MemoryPage
  },
  setup() {
    // État existant
    const events = ref([])
    const projects = ref(new Set())
    const isConnected = ref(false)
    let ws = null
    let reconnectTimeout = null

    // Nouveau état pour les deux panneaux
    const currentView = ref('workflow') // Start with workflow view by default ('tasks', 'workflow', 'emails', 'briefing')
    const leftPanelWidth = ref(40) // Changed from 50 to 40 for better balance at 100% zoom
    const selectedProject = ref('swift')
    const isResizing = ref(false)
    const isResizingVertical = ref(false)
    const topPanelHeight = ref(60) // Percentage for events section
    const showEmailModal = ref(false)
    const showTechDocsModal = ref(false)
    const showDocsViewer = ref(false)
    const showTmuxConfigModal = ref(false)

    // État pour la purge sélective des emails
    const showPurgeModal = ref(false)
    const purgeOptions = ref({
      moulinsart: false,
      equipeTmux: false
    })

    // Orbite du Silence controls
    const orbiteActive = ref(false)
    const startingOrbite = ref(false)

    // Trigger Nestor controls
    const nestorActive = ref(false)
    const startingNestor = ref(false)

    // Zoom controls
    const zoomLevel = ref(1.0) // Start at 100%
    const minZoom = 0.5 // 50%
    const maxZoom = 1.5 // 150%
    const zoomStep = 0.1 // 10% steps
    const mailServerStatus = ref(false)
    const restartingMail = ref(false)
    const emailForm = reactive({
      from: 'commandant@moulinsart.local',
      to: 'nestor@moulinsart.local',
      subject: '[MISSION] Test du système La Poste',
      body: ''
    })

    // Configuration des agents
    const agents = reactive([
      {
        name: 'nestor',
        displayName: 'Nestor',
        icon: '🎩',
        email: 'nestor@moulinsart.local',
        role: 'Chef d\'orchestre - Coordonne les projets',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/mailbox/nestor

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🎩 NESTOR - Chef d'Orchestre

## Ton Identité
Tu es **NESTOR**, le chef d'orchestre de la ferme de création iOS.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/mailbox/nestor\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
Commandant → NESTOR (toi) → TINTIN → DUPONT1 & DUPONT2

## Règles
1. Communiquer UNIQUEMENT par email
2. Ne pas créer de boucles (vérifier RE: RE: RE:)
3. Toujours CC le commandant sur les rapports finaux`
      },
      {
        name: 'tintin',
        displayName: 'Tintin',
        icon: '🚀',
        email: 'tintin@moulinsart.local',
        role: 'QA Lead - Tests et validation',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/mailbox/tintin

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🚀 TINTIN - QA Lead

## Ton Identité
Tu es **TINTIN**, responsable QA de la ferme iOS.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/mailbox/tintin\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
NESTOR → TINTIN (toi) → DUPONT1 & DUPONT2

## Règles
1. Communiquer UNIQUEMENT par email
2. Tester TOUT avant validation
3. Répondre "TESTÉ OK" ou "BUGS TROUVÉS" à Nestor`
      },
      {
        name: 'dupont1',
        displayName: 'Dupont 1',
        icon: '🎨',
        email: 'dupont1@moulinsart.local',
        role: 'Développeur Swift/iOS',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/mailbox/dupont1

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🎨 DUPONT1 - Développeur Swift

## Ton Identité
Tu es **DUPONT1**, développeur Swift spécialisé iOS.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/mailbox/dupont1\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
NESTOR → TINTIN → DUPONT1 (toi)

## Règles
1. Communiquer UNIQUEMENT par email
2. Écrire du code Swift propre
3. Répondre "DÉVELOPPÉ - [description]" à Nestor/Tintin`
      },
      {
        name: 'dupont2',
        displayName: 'Dupont 2',
        icon: '🔍',
        email: 'dupont2@moulinsart.local',
        role: 'Recherche & Documentation',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/mailbox/dupont2

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🔍 DUPONT2 - Recherche & Documentation

## Ton Identité
Tu es **DUPONT2**, spécialiste recherche et documentation.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/mailbox/dupont2\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
NESTOR → TINTIN → DUPONT2 (toi)

## Règles
1. Communiquer UNIQUEMENT par email
2. Fournir des sources fiables
3. Répondre "DOCUMENTÉ - [résumé]" à Nestor/Tintin`
      },
      // AGENTS ÉQUIPE TMUX
      {
        name: 'haddock',
        displayName: 'Haddock',
        icon: '⚓',
        email: 'haddock@moulinsart.local',
        role: 'Chef d\'orchestre Équipe TMUX',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/api/mailbox/haddock@moulinsart.local

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# ⚓ HADDOCK - Chef d'Orchestre Équipe TMUX

## Ton Identité
Tu es **HADDOCK**, le chef d'orchestre de l'équipe TMUX.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/api/mailbox/haddock@moulinsart.local\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
Minh-Tam → HADDOCK (toi) → RASTAPOPOULOS → TOURNESOL1 & TOURNESOL2

## Règles
1. Communiquer UNIQUEMENT par email
2. Éviter les boucles de communication
3. Diriger l'équipe TMUX avec efficacité`
      },
      {
        name: 'rastapopoulos',
        displayName: 'Rastapopoulos',
        icon: '🧔',
        email: 'rastapopoulos@moulinsart.local',
        role: 'QA Lead Équipe TMUX',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/api/mailbox/rastapopoulos@moulinsart.local

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🧔 RASTAPOPOULOS - QA Lead Équipe TMUX

## Ton Identité
Tu es **RASTAPOPOULOS**, responsable QA de l'équipe TMUX.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/api/mailbox/rastapopoulos@moulinsart.local\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
HADDOCK → RASTAPOPOULOS (toi) → TOURNESOL1 & TOURNESOL2

## Règles
1. Communiquer UNIQUEMENT par email
2. Tester et valider tous les développements
3. Reporter les résultats à Haddock`
      },
      {
        name: 'tournesol1',
        displayName: 'Tournesol 1',
        icon: '🧪',
        email: 'tournesol1@moulinsart.local',
        role: 'Développeur Principal Équipe TMUX',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/api/mailbox/tournesol1@moulinsart.local

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🧪 TOURNESOL1 - Développeur Principal Équipe TMUX

## Ton Identité
Tu es **TOURNESOL1**, développeur principal de l'équipe TMUX.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/api/mailbox/tournesol1@moulinsart.local\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
HADDOCK → RASTAPOPOULOS → TOURNESOL1 (toi)

## Règles
1. Communiquer UNIQUEMENT par email
2. Développer des solutions innovantes
3. Collaborer avec Tournesol2 sur la recherche`
      },
      {
        name: 'tournesol2',
        displayName: 'Tournesol 2',
        icon: '🔬',
        email: 'tournesol2@moulinsart.local',
        role: 'Recherche & Documentation Équipe TMUX',
        sessionActive: false,
        terminalOutput: '',
        commandInput: '',
        pollInterval: null,
        paused: false,
        tmuxNotification: `echo '🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!

Consulte ta boîte mail:
curl http://localhost:1080/api/mailbox/tournesol2@moulinsart.local

Ton identité et instructions sont dans CLAUDE.md
━━━━━━━━━━━━━━━━━━━━'`,
        claudeMdContent: `# 🔬 TOURNESOL2 - Recherche & Documentation Équipe TMUX

## Ton Identité
Tu es **TOURNESOL2**, spécialiste recherche et documentation Équipe TMUX.

## Communication
- **Consulter tes emails**: \`curl http://localhost:1080/api/mailbox/tournesol2@moulinsart.local\`
- **Envoyer un email**: \`./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"\`

## Hiérarchie
HADDOCK → RASTAPOPOULOS → TOURNESOL2 (toi)

## Règles
1. Communiquer UNIQUEMENT par email
2. Documenter tous les processus de l'équipe TMUX
3. Fournir des analyses approfondies`
      }
    ])

    // Méthodes existantes
    const getEventIcon = (type) => {
      const icons = {
        'prompt': '💬',
        'stop': '🛑',
        'email': '📧',
        'hook': '🪝',
        'test': '🧪'
      }
      return icons[type] || '📝'
    }

    const formatTime = (timestamp) => {
      const date = new Date(timestamp)
      return date.toLocaleTimeString('fr-FR', { 
        hour: '2-digit', 
        minute: '2-digit',
        second: '2-digit'
      })
    }

    const truncateText = (text, maxLength) => {
      if (!text) return ''
      if (text.length <= maxLength) return text
      return text.substring(0, maxLength) + '...'
    }

    // WebSocket connection
    const connectWebSocket = () => {
      console.log('🔴 Attempting to connect WebSocket...')
      ws = new WebSocket('ws://localhost:3001/ws')

      ws.onopen = () => {
        console.log('🔴 WebSocket connected successfully!')
        isConnected.value = true
      }
      
      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data)
          console.log('🔴 WebSocket message received:', message)

          if (message.type === 'event') {
            console.log('🔴 Adding event to events array:', message.data)
            events.value.unshift({
              ...message.data,
              id: Date.now() + Math.random(),
              timestamp: message.timestamp || new Date().toISOString()
            })
            console.log('🔴 Events array length:', events.value.length)

            if (events.value.length > 50) {
              events.value.pop()
            }

            if (message.data.project) {
              projects.value.add(message.data.project)
            }
          }
        } catch (err) {
          console.error('Failed to parse WebSocket message:', err)
        }
      }
      
      ws.onerror = (error) => {
        console.error('WebSocket error:', error)
      }
      
      ws.onclose = () => {
        console.log('WebSocket disconnected')
        isConnected.value = false
        
        if (!reconnectTimeout) {
          reconnectTimeout = setTimeout(() => {
            reconnectTimeout = null
            connectWebSocket()
          }, 3000)
        }
      }
    }

    // Nouvelles méthodes pour les panneaux
    const startResize = (e) => {
      isResizing.value = true
      document.addEventListener('mousemove', handleResize)
      document.addEventListener('mouseup', stopResize)
    }

    const handleResize = (e) => {
      if (!isResizing.value) return
      const newWidth = (e.clientX / window.innerWidth) * 100
      if (newWidth > 20 && newWidth < 80) {
        leftPanelWidth.value = newWidth
      }
    }

    const stopResize = () => {
      isResizing.value = false
      document.removeEventListener('mousemove', handleResize)
      document.removeEventListener('mouseup', stopResize)
    }

    // Gestion du redimensionnement vertical
    const startVerticalResize = (e) => {
      isResizingVertical.value = true
      document.addEventListener('mousemove', handleVerticalResize)
      document.addEventListener('mouseup', stopVerticalResize)
    }

    const handleVerticalResize = (e) => {
      if (!isResizingVertical.value) return
      const rightPanel = document.querySelector('.split-right-panel')
      if (rightPanel) {
        const rect = rightPanel.getBoundingClientRect()
        const newHeight = ((e.clientY - rect.top) / rect.height) * 100
        if (newHeight > 20 && newHeight < 80) {
          topPanelHeight.value = newHeight
        }
      }
    }

    const stopVerticalResize = () => {
      isResizingVertical.value = false
      document.removeEventListener('mousemove', handleVerticalResize)
      document.removeEventListener('mouseup', stopVerticalResize)
    }

    // Gestion des agents et tmux
    const launchTmuxSession = async (agent) => {
      // Pour l'instant on marque juste comme actif et on commence le polling
      agent.sessionActive = true
      pollTmuxOutput(agent)
      console.log(`📺 Démarrage du monitoring tmux pour ${agent.name}`)
    }

    const startClaude = async (agent, resume = false) => {
      // Toujours utiliser la même commande simple
      const command = 'claude --dangerously-skip-permissions'
      
      try {
        const response = await fetch('http://localhost:3001/api/tmux-send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            session: agent.name,
            command: command
          })
        })
        
        if (response.ok) {
          console.log(`🚀 Claude ${resume ? 'resumed' : 'started'} pour ${agent.name}`)
        }
      } catch (err) {
        console.error('Erreur start Claude:', err)
      }
    }
    
    const stopClaude = async (agent) => {
      // Envoyer Ctrl+C pour arrêter Claude
      try {
        const response = await fetch('http://localhost:3001/api/tmux-send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            session: agent.name,
            command: 'C-c'  // Ctrl+C en tmux
          })
        })
        
        if (response.ok) {
          console.log(`⏹ Claude arrêté pour ${agent.name}`)
        }
      } catch (err) {
        console.error('Erreur stop Claude:', err)
      }
    }
    
    const togglePause = (agent) => {
      agent.paused = !agent.paused
      console.log(`${agent.paused ? '⏸' : '▶'} ${agent.name} ${agent.paused ? 'en pause' : 'actif'}`)
    }
    
    const scrollToBottom = (agent) => {
      const terminal = document.querySelector(`#terminal-${agent.name} pre`)
      if (terminal) {
        terminal.scrollTop = terminal.scrollHeight
      }
    }

    const clearTerminal = async (agent) => {
      try {
        const response = await fetch('http://localhost:3001/api/tmux-send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            session: agent.name,
            command: 'clear'
          })
        })
        
        if (response.ok) {
          console.log(`🗑 Terminal nettoyé pour ${agent.name}`)
        }
      } catch (err) {
        console.error('Erreur clear:', err)
      }
    }

    const resetSession = (agent) => {
      // Effacer UNIQUEMENT le contenu affiché, sans envoyer de commande
      agent.terminalOutput = ''
      console.log(`↻ Affichage effacé pour ${agent.name}`)
    }

    const sendCommandToTmux = async (agent) => {
      if (!agent.commandInput) return
      
      try {
        const response = await fetch('http://localhost:3001/api/tmux-send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            session: agent.name,
            command: agent.commandInput 
          })
        })
        
        if (response.ok) {
          agent.commandInput = ''
          // Le output sera mis à jour par le polling
        }
      } catch (err) {
        console.error('Failed to send command:', err)
      }
    }

    const pollTmuxOutput = (agent) => {
      // Polling direct via commande bash
      if (agent.pollInterval) clearInterval(agent.pollInterval)
      
      agent.pollInterval = setInterval(async () => {
        if (!agent.sessionActive) return
        
        try {
          // Sauvegarder la position de scroll AVANT la mise à jour
          const terminal = document.querySelector(`#terminal-${agent.name} pre`)
          let savedScrollTop = 0
          if (terminal) {
            savedScrollTop = terminal.scrollTop
          }
          
          // Capture les 30 dernières lignes de la session tmux
          const response = await fetch('http://localhost:3001/api/tmux-capture', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ session: agent.name })
          })
          
          if (response.ok) {
            const data = await response.json()
            agent.terminalOutput = data.output || 'Session vide...'
            
            // Restaurer la position de scroll après la mise à jour
            nextTick(() => {
              const term = document.querySelector(`#terminal-${agent.name} pre`)
              if (term && savedScrollTop > 0) {
                term.scrollTop = savedScrollTop
              }
            })
          }
        } catch (err) {
          agent.terminalOutput = `Session ${agent.name} - En attente de connexion...`
        }
      }, 1500)  // Polling toutes les 1.5 secondes
    }

    const switchView = (view) => {
      currentView.value = view
      console.log('View switched to:', view)
      // Sauvegarder la vue préférée dans localStorage
      localStorage.setItem('preferredView', view)
    }

    const updateProjectConfig = () => {
      // Mettre à jour les configurations selon le projet
      console.log('Project changed to:', selectedProject.value)
    }

    const saveAgentConfig = async (agent) => {
      // Sauvegarder le CLAUDE.md directement dans le fichier via l'API
      try {
        const response = await fetch('http://localhost:3001/api/save-claude-md', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            agent: agent.name,
            content: agent.claudeMdContent
          })
        })
        
        if (response.ok) {
          console.log(`💾 CLAUDE.md sauvegardé pour ${agent.name}`)
        }
      } catch (err) {
        console.error('Erreur sauvegarde CLAUDE.md:', err)
      }
    }
    
    // Charger les CLAUDE.md au démarrage
    const loadAgentConfigs = async () => {
      for (const agent of agents) {
        try {
          const response = await fetch(`http://localhost:3001/api/get-claude-md/${agent.name}`)
          if (response.ok) {
            const data = await response.json()
            if (data.content) {
              agent.claudeMdContent = data.content
              console.log(`📖 CLAUDE.md chargé pour ${agent.name}`)
            }
          }
        } catch (err) {
          console.error(`Erreur chargement CLAUDE.md pour ${agent.name}:`, err)
        }
      }
    }

    // Ouvrir la modal de purge sélective (remplace l'ancien resetAllEmails)
    const resetAllEmails = () => {
      // Réinitialiser les options
      purgeOptions.value.moulinsart = false
      purgeOptions.value.equipeTmux = false
      showPurgeModal.value = true
    }

    // Purger les emails selon les options sélectionnées
    const executePurge = async () => {
      if (!purgeOptions.value.moulinsart && !purgeOptions.value.equipeTmux) {
        alert('Veuillez sélectionner au moins une équipe à purger')
        return
      }

      try {
        let purgedCount = 0
        const emailAddresses = []

        // Collecter les adresses email à purger
        const moulinsartAgents = ['nestor@moulinsart.local', 'tintin@moulinsart.local', 'dupont1@moulinsart.local', 'dupont2@moulinsart.local']
        const equipeTmuxAgents = ['haddock@moulinsart.local', 'rastapopoulos@moulinsart.local', 'tournesol1@moulinsart.local', 'tournesol2@moulinsart.local']

        if (purgeOptions.value.moulinsart) {
          emailAddresses.push(...moulinsartAgents)
        }
        if (purgeOptions.value.equipeTmux) {
          emailAddresses.push(...equipeTmuxAgents)
        }

        console.log(`🗑️ Début purge de ${emailAddresses.length} boîtes email:`, emailAddresses)

        // 1. Purger via l'API Oracle (base de données)
        try {
          const oracleResponse = await fetch('http://localhost:3001/api/purge-emails', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ emails: emailAddresses })
          })

          if (oracleResponse.ok) {
            const oracleResult = await oracleResponse.json()
            console.log('📊 Oracle DB purgée:', oracleResult)
          }
        } catch (oracleErr) {
          console.warn('⚠️ Erreur purge Oracle DB:', oracleErr)
        }

        // 2. Purger via l'API Mail Server (Mailhog)
        for (const email of emailAddresses) {
          try {
            const mailResponse = await fetch(`http://localhost:1080/api/mailbox/${email}/clear`, {
              method: 'DELETE'
            })
            if (mailResponse.ok) {
              purgedCount++
              console.log(`✅ Boîte ${email} purgée`)
            }
          } catch (mailErr) {
            console.warn(`⚠️ Erreur purge ${email}:`, mailErr)
          }
        }

        // 3. Purger les emails du Commandant si toutes les équipes sont purgées
        if (purgeOptions.value.moulinsart && purgeOptions.value.equipeTmux) {
          try {
            const commandantResponse = await fetch('http://localhost:3001/api/emails/purge-commandant', {
              method: 'POST'
            })
            if (commandantResponse.ok) {
              console.log('✅ Emails Commandant purgés')
            }
          } catch (cmdErr) {
            console.warn('⚠️ Erreur purge emails Commandant:', cmdErr)
          }
        }

        console.log(`📧 ${purgedCount} boîtes mail purgées via Mail Server`)
        alert(`✅ Purge terminée: ${purgedCount} boîtes email purgées`)
        showPurgeModal.value = false

        // Forcer le refresh de l'interface après purge
        window.location.reload()

      } catch (err) {
        console.error('Erreur lors de la purge:', err)
        alert('Erreur lors de la purge des emails: ' + err.message)
      }
    }

    const loadTemplate = (type) => {
      switch(type) {
        case 'test':
          emailForm.subject = '[TEST SYSTÈME] Démarrage Ferme iOS'
          emailForm.body = `Bonjour Nestor,

CECI EST UN TEST DE DÉMARRAGE DU SYSTÈME.

Tu es NESTOR, le chef d'orchestre de notre ferme de création d'applications iOS.

MISSION DE TEST:
1. Lis cet email attentivement
2. Transmets l'information à tes équipes (Tintin, Dupont1, Dupont2)
3. Chaque agent doit créer un fichier texte contenant:
   - Son nom et rôle
   - Sa compréhension qu'il fait partie d'une ferme de création iOS
   - Sa position dans la hiérarchie
   
Nom du fichier à créer: /tmp/test-[nom-agent].txt

RAPPEL DE LA HIÉRARCHIE:
- Tu es le CHEF, tu reportes directement au commandant
- TINTIN est ton lieutenant (QA Lead)
- DUPONT1 et DUPONT2 sont sous les ordres de Tintin

Merci de coordonner ce test avec ton équipe.

Cordialement,
Le Commandant`
          break
        case 'ios':
          emailForm.subject = '[PROJET] Nouvelle Application iOS'
          emailForm.body = `Bonjour Nestor,

Tu es NESTOR, le chef d'orchestre de ce projet.

NOUVEAU PROJET: Application iOS "TestApp"

SPÉCIFICATIONS:
- Interface SwiftUI moderne
- Page d'accueil avec animations
- Support iOS 15+
- Tests unitaires complets

COORDONNE AVEC:
- TINTIN pour les tests et validation
- DUPONT1 pour le développement Swift
- DUPONT2 pour la recherche et documentation

RAPPELS:
- Communiquez UNIQUEMENT par email
- Rapporte-moi l'avancement régulièrement
- Xcode doit compiler sans erreur

Bonne chance!
Le Commandant`
          break
        case 'custom':
          emailForm.subject = '[MISSION] '
          emailForm.body = `Bonjour Nestor,

Tu es NESTOR, le chef d'orchestre.

[VOTRE MISSION ICI]

Cordialement,
Le Commandant`
          break
      }
    }

    const sendInitialEmail = async () => {
      try {
        // Envoyer via Python script ou API
        const response = await fetch('http://localhost:1080/api/send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(emailForm)
        })
        
        if (response.ok) {
          alert('✅ Email envoyé à Nestor!')
          showEmailModal.value = false
          console.log('📧 Workflow initié')
        } else {
          alert('❌ Erreur lors de l\'envoi')
        }
      } catch (err) {
        console.error('Erreur:', err)
        alert('❌ Erreur de connexion au serveur mail')
      }
    }

    const initWorkflow = async () => {
      showEmailModal.value = true
      // Charger le template par défaut
      loadTemplate('test')
      // Envoyer l'email initial à Nestor pour démarrer le workflow
      const emailContent = {
        from: 'vous@moulinsart.local',
        to: 'nestor@moulinsart.local',
        subject: `Nouveau projet ${selectedProject.value}`,
        body: getInitialEmailContent()
      }
      
      try {
        const response = await fetch('http://localhost:3001/api/send-email', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(emailContent)
        })
        
        if (response.ok) {
          console.log('Workflow initiated!')
        }
      } catch (err) {
        console.error('Failed to initiate workflow:', err)
      }
    }

    const getInitialEmailContent = () => {
      if (selectedProject.value === 'swift') {
        return `Bonjour Nestor,

Tu es NESTOR, le chef d'orchestre de ce projet.

J'ai besoin d'une application iOS simple:
- Interface SwiftUI
- Une page avec un design moderne
- Nom: "TestApp"

Coordonne avec Tintin pour les tests et Dupont1 pour le développement.

Merci!`
      }
      // Autres projets...
      return 'Projet de test'
    }

    // Fonction pour vérifier le status du serveur mail
    const checkMailServerStatus = async () => {
      try {
        const response = await fetch('http://localhost:1080/api/mailboxes')
        mailServerStatus.value = response.ok
      } catch (err) {
        mailServerStatus.value = false
      }
    }

    // Fonction pour redémarrer le serveur mail
    const restartMailServer = async () => {
      restartingMail.value = true
      try {
        // Envoyer une commande pour redémarrer le serveur mail
        const response = await fetch('http://localhost:3001/api/restart-mail', {
          method: 'POST'
        })

        if (response.ok) {
          console.log('📧 Serveur mail en cours de redémarrage...')
          // Attendre un peu et vérifier le status
          setTimeout(() => {
            checkMailServerStatus()
            restartingMail.value = false
          }, 3000)
        }
      } catch (err) {
        console.error('Erreur redémarrage serveur mail:', err)
        restartingMail.value = false
      }
    }

    // Fonction pour démarrer l'Orbite du Silence
    const startOrbiteSilence = async () => {
      if (orbiteActive.value) {
        // Si déjà active, arrêter l'orbite
        try {
          const response = await fetch('http://localhost:3001/api/stop-orbite-silence', {
            method: 'POST'
          })

          if (response.ok) {
            orbiteActive.value = false
            console.log('🌌 Orbite du Silence arrêtée')
          }
        } catch (err) {
          console.error('Erreur arrêt Orbite du Silence:', err)
        }
        return
      }

      startingOrbite.value = true

      try {
        // Démarrer l'orbite du silence
        const response = await fetch('http://localhost:3001/api/start-orbite-silence', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        })

        if (response.ok) {
          orbiteActive.value = true
          console.log('🌌 Orbite du Silence activée - Surveillance autonome démarrée')
        } else {
          console.error('Erreur démarrage Orbite du Silence')
        }
      } catch (err) {
        console.error('Erreur démarrage Orbite du Silence:', err)
      } finally {
        startingOrbite.value = false
      }
    }

    // Fonction pour démarrer le Trigger Nestor
    const startTriggerNestor = async () => {
      if (nestorActive.value) {
        // Si déjà active, arrêter le trigger
        try {
          const response = await fetch('http://localhost:3001/api/stop-trigger-moulinsart', {
            method: 'POST'
          })

          if (response.ok) {
            nestorActive.value = false
            console.log('🎩 Trigger TMUX Nestor arrêté')
          }
        } catch (err) {
          console.error('Erreur arrêt Trigger TMUX Nestor:', err)
        }
        return
      }

      startingNestor.value = true

      try {
        // Démarrer le trigger nestor
        const response = await fetch('http://localhost:3001/api/start-trigger-moulinsart', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        })

        if (response.ok) {
          nestorActive.value = true
          console.log('🎩 Trigger TMUX Nestor activé - Surveillance équipe Nestor')
        } else {
          console.error('Erreur démarrage Trigger TMUX Nestor')
        }
      } catch (err) {
        console.error('Erreur démarrage Trigger TMUX Nestor:', err)
      } finally {
        startingNestor.value = false
      }
    }

    // Helper pour obtenir le pane TMUX d'un agent
    const getAgentPane = (agentName) => {
      const paneMap = {
        'haddock': '0',
        'rastapopoulos': '1',
        'tournesol1': '2',
        'tournesol2': '3'
      }
      return paneMap[agentName] || '0'
    }

    // Zoom control functions
    const applyZoom = () => {
      // Update CSS variable for global scaling
      document.documentElement.style.setProperty('--scale-factor', zoomLevel.value.toString())
      // Also update HTML font size for better compatibility
      document.documentElement.style.fontSize = `${16 * zoomLevel.value}px`
      // Save zoom preference
      localStorage.setItem('oracleZoomLevel', zoomLevel.value.toString())
    }

    const increaseZoom = () => {
      if (zoomLevel.value < maxZoom) {
        zoomLevel.value = Math.min(zoomLevel.value + zoomStep, maxZoom)
        applyZoom()
      }
    }

    const decreaseZoom = () => {
      if (zoomLevel.value > minZoom) {
        zoomLevel.value = Math.max(zoomLevel.value - zoomStep, minZoom)
        applyZoom()
      }
    }

    const resetZoom = () => {
      zoomLevel.value = 1.0
      applyZoom()
    }

    onMounted(async () => {
      connectWebSocket()
      
      // Restaurer la vue préférée
      const savedView = localStorage.getItem('preferredView')
      if (savedView && ['tasks', 'workflow', 'emails', 'briefing'].includes(savedView)) {
        currentView.value = savedView
      }
      
      // Restore saved zoom level
      const savedZoom = localStorage.getItem('oracleZoomLevel')
      if (savedZoom) {
        zoomLevel.value = parseFloat(savedZoom)
        applyZoom()
      }
      
      // Charger les CLAUDE.md depuis les fichiers
      await loadAgentConfigs()
      
      // Vérifier le status du serveur mail
      checkMailServerStatus()
      
      // Vérifier périodiquement le status
      setInterval(checkMailServerStatus, 10000)
    })

    onUnmounted(() => {
      if (reconnectTimeout) {
        clearTimeout(reconnectTimeout)
      }
      if (ws) {
        ws.close()
      }
    })

    return {
      events,
      projects,
      isConnected,
      currentView,
      getEventIcon,
      formatTime,
      truncateText,
      leftPanelWidth,
      selectedProject,
      agents,
      startResize,
      topPanelHeight,
      startVerticalResize,
      launchTmuxSession,
      sendCommandToTmux,
      startClaude,
      stopClaude,
      clearTerminal,
      resetSession,
      togglePause,
      scrollToBottom,
      switchView,
      updateProjectConfig,
      saveAgentConfig,
      initWorkflow,
      resetAllEmails,
      showEmailModal,
      emailForm,
      loadTemplate,
      sendInitialEmail,
      mailServerStatus,
      restartingMail,
      restartMailServer,
      showTechDocsModal,
      showDocsViewer,
      showTmuxConfigModal,
      startOrbiteSilence,
      orbiteActive,
      startingOrbite,
      startTriggerNestor,
      nestorActive,
      startingNestor,
      zoomLevel,
      increaseZoom,
      decreaseZoom,
      resetZoom,
      showPurgeModal,
      purgeOptions,
      executePurge
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Comic Sans MS', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #ffefd5 0%, #ffe4b5 100%);
  color: #333;
  min-height: 100vh;
  overflow: hidden;
}

#oracle-app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header style BD Tintin */
header {
  background: linear-gradient(135deg, #ff6b6b 0%, #ffd93d 100%);
  padding: 15px 30px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
  border-bottom: 3px solid #333;
  min-height: 120px;
  gap: 20px;
}

h1 {
  font-size: 1.8em;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 10px;
  color: #333;
  text-shadow: 2px 2px 0px #fff;
  font-family: 'Comic Sans MS', cursive;
}

.castle-logo {
  height: 40px;
  width: auto;
  margin-right: 10px;
  vertical-align: middle;
  filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
  position: fixed;
  top: 20px;
  left: 20px;
  z-index: 1000;
}

.status {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #ff4444;
}

.status.connected {
  background: #44ff44;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.header-controls {
  display: flex;
  flex-direction: column;
  gap: 10px;
  flex: 1;
}

.controls-row {
  display: flex;
  align-items: center;
  gap: 15px;
  justify-content: space-between;
  flex-wrap: wrap;
}

.primary-row {
  justify-content: flex-end;
}

.agentic-row {
  justify-content: center;
  padding: 5px 0;
  border-top: 2px solid rgba(255, 255, 255, 0.3);
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}

.view-buttons,
.utility-buttons,
.agentic-buttons,
.service-controls {
  display: flex;
  gap: 10px;
  align-items: center;
}

.agentic-buttons {
  justify-content: center;
  gap: 20px;
}

.service-status {
  padding: 5px 12px;
  background: #fff;
  border: 2px solid #333;
  border-radius: 20px;
  font-size: 0.9em;
  color: #333;
  font-weight: bold;
}

.header-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 10px 22px;
  border-radius: 20px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.95em;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  white-space: nowrap;
  min-width: fit-content;
  margin: 0 2px;
}

.header-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.3);
}

/* Zoom Controls */
.zoom-controls {
  display: flex;
  align-items: center;
  gap: 8px;
  background: white;
  border: 2px solid #333;
  border-radius: 25px;
  padding: 4px 10px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.zoom-btn {
  background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
  color: white;
  border: none;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 1em;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.zoom-btn:hover {
  transform: scale(1.1);
  box-shadow: 0 2px 5px rgba(0,0,0,0.3);
}

.zoom-btn:active {
  transform: scale(0.95);
}

.zoom-level {
  font-weight: bold;
  color: #333;
  min-width: 45px;
  text-align: center;
  font-size: 0.9em;
}

.view-toggle {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  font-weight: bold;
  transition: all 0.3s ease;
}

.view-toggle.active {
  background: linear-gradient(135deg, #ff6b6b 0%, #4ecdc4 100%) !important;
  animation: gradient-shift 3s ease-in-out infinite;
  box-shadow: 0 0 10px rgba(255, 107, 107, 0.5);
}

@keyframes gradient-shift {
  0%, 100% {
    background: linear-gradient(135deg, #ff6b6b 0%, #4ecdc4 100%);
  }
  50% {
    background: linear-gradient(135deg, #4ecdc4 0%, #ff6b6b 100%);
  }
}

/* Bouton AGENTIC MODE - Style Dragon Ball */
.agentic-btn {
  background: linear-gradient(135deg, #808080 0%, #696969 50%, #555555 100%) !important;
  font-weight: 800 !important;
  font-size: 1.05em !important;
  padding: 10px 25px !important;
  transition: all 0.3s ease;
  box-shadow:
    0 0 4px rgba(128, 128, 128, 0.3),
    0 4px 8px rgba(0, 0, 0, 0.3),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  text-transform: uppercase;
  letter-spacing: 1.5px;
  border: 2px solid #808080 !important;
  position: relative;
  overflow: hidden;
  margin: 0 5px !important;
  display: flex !important;
  align-items: center !important;
  gap: 8px !important;
  color: #CCCCCC !important;
}

.agentic-btn .btn-icon {
  font-size: 1.2em;
  filter: drop-shadow(0 0 3px rgba(255, 255, 255, 0.8));
}

.agentic-btn .btn-text {
  flex: 1;
  white-space: nowrap;
}

.agentic-btn .status-indicator {
  font-size: 0.8em;
  color: #00FF00;
  filter: drop-shadow(0 0 4px #00FF00);
  animation: blink 1s ease-in-out infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0.3; }
}

/* Styles spécifiques pour les deux équipes */
.tmux-btn {
  border: 2px solid #4A90E2 !important;
}

.tmux-btn.active {
  background: linear-gradient(135deg, #00FFFF 0%, #0080FF 50%, #4A90E2 100%) !important;
  border: 2px solid #00FFFF !important;
}

.moulinsart-btn {
  border: 2px solid #FF6B6B !important;
}

.moulinsart-btn.active {
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 50%, #FF6347 100%) !important;
  border: 2px solid #FF6B6B !important;
}

.agentic-btn::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: linear-gradient(45deg, transparent, rgba(255, 255, 255, 0.3), transparent);
  transform: rotate(45deg);
  animation: shine-sweep 3s ease-in-out infinite;
}

.agentic-btn:hover:not(:disabled) {
  transform: translateY(-3px) scale(1.05);
  box-shadow:
    0 0 20px rgba(255, 215, 0, 0.8),
    0 6px 15px rgba(0, 0, 0, 0.4),
    inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.agentic-btn.active {
  background: linear-gradient(135deg, #00FFFF 0%, #0080FF 50%, #8A2BE2 100%) !important;
  border: 2px solid #00FFFF !important;
  animation: dragonball-aura 1.5s ease-in-out infinite, power-pulse 0.8s ease-in-out infinite;
  box-shadow:
    0 0 30px rgba(0, 255, 255, 1),
    0 0 60px rgba(0, 128, 255, 0.8),
    0 0 90px rgba(138, 43, 226, 0.6),
    0 8px 16px rgba(0, 0, 0, 0.3);
  color: #FFFFFF !important;
  text-shadow: 0 0 10px rgba(255, 255, 255, 0.8);
}

.agentic-btn.active::before {
  animation: aura-sweep 1s linear infinite;
}

.agentic-btn.active::after {
  content: '';
  position: absolute;
  top: -10px;
  left: -10px;
  right: -10px;
  bottom: -10px;
  background: radial-gradient(circle, rgba(0, 255, 255, 0.3) 0%, transparent 70%);
  border-radius: 50px;
  animation: halo-expand 2s ease-in-out infinite;
  z-index: -1;
}

.agentic-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none !important;
  animation: none !important;
}

/* Animations Dragon Ball */
@keyframes dragonball-aura {
  0%, 100% {
    box-shadow:
      0 0 30px rgba(0, 255, 255, 1),
      0 0 60px rgba(0, 128, 255, 0.8),
      0 0 90px rgba(138, 43, 226, 0.6);
  }
  50% {
    box-shadow:
      0 0 50px rgba(0, 255, 255, 1),
      0 0 100px rgba(0, 128, 255, 1),
      0 0 150px rgba(138, 43, 226, 0.8);
  }
}

@keyframes power-pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.02);
  }
}

@keyframes halo-expand {
  0%, 100% {
    transform: scale(1);
    opacity: 0.3;
  }
  50% {
    transform: scale(1.2);
    opacity: 0.6;
  }
}

@keyframes shine-sweep {
  0% {
    transform: translateX(-100%) translateY(-100%) rotate(45deg);
  }
  50% {
    transform: translateX(100%) translateY(100%) rotate(45deg);
  }
  100% {
    transform: translateX(-100%) translateY(-100%) rotate(45deg);
  }
}

@keyframes aura-sweep {
  0% {
    transform: translateX(-200%) translateY(-200%) rotate(45deg);
  }
  100% {
    transform: translateX(200%) translateY(200%) rotate(45deg);
  }
}

/* Responsive design for smaller screens */
@media (max-width: 1400px) {
  .controls-row {
    gap: 12px;
  }

  .header-btn {
    padding: 8px 16px;
    font-size: 0.85em;
  }

  .agentic-btn {
    padding: 8px 20px !important;
    font-size: 0.95em !important;
    letter-spacing: 1px !important;
  }

  h1 {
    font-size: 1.6em;
  }
}

@media (max-width: 1200px) {
  .controls-row {
    gap: 10px;
  }

  .header-btn {
    padding: 7px 14px;
    font-size: 0.8em;
  }

  .agentic-btn {
    padding: 7px 18px !important;
    font-size: 0.9em !important;
  }

  h1 {
    font-size: 1.5em;
  }

  .agentic-buttons {
    gap: 15px;
  }
}

@media (max-width: 768px) {
  header {
    flex-direction: column;
    gap: 15px;
    padding: 15px;
    min-height: auto;
    align-items: center;
  }

  .header-controls {
    width: 100%;
  }

  .controls-row {
    flex-direction: column;
    gap: 10px;
    width: 100%;
  }

  .view-buttons,
  .utility-buttons,
  .agentic-buttons,
  .service-controls {
    flex-wrap: wrap;
    justify-content: center;
    gap: 8px;
  }

  .header-btn {
    padding: 6px 12px;
    font-size: 0.75em;
  }

  .agentic-btn {
    padding: 8px 16px !important;
    font-size: 0.85em !important;
    letter-spacing: 1px !important;
  }
}

.service-status {
  padding: 5px 10px !important;
  border-radius: 15px !important;
  font-weight: bold;
  border: none !important;
}

.service-status.online {
  background: #4CAF50 !important;
  color: white !important;
}

.service-status:not(.online) {
  background: #f44336 !important;
  color: white !important;
}

.btn-service {
  background: linear-gradient(145deg, #2196F3, #1976D2);
  color: white;
  border: 2px solid #1976D2 !important;
  padding: 8px 16px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  font-weight: bold;
  margin: 0 5px;
}

.btn-service:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.3);
}

.btn-service:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-reset-emails {
  background: linear-gradient(145deg, #ff6b6b, #ff5252);
  color: white;
  border: 2px solid #ff5252 !important;
  padding: 8px 16px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  font-weight: bold;
}

.btn-danger {
  background: linear-gradient(145deg, #dc3545, #c82333) !important;
  border: 2px solid #c82333 !important;
  animation: dangerPulse 2s infinite;
}

@keyframes dangerPulse {
  0%, 100% { box-shadow: 0 2px 4px rgba(220, 53, 69, 0.3); }
  50% { box-shadow: 0 4px 12px rgba(220, 53, 69, 0.6); }
}

.btn-reset-emails:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.3);
}

/* Main Content Layout */
.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.email-traffic-view {
  flex: 1;
  overflow: hidden;
}

.workflow-view {
  flex: 1;
}

/* Split Right Panel - Layout fixe avec flex */
.split-right-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
  position: relative;
}

.events-section {
  flex: 3;
  min-height: 200px;
  overflow-y: auto;
  padding: 10px;
  background: #f0f8ff;
}

.horizontal-separator {
  height: 8px;
  background: #ffd93d;
  border-top: 2px solid #333;
  border-bottom: 2px solid #333;
  cursor: row-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  user-select: none;
}

.horizontal-separator::before {
  content: '⋯';
  color: #333;
  font-weight: bold;
  font-size: 1.2em;
}

.horizontal-separator:hover {
  background: #ff6b6b;
}

.sprint-section {
  flex: 2;
  min-height: 200px;
  overflow-y: auto;
  padding: 10px;
  background: #f9f9f9;
  border-top: 1px solid #ddd;
}

/* Layout deux panneaux */
.two-panel-layout {
  flex: 1;
  display: flex;
  position: relative;
  overflow: hidden;
}

.left-panel,
.right-panel {
  height: 100%;
  overflow-y: auto;
  padding: 20px;
}

.left-panel {
  background: #fff8dc;
  border-right: 3px solid #333;
}

.right-panel {
  background: #f0f8ff;
}

.panel-header {
  margin-bottom: 20px;
}

.panel-header h2 {
  color: #333;
  font-size: 1.5em;
  padding-bottom: 10px;
  border-bottom: 3px solid #ff6b6b;
  font-family: 'Comic Sans MS', cursive;
}

/* Barre de redimensionnement */
.resize-bar {
  position: absolute;
  width: 10px;
  height: 100%;
  background: #ffd93d;
  border-left: 2px solid #333;
  border-right: 2px solid #333;
  cursor: col-resize;
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  z-index: 10;
}

.resize-bar:hover {
  background: #ff6b6b;
}

.resize-bar span {
  color: #999;
  font-size: 1.2em;
}

/* Sélecteur de projet */
.project-selector {
  background: #ffd93d;
  padding: 15px;
  border-radius: 12px;
  margin-bottom: 20px;
  border: 3px solid #333;
  box-shadow: 4px 4px 0px #333;
}

.project-selector label {
  margin-right: 10px;
  font-weight: bold;
}

.project-selector select {
  padding: 8px 15px;
  background: #fff;
  color: #333;
  border: 2px solid #333;
  border-radius: 8px;
  font-size: 1em;
  cursor: pointer;
  font-weight: bold;
}

/* Configuration tmux */
.tmux-config-section {
  margin-bottom: 30px;
}

.tmux-config-section h3 {
  color: #ff6b6b;
  margin-bottom: 15px;
  font-family: 'Comic Sans MS', cursive;
  text-shadow: 1px 1px 0px #333;
}

.agents-config {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
}

.agent-config {
  background: #fff;
  padding: 15px;
  border-radius: 12px;
  border: 3px solid #333;
  box-shadow: 3px 3px 0px #333;
}

.agent-config h4 {
  color: #333;
  margin-bottom: 10px;
  font-size: 1.1em;
  font-weight: bold;
}

.agent-config textarea {
  width: 100%;
  background: #f9f9f9;
  color: #333;
  border: 2px solid #333;
  border-radius: 8px;
  padding: 10px;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
  resize: vertical;
  min-height: 120px;
}

/* Terminaux tmux */
.tmux-terminals-section h3 {
  color: #4a90e2;
  margin-bottom: 15px;
  font-family: 'Comic Sans MS', cursive;
  text-shadow: 1px 1px 0px #333;
}

.terminals-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
}

.terminal-container {
  background: #f9f9f9;
  border: 3px solid #333;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 3px 3px 0px #333;
}

.terminal-header {
  background: #4a90e2;
  padding: 8px 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 3px solid #333;
  color: #fff;
  font-weight: bold;
}

.terminal-controls {
  display: flex;
  gap: 5px;
  align-items: center;
}

.btn-terminal {
  padding: 4px 10px;
  background: #ffd93d;
  color: #333;
  border: 2px solid #333;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.8em;
  font-weight: bold;
  transition: transform 0.2s;
}

.btn-terminal:hover {
  transform: scale(1.05);
}

.btn-start {
  background: #4caf50;
  color: white;
}

.btn-resume {
  background: #ff9800;
  color: white;
}

.btn-stop {
  background: #f44336;
  color: white;
}

.btn-clear {
  background: #9e9e9e;
  color: white;
}

.btn-pause {
  background: #2196F3;
  color: white;
}

.btn-paused {
  background: #607D8B;
  color: white;
}

.btn-scroll {
  background: #9C27B0;
  color: white;
  font-weight: bold;
  font-size: 1em;
}

.btn-reset {
  background: #dc3545;
  color: white;
  font-weight: bold;
  font-size: 1.2em;
}

.terminal-header button {
  padding: 4px 12px;
  background: #ffd93d;
  color: #333;
  border: 2px solid #333;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85em;
  font-weight: bold;
}

.terminal-header button:hover {
  background: #764ba2;
}

.session-active {
  color: #44ff44;
  font-size: 0.9em;
}

.terminal-body {
  height: 250px;
  position: relative;
  background: #fff;
}

.terminal-content {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.terminal-content pre {
  flex: 1;
  padding: 10px;
  color: #333;
  background: #f5f5f5;
  font-family: 'Courier New', monospace;
  font-size: 0.75em;
  line-height: 1.3;
  overflow-y: auto;
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  border: 1px solid #ddd;
}

.terminal-input {
  background: #fff;
  color: #333;
  border: none;
  border-top: 2px solid #333;
  padding: 8px 10px;
  font-family: 'Courier New', monospace;
  font-size: 0.85em;
}

.terminal-inactive {
  padding: 20px;
  text-align: center;
  color: #666;
  font-style: italic;
}

/* Boutons d'action */
.action-buttons {
  margin-top: 20px;
  text-align: center;
}

.btn-primary {
  padding: 12px 30px;
  background: #ff6b6b;
  color: #fff;
  border: 3px solid #333;
  border-radius: 25px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s;
  box-shadow: 4px 4px 0px #333;
  font-family: 'Comic Sans MS', cursive;
}

.btn-primary:hover {
  transform: scale(1.05);
}

/* Events (panneau droit) */
.events-container {
  padding-top: 10px;
}

.event-card {
  background: #fff;
  border: 3px solid #333;
  border-radius: 12px;
  padding: 12px 18px;
  margin-bottom: 15px;
  transition: all 0.2s ease;
  box-shadow: 3px 3px 0px #333;
}

.event-card:hover {
  background: rgba(255,255,255,0.15);
  transform: translateX(5px);
}

.event-prompt {
  border-left: 4px solid #44ff44;
}

.event-stop {
  border-left: 4px solid #ff4444;
}

.event-email {
  border-left: 4px solid #4444ff;
}

.event-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.event-type {
  font-weight: bold;
  text-transform: uppercase;
  font-size: 0.85em;
  color: #ff6b6b;
}

.event-time {
  font-size: 0.85em;
  color: #999;
}

.prompt-text {
  background: #f9f9f9;
  border: 2px solid #333;
  padding: 8px;
  border-radius: 8px;
  margin: 8px 0;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
  color: #333;
}

.event-meta {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.project-badge,
.agent-badge {
  display: inline-block;
  padding: 3px 10px;
  background: #ffd93d;
  border: 2px solid #333;
  border-radius: 15px;
  font-size: 0.85em;
  font-weight: bold;
  color: #333;
}

.agent-badge {
  background: #4a90e2;
  border-color: #333;
  color: #fff;
}

.path-info {
  margin-top: 6px;
  font-size: 0.8em;
  color: #666;
  font-family: 'Courier New', monospace;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.empty-icon {
  font-size: 4em;
  display: block;
  margin-bottom: 15px;
}

/* Animations */
.event-slide-enter-active {
  transition: all 0.3s ease;
}

.event-slide-leave-active {
  transition: all 0.2s ease;
}

.event-slide-enter-from {
  transform: translateX(-50px);
  opacity: 0;
}

.event-slide-leave-to {
  transform: translateX(50px);
  opacity: 0;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(0,0,0,0.2);
}

::-webkit-scrollbar-thumb {
  background: #ff6b6b;
  border-radius: 4px;
  border: 1px solid #333;
}

.btn-reset-emails {
  padding: 6px 15px;
  background: #ff6b6b;
  color: white;
  border: 2px solid #333;
  border-radius: 15px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.9em;
  margin-left: 15px;
  transition: transform 0.2s;
}

.btn-reset-emails:hover {
  transform: scale(1.1);
  background: #ff5252;
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
  background: #fff;
  border-radius: 15px;
  border: 3px solid #333;
  box-shadow: 0 10px 50px rgba(0, 0, 0, 0.5);
  width: 90%;
  max-width: 700px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #ff6b6b 0%, #ffd93d 100%);
  padding: 20px;
  border-bottom: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 12px 12px 0 0;
}

.modal-header h2 {
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 2em;
  cursor: pointer;
  color: #333;
  padding: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-close:hover {
  transform: scale(1.2);
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
}

.email-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.form-group label {
  font-weight: bold;
  color: #333;
  font-size: 0.9em;
}

.form-group input,
.form-group textarea {
  padding: 10px;
  border: 2px solid #333;
  border-radius: 8px;
  font-family: 'Courier New', monospace;
  font-size: 0.95em;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #ff6b6b;
  box-shadow: 0 0 5px rgba(255, 107, 107, 0.3);
}

.form-group input[readonly] {
  background: #f0f0f0;
  cursor: not-allowed;
}

.template-buttons {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.btn-template {
  padding: 8px 15px;
  background: #4a90e2;
  color: white;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: transform 0.2s;
}

.btn-template:hover {
  transform: scale(1.05);
  background: #357abd;
}

.modal-footer {
  padding: 20px;
  border-top: 3px solid #333;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.btn-send {
  padding: 10px 25px;
  background: #4caf50;
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s;
}

.btn-send:hover {
  transform: scale(1.05);
  background: #45a049;
}

.btn-cancel {
  padding: 10px 25px;
  background: #ccc;
  color: #333;
  border: 3px solid #333;
  border-radius: 10px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s;
}

.btn-cancel:hover {
  transform: scale(1.05);
  background: #bbb;
}

::-webkit-scrollbar-thumb:hover {
  background: #764ba2;
}

/* Purge Modal Styles */
.purge-modal {
  max-width: 600px;
}

.purge-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.purge-options {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.option-group {
  background: #f9f9f9;
  border: 2px solid #333;
  border-radius: 12px;
  padding: 15px;
  transition: all 0.3s ease;
}

.option-group:hover {
  background: #f0f8ff;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  font-weight: bold;
  color: #333;
  position: relative;
}

.checkbox-label input[type="checkbox"] {
  opacity: 0;
  position: absolute;
  width: 0;
  height: 0;
}

.checkmark {
  width: 24px;
  height: 24px;
  background: #fff;
  border: 3px solid #333;
  border-radius: 6px;
  position: relative;
  transition: all 0.3s ease;
  flex-shrink: 0;
}

.checkbox-label input[type="checkbox"]:checked + .checkmark {
  background: #4caf50;
  border-color: #4caf50;
}

.checkbox-label input[type="checkbox"]:checked + .checkmark::after {
  content: '✓';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: white;
  font-weight: bold;
  font-size: 16px;
}

.option-title {
  font-size: 1.1em;
  color: #333;
}

.option-details {
  margin-top: 8px;
  margin-left: 36px;
  font-size: 0.9em;
  color: #666;
  font-style: italic;
}

.warning-message {
  background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
  border: 2px solid #ff9800;
  border-radius: 10px;
  padding: 15px;
  color: #333;
  font-size: 0.95em;
  text-align: center;
}

.btn-purge {
  padding: 12px 25px;
  background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  animation: dangerPulse 2s infinite;
}

.btn-purge:hover:not(:disabled) {
  transform: scale(1.05);
  background: linear-gradient(135deg, #c82333 0%, #a71e2a 100%);
  box-shadow: 0 4px 12px rgba(220, 53, 69, 0.4);
}

.btn-purge:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  animation: none;
  transform: none !important;
}

/* Vue Briefing TMUX */
.memories-view, .briefing-view {
  height: 100vh;
  overflow: hidden;
}
</style>