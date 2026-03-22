<template>
  <div v-if="show" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content commands-modal">
      <div class="modal-header">
        <h2>🎮 Commandes Rapides</h2>
        <button @click="$emit('close')" class="close-btn">✕</button>
      </div>
      
      <div class="commands-container">
        <div class="command-section">
          <h3>⚡ Débloquer les agents</h3>
          <div class="command-group">
            <div class="command-item">
              <button @click="wakeAgent(0)" class="wake-btn">
                🔓 Débloquer Nestor
              </button>
              <code @click="copyCommand('tmux send-keys -t nestor-agents:agents.0 C-c Enter')">
                tmux send-keys -t nestor-agents:agents.0 C-c Enter
              </code>
            </div>
            <div class="command-item">
              <button @click="wakeAgent(1)" class="wake-btn">
                🔓 Débloquer Tintin
              </button>
              <code @click="copyCommand('tmux send-keys -t nestor-agents:agents.1 C-c Enter')">
                tmux send-keys -t nestor-agents:agents.1 C-c Enter
              </code>
            </div>
            <div class="command-item">
              <button @click="wakeAgent(2)" class="wake-btn">
                🔓 Débloquer Dupont1
              </button>
              <code @click="copyCommand('tmux send-keys -t nestor-agents:agents.2 C-c Enter')">
                tmux send-keys -t nestor-agents:agents.2 C-c Enter
              </code>
            </div>
            <div class="command-item">
              <button @click="wakeAgent(3)" class="wake-btn">
                🔓 Débloquer Dupont2
              </button>
              <code @click="copyCommand('tmux send-keys -t nestor-agents:agents.3 C-c Enter')">
                tmux send-keys -t nestor-agents:agents.3 C-c Enter
              </code>
            </div>
          </div>
          
          <div class="command-special">
            <button @click="wakeAllAgents()" class="wake-all-btn">
              🚨 DÉBLOQUER TOUS LES AGENTS
            </button>
            <code @click="copyCommand('for i in {0..3}; do tmux send-keys -t nestor-agents:agents.$i C-c Enter; done')">
              for i in {0..3}; do tmux send-keys -t nestor-agents:agents.$i C-c Enter; done
            </code>
          </div>
        </div>

        <div class="command-section">
          <h3>💬 Envoyer un message</h3>
          <div class="command-group">
            <div class="command-item">
              <code @click="copyCommand(`tmux send-keys -t nestor-agents:agents.0 'Votre message' Enter`)">
                tmux send-keys -t nestor-agents:agents.0 "Message" Enter
              </code>
              <span class="agent-label">À Nestor</span>
            </div>
            <div class="command-item">
              <code @click="copyCommand(`tmux send-keys -t nestor-agents:agents.1 'Votre message' Enter`)">
                tmux send-keys -t nestor-agents:agents.1 "Message" Enter
              </code>
              <span class="agent-label">À Tintin</span>
            </div>
          </div>
        </div>

        <div class="command-section">
          <h3>📧 Vérifier les boîtes mail</h3>
          <div class="command-group">
            <div class="command-item">
              <code @click="copyCommand('curl http://localhost:1080/api/mailbox/nestor@moulinsart.local')">
                curl http://localhost:1080/api/mailbox/nestor@moulinsart.local
              </code>
            </div>
            <div class="command-item">
              <code @click="copyCommand('curl http://localhost:1080/api/mailbox/tintin@moulinsart.local')">
                curl http://localhost:1080/api/mailbox/tintin@moulinsart.local
              </code>
            </div>
          </div>
        </div>

        <div class="command-section">
          <h3>👁️ Voir la session</h3>
          <div class="command-item">
            <code @click="copyCommand('tmux attach -t nestor-agents')">
              tmux attach -t nestor-agents
            </code>
            <span class="hint">Détacher: Ctrl+B puis D</span>
          </div>
        </div>

        <div class="command-section">
          <h3>📍 Mapping Agents</h3>
          <table class="mapping-table">
            <tr>
              <th>Agent</th>
              <th>Panel</th>
              <th>Email</th>
            </tr>
            <tr>
              <td>🎩 NESTOR</td>
              <td>0</td>
              <td>nestor@moulinsart.local</td>
            </tr>
            <tr>
              <td>🚀 TINTIN</td>
              <td>1</td>
              <td>tintin@moulinsart.local</td>
            </tr>
            <tr>
              <td>🎨 DUPONT1</td>
              <td>2</td>
              <td>dupont1@moulinsart.local</td>
            </tr>
            <tr>
              <td>🔍 DUPONT2</td>
              <td>3</td>
              <td>dupont2@moulinsart.local</td>
            </tr>
          </table>
        </div>
      </div>

      <div v-if="copied" class="copy-notification">
        ✅ Commande copiée!
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'CommandsModal',
  props: {
    show: Boolean
  },
  setup() {
    const copied = ref(false)
    
    const copyCommand = (cmd) => {
      navigator.clipboard.writeText(cmd)
      copied.value = true
      setTimeout(() => {
        copied.value = false
      }, 2000)
    }
    
    const wakeAgent = async (panel) => {
      const agents = ['nestor', 'tintin', 'dupont1', 'dupont2']
      const agentName = agents[panel]
      
      try {
        const response = await fetch('http://localhost:3001/api/wake-agent', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            panel,
            agent: agentName
          })
        })
        
        if (response.ok) {
          console.log(`✅ Agent ${agentName} débloqué`)
          // Afficher une notification
          copied.value = true
          setTimeout(() => {
            copied.value = false
          }, 2000)
        }
      } catch (error) {
        console.error('Erreur:', error)
      }
    }
    
    const wakeAllAgents = async () => {
      for (let panel = 0; panel < 4; panel++) {
        await wakeAgent(panel)
        await new Promise(resolve => setTimeout(resolve, 100)) // Petit délai entre chaque
      }
      console.log('✅ Tous les agents débloqués')
    }
    
    return {
      copied,
      copyCommand,
      wakeAgent,
      wakeAllAgents
    }
  }
}
</script>

<style scoped>
.commands-modal {
  max-width: 900px;
  max-height: 80vh;
  overflow-y: auto;
}

.commands-container {
  padding: 20px;
}

.command-section {
  margin-bottom: 30px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 15px;
}

.command-section h3 {
  color: #00ff41;
  margin-bottom: 15px;
  font-size: 1.2em;
}

.command-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.command-item {
  display: flex;
  align-items: center;
  gap: 15px;
}

.command-item code {
  background: #1a1a1a;
  padding: 8px 12px;
  border-radius: 4px;
  font-family: 'Monaco', monospace;
  font-size: 0.9em;
  cursor: pointer;
  transition: all 0.2s;
  flex-grow: 1;
  border: 1px solid rgba(0, 255, 65, 0.2);
}

.command-item code:hover {
  background: #2a2a2a;
  border-color: #00ff41;
  box-shadow: 0 0 10px rgba(0, 255, 65, 0.3);
}

.agent-label {
  color: #00ff41;
  font-weight: bold;
  min-width: 80px;
}

.command-special {
  margin-top: 20px;
  padding: 15px;
  background: rgba(0, 255, 65, 0.1);
  border-radius: 6px;
  border: 1px solid rgba(0, 255, 65, 0.3);
}

.command-special h4 {
  color: #00ff41;
  margin-bottom: 10px;
}

.hint {
  color: #888;
  font-style: italic;
  font-size: 0.9em;
}

.mapping-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

.mapping-table th {
  background: rgba(0, 255, 65, 0.2);
  color: #00ff41;
  padding: 8px;
  text-align: left;
}

.mapping-table td {
  padding: 8px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.wake-btn {
  background: linear-gradient(135deg, #00ff41, #00cc33);
  color: #0a0a0a;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
  margin-right: 10px;
  min-width: 150px;
}

.wake-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 15px rgba(0, 255, 65, 0.5);
}

.wake-btn:active {
  transform: scale(0.95);
}

.wake-all-btn {
  background: linear-gradient(135deg, #ff4141, #cc0000);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: bold;
  font-size: 1.1em;
  cursor: pointer;
  transition: all 0.3s;
  width: 100%;
  margin-bottom: 10px;
}

.wake-all-btn:hover {
  transform: scale(1.02);
  box-shadow: 0 6px 20px rgba(255, 65, 65, 0.5);
}

.copy-notification {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: #00ff41;
  color: #0a0a0a;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: bold;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #1a1a1a;
  border: 2px solid #00ff41;
  border-radius: 10px;
  box-shadow: 0 0 30px rgba(0, 255, 65, 0.5);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid rgba(0, 255, 65, 0.3);
}

.modal-header h2 {
  color: #00ff41;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  color: #00ff41;
  font-size: 24px;
  cursor: pointer;
  transition: transform 0.2s;
}

.close-btn:hover {
  transform: scale(1.2);
}
</style>