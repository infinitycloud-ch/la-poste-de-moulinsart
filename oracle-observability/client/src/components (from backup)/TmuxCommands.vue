<template>
  <div class="tmux-commands-container">
    <div class="commands-header">
      <h2>🖥️ Messages TMUX Personnalisés</h2>
      <button @click="showCreateModal = true" class="btn-create">
        ➕ Nouveau Message
      </button>
    </div>

    <!-- Liste des messages -->
    <div class="commands-grid">
      <div v-for="command in commands" :key="command.id" class="command-card">
        <div class="command-header">
          <span class="command-icon">{{ command.icon || '💬' }}</span>
          <span class="command-name">{{ command.name }}</span>
          <div class="command-actions">
            <button @click="editCommand(command)" class="btn-edit">✏️</button>
            <button @click="deleteCommand(command.id)" class="btn-delete">🗑️</button>
          </div>
        </div>
        <div class="command-content">
          <pre>{{ command.message }}</pre>
        </div>
        <div class="command-footer">
          <span class="command-category">{{ command.category || 'Général' }}</span>
          <span class="command-date">{{ formatDate(command.created_at) }}</span>
        </div>
      </div>
    </div>

    <!-- Modal de création/édition -->
    <div v-if="showCreateModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingCommand ? '✏️ Modifier' : '➕ Créer' }} un Message TMUX</h3>
          <button @click="closeModal" class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Nom du message:</label>
            <input v-model="formData.name" placeholder="Ex: Réveil urgent" />
          </div>
          <div class="form-group">
            <label>Icône:</label>
            <input v-model="formData.icon" placeholder="Ex: 🚨" maxlength="2" />
          </div>
          <div class="form-group">
            <label>Catégorie:</label>
            <select v-model="formData.category">
              <option>Général</option>
              <option>Réveil</option>
              <option>Debug</option>
              <option>Workflow</option>
              <option>Test</option>
            </select>
          </div>
          <div class="form-group">
            <label>Message TMUX:</label>
            <textarea 
              v-model="formData.message" 
              rows="15" 
              placeholder="Entrez votre message TMUX...
Utilisez \n pour les retours à la ligne"
            ></textarea>
          </div>
          <div class="form-group">
            <label>Variables disponibles:</label>
            <div class="variables-help">
              <code>{agent}</code> - Nom de l'agent<br>
              <code>{email}</code> - Email de l'agent<br>
              <code>{time}</code> - Heure actuelle<br>
              <code>{date}</code> - Date actuelle
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="saveCommand" class="btn-save">
            💾 {{ editingCommand ? 'Modifier' : 'Sauvegarder' }}
          </button>
          <button @click="closeModal" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const commands = ref([])
const showCreateModal = ref(false)
const editingCommand = ref(null)
const formData = ref({
  name: '',
  icon: '💬',
  category: 'Général',
  message: ''
})

// Charger les commandes depuis la base
const loadCommands = async () => {
  try {
    const response = await fetch('http://localhost:3001/api/tmux-commands')
    if (response.ok) {
      const data = await response.json()
      commands.value = data.commands || []
    }
  } catch (err) {
    console.error('Erreur chargement commandes:', err)
    // Commandes par défaut si la base est vide
    commands.value = [
      {
        id: 1,
        name: 'Réveil Simple',
        icon: '🔔',
        category: 'Réveil',
        message: '🔔 RÉVEIL AGENT\n━━━━━━━━━━━━━━━━━━━━\n📧 Vérifie tes emails!\n\ncurl http://localhost:1080/api/mailbox/{email}',
        created_at: new Date().toISOString()
      },
      {
        id: 2,
        name: 'Debug Mode',
        icon: '🐛',
        category: 'Debug',
        message: '🐛 MODE DEBUG ACTIVÉ\n━━━━━━━━━━━━━━━━━━━━\nAffiche les logs détaillés\ntail -f /tmp/oracle.log',
        created_at: new Date().toISOString()
      },
      {
        id: 3,
        name: 'Pause',
        icon: '⏸️',
        category: 'Workflow',
        message: '⏸️ PAUSE DEMANDÉE\n━━━━━━━━━━━━━━━━━━━━\nMets ton travail en pause\nAttends de nouvelles instructions',
        created_at: new Date().toISOString()
      }
    ]
  }
}

// Sauvegarder une commande
const saveCommand = async () => {
  try {
    const endpoint = editingCommand.value 
      ? `http://localhost:3001/api/tmux-commands/${editingCommand.value.id}`
      : 'http://localhost:3001/api/tmux-commands'
    
    const method = editingCommand.value ? 'PUT' : 'POST'
    
    const response = await fetch(endpoint, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData.value)
    })
    
    if (response.ok) {
      closeModal()
      // Recharger les commandes après fermeture du modal
      setTimeout(() => loadCommands(), 100)
    }
  } catch (err) {
    console.error('Erreur sauvegarde:', err)
    // Ajouter localement si l'API échoue
    if (editingCommand.value) {
      const index = commands.value.findIndex(c => c.id === editingCommand.value.id)
      if (index !== -1) {
        commands.value[index] = { ...commands.value[index], ...formData.value }
      }
    } else {
      commands.value.push({
        id: Date.now(),
        ...formData.value,
        created_at: new Date().toISOString()
      })
    }
    closeModal()
  }
}

// Éditer une commande
const editCommand = (command) => {
  editingCommand.value = command
  formData.value = {
    name: command.name,
    icon: command.icon || '💬',
    category: command.category || 'Général',
    message: command.message
  }
  showCreateModal.value = true
}

// Supprimer une commande
const deleteCommand = async (id) => {
  if (!confirm('Supprimer ce message ?')) return
  
  try {
    const response = await fetch(`http://localhost:3001/api/tmux-commands/${id}`, {
      method: 'DELETE'
    })
    
    if (response.ok) {
      commands.value = commands.value.filter(c => c.id !== id)
    }
  } catch (err) {
    console.error('Erreur suppression:', err)
    // Supprimer localement si l'API échoue
    commands.value = commands.value.filter(c => c.id !== id)
  }
}

// Fermer le modal
const closeModal = () => {
  showCreateModal.value = false
  editingCommand.value = null
  formData.value = {
    name: '',
    icon: '💬',
    category: 'Général',
    message: ''
  }
}

// Formater la date
const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('fr-FR')
}

// Exposer les commandes pour le composant parent
defineExpose({
  commands,
  loadCommands
})

onMounted(() => {
  loadCommands()
})
</script>

<style scoped>
.tmux-commands-container {
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 20px;
  background: #f9f9f9;
}

.commands-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 3px solid #ff6b6b;
}

.commands-header h2 {
  margin: 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  text-shadow: 1px 1px 0px #fff;
}

.btn-create {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
  border: 2px solid #333;
  border-radius: 20px;
  padding: 10px 20px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.btn-create:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.3);
}

.commands-grid {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow-y: auto;
  padding-right: 10px;
}

.command-card {
  background: white;
  border: 2px solid #333;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 2px 2px 0px #333;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
}

.command-card:hover {
  transform: translateX(2px);
  box-shadow: 3px 3px 0px #333;
}

.command-header {
  background: linear-gradient(135deg, #ffd93d 0%, #ffb347 100%);
  padding: 8px 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  border-bottom: 2px solid #333;
}

.command-icon {
  font-size: 1.1em;
}

.command-name {
  flex: 1;
  font-weight: bold;
  color: #333;
  font-size: 0.85em;
}

.command-actions {
  display: flex;
  gap: 5px;
}

.btn-edit, .btn-delete {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1em;
  transition: transform 0.2s;
  opacity: 0.7;
}

.btn-edit:hover, .btn-delete:hover {
  transform: scale(1.1);
  opacity: 1;
}

.command-content {
  padding: 10px;
  background: #f5f5f5;
  max-height: 60px;
  overflow: hidden;
  position: relative;
}

.command-content pre {
  margin: 0;
  font-family: 'Courier New', monospace;
  font-size: 0.8em;
  white-space: pre-wrap;
  color: #666;
  line-height: 1.3;
}

.command-footer {
  padding: 6px 10px;
  background: #fff;
  border-top: 1px solid #e0e0e0;
  display: flex;
  justify-content: space-between;
  font-size: 0.75em;
  color: #666;
}

.command-category {
  background: #4a90e2;
  color: white;
  padding: 2px 8px;
  border-radius: 10px;
  font-weight: bold;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 15px;
  border: 3px solid #333;
  width: 600px;
  max-width: 90%;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 50px rgba(0,0,0,0.5);
}

.modal-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 12px 12px 0 0;
}

.modal-header h3 {
  margin: 0;
  font-family: 'Comic Sans MS', cursive;
}

.modal-close {
  background: none;
  border: none;
  color: white;
  font-size: 2em;
  cursor: pointer;
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

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
  color: #333;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 10px;
  border: 2px solid #333;
  border-radius: 8px;
  font-family: inherit;
  font-size: 0.95em;
}

.form-group textarea {
  font-family: 'Courier New', monospace;
  resize: vertical;
}

.variables-help {
  background: #f5f5f5;
  padding: 10px;
  border-radius: 8px;
  border: 1px solid #ddd;
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
}

.variables-help code {
  background: #ffd93d;
  padding: 2px 4px;
  border-radius: 3px;
  font-weight: bold;
}

.modal-footer {
  padding: 20px;
  background: #f5f5f5;
  border-top: 2px solid #333;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  border-radius: 0 0 12px 12px;
}

.btn-save {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
  border: 2px solid #333;
  padding: 10px 25px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
}

.btn-save:hover {
  transform: scale(1.05);
}

.btn-cancel {
  background: #ccc;
  color: #333;
  border: 2px solid #333;
  padding: 10px 25px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s;
}

.btn-cancel:hover {
  background: #bbb;
}
</style>