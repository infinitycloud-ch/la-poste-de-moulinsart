<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>🏗️ Architecture Technique</h2>
        <button @click="$emit('close')" class="close-btn">✕</button>
      </div>
      
      <div class="docs-container">
        <!-- Documentation Architecture Technique -->
        <div class="arch-intro">
          <h3>🏗️ Vue d'Ensemble du Système</h3>
          <p>Le système Moulinsart Oracle est une architecture distribuée permettant la supervision en temps réel des agents Claude via plusieurs services interconnectés.</p>
        </div>

        <!-- Diagramme d'architecture -->
        <div class="architecture-diagram">
          <h3>🗺️ Vue d'Ensemble</h3>
          
          <div class="arch-grid">
            <!-- Claude Instances -->
            <div class="arch-section claude-section">
              <h4>🤖 Claude Instances (Tmux)</h4>
              <div class="claude-panels">
                <div class="panel">
                  <span class="panel-id">Panel 0</span>
                  <span class="agent-name">🎩 NESTOR</span>
                  <span class="email">nestor@moulinsart.local</span>
                </div>
                <div class="panel">
                  <span class="panel-id">Panel 1</span>
                  <span class="agent-name">🚀 TINTIN</span>
                  <span class="email">tintin@moulinsart.local</span>
                </div>
                <div class="panel">
                  <span class="panel-id">Panel 2</span>
                  <span class="agent-name">🎨 DUPONT1</span>
                  <span class="email">dupont1@moulinsart.local</span>
                </div>
                <div class="panel">
                  <span class="panel-id">Panel 3</span>
                  <span class="agent-name">🔍 DUPONT2</span>
                  <span class="email">dupont2@moulinsart.local</span>
                </div>
              </div>
            </div>

            <!-- Services -->
            <div class="arch-section services-section">
              <h4>⚙️ Services Core</h4>
              <div class="service-box oracle">
                <div class="service-header">📡 Oracle API</div>
                <div class="service-info">
                  <div>Port: <strong>3001</strong></div>
                  <div>WebSocket: ws://localhost:3001/ws</div>
                  <div>Endpoints: /api/events, /health</div>
                </div>
              </div>
              
              <div class="service-box mail">
                <div class="service-header">📧 Mail Server</div>
                <div class="service-info">
                  <div>SMTP: <strong>1025</strong></div>
                  <div>HTTP: <strong>1080</strong></div>
                  <div>SQLite: emails.db</div>
                </div>
              </div>
              
              <div class="service-box vue">
                <div class="service-header">🖥️ Interface Vue</div>
                <div class="service-info">
                  <div>Port: <strong>5175</strong></div>
                  <div>WebSocket Client</div>
                  <div>Feed temps réel</div>
                </div>
              </div>
            </div>

            <!-- Data Flow -->
            <div class="arch-section flow-section">
              <h4>🔄 Flux de Données</h4>
              <div class="flow-visualization">
                <div class="flow-step">Hook Python</div>
                <div class="flow-arrow">→</div>
                <div class="flow-step">Oracle API</div>
                <div class="flow-arrow">→</div>
                <div class="flow-step">Mail Server</div>
                <div class="flow-arrow">→</div>
                <div class="flow-step">Agents</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tableau des ports -->
        <div class="ports-table">
          <h3>🔌 Ports & Services</h3>
          <table>
            <thead>
              <tr>
                <th>Service</th>
                <th>Port</th>
                <th>Protocole</th>
                <th>Usage</th>
                <th>Status Check</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>📡 Oracle API</td>
                <td><strong>3001</strong></td>
                <td>HTTP/WS</td>
                <td>API REST & WebSocket</td>
                <td><code>curl http://localhost:3001/health</code></td>
              </tr>
              <tr>
                <td>📧 SMTP</td>
                <td><strong>1025</strong></td>
                <td>SMTP</td>
                <td>Réception emails</td>
                <td><code>nc -zv localhost 1025</code></td>
              </tr>
              <tr>
                <td>📮 Mail API</td>
                <td><strong>1080</strong></td>
                <td>HTTP</td>
                <td>Interface mail web</td>
                <td><code>curl http://localhost:1080</code></td>
              </tr>
              <tr>
                <td>🖥️ Vue App</td>
                <td><strong>5175</strong></td>
                <td>HTTP</td>
                <td>Interface utilisateur</td>
                <td><code>curl http://localhost:5175</code></td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Commandes utiles -->
        <div class="commands-section">
          <h3>💻 Commandes Essentielles</h3>
          
          <div class="command-group">
            <h4>🚀 Démarrage</h4>
            <div class="command-box">
              <code># Lancer tout le système
./moulinsart-manager-simple.sh

# Services individuels
bun run server/index.ts    # Oracle
bun run server/mail-server.ts  # Mail
cd client && bun run dev   # Vue</code>
            </div>
          </div>

          <div class="command-group">
            <h4>🔍 Monitoring</h4>
            <div class="command-box">
              <code># Vérifier les processus
ps aux | grep -E "oracle|mail|tmux"

# Logs temps réel
tail -f /tmp/oracle.log
tail -f /tmp/mail.log

# Sessions tmux
tmux ls
tmux attach -t moulinsart</code>
            </div>
          </div>

          <div class="command-group">
            <h4>🛠️ Troubleshooting</h4>
            <div class="command-box">
              <code># Débloquer un agent
./unfreeze-agent.sh [0-3]

# Reprendre avec --resume
./moulinsart-manager-simple.sh --resume

# Nettoyer les ports
lsof -i :3001,1025,1080,5175
kill -9 [PID]</code>
            </div>
          </div>
        </div>

        <!-- Base de données -->
        <div class="database-section">
          <h3>💾 Base de Données</h3>
          <div class="db-info">
            <div class="db-box">
              <h4>SQLite - oracle.db</h4>
              <ul>
                <li>Table <strong>events</strong>: Tous les événements capturés</li>
                <li>Table <strong>projects</strong>: Projets détectés</li>
                <li>Table <strong>emails</strong>: Emails persistés (soft delete)</li>
              </ul>
              <div class="command-box">
                <code>sqlite3 data/oracle.db ".tables"
sqlite3 data/oracle.db "SELECT * FROM events ORDER BY id DESC LIMIT 10;"</code>
              </div>
            </div>
          </div>
        </div>

        <!-- Fichiers importants -->
        <div class="files-section">
          <h3>📁 Fichiers Clés</h3>
          <div class="files-grid">
            <div class="file-item">
              <strong>~/.claude/settings.json</strong>
              <span>Configuration des hooks</span>
            </div>
            <div class="file-item">
              <strong>/tmp/oracle.log</strong>
              <span>Logs Oracle en temps réel</span>
            </div>
            <div class="file-item">
              <strong>/tmp/mail.log</strong>
              <span>Logs serveur mail</span>
            </div>
            <div class="file-item">
              <strong>CLAUDE.md</strong>
              <span>Instructions par agent</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  isOpen: Boolean
})

defineEmits(['close'])
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
  width: 98% !important;
  max-width: 1600px !important;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
  animation: slideUp 0.3s;
}

.modal-header {
  padding: 20px;
  border-bottom: 2px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
  border-radius: 12px 12px 0 0;
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

.docs-container {
  padding: 30px;
}

.arch-intro {
  margin-bottom: 30px;
  padding: 20px;
  background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
  border-radius: 12px;
  border: 2px solid #4a90e2;
}

.arch-intro h3 {
  margin: 0 0 15px 0;
  color: #2d3748;
  font-size: 20px;
  text-align: center;
}

.arch-intro p {
  margin: 0;
  color: #555;
  font-size: 16px;
  line-height: 1.6;
  text-align: center;
}


.architecture-diagram {
  margin-bottom: 40px;
}

.architecture-diagram h3 {
  margin: 0 0 20px 0;
  color: #333;
  font-size: 20px;
}

.arch-grid {
  display: grid;
  gap: 30px;
}

.arch-section {
  padding: 20px;
  background: #f8f9fa;
  border-radius: 10px;
  border: 2px solid #e0e0e0;
}

.arch-section h4 {
  margin: 0 0 15px 0;
  color: #555;
}

.claude-panels {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.panel {
  background: white;
  padding: 15px;
  border-radius: 8px;
  border: 2px solid #667eea;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  transition: transform 0.2s;
}

.panel:hover {
  transform: scale(1.05);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

.panel-id {
  font-size: 12px;
  color: #999;
  margin-bottom: 5px;
}

.agent-name {
  font-weight: bold;
  font-size: 16px;
  margin: 5px 0;
}

.email {
  font-size: 11px;
  color: #666;
  font-family: monospace;
}

.service-box {
  margin-bottom: 15px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #ddd;
}

.service-header {
  padding: 10px 15px;
  font-weight: bold;
  color: white;
}

.service-box.oracle .service-header {
  background: linear-gradient(135deg, #667eea, #764ba2);
}

.service-box.mail .service-header {
  background: linear-gradient(135deg, #f093fb, #f5576c);
}

.service-box.vue .service-header {
  background: linear-gradient(135deg, #4facfe, #00f2fe);
}

.service-info {
  padding: 15px;
  font-size: 14px;
}

.service-info div {
  margin: 5px 0;
}

.service-info strong {
  color: #e53e3e;
  font-family: monospace;
  font-size: 16px;
}

.flow-visualization {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: white;
  border-radius: 8px;
}

.flow-step {
  padding: 10px 20px;
  background: #667eea;
  color: white;
  border-radius: 20px;
  font-weight: bold;
}

.flow-arrow {
  margin: 0 15px;
  font-size: 24px;
  color: #667eea;
}

.ports-table {
  margin: 30px 0;
}

.ports-table h3 {
  margin: 0 0 15px 0;
  color: #333;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

th {
  background: #2d3748;
  color: white;
  padding: 12px;
  text-align: left;
  font-weight: 500;
}

td {
  padding: 12px;
  border-bottom: 1px solid #e0e0e0;
}

tr:hover {
  background: #f7fafc;
}

td code {
  background: #2d3748;
  color: #48bb78;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 12px;
  font-family: 'Monaco', monospace;
}

.commands-section {
  margin: 30px 0;
}

.command-group {
  margin-bottom: 25px;
}

.command-group h4 {
  margin: 0 0 10px 0;
  color: #555;
}

.command-box {
  background: #1a202c;
  border-radius: 8px;
  padding: 15px;
  overflow-x: auto;
}

.command-box code {
  color: #68d391;
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 13px;
  white-space: pre;
  display: block;
}

.database-section {
  margin: 30px 0;
}

.db-box {
  background: #f8f9fa;
  padding: 20px;
  border-radius: 8px;
  border: 2px solid #e0e0e0;
}

.db-box h4 {
  margin: 0 0 15px 0;
  color: #333;
}

.db-box ul {
  margin: 10px 0;
  padding-left: 20px;
}

.db-box li {
  margin: 5px 0;
  color: #666;
}

.files-section {
  margin: 30px 0;
}

.files-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.file-item {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 8px;
  border-left: 4px solid #48bb78;
}

.file-item strong {
  display: block;
  color: #2d3748;
  font-family: monospace;
  font-size: 13px;
  margin-bottom: 5px;
}

.file-item span {
  color: #666;
  font-size: 13px;
}
</style>