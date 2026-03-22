<template>
  <div 
    class="task-card-compact"
    :class="[
      `priority-${task.priority}`,
      `status-${task.status}`
    ]"
    @click="$emit('view-details', task)"
  >
    <div class="task-line">
      <!-- Priority & Title -->
      <span class="priority">{{ getPriorityIcon() }}</span>
      <span class="title" :title="task.title">{{ truncate(task.title, 30) }}</span>
      
      <!-- Progress -->
      <div class="progress-mini">
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: task.progress + '%' }"></div>
        </div>
        <span class="progress-text">{{ Math.round(task.progress) }}%</span>
      </div>
      
      <!-- Agent -->
      <span class="agent" :title="task.assigned_to">
        {{ getAgentIcon() }}
      </span>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  task: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['view-details'])

const getPriorityIcon = () => {
  const icons = {
    low: '🟢',
    medium: '🟡', 
    high: '🟠',
    urgent: '🔴'
  }
  return icons[props.task.priority] || '⚪'
}

const getAgentIcon = () => {
  const icons = {
    nestor: '🎩',
    tintin: '🚀',
    dupont1: '🎨',
    dupont2: '🔍'
  }
  return icons[props.task.assigned_to] || '👤'
}

const truncate = (text, maxLength) => {
  if (!text) return ''
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
}
</script>

<style scoped>
.task-card-compact {
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 6px 8px;
  margin-bottom: 4px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 12px;
}

.task-card-compact:hover {
  background: #f8f9fa;
  border-color: #999;
  transform: translateX(2px);
}

.task-card-compact.priority-urgent {
  border-left: 3px solid #dc3545;
}

.task-card-compact.priority-high {
  border-left: 3px solid #ff9800;
}

.task-card-compact.priority-medium {
  border-left: 3px solid #ffc107;
}

.task-card-compact.priority-low {
  border-left: 3px solid #4caf50;
}

.task-line {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 20px;
}

.priority {
  font-size: 14px;
  flex-shrink: 0;
}

.title {
  flex: 1;
  font-weight: 500;
  color: #333;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 0;
}

.progress-mini {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

.progress-bar {
  width: 40px;
  height: 4px;
  background: #e9ecef;
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #28a745;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 10px;
  color: #666;
  min-width: 25px;
}

.agent {
  font-size: 14px;
  flex-shrink: 0;
}

/* Status specific styles */
.task-card-compact.status-DONE {
  opacity: 0.6;
}

.task-card-compact.status-DONE .title {
  text-decoration: line-through;
}

.task-card-compact.status-IN_PROGRESS {
  background: #fff9e6;
}

.task-card-compact.status-TODO {
  background: #f0f0f0;
}
</style>