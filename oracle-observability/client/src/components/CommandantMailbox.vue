<template>
  <div class="commandant-mailbox">
    <div class="mailbox-header">
      <h2>📮 Boîte Mail du Commandant Minh-Tam</h2>
      <div class="mailbox-stats">
        <span class="badge">{{ receivedEmails.length }} reçus</span>
        <span class="badge">{{ sentEmails.length }} envoyés</span>
      </div>
    </div>

    <!-- Formulaire d'envoi d'email -->
    <div class="compose-email-section">
      <h3>✉️ Composer un Email</h3>
      <div class="compose-form">
        <div class="form-row">
          <div class="form-group">
            <label>De:</label>
            <input v-model="emailForm.from" type="email" readonly class="readonly-input" />
          </div>
          <div class="form-group">
            <label>À:</label>
            <select v-model="emailForm.to" class="recipient-select">
              <option value="">Sélectionner un destinataire</option>
              <optgroup label="Équipe TMUX-Nestor">
                <option value="nestor@moulinsart.local">Nestor (Chef d'équipe)</option>
                <option value="tintin@moulinsart.local">Tintin</option>
                <option value="dupont1@moulinsart.local">Dupont1</option>
                <option value="dupont2@moulinsart.local">Dupont2</option>
              </optgroup>
              <optgroup label="Équipe TMUX-Haddock">
                <option value="haddock@moulinsart.local">Haddock (Chef d'équipe)</option>
                <option value="rastapopoulos@moulinsart.local">Rastapopoulos</option>
                <option value="tournesol1@moulinsart.local">Tournesol1</option>
                <option value="tournesol2@moulinsart.local">Tournesol2</option>
              </optgroup>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label>Sujet:</label>
          <input v-model="emailForm.subject" type="text" placeholder="Sujet de la mission..." class="subject-input" />
        </div>

        <div class="form-group">
          <label>Message:</label>
          <textarea v-model="emailForm.body" rows="8" placeholder="Vos instructions..." class="message-textarea"></textarea>
        </div>

        <div class="form-actions">
          <div class="template-buttons">
            <button @click="loadTemplate('test')" class="btn-template">🧪 Template Test</button>
            <button @click="loadTemplate('mission')" class="btn-template">🎯 Template Mission</button>
            <button @click="loadTemplate('urgent')" class="btn-template">🚨 Template Urgent</button>
            <button @click="clearForm" class="btn-clear">🗑️ Vider</button>
          </div>
          <button @click="sendEmail" class="btn-send" :disabled="!canSendEmail || sending">
            {{ sending ? '📤 Envoi...' : '🚀 Envoyer Email' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Messages d'état -->
    <div v-if="message" :class="['status-message', messageType]">
      {{ message }}
    </div>

    <!-- Historique des emails -->
    <div class="email-history">
      <h3>📧 Historique des Communications</h3>

      <!-- Emails envoyés -->
      <div v-if="sentEmails.length > 0" class="email-section">
        <h4 class="section-title">📤 Emails Envoyés ({{ sentEmails.length }})</h4>
        <div class="emails-list">
          <div v-for="email in sentEmails" :key="`sent-${email.id}`" class="email-item sent">
            <div class="email-header">
              <span class="email-to">À: {{ email.to_address }}</span>
              <span class="email-date">{{ formatDate(email.timestamp) }}</span>
            </div>
            <div class="email-subject" @click="toggleEmailExpand(email)">
              {{ email.subject }}
            </div>
            <div v-if="expandedEmail === email.id" class="email-body">
              <pre>{{ email.body }}</pre>
            </div>
          </div>
        </div>
      </div>

      <!-- Emails reçus -->
      <div v-if="receivedEmails.length > 0" class="email-section">
        <h4 class="section-title">📥 Emails Reçus ({{ receivedEmails.length }})</h4>
        <div class="emails-list">
          <div v-for="email in receivedEmails" :key="`received-${email.id}`" class="email-item received">
            <div class="email-header">
              <span class="email-from">De: {{ email.from_address }}</span>
              <span class="email-date">{{ formatDate(email.timestamp) }}</span>
            </div>
            <div class="email-subject" @click="toggleEmailExpand(email)">
              {{ email.subject }}
            </div>
            <div v-if="expandedEmail === email.id" class="email-body">
              <pre>{{ email.body }}</pre>
            </div>
          </div>
        </div>
      </div>

      <div v-if="sentEmails.length === 0 && receivedEmails.length === 0" class="no-emails">
        📭 Aucun email dans l'historique
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

// État du composant
const emailForm = ref({
  from: 'minh-tam@moulinsart.local',
  to: '',
  subject: '',
  body: ''
})

const sentEmails = ref([])
const receivedEmails = ref([])
const sending = ref(false)
const message = ref('')
const messageType = ref('')
const expandedEmail = ref(null)

// WebSocket pour updates temps réel
let ws = null
const isConnected = ref(false)

// Vérification si l'email peut être envoyé
const canSendEmail = computed(() => {
  return emailForm.value.to &&
         emailForm.value.subject.trim() &&
         emailForm.value.body.trim()
})

// Templates d'emails
const templates = {
  test: {
    subject: 'Test de Communication',
    body: `Bonjour,

Ceci est un test de communication depuis le Commandant.

Merci de confirmer la réception de ce message.

--
Commandant Minh-Tam
Château de Moulinsart`
  },
  mission: {
    subject: 'Nouvelle Mission Assignée',
    body: `Agent,

Je vous assigne une nouvelle mission prioritaire.

Détails:
- Objectif: [À compléter]
- Délai: [À définir]
- Ressources: [À préciser]

Tenez-moi informé de vos progrès.

--
Commandant Minh-Tam
Château de Moulinsart`
  },
  urgent: {
    subject: '🚨 URGENT - Action Immédiate Requise',
    body: `URGENT - ACTION IMMÉDIATE

Agent,

Situation critique nécessitant votre intervention immédiate.

[Détails de la situation urgente]

Veuillez confirmer réception et action dans les plus brefs délais.

--
Commandant Minh-Tam
Château de Moulinsart`
  }
}

// Fonctions
const showMessage = (text, type = 'success') => {
  message.value = text
  messageType.value = type
  setTimeout(() => {
    message.value = ''
  }, 5000)
}

const loadTemplate = (type) => {
  if (templates[type]) {
    emailForm.value.subject = templates[type].subject
    emailForm.value.body = templates[type].body
    showMessage(`Template "${type}" chargé`, 'info')
  }
}

const clearForm = () => {
  emailForm.value.to = ''
  emailForm.value.subject = ''
  emailForm.value.body = ''
  showMessage('Formulaire vidé', 'info')
}

const sendEmail = async () => {
  if (!canSendEmail.value) return

  sending.value = true
  try {
    // Utiliser le script shell du Commandant
    const response = await fetch('http://localhost:3001/api/execute-shell', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        command: '/Users/studio_m3/moulinsart/send-mail-commandant.sh',
        args: [emailForm.value.to, emailForm.value.subject, emailForm.value.body]
      })
    })

    if (response.ok) {
      const result = await response.json()
      if (result.success) {
        showMessage(`✅ Email du Commandant envoyé à ${emailForm.value.to}`, 'success')
        clearForm()
        loadEmails() // Recharger l'historique
      } else {
        showMessage(`❌ Erreur script: ${result.error}`, 'error')
      }
    } else {
      showMessage(`❌ Erreur serveur lors de l'exécution du script`, 'error')
    }
  } catch (err) {
    showMessage(`❌ Erreur réseau: ${err.message}`, 'error')
  }
  sending.value = false
}

const loadEmails = async () => {
  try {
    // Charger emails envoyés
    const sentResponse = await fetch('http://localhost:1080/api/emails/sent/minh-tam@moulinsart.local')
    if (sentResponse.ok) {
      sentEmails.value = await sentResponse.json()
    }

    // Charger emails reçus
    const receivedResponse = await fetch('http://localhost:1080/api/mailbox/minh-tam@moulinsart.local')
    if (receivedResponse.ok) {
      receivedEmails.value = await receivedResponse.json()
    }
  } catch (err) {
    console.error('Erreur chargement emails:', err)
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const toggleEmailExpand = (email) => {
  expandedEmail.value = expandedEmail.value === email.id ? null : email.id
}

// Connexion WebSocket pour updates temps réel
const connectWebSocket = () => {
  ws = new WebSocket('ws://localhost:3001/ws')

  ws.onopen = () => {
    console.log('CommandantMailbox WebSocket connected')
    isConnected.value = true
  }

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data)

      // Si c'est un événement email, recharger les emails
      if (data.type === 'event' && data.data.type === 'email') {
        console.log('📧 Nouvel email détecté, rechargement de l\'historique')
        loadEmails()
      }
    } catch (err) {
      console.error('Erreur parsing WebSocket:', err)
    }
  }

  ws.onerror = (error) => {
    console.error('CommandantMailbox WebSocket error:', error)
  }

  ws.onclose = () => {
    console.log('CommandantMailbox WebSocket disconnected')
    isConnected.value = false

    // Reconnexion automatique après 3 secondes
    setTimeout(() => {
      connectWebSocket()
    }, 3000)
  }
}

// Charger les emails au montage
onMounted(() => {
  loadEmails()
  connectWebSocket()
  // Recharger toutes les 30 secondes en backup
  setInterval(loadEmails, 30000)
})

// Nettoyer WebSocket au démontage
onUnmounted(() => {
  if (ws) {
    ws.close()
  }
})
</script>

<style scoped>
.commandant-mailbox {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  border-radius: 15px;
  padding: 25px;
  color: #ffffff;
  margin: 20px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.3);
}

.mailbox-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid #4a5568;
}

.mailbox-header h2 {
  color: #ffd700;
  margin: 0;
  font-size: 1.8rem;
}

.mailbox-stats {
  display: flex;
  gap: 10px;
}

.badge {
  background: #4a5568;
  color: #ffffff;
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: bold;
}

.compose-email-section {
  background: rgba(255,255,255,0.05);
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 30px;
  border: 1px solid rgba(255,255,255,0.1);
}

.compose-email-section h3 {
  color: #90cdf4;
  margin-bottom: 20px;
  font-size: 1.4rem;
}

.form-row {
  display: flex;
  gap: 20px;
  margin-bottom: 15px;
}

.form-group {
  flex: 1;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: #cbd5e0;
  font-weight: bold;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 12px;
  border: 2px solid #4a5568;
  border-radius: 8px;
  background: #2d3748;
  color: #ffffff;
  font-size: 1rem;
}

.readonly-input {
  background: #1a202c !important;
  cursor: not-allowed;
}

.recipient-select option {
  background: #2d3748;
  color: #ffffff;
}

.subject-input,
.message-textarea {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.message-textarea {
  resize: vertical;
  min-height: 120px;
}

.form-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 20px;
}

.template-buttons {
  display: flex;
  gap: 10px;
}

.btn-template,
.btn-clear {
  background: #4a5568;
  color: #ffffff;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.btn-template:hover,
.btn-clear:hover {
  background: #5a6578;
  transform: translateY(-2px);
}

.btn-send {
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1.1rem;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-send:hover:not(:disabled) {
  background: linear-gradient(135deg, #3182ce 0%, #2c5282 100%);
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(66, 153, 225, 0.4);
}

.btn-send:disabled {
  background: #4a5568;
  cursor: not-allowed;
  transform: none;
}

.status-message {
  padding: 15px;
  border-radius: 8px;
  margin: 20px 0;
  font-weight: bold;
}

.status-message.success {
  background: rgba(72, 187, 120, 0.2);
  color: #48bb78;
  border: 1px solid #48bb78;
}

.status-message.error {
  background: rgba(245, 101, 101, 0.2);
  color: #f56565;
  border: 1px solid #f56565;
}

.status-message.info {
  background: rgba(66, 153, 225, 0.2);
  color: #4299e1;
  border: 1px solid #4299e1;
}

.email-history {
  background: rgba(255,255,255,0.05);
  border-radius: 10px;
  padding: 20px;
  border: 1px solid rgba(255,255,255,0.1);
}

.email-history h3 {
  color: #90cdf4;
  margin-bottom: 20px;
  font-size: 1.4rem;
}

.email-section {
  margin-bottom: 30px;
}

.section-title {
  color: #cbd5e0;
  margin-bottom: 15px;
  font-size: 1.2rem;
  border-bottom: 1px solid #4a5568;
  padding-bottom: 8px;
}

.emails-list {
  space-y: 10px;
}

.email-item {
  background: rgba(255,255,255,0.03);
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 10px;
  border: 1px solid rgba(255,255,255,0.1);
  transition: all 0.2s;
}

.email-item:hover {
  background: rgba(255,255,255,0.08);
  border-color: rgba(255,255,255,0.2);
}

.email-item.sent {
  border-left: 4px solid #4299e1;
}

.email-item.received {
  border-left: 4px solid #48bb78;
}

.email-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #a0aec0;
}

.email-subject {
  font-weight: bold;
  color: #ffffff;
  cursor: pointer;
  padding: 5px 0;
}

.email-subject:hover {
  color: #90cdf4;
}

.email-body {
  margin-top: 15px;
  padding: 15px;
  background: rgba(0,0,0,0.2);
  border-radius: 6px;
  border: 1px solid rgba(255,255,255,0.1);
}

.email-body pre {
  white-space: pre-wrap;
  font-family: inherit;
  color: #e2e8f0;
  line-height: 1.5;
  margin: 0;
}

.no-emails {
  text-align: center;
  color: #a0aec0;
  font-style: italic;
  padding: 40px;
}
</style>