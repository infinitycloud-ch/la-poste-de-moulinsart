<template>
  <div class="mailboxes-container">
    <h2 class="mailboxes-title">📮 Boîtes Mail des Agents</h2>

    <!-- Section Commandant -->
    <div class="project-section commandant-section">
      <div class="project-header">
        <h3 class="project-title">👑 Commandant Minh-Tam</h3>
        <button @click="showCommandantComposer = true" class="compose-btn" title="Composer un email">
          ✉️ Composer
        </button>
      </div>
      <div class="commandant-layout">
        <!-- Portrait du Commandant -->
        <div class="commandant-portrait">
          <img
            src="/portrait-militaire.png?v=1"
            alt="Commandant Minh-Tam"
            class="portrait-image"
            @error="console.log('Erreur chargement portrait:', $event)"
            @load="console.log('Portrait chargé avec succès')"
          />
          <div class="portrait-label">Commandant Minh-Tam</div>
        </div>

        <!-- Boîte mail du Commandant -->
        <div class="mailboxes-grid">
          <div class="mailbox-card commandant-card">
            <div class="mailbox-header commandant-header">
              <AgentAvatar agent="commandant" size="medium" />
              <span class="agent-name">Commandant</span>
              <span class="email-count">{{ commandantEmails.length }} emails</span>
            </div>
            <div class="mailbox-body">
              <div v-if="commandantEmails.length === 0" class="no-emails">
                📭 Boîte mail vide
              </div>
              <div v-else class="emails-list">
                <div v-for="email in commandantEmails.slice(0, 3)" :key="email.id" class="email-preview">
                  <div class="email-meta">
                    <span class="email-recipient">À: {{ email.to_address }}</span>
                    <span class="email-time">{{ formatDate(email.timestamp) }}</span>
                  </div>
                  <div class="email-subject">{{ email.subject }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="projects-container">
      <!-- Section Moulinsart -->
      <div class="project-section">
        <div class="project-header">
          <h3 class="project-title">🎩 TMUX Nestor</h3>
          <button @click="toggleProject('moulinsart')" class="project-toggle-btn" :title="projectsVisible.moulinsart ? 'Masquer' : 'Afficher'">
            {{ projectsVisible.moulinsart ? '📂 ⬆️' : '📁 ⬇️' }}
          </button>
        </div>
        <div v-show="projectsVisible.moulinsart" class="mailboxes-grid">
          <div v-for="agent in moulinsartAgents" :key="agent.name" class="mailbox-card" :class="`mailbox-${agent.name.toLowerCase()}`">
            <div class="mailbox-header" :class="agent.colorClass">
              <AgentAvatar :agent="agent.name.toLowerCase()" size="medium" />
              <span class="agent-name">{{ agent.name }}</span>
              <span class="email-count">{{ agent.emails.length }} emails</span>
              <button @click="showTmuxModalForAgent(agent, 'nestor-agents')" class="notify-btn" title="Envoyer message TMUX">
                🔔
              </button>
              <button @click="refreshMailbox(agent)" class="refresh-btn" title="📧 Recharger emails">
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
      
      <!-- Section Équipe TMUX -->
      <div class="project-section">
        <div class="project-header">
          <h3 class="project-title">⚓ TMUX Haddock</h3>
          <button @click="toggleProject('equipe-tmux')" class="project-toggle-btn" :title="projectsVisible['equipe-tmux'] ? 'Masquer' : 'Afficher'">
            {{ projectsVisible['equipe-tmux'] ? '📂 ⬆️' : '📁 ⬇️' }}
          </button>
        </div>
        <div v-show="projectsVisible['equipe-tmux']" class="mailboxes-grid">
          <div v-for="agent in equipeTmuxAgents" :key="agent.name" class="mailbox-card" :class="`mailbox-${agent.name.toLowerCase()}`">
            <div class="mailbox-header" :class="agent.colorClass">
              <AgentAvatar :agent="agent.name.toLowerCase()" size="medium" />
              <span class="agent-name">{{ agent.name }}</span>
              <span class="email-count">{{ agent.emails.length }} emails</span>
              <button @click="showTmuxModalForAgent(agent, 'haddock-agents')" class="notify-btn" title="Envoyer message TMUX">
                🔔
              </button>
              <button @click="refreshMailbox(agent)" class="refresh-btn" title="📧 Recharger emails">
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
    
    <!-- Modal Composer Email Commandant -->
    <div v-if="showCommandantComposer" class="modal-overlay" @click.self="showCommandantComposer = false">
      <div class="modal-content commandant-composer">
        <div class="modal-header">
          <h3>✉️ Composer Email - Commandant Minh-Tam</h3>
          <button @click="showCommandantComposer = false" class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>À:</label>
            <select v-model="commandantForm.to" class="recipient-select">
              <option value="">Sélectionner destinataire</option>
              <optgroup label="Équipe TMUX-Nestor">
                <option value="nestor@moulinsart.local">Nestor (Chef équipe)</option>
                <option value="tintin@moulinsart.local">Tintin</option>
                <option value="dupont1@moulinsart.local">Dupont1</option>
                <option value="dupont2@moulinsart.local">Dupont2</option>
              </optgroup>
              <optgroup label="Équipe TMUX-Haddock">
                <option value="haddock@moulinsart.local">Haddock (Chef équipe)</option>
                <option value="rastapopoulos@moulinsart.local">Rastapopoulos</option>
                <option value="tournesol1@moulinsart.local">Tournesol1</option>
                <option value="tournesol2@moulinsart.local">Tournesol2</option>
              </optgroup>
            </select>
          </div>
          <div class="form-group">
            <label>Sujet:</label>
            <input v-model="commandantForm.subject" type="text" placeholder="Sujet de la mission...">
          </div>
          <div class="form-group">
            <label>Message:</label>
            <textarea v-model="commandantForm.body" rows="6" placeholder="Vos instructions..."></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="sendCommandantEmail" :disabled="!canSendCommandantEmail" class="btn-send-commandant">
            🚀 Envoyer
          </button>
          <button @click="showCommandantComposer = false" class="btn-cancel">Annuler</button>
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

    <!-- Modal Purge Sélective -->
    <div v-if="showPurgeModal" class="modal-overlay" @click.self="showPurgeModal = false">
      <div class="modal-content purge-modal">
        <div class="modal-header">
          <h3>🗑️ Purge Sélective des Emails</h3>
          <button @click="showPurgeModal = false" class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <p class="purge-warning">⚠️ Sélectionnez les équipes dont vous voulez purger les emails :</p>

          <div class="purge-options">
            <label class="purge-option">
              <input
                type="checkbox"
                v-model="purgeOptions.moulinsart"
              >
              <span class="checkmark"></span>
              <span class="option-label">
                🎩 TMUX Nestor (Nestor, Tintin, Dupont1, Dupont2)
              </span>
            </label>

            <label class="purge-option">
              <input
                type="checkbox"
                v-model="purgeOptions.equipeTmux"
              >
              <span class="checkmark"></span>
              <span class="option-label">
                ⚓ Équipe TMUX (Haddock, Rastapopoulos, Tournesol1, Tournesol2)
              </span>
            </label>
          </div>

          <div class="purge-summary" v-if="purgeOptions.moulinsart || purgeOptions.equipeTmux">
            <strong>Action :</strong>
            <span v-if="purgeOptions.moulinsart && purgeOptions.equipeTmux">
              Purger TOUTES les boîtes mail (8 agents)
            </span>
            <span v-else-if="purgeOptions.moulinsart">
              Purger uniquement TMUX Nestor (4 agents)
            </span>
            <span v-else>
              Purger uniquement Équipe TMUX (4 agents)
            </span>
          </div>
        </div>
        <div class="modal-footer">
          <button
            @click="executePurge"
            class="btn-purge"
            :disabled="!purgeOptions.moulinsart && !purgeOptions.equipeTmux"
          >
            🗑️ Confirmer la Purge
          </button>
          <button @click="showPurgeModal = false" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import AgentAvatar from './AgentAvatar.vue'

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

const equipeTmuxAgents = ref([
  { 
    name: 'Haddock',
    email: 'haddock@moulinsart.local',
    icon: '⚓',
    colorClass: 'haddock',
    emails: [],
    loading: false
  },
  { 
    name: 'Rastapopoulos',
    email: 'rastapopoulos@moulinsart.local',
    icon: '🧔',
    colorClass: 'rastapopoulos',
    emails: [],
    loading: false
  },
  { 
    name: 'Tournesol1',
    email: 'tournesol1@moulinsart.local',
    icon: '🧪',
    colorClass: 'tournesol1',
    emails: [],
    loading: false
  },
  { 
    name: 'Tournesol2',
    email: 'tournesol2@moulinsart.local',
    icon: '🔬',
    colorClass: 'tournesol2',
    emails: [],
    loading: false
  }
])

// Compatibilité avec l'ancien code
const agents = ref([...moulinsartAgents.value, ...equipeTmuxAgents.value])

// Stockage des emails archivés (en mémoire pour l'instant)
const archivedEmails = ref({})

const selectedEmail = ref(null)
const showComposeModal = ref(false)
const showCommandantComposer = ref(false)
const commandantEmails = ref([])
const commandantForm = ref({
  to: '',
  subject: '',
  body: ''
})
const showTmuxModal = ref(false)
const selectedAgent = ref(null)
const selectedSession = ref('')
const quickMessage = ref('')
const tmuxCommands = ref([])

// État pour la purge sélective des emails
const showPurgeModal = ref(false)
const purgeOptions = ref({
  moulinsart: false,
  equipeTmux: false
})

// Validation email Commandant
const canSendCommandantEmail = computed(() => {
  return commandantForm.value.to &&
         commandantForm.value.subject.trim() &&
         commandantForm.value.body.trim()
})
const projectsVisible = ref({
  moulinsart: true,
  'equipe-tmux': true
})
const newEmail = ref({
  from: 'commandant@moulinsart.local',
  to: '',
  subject: '',
  body: ''
})

let refreshInterval = null

// Charger la liste des agents depuis l'API
const loadAgentsFromAPI = async () => {
  try {
    const response = await fetch('http://localhost:1080/api/mailboxes')
    if (response.ok) {
      const data = await response.json()

      // Mettre à jour les agents Moulinsart
      if (data.agents) {
        moulinsartAgents.value = data.agents.map(agent => ({
          name: agent.name.charAt(0).toUpperCase() + agent.name.slice(1),
          email: agent.email,
          icon: getAgentIcon(agent.name),
          colorClass: agent.name,
          emails: [],
          loading: false
        }))
      }

      // Mettre à jour les agents Équipe TMUX
      if (data.equipeTmuxAgents) {
        equipeTmuxAgents.value = data.equipeTmuxAgents.map(agent => ({
          name: agent.name.charAt(0).toUpperCase() + agent.name.slice(1),
          email: agent.email,
          icon: getAgentIcon(agent.name),
          colorClass: agent.name,
          emails: [],
          loading: false
        }))
      }

      // Mettre à jour la liste combinée pour compatibilité
      agents.value = [...moulinsartAgents.value, ...equipeTmuxAgents.value]

      console.log('🔄 Agents chargés depuis l\'API:', {
        moulinsart: moulinsartAgents.value.length,
        'equipe-tmux': equipeTmuxAgents.value.length
      })
    }
  } catch (err) {
    console.error('Erreur chargement agents:', err)
    // Garder les agents par défaut en cas d'erreur
  }
}

// Fonction pour obtenir l'icône d'un agent
const getAgentIcon = (agentName) => {
  const icons = {
    nestor: '🎩',
    tintin: '🚀',
    dupont1: '🎨',
    dupont2: '🔍',
    haddock: '⚓',
    rastapopoulos: '🧔',
    tournesol1: '🧪',
    tournesol2: '🔬'
  }
  return icons[agentName] || '👤'
}

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
  // Rafraîchir même si un email est sélectionné, mais préserver la sélection
  const currentSelection = selectedEmail.value

  for (const agent of [...moulinsartAgents.value, ...equipeTmuxAgents.value]) {
    await refreshMailbox(agent)
  }

  // Restaurer la sélection si elle existait
  if (currentSelection) {
    // Chercher l'email correspondant dans les nouveaux emails chargés
    for (const agent of [...moulinsartAgents.value, ...equipeTmuxAgents.value]) {
      const foundEmail = agent.emails.find(e => e.id === currentSelection.id)
      if (foundEmail) {
        selectedEmail.value = foundEmail
        break
      }
    }
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

// Ouvrir la modal de purge sélective
const clearMailbox = (agent) => {
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
    if (purgeOptions.value.moulinsart) {
      emailAddresses.push(...moulinsartAgents.value.map(agent => agent.email))
    }
    if (purgeOptions.value.equipeTmux) {
      emailAddresses.push(...equipeTmuxAgents.value.map(agent => agent.email))
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

    // 3. Vider les emails locaux du composant Vue
    if (purgeOptions.value.moulinsart) {
      moulinsartAgents.value.forEach(agent => {
        agent.emails = []
      })
    }
    if (purgeOptions.value.equipeTmux) {
      equipeTmuxAgents.value.forEach(agent => {
        agent.emails = []
      })
    }

    // 4. Purger les emails du Commandant si toutes les équipes sont purgées
    if (purgeOptions.value.moulinsart && purgeOptions.value.equipeTmux) {
      try {
        const commandantResponse = await fetch('http://localhost:3001/api/emails/purge-commandant', {
          method: 'POST'
        })
        if (commandantResponse.ok) {
          commandantEmails.value = []
          console.log('✅ Emails Commandant purgés')
        }
      } catch (cmdErr) {
        console.warn('⚠️ Erreur purge emails Commandant:', cmdErr)
      }
    }

    console.log(`📧 ${purgedCount} boîtes mail purgées via Mail Server`)
    alert(`✅ Purge terminée: ${purgedCount} boîtes email purgées`)
    showPurgeModal.value = false

    // Rafraîchir l'affichage après délai
    setTimeout(async () => {
      await refreshAllMailboxes()
      await loadCommandantEmails()
    }, 1000)

  } catch (err) {
    console.error('Erreur lors de la purge:', err)
    alert('Erreur lors de la purge des emails: ' + err.message)
  }
}

// Ouvrir la mailbox dans un nouvel onglet (JSON)
const openMailbox = (agent) => {
  window.open(`http://localhost:1080/api/mailbox/${agent.email}`, '_blank')
}

// Ouvrir le modal TMUX pour un agent
const showTmuxModalForAgent = async (agent, sessionName = 'nestor-agents') => {
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

// Fonction envoi email Commandant
const sendCommandantEmail = async () => {
  if (!canSendCommandantEmail.value) return

  try {
    const response = await fetch('http://localhost:3001/api/execute-shell', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        command: '/Users/studio_m3/moulinsart/send-mail-commandant.sh',
        args: [
          commandantForm.value.to,
          commandantForm.value.subject,
          commandantForm.value.body
        ]
      })
    })

    if (response.ok) {
      const result = await response.json()
      if (result.success) {
        alert(`✅ Email envoyé à ${commandantForm.value.to}`)

        // Reset formulaire
        commandantForm.value.to = ''
        commandantForm.value.subject = ''
        commandantForm.value.body = ''

        showCommandantComposer.value = false

        // Rafraîchir emails
        loadCommandantEmails()
      } else {
        alert(`❌ Erreur: ${result.error}`)
      }
    }
  } catch (err) {
    alert(`❌ Erreur réseau: ${err.message}`)
  }
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
  
  if (sessionName === 'nestor-agents') {
    switch(agent.name.toLowerCase()) {
      case 'nestor': panelNumber = 0; break;
      case 'tintin': panelNumber = 1; break;
      case 'dupont1': panelNumber = 2; break;
      case 'dupont2': panelNumber = 3; break;
      default: return;
    }
  } else if (sessionName === 'haddock-agents') {
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
const notifyAgent = async (agent, sessionName = 'nestor-agents') => {
  // Déterminer le numéro du panel selon le projet
  let panelNumber
  
  if (sessionName === 'nestor-agents') {
    switch(agent.name.toLowerCase()) {
      case 'nestor': panelNumber = 0; break;
      case 'tintin': panelNumber = 1; break;
      case 'dupont1': panelNumber = 2; break;
      case 'dupont2': panelNumber = 3; break;
      default: return;
    }
  } else if (sessionName === 'haddock-agents') {
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

// Charger les emails du Commandant depuis la base Oracle
const loadCommandantEmails = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/emails?from=minh-tam@moulinsart.local')
    if (response.ok) {
      const data = await response.json()
      commandantEmails.value = data.emails || []
    }
  } catch (err) {
    console.error('Erreur chargement emails Commandant:', err)
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
onMounted(async () => {
  // Charger les agents depuis l'API d'abord
  await loadAgentsFromAPI()
  // Puis charger leurs emails
  await refreshAllMailboxes()
  // Charger emails Commandant
  await loadCommandantEmails()
  // Rafraîchir toutes les 3 secondes pour meilleure réactivité
  refreshInterval = setInterval(() => {
    refreshAllMailboxes()
    loadCommandantEmails()
  }, 3000)
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
  background: rgba(255, 255, 255, 0.18) !important;
  backdrop-filter: blur(18px) saturate(190%) contrast(115%) !important;
  -webkit-backdrop-filter: blur(18px) saturate(190%) contrast(115%) !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  border-radius: 16px !important;
  padding: 20px !important;
  margin-bottom: 20px !important;
  box-shadow: 0 6px 25px rgba(0, 0, 0, 0.08) !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
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

.project-toggle-btn, .compose-btn {
  background: rgba(74, 144, 226, 0.8) !important;
  backdrop-filter: blur(10px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(180%) !important;
  color: white !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 12px !important;
  padding: 8px 16px !important;
  cursor: pointer !important;
  font-weight: bold !important;
  font-size: 0.85em !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
  box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3) !important;
}

.project-toggle-btn:hover, .compose-btn:hover {
  transform: translateY(-2px) scale(1.05) !important;
  background: rgba(74, 144, 226, 0.9) !important;
  backdrop-filter: blur(15px) saturate(200%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(200%) !important;
  box-shadow: 0 8px 25px rgba(74, 144, 226, 0.4) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
}

.mailboxes-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.mailbox-card {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  border-radius: 20px !important;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.08),
    inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  overflow: hidden;
  position: relative;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

/* Effet hover liquid glass pour les cartes */
.mailbox-card:hover {
  background: rgba(255, 255, 255, 0.35) !important;
  backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  -webkit-backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  border: 1px solid rgba(255, 255, 255, 0.3) !important;
  box-shadow:
    0 16px 64px rgba(0, 0, 0, 0.15),
    0 4px 16px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.6) !important;
  transform: translateY(-3px) scale(1.02) !important;
}

/* Bordures colorées et bustiers haute résolution par agent */
.mailbox-nestor {
  border-color: #10B981 !important;
  background-image: url('/characters/nestor.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4) !important;
}

.mailbox-tintin {
  border-color: #3B82F6 !important;
  background-image: url('/characters/tintin.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4) !important;
}

.mailbox-dupont1 {
  border-color: #FBBF24 !important;
  background-image: url('/characters/dupont1.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(251, 191, 36, 0.4) !important;
}

.mailbox-dupont2 {
  border-color: #8B5CF6 !important;
  background-image: url('/characters/dupont2.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(139, 92, 246, 0.4) !important;
}

.mailbox-haddock {
  border-color: #1565C0 !important;
  background-image: url('/characters/haddock.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(21, 101, 192, 0.4) !important;
}

.mailbox-rastapopoulos {
  border-color: #D32F2F !important;
  background-image: url('/characters/rastapopoulos.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(211, 47, 47, 0.4) !important;
}

.mailbox-tournesol1 {
  border-color: #388E3C !important;
  background-image: url('/characters/tournesol1.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(56, 142, 60, 0.4) !important;
}

.mailbox-tournesol2 {
  border-color: #7B1FA2 !important;
  background-image: url('/characters/tournesol2.png');
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
  background-color: white;
  box-shadow: 0 4px 12px rgba(123, 31, 162, 0.4) !important;
}

/* Créer un pseudo-element avec l'image circulaire pour tous les avatars */
.mailbox-nestor::before,
.mailbox-tintin::before,
.mailbox-dupont1::before,
.mailbox-dupont2::before,
.mailbox-haddock::before,
.mailbox-rastapopoulos::before,
.mailbox-tournesol1::before,
.mailbox-tournesol2::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 200px;
  height: 200px;
  border-radius: 50%;
  z-index: 0;
  background-size: 200px auto;
  background-position: center center;
  background-repeat: no-repeat;
}

/* Spécifier l'image pour chaque agent dans le pseudo-element */
.mailbox-nestor::before { background-image: url('/characters/nestor.png'); }
.mailbox-tintin::before { background-image: url('/characters/tintin.png'); }
.mailbox-dupont1::before { background-image: url('/characters/dupont1.png'); }
.mailbox-dupont2::before { background-image: url('/characters/dupont2.png'); }
.mailbox-haddock::before { background-image: url('/characters/haddock.png'); }
.mailbox-rastapopoulos::before { background-image: url('/characters/rastapopoulos.png'); }
.mailbox-tournesol1::before { background-image: url('/characters/tournesol1.png'); }
.mailbox-tournesol2::before { background-image: url('/characters/tournesol2.png'); }

/* Supprimer l'image de fond originale pour éviter la duplication */
.mailbox-nestor,
.mailbox-tintin,
.mailbox-dupont1,
.mailbox-dupont2,
.mailbox-haddock,
.mailbox-rastapopoulos,
.mailbox-tournesol1,
.mailbox-tournesol2 {
  background-image: none !important;
}

/* S'assurer que le contenu des emails s'affiche par-dessus l'avatar */
.mailbox-content {
  position: relative;
  z-index: 1;
}

/* S'assurer que les mailbox-card ont position relative pour les pseudo-elements */
.mailbox-card {
  position: relative;
  overflow: visible;
}

/* Layout pour la section Commandant */
.commandant-layout {
  display: flex !important;
  gap: 20px !important;
  align-items: flex-start !important;
}

/* Portrait du Commandant */
.commandant-portrait {
  flex-shrink: 0 !important;
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(200%) contrast(120%) brightness(110%) !important;
  border: 1px solid rgba(255, 215, 0, 0.4) !important;
  border-radius: 20px !important;
  padding: 20px !important;
  box-shadow:
    0 8px 32px rgba(255, 107, 107, 0.15),
    0 2px 8px rgba(255, 107, 107, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.5) !important;
  transition: all 0.4s cubic-bezier(0.23, 1, 0.32, 1) !important;
}

.commandant-portrait:hover {
  background: rgba(255, 255, 255, 0.35) !important;
  backdrop-filter: blur(30px) saturate(220%) contrast(130%) brightness(115%) !important;
  transform: translateY(-2px) scale(1.02) !important;
  box-shadow:
    0 12px 40px rgba(255, 107, 107, 0.2),
    0 4px 12px rgba(255, 107, 107, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.6) !important;
}

.portrait-image {
  width: 150px !important;
  height: 150px !important;
  border-radius: 15px !important;
  object-fit: cover !important;
  border: 3px solid rgba(255, 215, 0, 0.8) !important;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2) !important;
  transition: all 0.3s ease !important;
}

.portrait-image:hover {
  transform: scale(1.05) !important;
  border-color: rgba(255, 215, 0, 1) !important;
  box-shadow: 0 6px 24px rgba(255, 215, 0, 0.3) !important;
}

.portrait-label {
  margin-top: 12px !important;
  font-weight: bold !important;
  color: #2C3E50 !important;
  text-align: center !important;
  font-size: 14px !important;
  background: rgba(255, 215, 0, 0.8) !important;
  padding: 6px 12px !important;
  border-radius: 12px !important;
  border: 1px solid rgba(255, 215, 0, 0.9) !important;
  box-shadow: 0 2px 8px rgba(255, 215, 0, 0.3) !important;
}

/* Bordure spéciale pour la carte Commandant */
.commandant-card {
  border-color: #FF6B6B !important;
  background: linear-gradient(135deg, rgba(255, 107, 107, 0.1) 0%, rgba(255, 255, 255, 1) 100%) !important;
  box-shadow: 0 6px 20px rgba(255, 107, 107, 0.4) !important;
  flex: 1 !important;
}

.mailbox-header {
  padding: 12px 16px !important;
  color: white !important;
  display: flex !important;
  align-items: center !important;
  gap: 10px !important;
  font-weight: bold !important;
  font-size: 0.9em !important;
  background: rgba(0, 0, 0, 0.15) !important;
  backdrop-filter: blur(15px) saturate(150%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(150%) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
  border-radius: 20px 20px 0 0 !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
}

/* Couleurs Moulinsart avec effet liquid glass */
.mailbox-header.nestor {
  background: rgba(16, 185, 129, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.tintin {
  background: rgba(59, 130, 246, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.dupont1 {
  background: rgba(251, 191, 36, 0.8) !important;
  color: #333 !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.dupont2 {
  background: rgba(139, 92, 246, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}

/* Couleurs Équipe TMUX avec effet liquid glass */
.mailbox-header.haddock {
  background: rgba(21, 101, 192, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.rastapopoulos {
  background: rgba(211, 47, 47, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.tournesol1 {
  background: rgba(56, 142, 60, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}
.mailbox-header.tournesol2 {
  background: rgba(123, 31, 162, 0.8) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
}

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
  border: 1px solid rgba(224, 224, 224, 0.3);
  border-radius: 6px;
  overflow: hidden;
  background: rgba(250, 250, 250, 0.15);
  backdrop-filter: blur(2px);
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
  border: 1px solid rgba(224, 224, 224, 0.2);
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: calc(3px * var(--scale-factor, 1));
  background: rgba(255, 255, 255, 0.1);
}

.email-item:hover {
  background: rgba(240, 240, 240, 0.3);
}

.email-item.unread {
  background: #e3f2fd;
  border-color: #2196f3;
  font-weight: bold;
}

.email-item.received {
  border-left: 4px solid rgba(76, 175, 80, 0.6);
  background: rgba(241, 248, 233, 0.2);
}

.email-item.sent {
  border-left: 4px solid rgba(33, 150, 243, 0.6);
  background: rgba(227, 242, 253, 0.2);
}

.email-item.archived {
  border-left: 4px solid rgba(158, 158, 158, 0.4);
  background: rgba(245, 245, 245, 0.1);
  opacity: 0.6;
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
  background: rgba(245, 245, 245, 0.3);
  border-color: rgba(153, 153, 153, 0.4);
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

/* Modal de purge sélective */
.purge-modal .modal-header {
  background: #ff6b6b;
}

.purge-warning {
  margin-bottom: 20px;
  padding: 10px;
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 5px;
  color: #856404;
}

.purge-options {
  margin-bottom: 20px;
}

.purge-option {
  display: flex;
  align-items: center;
  margin-bottom: 15px;
  padding: 10px;
  border: 2px solid #ddd;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.purge-option:hover {
  border-color: #ff6b6b;
  background: #ffeeff;
}

.purge-option input[type="checkbox"] {
  margin-right: 12px;
  transform: scale(1.2);
}

.option-label {
  font-size: 16px;
  font-weight: 500;
}

.purge-summary {
  padding: 15px;
  background: #e3f2fd;
  border-left: 4px solid #2196f3;
  border-radius: 4px;
  margin-bottom: 10px;
}

.btn-purge {
  padding: 10px 20px;
  background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
}

.btn-purge:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 107, 107, 0.4);
}

.btn-purge:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Liquid Glass pour le contenu des mailboxes */
.mailbox-body {
  padding: 15px !important;
  background: rgba(255, 255, 255, 0.05) !important;
  backdrop-filter: blur(5px) saturate(120%) !important;
  -webkit-backdrop-filter: blur(5px) saturate(120%) !important;
  border-radius: 0 0 20px 20px !important;
  margin: 0 !important;
}

.email-preview {
  background: rgba(255, 255, 255, 0.15) !important;
  backdrop-filter: blur(6px) saturate(150%) !important;
  -webkit-backdrop-filter: blur(6px) saturate(150%) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  border-radius: 8px !important;
  padding: 10px !important;
  margin: 6px 0 !important;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94) !important;
}

.email-preview:hover {
  background: rgba(255, 255, 255, 0.25) !important;
  backdrop-filter: blur(10px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(10px) saturate(180%) !important;
  transform: translateY(-1px) scale(1.01) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
}

.no-emails {
  background: rgba(255, 255, 255, 0.1) !important;
  backdrop-filter: blur(8px) !important;
  -webkit-backdrop-filter: blur(8px) !important;
  border: 1px solid rgba(255, 255, 255, 0.1) !important;
  border-radius: 8px !important;
  padding: 20px !important;
  text-align: center !important;
  color: #666 !important;
  font-style: italic !important;
}

/* Amélioration du titre de section pour le liquid glass */
.mailboxes-title {
  background: rgba(255, 255, 255, 0.2) !important;
  backdrop-filter: blur(15px) saturate(180%) !important;
  -webkit-backdrop-filter: blur(15px) saturate(180%) !important;
  border: 1px solid rgba(255, 255, 255, 0.25) !important;
  border-radius: 16px !important;
  padding: 15px 25px !important;
  margin-bottom: 25px !important;
  box-shadow: 0 6px 25px rgba(0, 0, 0, 0.08) !important;
  text-align: center !important;
  color: #333 !important;
}
</style>