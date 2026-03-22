<template>
  <div 
    class="task-card"
    :class="[
      `priority-${task.priority}`,
      `status-${task.status}`,
      { 'overdue': isOverdue }
    ]"
    @click="$emit('view-details', task)"
  >
    <!-- Task Header -->
    <div class="task-header">
      <div class="task-title">
        <span class="priority-indicator">{{ getPriorityIcon() }}</span>
        {{ task.title }}
      </div>
      <div class="task-actions">
        <button @click.stop="$emit('validate', task)" class="btn-validate" v-if="task.status === 'VALIDATION'">
          🔍
        </button>
        <span class="agent-badge" :class="`agent-${task.assigned_to}`">
          {{ getAgentIcon() }} {{ task.assigned_to }}
        </span>
      </div>
    </div>

    <!-- Task Description -->
    <div class="task-description" v-if="task.description">
      {{ truncateText(task.description, 100) }}
    </div>

    <!-- Progress Bar -->
    <div class="progress-section">
      <div class="progress-bar">
        <div 
          class="progress-fill" 
          :style="{ width: task.progress + '%' }"
          :class="getProgressClass()"
        ></div>
      </div>
      <span class="progress-text">{{ Math.round(task.progress) }}%</span>
    </div>

    <!-- Validation Checkboxes Preview -->
    <div class="checkboxes-preview">
      <div 
        v-for="checkbox in task.checkboxes?.slice(0, 3)" 
        :key="checkbox.id"
        class="checkbox-item"
        :class="{ 'completed': checkbox.completed, 'required': checkbox.required }"
      >
        <span class="checkbox-icon">
          {{ checkbox.completed ? '✅' : (checkbox.required ? '❌' : '⬜') }}
        </span>
        <span class="checkbox-label">{{ truncateText(checkbox.label, 30) }}</span>
      </div>
      <div v-if="task.checkboxes?.length > 3" class="checkbox-more">
        +{{ task.checkboxes.length - 3 }} more
      </div>
    </div>

    <!-- Task Meta Info -->
    <div class="task-meta">
      <div class="meta-row">
        <span class="meta-item">
          📅 {{ formatDate(task.created_at) }}
        </span>
        <span class="meta-item" v-if="task.due_date">
          ⏰ Due: {{ formatDate(task.due_date) }}
        </span>
      </div>
      
      <div class="meta-row" v-if="task.estimated_hours || task.actual_hours">
        <span class="meta-item" v-if="task.estimated_hours">
          ⏱️ Est: {{ task.estimated_hours }}h
        </span>
        <span class="meta-item" v-if="task.actual_hours">
          ⏳ Actual: {{ task.actual_hours }}h
        </span>
      </div>
    </div>

    <!-- Validation Alerts -->
    <div class="validation-alerts" v-if="showValidationAlerts()">
      <div class="alert alert-warning" v-if="hasIncompleteRequired()">
        ⚠️ {{ getIncompleteRequiredCount() }} required validation(s) missing
      </div>
      <div class="alert alert-danger" v-if="isStuckInValidation()">
        🚨 Stuck in validation > 30min
      </div>
    </div>

    <!-- Recent Screenshots -->
    <div class="recent-screenshots" v-if="task.validations?.length > 0">
      <div class="screenshots-header">📸 Recent Evidence</div>
      <div class="screenshots-grid">
        <div 
          v-for="validation in task.validations.slice(0, 2)" 
          :key="validation.id"
          class="screenshot-thumb"
          @click.stop="viewScreenshot(validation)"
        >
          <img 
            v-if="validation.screenshot_path" 
            :src="validation.screenshot_path" 
            :alt="'Validation screenshot'"
          />
          <div v-else class="no-screenshot">📋</div>
          <div class="screenshot-date">{{ formatTime(validation.timestamp) }}</div>
        </div>
      </div>
    </div>

    <!-- Tags -->
    <div class="task-tags" v-if="task.tags">
      <span 
        v-for="tag in getTagsArray()" 
        :key="tag"
        class="task-tag"
      >
        {{ tag }}
      </span>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'TaskCard',
  props: {
    task: {
      type: Object,
      required: true
    }
  },
  emits: ['view-details', 'validate', 'update-status'],
  setup(props, { emit }) {
    const isOverdue = computed(() => {
      if (!props.task.due_date) return false
      return new Date(props.task.due_date) < new Date() && props.task.status !== 'DONE'
    })

    const getPriorityIcon = () => {
      const icons = {
        low: '🟢',
        medium: '🟡',
        high: '🟠',
        urgent: '🔴'
      }
      return icons[props.task.priority] || '🟡'
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

    const getProgressClass = () => {
      if (props.task.progress >= 100) return 'progress-complete'
      if (props.task.progress >= 75) return 'progress-high'
      if (props.task.progress >= 50) return 'progress-medium'
      return 'progress-low'
    }

    const hasIncompleteRequired = () => {
      return props.task.checkboxes?.some(cb => cb.required && !cb.completed) || false
    }

    const getIncompleteRequiredCount = () => {
      return props.task.checkboxes?.filter(cb => cb.required && !cb.completed).length || 0
    }

    const isStuckInValidation = () => {
      if (props.task.status !== 'VALIDATION') return false
      
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000)
      return new Date(props.task.updated_at) < thirtyMinutesAgo
    }

    const showValidationAlerts = () => {
      return hasIncompleteRequired() || isStuckInValidation()
    }

    const truncateText = (text, maxLength) => {
      if (!text) return ''
      return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
    }

    const formatDate = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
      })
    }

    const formatTime = (dateString) => {
      if (!dateString) return ''
      return new Date(dateString).toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const getTagsArray = () => {
      if (!props.task.tags) return []
      return props.task.tags.split(',').map(tag => tag.trim()).filter(Boolean)
    }

    const viewScreenshot = (validation) => {
      if (validation.screenshot_path) {
        window.open(validation.screenshot_path, '_blank')
      }
    }

    return {
      isOverdue,
      getPriorityIcon,
      getAgentIcon,
      getProgressClass,
      hasIncompleteRequired,
      getIncompleteRequiredCount,
      isStuckInValidation,
      showValidationAlerts,
      truncateText,
      formatDate,
      formatTime,
      getTagsArray,
      viewScreenshot
    }
  }
}
</script>

<style scoped>
.task-card {
  background: white;
  border: 3px solid #333;
  border-radius: 12px;
  padding: 15px;
  margin-bottom: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: relative;
}

.task-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
  border-color: #ff6b6b;
}

.task-card.overdue {
  border-color: #dc3545;
  background: linear-gradient(135deg, #fff 0%, #ffebee 100%);
}

.task-card.priority-urgent {
  border-left: 8px solid #dc3545;
}

.task-card.priority-high {
  border-left: 8px solid #ff9800;
}

.task-card.priority-medium {
  border-left: 8px solid #ffc107;
}

.task-card.priority-low {
  border-left: 8px solid #4caf50;
}

.task-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.task-title {
  font-weight: bold;
  color: #333;
  font-size: 1.1em;
  line-height: 1.3;
  flex: 1;
  margin-right: 10px;
  font-family: 'Comic Sans MS', cursive;
}

.priority-indicator {
  margin-right: 8px;
  font-size: 1.2em;
}

.task-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-validate {
  background: #17a2b8;
  color: white;
  border: 2px solid #333;
  border-radius: 6px;
  padding: 4px 8px;
  cursor: pointer;
  font-size: 1em;
  transition: all 0.2s;
}

.btn-validate:hover {
  background: #138496;
  transform: scale(1.1);
}

.agent-badge {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.85em;
  font-weight: bold;
  text-transform: capitalize;
  border: 2px solid #333;
}

.agent-nestor { background: #e1bee7; color: #4a148c; }
.agent-tintin { background: #bbdefb; color: #0d47a1; }
.agent-dupont1 { background: #c8e6c9; color: #1b5e20; }
.agent-dupont2 { background: #ffe0b2; color: #e65100; }

.task-description {
  color: #666;
  font-size: 0.95em;
  line-height: 1.4;
  margin-bottom: 12px;
  padding: 8px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #dee2e6;
}

.progress-section {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.progress-bar {
  flex: 1;
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  border: 1px solid #333;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  transition: width 0.3s ease;
  border-radius: 3px;
}

.progress-complete { background: linear-gradient(90deg, #28a745, #20c997); }
.progress-high { background: linear-gradient(90deg, #17a2b8, #20c997); }
.progress-medium { background: linear-gradient(90deg, #ffc107, #fd7e14); }
.progress-low { background: linear-gradient(90deg, #dc3545, #e83e8c); }

.progress-text {
  font-size: 0.85em;
  font-weight: bold;
  color: #495057;
  min-width: 35px;
}

.checkboxes-preview {
  margin-bottom: 12px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
  font-size: 0.85em;
}

.checkbox-item.required .checkbox-label {
  font-weight: bold;
}

.checkbox-item.completed .checkbox-label {
  color: #28a745;
  text-decoration: line-through;
}

.checkbox-icon {
  font-size: 1em;
}

.checkbox-label {
  color: #495057;
  flex: 1;
}

.checkbox-more {
  font-size: 0.8em;
  color: #6c757d;
  font-style: italic;
  margin-top: 4px;
}

.task-meta {
  border-top: 1px solid #dee2e6;
  padding-top: 8px;
  margin-bottom: 8px;
}

.meta-row {
  display: flex;
  gap: 15px;
  margin-bottom: 4px;
}

.meta-item {
  font-size: 0.8em;
  color: #6c757d;
  display: flex;
  align-items: center;
  gap: 4px;
}

.validation-alerts {
  margin-bottom: 10px;
}

.alert {
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 0.85em;
  font-weight: bold;
  margin-bottom: 4px;
  border: 2px solid;
}

.alert-warning {
  background: #fff3cd;
  color: #856404;
  border-color: #ffeaa7;
}

.alert-danger {
  background: #f8d7da;
  color: #721c24;
  border-color: #f5c6cb;
}

.recent-screenshots {
  margin-bottom: 10px;
}

.screenshots-header {
  font-size: 0.85em;
  font-weight: bold;
  color: #495057;
  margin-bottom: 6px;
}

.screenshots-grid {
  display: flex;
  gap: 8px;
}

.screenshot-thumb {
  width: 40px;
  height: 40px;
  border: 2px solid #333;
  border-radius: 6px;
  overflow: hidden;
  cursor: pointer;
  position: relative;
  transition: transform 0.2s;
}

.screenshot-thumb:hover {
  transform: scale(1.1);
}

.screenshot-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-screenshot {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f9fa;
  font-size: 1.2em;
}

.screenshot-date {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.6em;
  text-align: center;
  padding: 1px;
}

.task-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 8px;
}

.task-tag {
  background: #6c757d;
  color: white;
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 0.75em;
  font-weight: bold;
  border: 1px solid #333;
}

/* Status-based styling */
.status-TODO {
  border-top: 4px solid #6c757d;
}

.status-IN_PROGRESS {
  border-top: 4px solid #ffc107;
  animation: pulse-progress 2s infinite;
}

.status-VALIDATION {
  border-top: 4px solid #17a2b8;
}

.status-DONE {
  border-top: 4px solid #28a745;
  opacity: 0.9;
}

@keyframes pulse-progress {
  0%, 100% { border-top-color: #ffc107; }
  50% { border-top-color: #fd7e14; }
}

/* Dragging state */
.task-card:active {
  cursor: grabbing;
  transform: rotate(3deg);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
  z-index: 1000;
}
</style>