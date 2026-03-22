<template>
  <div class="documentation-modal" v-if="isVisible">
    <div class="modal-backdrop" @click="$emit('close')"></div>
    <div class="modal-content">
      <div class="modal-header">
        <h2>📚 Documentation Moulinsart</h2>
        <button @click="$emit('close')" class="close-btn">✖</button>
      </div>
      
      <div class="doc-tabs">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="{ active: activeTab === tab.id }"
          class="tab-btn"
        >
          {{ tab.icon }} {{ tab.title }}
        </button>
      </div>

      <div class="doc-content">
        <!-- Task Management System -->
        <div v-if="activeTab === 'tasks'" class="doc-section">
          <h3>🎯 Task Management Dashboard</h3>
          
          <div class="feature-box">
            <h4>📋 Concept</h4>
            <p>Remplace les emails par un système visuel de tâches avec validation obligatoire.</p>
          </div>

          <div class="feature-box">
            <h4>🔧 Comment ça marche</h4>
            <ol>
              <li><strong>Création de tâche</strong> : Bouton "➕ Create Task" ou "📋 Split PRD"</li>
              <li><strong>Assignation</strong> : Drag & drop vers un agent (Nestor, Tintin, Dupont1, Dupont2)</li>
              <li><strong>Statuts</strong> : TODO → IN_PROGRESS → VALIDATION → DONE</li>
              <li><strong>Validation obligatoire</strong> : Checkboxes avec preuves (screenshots, logs)</li>
            </ol>
          </div>

          <div class="feature-box">
            <h4>✅ Checkboxes obligatoires</h4>
            <ul>
              <li>☐ Code/Implementation complete</li>
              <li>☐ Screenshot taken (avec preview)</li>
              <li>☐ Build successful (avec log)</li>
              <li>☐ Visual validation (3+ langues)</li>
              <li>☐ Documentation updated</li>
            </ul>
            <p class="warning">⚠️ Impossible de passer en DONE sans TOUTES les checkboxes!</p>
          </div>

          <div class="feature-box">
            <h4>🤖 Pour les agents</h4>
            <pre>curl http://localhost:3001/api/tasks/agent/nestor</pre>
            <p>Les agents peuvent consulter leurs tâches via l'API au lieu des emails.</p>
          </div>
        </div>

        <!-- Project Duplication -->
        <div v-if="activeTab === 'duplication'" class="doc-section">
          <h3>🔄 Duplication de Projets</h3>
          
          <div class="feature-box">
            <h4>📦 Concept</h4>
            <p>Créer plusieurs fermes d'agents indépendantes pour travailler en parallèle.</p>
          </div>

          <div class="feature-box">
            <h4>🚀 Création rapide</h4>
            <pre>./project-manager.sh create nouveau-projet</pre>
            <p>Crée automatiquement :</p>
            <ul>
              <li>Session tmux : <code>nouveau-projet-agents</code></li>
              <li>Domaine email : <code>@nouveau-projet.local</code></li>
              <li>4 agents avec leurs boîtes mail</li>
            </ul>
          </div>

          <div class="feature-box">
            <h4>📧 Emails isolés</h4>
            <p>Chaque projet a son domaine :</p>
            <ul>
              <li>Projet 1 : nestor@projet1.local</li>
              <li>Projet 2 : nestor@projet2.local</li>
              <li>Moulinsart : nestor@moulinsart.local (par défaut)</li>
            </ul>
          </div>

          <div class="feature-box">
            <h4>🎮 Gestion</h4>
            <pre># Voir les projets actifs
tmux ls | grep agents

# Attacher à un projet
tmux attach -t nouveau-projet-agents

# Supprimer un projet
tmux kill-session -t nouveau-projet-agents</pre>
          </div>
        </div>

        <!-- Email System -->
        <div v-if="activeTab === 'email'" class="doc-section">
          <h3>📧 Système Email</h3>
          
          <div class="feature-box">
            <h4>📮 Architecture</h4>
            <ul>
              <li><strong>SMTP</strong> : Port 1025 (envoi)</li>
              <li><strong>HTTP API</strong> : Port 1080 (lecture)</li>
              <li><strong>Interface</strong> : http://localhost:1080</li>
              <li><strong>Monitoring</strong> : Auto-restart si crash</li>
            </ul>
          </div>

          <div class="feature-box">
            <h4>📤 Envoi d'email</h4>
            <pre># Méthode simple
./send-mail.sh destinataire@moulinsart.local "Sujet" "Message"

# SMTP direct
echo "Message" | curl --url "smtp://localhost:1025" \
  --mail-from "agent@moulinsart.local" \
  --mail-rcpt "destinataire@moulinsart.local" \
  --upload-file -</pre>
          </div>

          <div class="feature-box">
            <h4>📥 Lecture emails</h4>
            <pre># Via API
curl http://localhost:1080/api/mailbox/nestor@moulinsart.local

# Interface web
http://localhost:1080</pre>
          </div>

          <div class="feature-box">
            <h4>🔔 Notifications tmux</h4>
            <p>Quand un email arrive, l'agent reçoit une notification tmux avec :</p>
            <ul>
              <li>De qui vient l'email</li>
              <li>Le sujet</li>
              <li>La commande pour lire</li>
            </ul>
          </div>
        </div>

        <!-- Quick Commands -->
        <div v-if="activeTab === 'commands'" class="doc-section">
          <h3>⚡ Commandes Rapides</h3>
          
          <div class="command-group">
            <h4>🚀 Démarrage</h4>
            <pre># Tout démarrer
cd /Users/studio_m3/moulinsart/oracle-observability
./start-all.sh

# Ou manuellement
bun run server/index.ts &       # Oracle (3001)
bun run server/mail-server.ts & # Mail (1025/1080)
cd client && npm run dev &      # Interface (5175)</pre>
          </div>

          <div class="command-group">
            <h4>🔍 Vérifications</h4>
            <pre># Statut des services
curl http://localhost:3001/health  # Oracle
curl http://localhost:1080/api/emails | jq '.emails | length'  # Emails

# Logs
tail -f /tmp/oracle.log
tail -f /tmp/mail.log

# Processus
ps aux | grep -E "oracle|mail-server"</pre>
          </div>

          <div class="command-group">
            <h4>🎯 Tasks API</h4>
            <pre># Créer une tâche
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","assigned_to":"nestor"}'

# Voir les tâches d'un agent
curl http://localhost:3001/api/tasks/agent/nestor

# Valider une tâche
curl -X PUT http://localhost:3001/api/tasks/1/validate \
  -F "screenshot=@capture.png"</pre>
          </div>

          <div class="command-group">
            <h4>🔄 Duplication projet</h4>
            <pre># Créer nouveau projet
./project-manager.sh create alpha

# Via API
curl -X POST http://localhost:3001/api/create-project \
  -d '{"name":"beta","agents":["bob","alice"]}'</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'DocumentationModal',
  props: {
    isVisible: {
      type: Boolean,
      default: false
    }
  },
  setup() {
    const activeTab = ref('tasks')
    
    const tabs = [
      { id: 'tasks', title: 'Task Dashboard', icon: '🎯' },
      { id: 'duplication', title: 'Duplication', icon: '🔄' },
      { id: 'email', title: 'Emails', icon: '📧' },
      { id: 'commands', title: 'Commandes', icon: '⚡' }
    ]
    
    return {
      activeTab,
      tabs
    }
  }
}
</script>

<style scoped>
.documentation-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
}

.modal-backdrop {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
}

.modal-content {
  position: relative;
  width: 95% !important;
  max-width: 1400px !important;
  height: 80vh;
  margin: 5vh auto;
  background: white;
  border-radius: 15px;
  border: 3px solid #333;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  margin: 0;
  font-family: 'Comic Sans MS', cursive;
}

.close-btn {
  background: white;
  color: #333;
  border: none;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  cursor: pointer;
  font-size: 20px;
}

.doc-tabs {
  display: flex;
  background: #f0f0f0;
  border-bottom: 2px solid #333;
}

.tab-btn {
  flex: 1;
  padding: 15px;
  background: transparent;
  border: none;
  border-right: 1px solid #ccc;
  cursor: pointer;
  font-family: 'Comic Sans MS', cursive;
  font-size: 14px;
  transition: all 0.3s;
}

.tab-btn:hover {
  background: #e0e0e0;
}

.tab-btn.active {
  background: white;
  border-bottom: 3px solid #667eea;
  font-weight: bold;
}

.doc-content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background: #fafafa;
}

.doc-section h3 {
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  border-bottom: 2px solid #667eea;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

.feature-box, .command-group {
  background: white;
  border: 2px solid #ddd;
  border-radius: 10px;
  padding: 15px;
  margin-bottom: 20px;
}

.feature-box h4, .command-group h4 {
  color: #667eea;
  margin-top: 0;
  font-family: 'Comic Sans MS', cursive;
}

.feature-box ul, .feature-box ol {
  margin: 10px 0;
  padding-left: 25px;
}

.feature-box li {
  margin: 5px 0;
}

pre {
  background: #2d2d2d;
  color: #f8f8f2;
  padding: 10px;
  border-radius: 5px;
  overflow-x: auto;
  font-size: 13px;
}

code {
  background: #f0f0f0;
  padding: 2px 5px;
  border-radius: 3px;
  font-family: 'Courier New', monospace;
}

.warning {
  background: #fff3cd;
  border: 1px solid #ffc107;
  color: #856404;
  padding: 10px;
  border-radius: 5px;
  margin: 10px 0;
}
</style>