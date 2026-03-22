<template>
  <div v-if="isOpen" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>🔄 Workflow de Communication</h2>
        <button @click="$emit('close')" class="close-btn">✕</button>
      </div>
      
      <div class="workflow-container">
        <!-- Étapes du workflow -->
        <div class="workflow-step">
          <div class="step-number">1</div>
          <div class="step-content">
            <h3>📝 Capture du Prompt</h3>
            <p>Hook Python capture chaque prompt Claude</p>
            <code>~/.claude/settings.json → UserPromptSubmit</code>
          </div>
        </div>

        <div class="workflow-arrow">↓</div>

        <div class="workflow-step">
          <div class="step-number">2</div>
          <div class="step-content">
            <h3>📡 Envoi à Oracle</h3>
            <p>Le hook envoie l'événement à l'API Oracle</p>
            <code>POST http://localhost:3001/api/events</code>
          </div>
        </div>

        <div class="workflow-arrow">↓</div>

        <div class="workflow-step">
          <div class="step-number">3</div>
          <div class="step-content">
            <h3>📧 Email à Nestor</h3>
            <p>Oracle envoie un email au chef d'orchestre</p>
            <code>SMTP → nestor@moulinsart.local</code>
          </div>
        </div>

        <div class="workflow-arrow">↓</div>

        <div class="workflow-step">
          <div class="step-number">4</div>
          <div class="step-content">
            <h3>🎭 Distribution aux Agents</h3>
            <p>Nestor forward aux autres agents selon le contexte</p>
            <div class="agents-grid">
              <div class="agent-box">
                <span class="agent-emoji">🚀</span>
                <span>Tintin (QA)</span>
              </div>
              <div class="agent-box">
                <span class="agent-emoji">🎨</span>
                <span>Dupont1 (Dev)</span>
              </div>
              <div class="agent-box">
                <span class="agent-emoji">🔍</span>
                <span>Dupont2 (R&D)</span>
              </div>
            </div>
          </div>
        </div>

        <div class="workflow-arrow">↓</div>

        <div class="workflow-step">
          <div class="step-number">5</div>
          <div class="step-content">
            <h3>💉 Notification Tmux</h3>
            <p>Injection de notification dans le panel correspondant</p>
            <code>tmux send-keys -t session:agents.[0-3]</code>
          </div>
        </div>

        <div class="workflow-arrow">↓</div>

        <div class="workflow-step">
          <div class="step-number">6</div>
          <div class="step-content">
            <h3>🔄 Réponse et Collaboration</h3>
            <p>Les agents répondent par email et collaborent</p>
            <code>Boucle de communication inter-agents</code>
          </div>
        </div>

        <!-- Flux de données -->
        <div class="data-flow">
          <h3>📊 Flux de Données</h3>
          <div class="flow-diagram">
            <div class="flow-item">
              <strong>WebSocket:</strong> Feed temps réel vers l'interface
            </div>
            <div class="flow-item">
              <strong>SQLite:</strong> Persistance emails et événements
            </div>
            <div class="flow-item">
              <strong>SMTP:</strong> Communication asynchrone entre agents
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

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
  animation: slideUp 0.3s;
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.modal-header {
  padding: 20px;
  border-bottom: 2px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px 12px 0 0;
}

.modal-header h2 {
  margin: 0;
  font-size: 24px;
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
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.workflow-container {
  padding: 30px;
}

.workflow-step {
  display: flex;
  align-items: flex-start;
  margin-bottom: 20px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #667eea;
  transition: transform 0.2s, box-shadow 0.2s;
}

.workflow-step:hover {
  transform: translateX(5px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.step-number {
  width: 40px;
  height: 40px;
  background: #667eea;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 18px;
  margin-right: 20px;
  flex-shrink: 0;
}

.step-content h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 18px;
}

.step-content p {
  margin: 0 0 10px 0;
  color: #666;
}

.step-content code {
  display: inline-block;
  background: #2d3748;
  color: #48bb78;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-family: 'Monaco', 'Courier New', monospace;
}

.workflow-arrow {
  text-align: center;
  font-size: 24px;
  color: #667eea;
  margin: 10px 0;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(5px); }
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  margin-top: 10px;
}

.agent-box {
  background: white;
  padding: 10px;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: transform 0.2s;
}

.agent-box:hover {
  transform: scale(1.05);
  box-shadow: 0 5px 10px rgba(0, 0, 0, 0.1);
}

.agent-emoji {
  font-size: 24px;
  margin-bottom: 5px;
}

.data-flow {
  margin-top: 40px;
  padding: 20px;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  border-radius: 8px;
}

.data-flow h3 {
  margin: 0 0 15px 0;
  color: #333;
}

.flow-diagram {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.flow-item {
  background: white;
  padding: 12px 15px;
  border-radius: 6px;
  border-left: 3px solid #48bb78;
}

.flow-item strong {
  color: #2d3748;
}
</style>