<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>📋 Documentation Centralisée</h2>
        <button @click="$emit('close')" class="close-btn">✕</button>
      </div>

      <div class="docs-viewer">
        <!-- Sélecteur de documents -->
        <div class="docs-sidebar">
          <h3>📁 Documents</h3>
          <div class="doc-list">
            <div
              v-for="doc in availableDocs"
              :key="doc.id"
              @click="selectDoc(doc)"
              class="doc-item"
              :class="{ active: selectedDoc?.id === doc.id }"
            >
              <span class="doc-icon">{{ doc.icon }}</span>
              <span class="doc-name">{{ doc.name }}</span>
            </div>
          </div>
        </div>

        <!-- Contenu du document -->
        <div class="docs-content">
          <div v-if="!selectedDoc" class="no-doc-selected">
            <div class="placeholder-icon">📖</div>
            <h3>Sélectionnez un document</h3>
            <p>Choisissez un document dans la liste pour afficher son contenu.</p>
          </div>

          <div v-else class="doc-display">
            <div class="doc-header">
              <h3>{{ selectedDoc.icon }} {{ selectedDoc.name }}</h3>
              <div class="doc-meta">
                <span class="doc-size">{{ docContent.length }} caractères</span>
                <button @click="copyDocContent" class="copy-btn" title="Copier le contenu">
                  📋 Copier
                </button>
              </div>
            </div>

            <div class="doc-content">
              <div v-if="loading" class="loading">
                🔄 Chargement...
              </div>
              <div v-else-if="error" class="error">
                ❌ Erreur: {{ error }}
              </div>
              <pre v-else class="markdown-content">{{ docContent }}</pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

defineProps({
  isOpen: Boolean
})

defineEmits(['close'])

const selectedDoc = ref(null)
const docContent = ref('')
const loading = ref(false)
const error = ref('')

// Documents disponibles (à étendre selon besoins)
const availableDocs = ref([
  {
    id: 'claude-tintin',
    name: 'Instructions Tintin',
    icon: '🚀',
    path: '/Users/studio_m3/moulinsart/CLAUDE.md'
  },
  {
    id: 'claude-haddock',
    name: 'Instructions Haddock',
    icon: '⚓',
    path: '/Users/studio_m3/moulinsart/agents/haddock/CLAUDE.md'
  },
  {
    id: 'outils-equipe',
    name: 'Outils Équipe',
    icon: '🧰',
    path: '/Users/studio_m3/moulinsart/OUTILS_EQUIPE.md'
  },
  {
    id: 'architecture',
    name: 'Architecture Système',
    icon: '🏗️',
    content: `# 🏗️ Architecture Système Moulinsart

## Services Core
- **Oracle API** : localhost:3001 - Gestion événements
- **Mail Server** : localhost:1080 - Emails agents
- **Vue Dashboard** : localhost:5175 - Interface utilisateur

## Agents
### 🎩 TMUX Nestor
- Nestor (Panel 0) - nestor@moulinsart.local
- Tintin (Panel 1) - tintin@moulinsart.local
- Dupont1 (Panel 2) - dupont1@moulinsart.local
- Dupont2 (Panel 3) - dupont2@moulinsart.local

### ⚓ TMUX Haddock
- Haddock (Panel 0) - haddock@moulinsart.local
- Rastapopoulos (Panel 1) - rastapopoulos@moulinsart.local
- Tournesol1 (Panel 2) - tournesol1@moulinsart.local
- Tournesol2 (Panel 3) - tournesol2@moulinsart.local

## Communication
- Email uniquement via @moulinsart.local
- Notifications TMUX pour alertes
- Dashboard temps réel pour supervision`
  }
])

const selectDoc = async (doc) => {
  selectedDoc.value = doc
  loading.value = true
  error.value = ''

  try {
    if (doc.content) {
      // Contenu inline
      docContent.value = doc.content
    } else if (doc.path) {
      // Charger depuis fichier (simulation - en réalité il faudrait une API)
      const response = await fetch(`/api/docs?path=${encodeURIComponent(doc.path)}`)
      if (response.ok) {
        docContent.value = await response.text()
      } else {
        throw new Error(`Impossible de charger ${doc.path}`)
      }
    }
  } catch (err) {
    error.value = err.message
    docContent.value = ''
  } finally {
    loading.value = false
  }
}

const copyDocContent = async () => {
  try {
    await navigator.clipboard.writeText(docContent.value)
    // Feedback visuel temporaire
    const btn = document.querySelector('.copy-btn')
    const originalText = btn.textContent
    btn.textContent = '✅ Copié!'
    setTimeout(() => {
      btn.textContent = originalText
    }, 2000)
  } catch (err) {
    console.error('Erreur copie:', err)
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
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.2s;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 95%;
  max-width: 1400px;
  height: 85vh;
  overflow: hidden;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
  animation: slideUp 0.3s;
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 20px;
  border-bottom: 2px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
  color: white;
  border-radius: 12px 12px 0 0;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5em;
}

.close-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  font-size: 24px;
  cursor: pointer;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  transition: background 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.docs-viewer {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.docs-sidebar {
  width: 300px;
  background: #f8f9fa;
  border-right: 2px solid #e0e0e0;
  padding: 20px;
  overflow-y: auto;
}

.docs-sidebar h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.1em;
}

.doc-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.doc-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.doc-item:hover {
  background: #e3f2fd;
  border-color: #4a90e2;
  transform: translateX(5px);
}

.doc-item.active {
  background: #4a90e2;
  border-color: #357abd;
  color: white;
}

.doc-icon {
  font-size: 1.3em;
}

.doc-name {
  font-weight: 500;
  font-size: 0.9em;
}

.docs-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.no-doc-selected {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #666;
  padding: 40px;
}

.placeholder-icon {
  font-size: 4em;
  margin-bottom: 20px;
  opacity: 0.5;
}

.no-doc-selected h3 {
  margin: 0 0 10px 0;
  font-size: 1.5em;
}

.no-doc-selected p {
  margin: 0;
  text-align: center;
  line-height: 1.5;
}

.doc-display {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.doc-header {
  padding: 20px;
  border-bottom: 2px solid #f0f0f0;
  background: #fafafa;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.doc-header h3 {
  margin: 0;
  color: #333;
  font-size: 1.2em;
}

.doc-meta {
  display: flex;
  align-items: center;
  gap: 15px;
}

.doc-size {
  color: #666;
  font-size: 0.9em;
}

.copy-btn {
  background: #4a90e2;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.2s;
}

.copy-btn:hover {
  background: #357abd;
  transform: translateY(-1px);
}

.doc-content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

.loading, .error {
  text-align: center;
  padding: 40px;
  font-size: 1.1em;
}

.error {
  color: #e53e3e;
}

.markdown-content {
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 14px;
  line-height: 1.6;
  color: #333;
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
  white-space: pre-wrap;
  word-wrap: break-word;
  margin: 0;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
</style>