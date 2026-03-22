<template>
  <div class="tmux-config-modal" v-if="isVisible">
    <div class="modal-backdrop" @click="$emit('close')"></div>
    <div class="modal-content">
      <div class="modal-header">
        <h2>🔔 Configuration Notifications Tmux</h2>
        <button @click="$emit('close')" class="close-btn">✖</button>
      </div>
      
      <div class="modal-body">
        <TmuxNotificationConfig />
      </div>
    </div>
  </div>
</template>

<script setup>
import TmuxNotificationConfig from './TmuxNotificationConfig.vue'

defineProps({
  isVisible: Boolean
})

defineEmits(['close'])
</script>

<style scoped>
.tmux-config-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7);
}

.modal-content {
  position: relative;
  background: #2a2a2a;
  border-radius: 15px;
  width: 95% !important;
  max-width: 1600px !important;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
  border: 2px solid #444;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #444;
  background: linear-gradient(135deg, #2a2a2a 0%, #333 100%);
  border-radius: 15px 15px 0 0;
}

.modal-header h2 {
  margin: 0;
  color: #fff;
  font-size: 24px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.close-btn {
  background: none;
  border: none;
  color: #999;
  font-size: 28px;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-btn:hover {
  color: #fff;
  transform: rotate(90deg);
}

.modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 0;
}
</style>