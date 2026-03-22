<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-container">
      <div class="modal-header">
        <h2>📎 Attacher PRD au Projet</h2>
        <button class="btn-close" @click="$emit('close')">✕</button>
      </div>

      <div class="modal-content">
        <div class="form-group">
          <label>Sélectionner le fichier PRD (.md)</label>
          <div class="file-browser">
            <input
              type="text"
              v-model="selectedPRDPath"
              placeholder="Cliquez sur Browser pour sélectionner votre PRD"
              class="form-input path-input"
              readonly
            >
            <button @click="browsePRDFile" class="btn-browse">
              📄 Browser PRD
            </button>
          </div>
          <div v-if="selectedPRDInfo" class="project-info">
            <strong>PRD sélectionné:</strong> {{ selectedPRDInfo.name }}<br>
            <strong>Projet détecté:</strong> {{ selectedPRDInfo.projectName }}
          </div>
        </div>

        <div class="prd-preview" v-if="selectedPRD && prdContent">
          <h3>📋 Aperçu du PRD</h3>
          <div class="prd-content">{{ prdContent.substring(0, 500) }}...</div>
        </div>

        <div class="form-actions">
          <button @click="$emit('close')" class="btn-cancel">
            Annuler
          </button>
          <button @click="attachPRD" class="btn-attach" :disabled="!canAttach">
            📎 Créer Projet et Attacher PRD
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'

export default {
  name: 'AttachPRDModal',
  props: {
    projects: Array
  },
  emits: ['close', 'attached'],
  setup(props, { emit }) {
    const selectedPRDPath = ref('')
    const selectedPRDInfo = ref(null)
    const selectedPRD = ref('')
    const prdContent = ref('')

    const canAttach = computed(() => {
      return selectedPRDPath.value && selectedPRDInfo.value && prdContent.value
    })

    const formatDate = (dateStr) => {
      return new Date(dateStr).toLocaleDateString('fr-FR')
    }

    const loadPRDs = async () => {
      try {
        const response = await fetch('http://localhost:3001/api/prds')
        const data = await response.json()
        availablePRDs.value = data.prds || []
      } catch (error) {
        console.error('Error loading PRDs:', error)
        availablePRDs.value = []
      }
    }

    // Load all projects (even without PRDs) for the attachment modal
    const loadAllProjects = async () => {
      try {
        const response = await fetch('http://localhost:3001/api/projects?include_all=true')
        const data = await response.json()
        return data || []
      } catch (error) {
        console.error('Error loading all projects:', error)
        return []
      }
    }

    const browsePRDFile = async () => {
      try {
        // Utilisation de l'API File System Access pour sélectionner un fichier
        if ('showOpenFilePicker' in window) {
          const [fileHandle] = await window.showOpenFilePicker({
            types: [{
              description: 'Fichiers Markdown',
              accept: { 'text/markdown': ['.md'] }
            }],
            multiple: false
          })

          const file = await fileHandle.getFile()
          const content = await file.text()

          selectedPRDPath.value = file.name
          prdContent.value = content

          // Détecter le nom du projet depuis le chemin du fichier
          const projectName = file.name.replace('.md', '').replace(/[-_]/g, ' ')
          selectedPRDInfo.value = {
            name: file.name,
            projectName: projectName,
            path: file.name
          }

        } else {
          // Fallback pour browsers plus anciens
          const input = document.createElement('input')
          input.type = 'file'
          input.accept = '.md'
          input.addEventListener('change', async (e) => {
            const file = e.target.files[0]
            if (file) {
              const content = await file.text()
              selectedPRDPath.value = file.name
              prdContent.value = content

              const projectName = file.name.replace('.md', '').replace(/[-_]/g, ' ')
              selectedPRDInfo.value = {
                name: file.name,
                projectName: projectName,
                path: file.name
              }
            }
          })
          input.click()
        }
      } catch (error) {
        console.error('Error browsing PRD file:', error)
        alert('Erreur lors de la sélection du fichier PRD')
      }
    }

    const onPRDChange = async () => {
      if (!selectedPRD.value) {
        prdContent.value = ''
        return
      }

      try {
        const response = await fetch(`http://localhost:3001/api/prds/${selectedPRD.value.name}`)
        const data = await response.json()
        prdContent.value = data.content || ''
      } catch (error) {
        console.error('Error loading PRD content:', error)
        prdContent.value = ''
      }
    }

    const attachPRD = async () => {
      if (!canAttach.value) return

      try {
        // Créer le projet avec le PRD sélectionné
        const createResponse = await fetch('http://localhost:3001/api/projects', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: selectedPRDInfo.value.projectName,
            path: selectedPRDPath.value,
            prd: selectedPRDInfo.value.name,
            prd_content: prdContent.value
          })
        })

        if (createResponse.ok) {
          const projectData = await createResponse.json()
          emit('attached', {
            projectId: projectData.id,
            projectName: selectedPRDInfo.value.projectName,
            projectPath: selectedPRDPath.value,
            prdName: selectedPRDInfo.value.name,
            prdContent: prdContent.value
          })
          emit('close')
        } else {
          const error = await createResponse.json()
          alert(`Erreur: ${error.error || 'Impossible de créer le projet et attacher le PRD'}`)
        }
      } catch (error) {
        console.error('Error attaching PRD:', error)
        alert('Erreur lors de l\'attachement du PRD')
      }
    }

    onMounted(() => {
      loadPRDs()
    })

    return {
      selectedPRDPath,
      selectedPRDInfo,
      selectedPRD,
      prdContent,
      canAttach,
      formatDate,
      browsePRDFile,
      attachPRD
    }
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-container {
  background: white;
  border-radius: 15px;
  width: 90%;
  max-width: 700px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  border: 3px solid #333;
}

.modal-header {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px 12px 0 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 3px solid #333;
}

.modal-header h2 {
  margin: 0;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.5em;
}

.btn-close {
  background: white;
  color: #333;
  border: 2px solid #333;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  font-size: 1.2em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-close:hover {
  transform: rotate(90deg);
  background: #ff6b6b;
  color: white;
}

.modal-content {
  padding: 30px;
  overflow-y: auto;
  flex: 1;
}

.form-group {
  margin-bottom: 25px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: bold;
  color: #333;
  font-size: 1.1em;
}

.form-select {
  width: 100%;
  padding: 12px;
  border: 2px solid #333;
  border-radius: 8px;
  font-size: 1em;
  background: white;
  transition: all 0.3s ease;
}

.form-select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.prd-preview {
  background: #f8f9fa;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  margin-top: 20px;
}

.prd-preview h3 {
  margin: 0 0 15px 0;
  color: #333;
}

.prd-content {
  font-family: 'Courier New', monospace;
  font-size: 0.9em;
  line-height: 1.5;
  color: #666;
  white-space: pre-wrap;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 15px;
  padding-top: 20px;
  border-top: 2px solid #f0f0f0;
  margin-top: 30px;
}

.btn-cancel,
.btn-attach {
  padding: 12px 24px;
  border: 3px solid #333;
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1em;
}

.btn-cancel {
  background: #f8f9fa;
  color: #333;
}

.btn-cancel:hover {
  background: #e9ecef;
  transform: translateY(-2px);
}

.btn-attach {
  background: linear-gradient(145deg, #667eea, #764ba2);
  color: white;
}

.btn-attach:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(102, 126, 234, 0.3);
}

.btn-attach:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.file-browser {
  display: flex;
  gap: 10px;
  align-items: center;
}

.path-input {
  flex: 1;
  padding: 12px;
  border: 2px solid #333;
  border-radius: 8px;
  font-size: 1em;
  transition: all 0.3s ease;
}

.path-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.btn-browse {
  padding: 12px 20px;
  background: linear-gradient(145deg, #28a745, #20c997);
  color: white;
  border: 3px solid #333;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  white-space: nowrap;
}

.btn-browse:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(40, 167, 69, 0.3);
}

.project-info {
  margin-top: 10px;
  padding: 10px;
  background: #e8f5e8;
  border: 2px solid #28a745;
  border-radius: 8px;
  color: #155724;
}
</style>