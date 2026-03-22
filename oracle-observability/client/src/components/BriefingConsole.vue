<template>
  <div class="briefing-console">
    <div class="console-header">
      <h2>🎩 Console de Briefing TMUX</h2>
      <div class="project-selector">
        <label>Projet actuel :</label>
        <select v-model="selectedProjectId" @change="loadProjectBriefings">
          <option v-for="project in projects" :key="project.id" :value="project.id">
            {{ project.id }} - {{ project.name }}
          </option>
        </select>
      </div>
    </div>

    <div class="console-layout">
      <!-- Panel gauche - Équipes et Actions -->
      <div class="teams-panel">
        <h3>👥 Équipes TMUX</h3>

        <!-- Équipe Nestor -->
        <div class="team-section">
          <h4>🎩 Équipe Nestor</h4>
          <div class="agent-buttons">
            <button
              v-for="agent in nestorTeam"
              :key="agent"
              @click="selectAgent(agent)"
              :class="['agent-btn', 'nestor-team', { active: selectedAgent === agent }]"
            >
              {{ agent }}
            </button>
          </div>
        </div>

        <!-- Équipe Haddock -->
        <div class="team-section">
          <h4>⚓ Équipe Haddock</h4>
          <div class="agent-buttons">
            <button
              v-for="agent in haddockTeam"
              :key="agent"
              @click="selectAgent(agent)"
              :class="['agent-btn', 'haddock-team', { active: selectedAgent === agent }]"
            >
              {{ agent }}
            </button>
          </div>
        </div>

        <!-- Actions -->
        <div class="actions-section" v-if="selectedAgent">
          <h4>⚡ Actions pour {{ selectedAgent }}</h4>
          <button @click="executeBriefing" :disabled="executing" class="btn-execute">
            {{ executing ? '⏳ Exécution...' : '🚀 Exécuter Briefing' }}
          </button>
          <button @click="showSaveDialog = true" class="btn-save">
            💾 Sauvegarder Version
          </button>
          <button @click="loadAgentHistory" class="btn-history">
            📜 Voir Historique
          </button>
        </div>
      </div>

      <!-- Panel central - Console et Output -->
      <div class="console-panel">
        <div class="console-output">
          <h3>📺 Console Output</h3>
          <div class="terminal" ref="terminal">
            <div v-for="(line, index) in consoleOutput" :key="index" class="terminal-line">
              <span class="timestamp">{{ line.timestamp }}</span>
              <span :class="['message', line.type]">{{ line.message }}</span>
            </div>
          </div>
        </div>

        <!-- Instructions Editor -->
        <div class="instructions-editor" v-if="selectedAgent">
          <h3>📝 Instructions Spécifiques - {{ selectedAgent }}</h3>
          <textarea
            v-model="currentInstructions"
            @input="instructionsChanged = true"
            class="instructions-textarea"
            placeholder="Instructions spécifiques pour cet agent..."
          ></textarea>
          <button
            @click="saveInstructions"
            :disabled="!instructionsChanged"
            class="btn-save-instructions"
          >
            {{ instructionsChanged ? '💾 Sauvegarder Instructions' : '✅ Instructions à jour' }}
          </button>
        </div>
      </div>

      <!-- Panel droit - Historique et Versions -->
      <div class="history-panel">
        <h3>📜 Historique Versions</h3>

        <div class="version-list">
          <div
            v-for="version in versionHistory"
            :key="version.id"
            :class="['version-item', { current: version.current }]"
          >
            <div class="version-header">
              <span class="version-date">{{ formatDate(version.created_at) }}</span>
              <span class="version-agent">{{ version.agent }}</span>
            </div>
            <div class="version-comment">{{ version.comment || 'Pas de commentaire' }}</div>
            <div class="version-actions">
              <button @click="previewVersion(version)" class="btn-preview">👁️</button>
              <button @click="restoreVersion(version)" class="btn-restore">🔄</button>
              <button @click="deleteVersion(version)" class="btn-delete">🗑️</button>
            </div>
          </div>
        </div>

        <div v-if="versionHistory.length === 0" class="no-versions">
          Aucune version sauvegardée pour ce projet
        </div>
      </div>
    </div>

    <!-- Modal de sauvegarde -->
    <div v-if="showSaveDialog" class="modal-overlay" @click="showSaveDialog = false">
      <div class="modal-content" @click.stop>
        <h3>💾 Sauvegarder Version</h3>
        <div class="save-form">
          <label>Agent :</label>
          <input v-model="selectedAgent" readonly class="readonly-input" />

          <label>Commentaire :</label>
          <textarea v-model="saveComment" placeholder="Décrivez cette version..."></textarea>

          <div class="modal-actions">
            <button @click="saveVersion" class="btn-confirm">💾 Sauvegarder</button>
            <button @click="showSaveDialog = false" class="btn-cancel">❌ Annuler</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de prévisualisation -->
    <div v-if="showPreviewDialog" class="modal-overlay" @click="showPreviewDialog = false">
      <div class="modal-content large" @click.stop>
        <h3>👁️ Prévisualisation Version</h3>
        <div class="preview-content">
          <pre>{{ previewContent }}</pre>
        </div>
        <div class="modal-actions">
          <button @click="showPreviewDialog = false" class="btn-close">✅ Fermer</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'

// État réactif
const selectedProjectId = ref(22) // Défaut MonoCLI
const projects = ref([])
const selectedAgent = ref('')
const executing = ref(false)
const instructionsChanged = ref(false)
const currentInstructions = ref('')
const consoleOutput = ref([])
const versionHistory = ref([])
const showSaveDialog = ref(false)
const showPreviewDialog = ref(false)
const saveComment = ref('')
const previewContent = ref('')

// Équipes
const nestorTeam = ['nestor', 'tintin', 'dupont1', 'dupont2']
const haddockTeam = ['haddock', 'rastapopoulos', 'tournesol1', 'tournesol2']

// Références DOM
const terminal = ref(null)

// Fonctions utilitaires
const addConsoleLog = (message, type = 'info') => {
  consoleOutput.value.push({
    timestamp: new Date().toLocaleTimeString(),
    message,
    type
  })
  nextTick(() => {
    if (terminal.value) {
      terminal.value.scrollTop = terminal.value.scrollHeight
    }
  })
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleString('fr-FR')
}

// Actions principales
const selectAgent = async (agent) => {
  selectedAgent.value = agent
  addConsoleLog(`Agent sélectionné: ${agent}`, 'info')

  // Charger les instructions actuelles
  await loadCurrentInstructions(agent)

  // Charger l'historique
  await loadAgentHistory()
}

const loadCurrentInstructions = async (agent) => {
  try {
    const team = nestorTeam.includes(agent) ? 'nestor-equipe' : 'haddock-equipe'
    const response = await fetch(`http://localhost:3001/api/briefing/instructions?agent=${agent}&team=${team}`)

    if (response.ok) {
      const data = await response.json()
      currentInstructions.value = data.content || ''
      instructionsChanged.value = false
    } else {
      addConsoleLog(`Erreur chargement instructions pour ${agent}`, 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

const saveInstructions = async () => {
  try {
    const team = nestorTeam.includes(selectedAgent.value) ? 'nestor-equipe' : 'haddock-equipe'
    const response = await fetch('http://localhost:3001/api/briefing/save-instructions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        agent: selectedAgent.value,
        team,
        content: currentInstructions.value
      })
    })

    if (response.ok) {
      addConsoleLog(`Instructions sauvegardées pour ${selectedAgent.value}`, 'success')
      instructionsChanged.value = false
    } else {
      addConsoleLog('Erreur sauvegarde instructions', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

const executeBriefing = async () => {
  if (!selectedAgent.value) return

  executing.value = true
  addConsoleLog(`🚀 Exécution briefing pour ${selectedAgent.value}...`, 'info')

  try {
    const response = await fetch('http://localhost:3001/api/briefing/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        agent: selectedAgent.value,
        project_id: selectedProjectId.value
      })
    })

    if (response.ok) {
      const result = await response.json()
      addConsoleLog('✅ Briefing exécuté avec succès', 'success')
      addConsoleLog(result.output, 'output')
    } else {
      addConsoleLog('❌ Erreur exécution briefing', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }

  executing.value = false
}

const saveVersion = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/briefing/save-version', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project_id: selectedProjectId.value,
        agent: selectedAgent.value,
        comment: saveComment.value,
        instructions: currentInstructions.value
      })
    })

    if (response.ok) {
      addConsoleLog(`Version sauvegardée pour ${selectedAgent.value}`, 'success')
      showSaveDialog.value = false
      saveComment.value = ''
      await loadAgentHistory()
    } else {
      addConsoleLog('Erreur sauvegarde version', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

const loadAgentHistory = async () => {
  if (!selectedAgent.value) return

  try {
    const response = await fetch(`http://localhost:3001/api/briefing/history?project_id=${selectedProjectId.value}&agent=${selectedAgent.value}`)

    if (response.ok) {
      versionHistory.value = await response.json()
    } else {
      addConsoleLog('Erreur chargement historique', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

const loadProjectBriefings = async () => {
  await loadAgentHistory()
  addConsoleLog(`Projet changé: ${selectedProjectId.value}`, 'info')
}

const previewVersion = async (version) => {
  previewContent.value = version.instructions || 'Contenu non disponible'
  showPreviewDialog.value = true
}

const restoreVersion = async (version) => {
  if (!confirm(`Restaurer la version du ${formatDate(version.created_at)} ?`)) return

  try {
    const response = await fetch('http://localhost:3001/api/briefing/restore-version', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        version_id: version.id,
        agent: selectedAgent.value
      })
    })

    if (response.ok) {
      addConsoleLog(`Version restaurée pour ${selectedAgent.value}`, 'success')
      await loadCurrentInstructions(selectedAgent.value)
      await loadAgentHistory()
    } else {
      addConsoleLog('Erreur restauration version', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

const deleteVersion = async (version) => {
  if (!confirm(`Supprimer la version du ${formatDate(version.created_at)} ?`)) return

  try {
    const response = await fetch(`http://localhost:3001/api/briefing/delete-version/${version.id}`, {
      method: 'DELETE'
    })

    if (response.ok) {
      addConsoleLog('Version supprimée', 'success')
      await loadAgentHistory()
    } else {
      addConsoleLog('Erreur suppression version', 'error')
    }
  } catch (error) {
    addConsoleLog(`Erreur: ${error.message}`, 'error')
  }
}

// Chargement initial
onMounted(async () => {
  // Charger la liste des projets
  try {
    const response = await fetch('http://localhost:3001/api/projects')
    if (response.ok) {
      projects.value = await response.json()
    }
  } catch (error) {
    addConsoleLog('Erreur chargement projets', 'error')
  }

  addConsoleLog('Console de briefing initialisée', 'success')
})
</script>

<style scoped>
.briefing-console {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #1e3a8a 0%, #3730a3 100%);
  color: white;
}

.console-header {
  padding: 20px;
  background: rgba(0, 0, 0, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.project-selector label {
  margin-right: 10px;
  font-weight: bold;
}

.project-selector select {
  padding: 8px 12px;
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 14px;
}

.console-layout {
  display: flex;
  flex: 1;
  gap: 20px;
  padding: 20px;
}

.teams-panel {
  width: 300px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 20px;
  backdrop-filter: blur(10px);
}

.team-section {
  margin-bottom: 30px;
}

.team-section h4 {
  margin-bottom: 15px;
  color: #fbbf24;
}

.agent-buttons {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.agent-btn {
  padding: 10px 15px;
  border: none;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  text-transform: capitalize;
}

.agent-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateX(5px);
}

.agent-btn.active {
  background: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
}

.nestor-team.active {
  background: #10b981;
}

.haddock-team.active {
  background: #1565c0;
}

.actions-section {
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.actions-section h4 {
  margin-bottom: 15px;
  color: #fbbf24;
}

.btn-execute, .btn-save, .btn-history, .btn-save-instructions {
  width: 100%;
  padding: 12px;
  margin-bottom: 10px;
  border: none;
  border-radius: 8px;
  background: #3b82f6;
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: bold;
}

.btn-execute:hover {
  background: #2563eb;
  transform: translateY(-2px);
}

.btn-save {
  background: #10b981;
}

.btn-save:hover {
  background: #059669;
}

.btn-history {
  background: #8b5cf6;
}

.btn-history:hover {
  background: #7c3aed;
}

.console-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.console-output {
  flex: 1;
  background: rgba(0, 0, 0, 0.3);
  border-radius: 12px;
  padding: 20px;
}

.console-output h3 {
  margin-bottom: 15px;
  color: #fbbf24;
}

.terminal {
  height: 300px;
  overflow-y: auto;
  background: #1f2937;
  border-radius: 8px;
  padding: 15px;
  font-family: 'Monaco', 'Consolas', monospace;
  font-size: 13px;
}

.terminal-line {
  margin-bottom: 5px;
  display: flex;
  gap: 10px;
}

.timestamp {
  color: #6b7280;
  font-size: 11px;
  min-width: 80px;
}

.message.info {
  color: #60a5fa;
}

.message.success {
  color: #34d399;
}

.message.error {
  color: #f87171;
}

.message.output {
  color: #d1d5db;
  white-space: pre-wrap;
}

.instructions-editor {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 20px;
  backdrop-filter: blur(10px);
}

.instructions-editor h3 {
  margin-bottom: 15px;
  color: #fbbf24;
}

.instructions-textarea {
  width: 100%;
  height: 200px;
  padding: 15px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.2);
  color: white;
  font-family: 'Monaco', 'Consolas', monospace;
  font-size: 13px;
  resize: vertical;
}

.instructions-textarea::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.btn-save-instructions {
  margin-top: 15px;
  width: auto;
  padding: 10px 20px;
}

.btn-save-instructions:disabled {
  background: #6b7280;
  cursor: not-allowed;
}

.history-panel {
  width: 350px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 20px;
  backdrop-filter: blur(10px);
}

.history-panel h3 {
  margin-bottom: 20px;
  color: #fbbf24;
}

.version-list {
  max-height: 600px;
  overflow-y: auto;
}

.version-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 15px;
  border-left: 4px solid #6b7280;
}

.version-item.current {
  border-left-color: #10b981;
  background: rgba(16, 185, 129, 0.1);
}

.version-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.version-date {
  font-size: 12px;
  color: #d1d5db;
}

.version-agent {
  font-weight: bold;
  color: #fbbf24;
  text-transform: capitalize;
}

.version-comment {
  font-size: 13px;
  color: #9ca3af;
  margin-bottom: 10px;
  font-style: italic;
}

.version-actions {
  display: flex;
  gap: 8px;
}

.btn-preview, .btn-restore, .btn-delete {
  padding: 6px 10px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s ease;
}

.btn-preview {
  background: #6366f1;
  color: white;
}

.btn-restore {
  background: #10b981;
  color: white;
}

.btn-delete {
  background: #ef4444;
  color: white;
}

.btn-preview:hover, .btn-restore:hover, .btn-delete:hover {
  transform: translateY(-1px);
  opacity: 0.8;
}

.no-versions {
  text-align: center;
  color: #9ca3af;
  font-style: italic;
  padding: 40px 20px;
}

/* Modals */
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
  background: #1f2937;
  border-radius: 12px;
  padding: 30px;
  min-width: 400px;
  max-width: 90vw;
  max-height: 90vh;
  color: white;
}

.modal-content.large {
  min-width: 600px;
}

.modal-content h3 {
  margin-bottom: 20px;
  color: #fbbf24;
}

.save-form label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
  color: #d1d5db;
}

.save-form input, .save-form textarea {
  width: 100%;
  padding: 10px;
  margin-bottom: 15px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.readonly-input {
  background: rgba(255, 255, 255, 0.05);
  cursor: not-allowed;
}

.modal-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 20px;
}

.btn-confirm, .btn-cancel, .btn-close {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
}

.btn-confirm {
  background: #10b981;
  color: white;
}

.btn-cancel {
  background: #6b7280;
  color: white;
}

.btn-close {
  background: #3b82f6;
  color: white;
}

.preview-content {
  max-height: 400px;
  overflow-y: auto;
  background: #374151;
  border-radius: 8px;
  padding: 20px;
}

.preview-content pre {
  white-space: pre-wrap;
  font-family: 'Monaco', 'Consolas', monospace;
  font-size: 13px;
  color: #d1d5db;
  margin: 0;
}

/* Scrollbars */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.5);
}
</style>