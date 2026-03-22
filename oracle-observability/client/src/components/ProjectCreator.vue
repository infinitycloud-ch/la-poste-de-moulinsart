<template>
  <div class="project-creator">
    <!-- Sélecteur de projet actif -->
    <div class="project-selector-section">
      <h3>📁 Projet Actif</h3>
      <div class="project-selector">
        <select v-model="activeProject" @change="switchProject">
          <option value="moulinsart">🏰 Moulinsart (Défaut)</option>
          <option v-for="project in projects" :key="project.name" :value="project.name">
            {{ project.icon }} {{ project.name }} - @{{ project.domain }}
          </option>
        </select>
        <button @click="showCreateForm = !showCreateForm" class="btn-new-project">
          ➕ Nouveau Projet
        </button>
      </div>
    </div>

    <!-- Formulaire de création -->
    <div v-if="showCreateForm" class="creation-form">
      <h3>🚀 Créer une Nouvelle Équipe</h3>
      
      <div class="form-group">
        <label>Nom du projet:</label>
        <input 
          v-model="newProject.name" 
          @input="updateDomain"
          placeholder="ex: ios-app"
          maxlength="20"
        />
        <span class="domain-preview">Domaine: @{{ projectDomain }}.local</span>
      </div>

      <div class="form-group">
        <label>Type de projet:</label>
        <select v-model="newProject.type">
          <option value="ios">🍎 iOS (Swift)</option>
          <option value="web">🌐 Web (React/Node)</option>
          <option value="python">🐍 Python (API/Script)</option>
          <option value="custom">✨ Custom</option>
        </select>
      </div>

      <div class="agents-section">
        <h4>👥 Équipe (4 agents)</h4>
        <div class="agent-input">
          <label>Chef d'orchestre:</label>
          <input v-model="newProject.agents.chef" placeholder="ex: nestor">
          <span class="email-preview">{{ newProject.agents.chef || 'agent1' }}@{{ projectDomain }}.local</span>
        </div>
        <div class="agent-input">
          <label>QA/Testeur:</label>
          <input v-model="newProject.agents.qa" placeholder="ex: tintin">
          <span class="email-preview">{{ newProject.agents.qa || 'agent2' }}@{{ projectDomain }}.local</span>
        </div>
        <div class="agent-input">
          <label>Développeur 1:</label>
          <input v-model="newProject.agents.dev1" placeholder="ex: dupont1">
          <span class="email-preview">{{ newProject.agents.dev1 || 'agent3' }}@{{ projectDomain }}.local</span>
        </div>
        <div class="agent-input">
          <label>Développeur 2:</label>
          <input v-model="newProject.agents.dev2" placeholder="ex: dupont2">
          <span class="email-preview">{{ newProject.agents.dev2 || 'agent4' }}@{{ projectDomain }}.local</span>
        </div>
      </div>

      <div class="form-actions">
        <button @click="createProject" class="btn-create" :disabled="!isFormValid">
          🚀 Créer l'Équipe
        </button>
        <button @click="cancelCreate" class="btn-cancel">
          ❌ Annuler
        </button>
      </div>
    </div>

    <!-- Liste des projets actifs -->
    <div v-if="projects.length > 0" class="active-projects">
      <h3>📊 Projets Actifs</h3>
      <div class="projects-list">
        <div v-for="project in projects" :key="project.name" class="project-card">
          <div class="project-header">
            <span class="project-name">{{ project.icon }} {{ project.name }}</span>
            <span class="project-status" :class="{ active: project.active }">
              {{ project.active ? '🟢' : '⚫' }}
            </span>
          </div>
          <div class="project-info">
            <div>Domaine: @{{ project.domain }}</div>
            <div>Session: {{ project.session }}</div>
            <div>Créé: {{ formatDate(project.created) }}</div>
          </div>
          <div class="project-commands">
            <div class="command-line">
              <strong>Lancer:</strong>
              <code @click="copyCommand(`./project-manager.sh launch ${project.name}`)">
                ./project-manager.sh launch {{ project.name }}
              </code>
              <span class="copy-hint">📋</span>
            </div>
            <div class="command-line">
              <strong>Attacher:</strong>
              <code @click="copyCommand(`tmux attach -t moulinsart-${project.name}`)">
                tmux attach -t moulinsart-{{ project.name }}
              </code>
              <span class="copy-hint">📋</span>
            </div>
          </div>
          <div class="project-actions">
            <button @click="launchProject(project.name)" class="btn-launch">
              🚀 Lancer
            </button>
            <button @click="stopProject(project)" class="btn-stop">
              ⏹️ Arrêter
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const showCreateForm = ref(false)
const activeProject = ref('moulinsart')
const projects = ref([])

const newProject = ref({
  name: '',
  type: 'ios',
  agents: {
    chef: '',
    qa: '',
    dev1: '',
    dev2: ''
  }
})

const projectDomain = computed(() => {
  if (!newProject.value.name) return 'projet'
  return newProject.value.name.toLowerCase().replace(/[^a-z0-9-]/g, '-')
})

const isFormValid = computed(() => {
  return newProject.value.name && 
         newProject.value.agents.chef &&
         newProject.value.agents.qa &&
         newProject.value.agents.dev1 &&
         newProject.value.agents.dev2
})

function updateDomain() {
  // Auto-format le nom du projet
  newProject.value.name = newProject.value.name.toLowerCase().replace(/\s+/g, '-')
}

async function createProject() {
  if (!isFormValid.value) return
  
  const projectData = {
    name: newProject.value.name,
    domain: `${projectDomain.value}.local`,
    type: newProject.value.type,
    agents: {
      agent1: newProject.value.agents.chef,
      agent2: newProject.value.agents.qa,
      agent3: newProject.value.agents.dev1,
      agent4: newProject.value.agents.dev2
    }
  }
  
  try {
    // Appeler l'API pour créer le projet
    const response = await fetch('http://localhost:3001/api/projects/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(projectData)
    })
    
    if (response.ok) {
      const result = await response.json()
      console.log('✅ Projet créé:', result)
      
      // Ajouter à la liste
      projects.value.push({
        ...projectData,
        session: `moulinsart-${projectData.name}`,
        created: new Date(),
        active: false,
        icon: getProjectIcon(projectData.type)
      })
      
      // Réinitialiser le formulaire
      cancelCreate()
      
      // Proposer de lancer le projet
      if (confirm(`Projet créé! Voulez-vous lancer la session tmux maintenant?`)) {
        launchProject(projectData.name)
      }
    }
  } catch (err) {
    console.error('Erreur création projet:', err)
    alert('Erreur lors de la création du projet')
  }
}

function cancelCreate() {
  showCreateForm.value = false
  newProject.value = {
    name: '',
    type: 'ios',
    agents: { chef: '', qa: '', dev1: '', dev2: '' }
  }
}

function switchProject() {
  console.log('Switching to project:', activeProject.value)
  // TODO: Mettre à jour l'interface pour afficher les emails du projet sélectionné
}

function copyCommand(command) {
  navigator.clipboard.writeText(command).then(() => {
    console.log('✅ Commande copiée:', command)
    // Feedback visuel temporaire
    const el = event.target
    const originalText = el.textContent
    el.style.background = '#48bb78'
    el.style.color = 'white'
    setTimeout(() => {
      el.style.background = ''
      el.style.color = ''
    }, 500)
  }).catch(err => {
    console.error('Erreur copie:', err)
    alert(`Commande à copier:\n${command}`)
  })
}

async function launchProject(projectName) {
  const command = `./project-manager.sh launch ${projectName}`
  copyCommand(command)
  alert(`Commande copiée! Exécutez dans le terminal:\n${command}`)
}

async function stopProject(project) {
  if (!confirm(`Arrêter le projet ${project.name}?`)) return
  
  const command = `tmux kill-session -t ${project.session}`
  console.log('Arrêt:', command)
  project.active = false
}

function getProjectIcon(type) {
  const icons = {
    ios: '🍎',
    web: '🌐',
    python: '🐍',
    custom: '✨'
  }
  return icons[type] || '📁'
}

function formatDate(date) {
  return new Date(date).toLocaleString('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit'
  })
}

// Charger les projets existants au démarrage
onMounted(async () => {
  try {
    const response = await fetch('http://localhost:3001/api/projects')
    if (response.ok) {
      const data = await response.json()
      projects.value = data.projects || []
    }
  } catch (err) {
    console.log('Pas de projets existants')
  }
})
</script>

<style scoped>
.project-creator {
  padding: 15px;
  background: #f9f9f9;
  border-radius: 8px;
  margin: 10px 0;
}

.project-selector-section {
  margin-bottom: 15px;
}

.project-selector-section h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1.1em;
}

.project-selector {
  display: flex;
  gap: 10px;
  align-items: center;
}

.project-selector select {
  flex: 1;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.btn-new-project {
  padding: 8px 15px;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.btn-new-project:hover {
  background: #45a049;
}

.creation-form {
  background: white;
  padding: 20px;
  border-radius: 8px;
  margin: 15px 0;
  border: 2px solid #4CAF50;
}

.creation-form h3 {
  margin: 0 0 15px 0;
  color: #333;
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
.form-group select {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.domain-preview {
  display: block;
  margin-top: 5px;
  color: #666;
  font-size: 0.9em;
}

.agents-section {
  margin: 20px 0;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 6px;
}

.agents-section h4 {
  margin: 0 0 15px 0;
  color: #333;
}

.agent-input {
  margin-bottom: 12px;
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 10px;
  align-items: center;
}

.agent-input label {
  font-weight: 500;
  color: #555;
}

.agent-input input {
  padding: 6px 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.email-preview {
  grid-column: 2;
  color: #666;
  font-size: 0.85em;
  margin-top: 3px;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.btn-create {
  flex: 1;
  padding: 12px;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  font-size: 16px;
}

.btn-create:hover:not(:disabled) {
  background: #45a049;
}

.btn-create:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-cancel {
  padding: 12px 20px;
  background: #f44336;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.btn-cancel:hover {
  background: #da190b;
}

.active-projects {
  margin-top: 20px;
}

.active-projects h3 {
  margin: 0 0 15px 0;
  color: #333;
}

.projects-list {
  display: grid;
  gap: 10px;
}

.project-card {
  background: white;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid #ddd;
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.project-name {
  font-weight: 500;
  color: #333;
}

.project-status.active {
  color: #4CAF50;
}

.project-info {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 10px;
}

.project-info div {
  margin: 2px 0;
}

.project-commands {
  margin: 10px 0;
  padding: 10px;
  background: #f0f0f0;
  border-radius: 4px;
  font-size: 0.85em;
}

.command-line {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 5px 0;
}

.command-line strong {
  color: #555;
  min-width: 70px;
}

.command-line code {
  flex: 1;
  background: #2d3748;
  color: #48bb78;
  padding: 5px 10px;
  border-radius: 4px;
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: all;
}

.command-line code:hover {
  background: #1a202c;
  transform: translateX(2px);
}

.copy-hint {
  font-size: 16px;
  opacity: 0.6;
}

.project-actions {
  display: flex;
  gap: 8px;
}

.project-actions button {
  padding: 5px 10px;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 0.85em;
}

.btn-launch {
  background: #4CAF50;
  color: white;
}

.btn-stop {
  background: #f44336;
  color: white;
}
</style>