<template>
  <div class="tmux-config">
    <div class="config-editor">
      <h3>📝 Configuration Notifications Tmux</h3>
      <p class="hint">Modifiez directement le fichier de configuration JSON ci-dessous:</p>
      
      <textarea 
        v-model="configText" 
        class="config-textarea"
        @input="hasChanges = true"
        spellcheck="false"
      ></textarea>
      
      <div class="action-buttons">
        <button @click="saveConfig" class="btn-save" :disabled="!hasChanges">
          💾 Sauvegarder
        </button>
        <button @click="reloadConfig" class="btn-reload">
          🔄 Recharger
        </button>
        <button @click="restartMailServer" class="btn-restart">
          🔁 Redémarrer Mail Server
        </button>
      </div>
      
      <div v-if="message" :class="['message', messageType]">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const configText = ref('')
const hasChanges = ref(false)
const message = ref('')
const messageType = ref('')

const showMessage = (text, type = 'success') => {
  message.value = text
  messageType.value = type
  setTimeout(() => {
    message.value = ''
  }, 3000)
}

const loadConfig = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/tmux-config')
    const data = await response.json()
    configText.value = JSON.stringify(data.config, null, 2)
    hasChanges.value = false
  } catch (error) {
    showMessage('Erreur lors du chargement de la configuration', 'error')
  }
}

const saveConfig = async () => {
  try {
    // Valider le JSON
    const config = JSON.parse(configText.value)
    
    const response = await fetch('http://localhost:3001/api/tmux-config', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ config })
    })
    
    if (response.ok) {
      showMessage('✅ Configuration sauvegardée avec succès')
      hasChanges.value = false
    } else {
      showMessage('Erreur lors de la sauvegarde', 'error')
    }
  } catch (error) {
    if (error instanceof SyntaxError) {
      showMessage('⚠️ JSON invalide - vérifiez la syntaxe', 'error')
    } else {
      showMessage('Erreur lors de la sauvegarde', 'error')
    }
  }
}

const reloadConfig = async () => {
  if (hasChanges.value) {
    if (!confirm('Des modifications non sauvegardées seront perdues. Continuer?')) {
      return
    }
  }
  await loadConfig()
  showMessage('Configuration rechargée')
}

const restartMailServer = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/restart-mail-server', {
      method: 'POST'
    })
    
    if (response.ok) {
      showMessage('🔄 Mail server redémarré')
    }
  } catch (error) {
    showMessage('Erreur lors du redémarrage', 'error')
  }
}

onMounted(() => {
  loadConfig()
})
</script>

<style scoped>
.tmux-config {
  padding: 20px;
  height: 100%;
  overflow-y: auto;
}

.config-editor {
  max-width: 900px;
  margin: 0 auto;
}

h3 {
  color: #fff;
  margin-bottom: 10px;
}

.hint {
  color: #999;
  font-size: 14px;
  margin-bottom: 15px;
}

.config-textarea {
  width: 100%;
  min-height: 500px;
  background: #1a1a1a;
  color: #f0f0f0;
  border: 1px solid #444;
  border-radius: 8px;
  padding: 15px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  font-size: 13px;
  line-height: 1.6;
  resize: vertical;
  white-space: pre;
  overflow-wrap: normal;
  overflow-x: auto;
}

.config-textarea:focus {
  outline: none;
  border-color: #4CAF50;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
}

.action-buttons {
  display: flex;
  gap: 10px;
  margin-top: 15px;
}

.btn-save, .btn-reload, .btn-restart {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-save {
  background: #4CAF50;
  color: white;
}

.btn-save:hover:not(:disabled) {
  background: #45a049;
  transform: translateY(-1px);
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-reload {
  background: #2196F3;
  color: white;
}

.btn-reload:hover {
  background: #1976D2;
  transform: translateY(-1px);
}

.btn-restart {
  background: #FF9800;
  color: white;
}

.btn-restart:hover {
  background: #F57C00;
  transform: translateY(-1px);
}

.message {
  margin-top: 15px;
  padding: 10px 15px;
  border-radius: 6px;
  font-size: 14px;
  animation: slideIn 0.3s ease;
}

.message.success {
  background: rgba(76, 175, 80, 0.2);
  border: 1px solid #4CAF50;
  color: #4CAF50;
}

.message.error {
  background: rgba(244, 67, 54, 0.2);
  border: 1px solid #f44336;
  color: #f44336;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>