<template>
  <div v-if="show" class="modal-overlay" @click="closeModal">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h2>📁 Créer un nouveau projet</h2>
        <button @click="closeModal" class="close-btn">×</button>
      </div>

      <div class="modal-body">
        <form @submit.prevent="createProject">
          <div class="form-group">
            <label for="projectName">Nom du projet:</label>
            <input
              id="projectName"
              v-model="projectName"
              type="text"
              placeholder="ex: MonoCLI_v2"
              required
              class="form-input"
            />
            <small class="help-text">
              Sera transformé en: {{ cleanProjectName }}
            </small>
          </div>

          <div class="form-group">
            <label for="prdContent">Contenu du PRD.md:</label>
            <textarea
              id="prdContent"
              v-model="prdContent"
              placeholder="# PRD - Mon Projet

## 🎯 Objectif
Décrire l'objectif du projet...

## 📋 Fonctionnalités
- Feature 1
- Feature 2

## 🔧 Spécifications techniques
..."
              required
              class="form-textarea"
              rows="15"
            ></textarea>
          </div>

          <div class="form-actions">
            <button type="button" @click="closeModal" class="btn-cancel">
              Annuler
            </button>
            <button
              type="submit"
              :disabled="creating || !projectName.trim() || !prdContent.trim()"
              class="btn-primary"
            >
              {{ creating ? '⏳ Création...' : '📁 Créer le projet' }}
            </button>
          </div>
        </form>

        <div v-if="error" class="error-message">
          ❌ {{ error }}
        </div>

        <div v-if="success" class="success-message">
          ✅ {{ success }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'created'])

const projectName = ref('')
const prdContent = ref('')
const creating = ref(false)
const error = ref('')
const success = ref('')

// Nom nettoyé en temps réel
const cleanProjectName = computed(() => {
  return projectName.value.replace(/[^a-zA-Z0-9_-]/g, '_').toLowerCase()
})

const createProject = async () => {
  if (!projectName.value.trim() || !prdContent.value.trim()) {
    error.value = 'Nom du projet et contenu PRD requis'
    return
  }

  creating.value = true
  error.value = ''
  success.value = ''

  try {
    const response = await fetch('http://localhost:3001/api/projects/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: projectName.value.trim(),
        prd_content: prdContent.value.trim()
      })
    })

    if (response.ok) {
      const result = await response.json()
      success.value = `Projet créé: ${result.name}`

      // Réinitialiser le formulaire
      projectName.value = ''
      prdContent.value = ''

      // Émettre l'événement de création
      emit('created', result)

      // Fermer le modal après 1.5s
      setTimeout(() => {
        closeModal()
      }, 1500)
    } else {
      const errorData = await response.json()
      error.value = errorData.error || 'Erreur lors de la création'
    }
  } catch (err) {
    error.value = 'Erreur de connexion'
    console.error('Error creating project:', err)
  } finally {
    creating.value = false
  }
}

const closeModal = () => {
  // Reset form
  projectName.value = ''
  prdContent.value = ''
  error.value = ''
  success.value = ''
  creating.value = false

  emit('close')
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.modal-content {
  background: linear-gradient(145deg, #1e293b 0%, #334155 100%);
  border-radius: 15px;
  width: 90%;
  max-width: 700px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
  border: 1px solid rgba(148, 163, 184, 0.2);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid rgba(148, 163, 184, 0.2);
}

.modal-header h2 {
  margin: 0;
  color: #e2e8f0;
  font-size: 1.3em;
}

.close-btn {
  background: none;
  border: none;
  color: #94a3b8;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: rgba(239, 68, 68, 0.2);
  color: #ef4444;
}

.modal-body {
  padding: 20px;
  color: #e2e8f0;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #f1f5f9;
}

.form-input {
  width: 100%;
  padding: 12px;
  border: 1px solid rgba(148, 163, 184, 0.3);
  border-radius: 8px;
  background: rgba(30, 41, 59, 0.7);
  color: #e2e8f0;
  font-size: 14px;
  transition: all 0.2s ease;
}

.form-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid rgba(148, 163, 184, 0.3);
  border-radius: 8px;
  background: rgba(30, 41, 59, 0.7);
  color: #e2e8f0;
  font-size: 14px;
  resize: vertical;
  min-height: 300px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
  transition: all 0.2s ease;
}

.form-textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.help-text {
  display: block;
  margin-top: 4px;
  color: #94a3b8;
  font-size: 12px;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 30px;
}

.btn-cancel, .btn-primary {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-cancel {
  background: rgba(148, 163, 184, 0.2);
  color: #e2e8f0;
  border: 1px solid rgba(148, 163, 184, 0.3);
}

.btn-cancel:hover {
  background: rgba(148, 163, 184, 0.3);
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6, #1e40af);
  color: white;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.btn-primary:hover:not(:disabled) {
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.error-message {
  margin-top: 15px;
  padding: 12px;
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 8px;
  color: #fca5a5;
}

.success-message {
  margin-top: 15px;
  padding: 12px;
  background: rgba(34, 197, 94, 0.1);
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: 8px;
  color: #86efac;
}
</style>