<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>📋 Task Details</h2>
        <button @click="$emit('close')" class="modal-close">×</button>
      </div>
      
      <div class="modal-body">
        <!-- Task Status Header -->
        <div class="task-status-header" :class="`status-${task.status}`">
          <div class="status-info">
            <h3>{{ task.title }}</h3>
            <div class="status-badge" :class="`badge-${task.status}`">
              {{ getStatusIcon() }} {{ getStatusText() }}
            </div>
          </div>
          <div class="task-actions">
            <button 
              v-if="canEditTask()" 
              @click="isEditing = !isEditing" 
              class="btn-edit"
            >
              {{ isEditing ? '💾 Save' : '✏️ Edit' }}
            </button>
            <button @click="showHistory = !showHistory" class="btn-history">
              📜 History
            </button>
          </div>
        </div>

        <!-- Task Information -->
        <div class="task-info-grid">
          <div class="info-card">
            <h4>📊 Task Information</h4>
            <div class="info-rows">
              <div class="info-row">
                <span class="label">Project:</span>
                <span class="value">{{ task.project_name }}</span>
              </div>
              <div class="info-row">
                <span class="label">Assigned to:</span>
                <span class="value agent-name" :class="`agent-${task.assigned_to}`">
                  {{ getAgentIcon() }} {{ task.assigned_to }}
                </span>
              </div>
              <div class="info-row">
                <span class="label">Priority:</span>
                <span class="value priority" :class="`priority-${task.priority}`">
                  {{ getPriorityIcon() }} {{ task.priority }}
                </span>
              </div>
              <div class="info-row">
                <span class="label">Created:</span>
                <span class="value">{{ formatDateTime(task.created_at) }}</span>
              </div>
              <div class="info-row" v-if="task.due_date">
                <span class="label">Due Date:</span>
                <span class="value" :class="{ 'overdue': isOverdue() }">
                  {{ formatDateTime(task.due_date) }}
                </span>
              </div>
            </div>
          </div>

          <div class="info-card">
            <h4>⏱️ Time Tracking</h4>
            <div class="time-info">
              <div class="time-item">
                <span class="time-label">Estimated:</span>
                <span class="time-value">{{ task.estimated_hours || 'N/A' }}h</span>
              </div>
              <div class="time-item">
                <span class="time-label">Actual:</span>
                <span class="time-value">{{ task.actual_hours || '0' }}h</span>
              </div>
              <div class="time-item" v-if="task.estimated_hours && task.actual_hours">
                <span class="time-label">Variance:</span>
                <span class="time-value" :class="getVarianceClass()">
                  {{ getTimeVariance() }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Task Description -->
        <div class="description-section">
          <h4>📝 Description</h4>
          <div v-if="!isEditing" class="description-display">
            <pre class="description-text">{{ task.description || 'No description provided.' }}</pre>
          </div>
          <div v-else class="description-edit">
            <textarea 
              v-model="editedDescription"
              rows="6"
              class="description-textarea"
              placeholder="Enter task description..."
            ></textarea>
          </div>
        </div>

        <!-- Progress and Validation -->
        <div class="progress-section">
          <h4>✅ Validation Progress</h4>
          <div class="progress-overview">
            <div class="progress-bar-container">
              <div class="progress-bar">
                <div 
                  class="progress-fill" 
                  :style="{ width: task.progress + '%' }"
                  :class="getProgressClass()"
                ></div>
              </div>
              <span class="progress-text">{{ Math.round(task.progress) }}% Complete</span>
            </div>
            
            <div class="progress-stats">
              <span class="stat">
                {{ getCompletedCheckboxes() }}/{{ getTotalCheckboxes() }} validations
              </span>
              <span class="stat">
                {{ getRequiredIncomplete() }} required remaining
              </span>
            </div>
          </div>

          <!-- Detailed Checkboxes -->
          <div class="checkboxes-detailed">
            <div 
              v-for="checkbox in task.checkboxes" 
              :key="checkbox.id"
              class="checkbox-detail"
              :class="{
                'completed': checkbox.completed,
                'required': checkbox.required,
                'with-evidence': checkbox.evidence_url
              }"
            >
              <div class="checkbox-header">
                <span class="checkbox-icon">
                  {{ checkbox.completed ? '✅' : (checkbox.required ? '❌' : '⬜') }}
                </span>
                <span class="checkbox-label">
                  {{ checkbox.label }}
                  <span v-if="checkbox.required" class="required-badge">REQUIRED</span>
                </span>
                <span v-if="checkbox.completed_at" class="completed-date">
                  {{ formatDateTime(checkbox.completed_at) }}
                </span>
              </div>
              
              <div v-if="checkbox.evidence_url" class="evidence-info">
                <a :href="checkbox.evidence_url" target="_blank" class="evidence-link">
                  🔗 View Evidence
                </a>
              </div>
              
              <div v-if="checkbox.notes" class="checkbox-notes">
                <em>{{ checkbox.notes }}</em>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Validations -->
        <div v-if="task.validations?.length" class="validations-section">
          <h4>🔍 Recent Validations</h4>
          <div class="validations-list">
            <div 
              v-for="validation in task.validations.slice(0, 3)" 
              :key="validation.id"
              class="validation-item"
              :class="`validation-${validation.validation_status}`"
            >
              <div class="validation-header">
                <span class="validation-status">
                  {{ getValidationStatusIcon(validation.validation_status) }}
                  {{ validation.validation_status.toUpperCase() }}
                </span>
                <span class="validation-date">{{ formatDateTime(validation.timestamp) }}</span>
              </div>
              
              <div v-if="validation.validation_notes" class="validation-notes">
                {{ validation.validation_notes }}
              </div>
              
              <div class="validation-details">
                <div v-if="validation.screenshot_path" class="validation-detail">
                  <a :href="validation.screenshot_path" target="_blank" class="screenshot-link">
                    📸 Screenshot
                  </a>
                </div>
                <div v-if="validation.build_log_url" class="validation-detail">
                  <a :href="validation.build_log_url" target="_blank" class="build-link">
                    🔨 Build Log
                  </a>
                </div>
                <div v-if="validation.languages_tested" class="validation-detail">
                  🌐 Languages: {{ validation.languages_tested }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Task History -->
        <div v-if="showHistory" class="history-section">
          <h4>📜 Task History</h4>
          <div class="history-timeline">
            <!-- Placeholder for task history - would be loaded from task_history table -->
            <div class="history-item">
              <span class="history-time">{{ formatDateTime(task.created_at) }}</span>
              <span class="history-action">Task created</span>
              <span class="history-user">system</span>
            </div>
            <div v-if="task.updated_at !== task.created_at" class="history-item">
              <span class="history-time">{{ formatDateTime(task.updated_at) }}</span>
              <span class="history-action">Status updated to {{ task.status }}</span>
              <span class="history-user">dashboard</span>
            </div>
          </div>
        </div>

        <!-- Tags and Dependencies -->
        <div class="meta-section">
          <div v-if="task.tags" class="tags-display">
            <h4>🏷️ Tags</h4>
            <div class="tags-list">
              <span 
                v-for="tag in getTagsArray()" 
                :key="tag"
                class="tag"
              >
                {{ tag }}
              </span>
            </div>
          </div>
          
          <div v-if="task.dependencies" class="dependencies-display">
            <h4>🔗 Dependencies</h4>
            <div class="dependencies-list">
              <span class="dependency-info">
                Depends on tasks: {{ task.dependencies }}
              </span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="modal-footer">
        <div class="footer-left">
          <button 
            @click="moveTask('TODO')" 
            :disabled="task.status === 'TODO'"
            class="btn-status todo"
          >
            📋 To Do
          </button>
          <button 
            @click="moveTask('IN_PROGRESS')" 
            :disabled="task.status === 'IN_PROGRESS'"
            class="btn-status in-progress"
          >
            🚀 In Progress
          </button>
          <button 
            @click="moveTask('VALIDATION')" 
            :disabled="task.status === 'VALIDATION'"
            class="btn-status validation"
          >
            🔍 Validation
          </button>
          <button 
            @click="moveTask('DONE')" 
            :disabled="task.status === 'DONE' || !canMoveToDone()"
            class="btn-status done"
            :title="!canMoveToDone() ? 'Complete all required validations first' : ''"
          >
            ✅ Done
          </button>
        </div>
        
        <div class="footer-right">
          <button @click="openValidationModal" class="btn-validate-task">
            🔍 Validate
          </button>
          <button @click="$emit('close')" class="btn-close">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'

export default {
  name: 'TaskDetailsModal',
  props: {
    task: {
      type: Object,
      required: true
    }
  },
  emits: ['close', 'updated'],
  setup(props, { emit }) {
    const isEditing = ref(false)
    const showHistory = ref(false)
    const editedDescription = ref(props.task.description || '')

    const getStatusIcon = () => {
      const icons = {
        TODO: '📋',
        IN_PROGRESS: '🚀',
        VALIDATION: '🔍',
        DONE: '✅'
      }
      return icons[props.task.status] || '❓'
    }

    const getStatusText = () => {
      const texts = {
        TODO: 'To Do',
        IN_PROGRESS: 'In Progress',
        VALIDATION: 'In Validation',
        DONE: 'Completed'
      }
      return texts[props.task.status] || 'Unknown'
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

    const getPriorityIcon = () => {
      const icons = {
        low: '🟢',
        medium: '🟡',
        high: '🟠',
        urgent: '🔴'
      }
      return icons[props.task.priority] || '🟡'
    }

    const getProgressClass = () => {
      if (props.task.progress >= 100) return 'progress-complete'
      if (props.task.progress >= 75) return 'progress-high'
      if (props.task.progress >= 50) return 'progress-medium'
      return 'progress-low'
    }

    const getValidationStatusIcon = (status) => {
      const icons = {
        approved: '✅',
        rejected: '❌',
        conditional: '⚠️',
        pending: '⏳'
      }
      return icons[status] || '❓'
    }

    const isOverdue = () => {
      if (!props.task.due_date) return false
      return new Date(props.task.due_date) < new Date() && props.task.status !== 'DONE'
    }

    const getTimeVariance = () => {
      if (!props.task.estimated_hours || !props.task.actual_hours) return 'N/A'
      const variance = props.task.actual_hours - props.task.estimated_hours
      return variance > 0 ? `+${variance}h` : `${variance}h`
    }

    const getVarianceClass = () => {
      if (!props.task.estimated_hours || !props.task.actual_hours) return ''
      const variance = props.task.actual_hours - props.task.estimated_hours
      if (variance > props.task.estimated_hours * 0.2) return 'over-budget'
      if (variance < 0) return 'under-budget'
      return 'on-budget'
    }

    const getCompletedCheckboxes = () => {
      return props.task.checkboxes?.filter(cb => cb.completed).length || 0
    }

    const getTotalCheckboxes = () => {
      return props.task.checkboxes?.length || 0
    }

    const getRequiredIncomplete = () => {
      return props.task.checkboxes?.filter(cb => cb.required && !cb.completed).length || 0
    }

    const getTagsArray = () => {
      if (!props.task.tags) return []
      return props.task.tags.split(',').map(tag => tag.trim()).filter(Boolean)
    }

    const canEditTask = () => {
      // Only allow editing of certain fields in certain statuses
      return ['TODO', 'IN_PROGRESS'].includes(props.task.status)
    }

    const canMoveToDone = () => {
      // Can only move to DONE if all required checkboxes are completed
      return getRequiredIncomplete() === 0
    }

    const formatDateTime = (dateString) => {
      if (!dateString) return 'N/A'
      return new Date(dateString).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const moveTask = async (newStatus) => {
      try {
        const response = await fetch(`http://localhost:3001/api/tasks/${props.task.id}/status`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            status: newStatus, 
            updated_by: 'task-details-modal',
            notes: `Status changed from ${props.task.status} to ${newStatus}`
          })
        })

        if (response.ok) {
          emit('updated')
        } else {
          alert('Failed to update task status')
        }
      } catch (error) {
        console.error('Error updating task:', error)
        alert('Error updating task')
      }
    }

    const openValidationModal = () => {
      // Emit event to parent to open validation modal
      emit('close')
      // This would trigger the validation modal in the parent component
    }

    return {
      isEditing,
      showHistory,
      editedDescription,
      getStatusIcon,
      getStatusText,
      getAgentIcon,
      getPriorityIcon,
      getProgressClass,
      getValidationStatusIcon,
      isOverdue,
      getTimeVariance,
      getVarianceClass,
      getCompletedCheckboxes,
      getTotalCheckboxes,
      getRequiredIncomplete,
      getTagsArray,
      canEditTask,
      canMoveToDone,
      formatDateTime,
      moveTask,
      openValidationModal
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
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 15px;
  border: 3px solid #333;
  box-shadow: 0 10px 50px rgba(0, 0, 0, 0.5);
  width: 90%;
  max-width: 1000px;
  max-height: 95vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #6f42c1 0%, #5a2d91 100%);
  padding: 20px;
  border-bottom: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-radius: 12px 12px 0 0;
}

.modal-header h2 {
  color: white;
  font-family: 'Comic Sans MS', cursive;
  margin: 0;
  text-shadow: 2px 2px 0px rgba(0,0,0,0.3);
}

.modal-close {
  background: none;
  border: none;
  font-size: 2em;
  cursor: pointer;
  color: white;
  padding: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s;
}

.modal-close:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.task-status-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-radius: 12px;
  border: 3px solid #333;
}

.status-TODO { background: linear-gradient(135deg, #f8f9fa, #e9ecef); }
.status-IN_PROGRESS { background: linear-gradient(135deg, #fff3cd, #ffeaa7); }
.status-VALIDATION { background: linear-gradient(135deg, #d1ecf1, #bee5eb); }
.status-DONE { background: linear-gradient(135deg, #d4edda, #c3e6cb); }

.status-info h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.5em;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 20px;
  font-weight: bold;
  border: 2px solid #333;
}

.badge-TODO { background: #6c757d; color: white; }
.badge-IN_PROGRESS { background: #ffc107; color: #333; }
.badge-VALIDATION { background: #17a2b8; color: white; }
.badge-DONE { background: #28a745; color: white; }

.task-actions {
  display: flex;
  gap: 10px;
}

.btn-edit,
.btn-history {
  padding: 8px 16px;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s;
  background: white;
  color: #333;
}

.btn-edit:hover,
.btn-history:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.task-info-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 20px;
}

.info-card {
  background: #f8f9fa;
  border: 3px solid #333;
  border-radius: 12px;
  padding: 15px;
}

.info-card h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
}

.info-rows {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.label {
  font-weight: bold;
  color: #666;
}

.value {
  color: #333;
}

.agent-name {
  padding: 4px 8px;
  border-radius: 12px;
  font-weight: bold;
  border: 2px solid #333;
}

.agent-nestor { background: #e1bee7; }
.agent-tintin { background: #bbdefb; }
.agent-dupont1 { background: #c8e6c9; }
.agent-dupont2 { background: #ffe0b2; }

.priority {
  font-weight: bold;
  text-transform: capitalize;
}

.priority-urgent { color: #dc3545; }
.priority-high { color: #fd7e14; }
.priority-medium { color: #ffc107; }
.priority-low { color: #28a745; }

.overdue {
  color: #dc3545;
  font-weight: bold;
}

.time-info {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.time-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.time-label {
  font-weight: bold;
  color: #666;
}

.time-value {
  font-weight: bold;
  color: #333;
}

.over-budget { color: #dc3545; }
.under-budget { color: #28a745; }
.on-budget { color: #17a2b8; }

.description-section h4,
.progress-section h4,
.validations-section h4,
.history-section h4,
.meta-section h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.2em;
}

.description-display {
  background: #f8f9fa;
  border: 2px solid #333;
  border-radius: 8px;
  padding: 15px;
}

.description-text {
  font-family: 'Arial', sans-serif;
  white-space: pre-wrap;
  margin: 0;
  line-height: 1.6;
  color: #333;
}

.description-textarea {
  width: 100%;
  padding: 15px;
  border: 2px solid #333;
  border-radius: 8px;
  font-family: 'Arial', sans-serif;
  resize: vertical;
}

.progress-overview {
  background: #f8f9fa;
  border: 2px solid #333;
  border-radius: 10px;
  padding: 15px;
  margin-bottom: 15px;
}

.progress-bar-container {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 10px;
}

.progress-bar {
  flex: 1;
  height: 12px;
  background: #e9ecef;
  border-radius: 6px;
  border: 2px solid #333;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  transition: width 0.3s ease;
  border-radius: 4px;
}

.progress-complete { background: linear-gradient(90deg, #28a745, #20c997); }
.progress-high { background: linear-gradient(90deg, #17a2b8, #20c997); }
.progress-medium { background: linear-gradient(90deg, #ffc107, #fd7e14); }
.progress-low { background: linear-gradient(90deg, #dc3545, #e83e8c); }

.progress-text {
  font-weight: bold;
  color: #333;
  min-width: 80px;
}

.progress-stats {
  display: flex;
  gap: 20px;
}

.stat {
  font-size: 0.9em;
  color: #666;
  font-weight: bold;
}

.checkboxes-detailed {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.checkbox-detail {
  border: 2px solid #dee2e6;
  border-radius: 8px;
  padding: 12px;
  background: white;
}

.checkbox-detail.completed {
  background: #d4edda;
  border-color: #c3e6cb;
}

.checkbox-detail.required {
  border-left: 6px solid #ffc107;
}

.checkbox-detail.with-evidence {
  border-right: 6px solid #17a2b8;
}

.checkbox-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.checkbox-icon {
  font-size: 1.2em;
}

.checkbox-label {
  flex: 1;
  font-weight: bold;
  color: #333;
}

.required-badge {
  background: #dc3545;
  color: white;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.7em;
  font-weight: bold;
  margin-left: 8px;
}

.completed-date {
  font-size: 0.85em;
  color: #666;
}

.evidence-info {
  margin-bottom: 6px;
}

.evidence-link {
  color: #007bff;
  text-decoration: none;
  font-weight: bold;
  font-size: 0.9em;
}

.evidence-link:hover {
  text-decoration: underline;
}

.checkbox-notes {
  font-size: 0.9em;
  color: #666;
  font-style: italic;
}

.validations-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.validation-item {
  border: 2px solid #dee2e6;
  border-radius: 8px;
  padding: 12px;
  background: white;
}

.validation-approved { border-color: #28a745; background: #d4edda; }
.validation-rejected { border-color: #dc3545; background: #f8d7da; }
.validation-conditional { border-color: #ffc107; background: #fff3cd; }
.validation-pending { border-color: #6c757d; background: #f8f9fa; }

.validation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.validation-status {
  font-weight: bold;
  color: #333;
}

.validation-date {
  font-size: 0.85em;
  color: #666;
}

.validation-notes {
  font-style: italic;
  color: #666;
  margin-bottom: 8px;
}

.validation-details {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.validation-detail a {
  color: #007bff;
  text-decoration: none;
  font-size: 0.9em;
  font-weight: bold;
}

.validation-detail a:hover {
  text-decoration: underline;
}

.history-timeline {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.history-item {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 15px;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #17a2b8;
}

.history-time {
  font-size: 0.85em;
  color: #666;
  white-space: nowrap;
}

.history-action {
  font-weight: bold;
  color: #333;
}

.history-user {
  font-size: 0.85em;
  color: #666;
}

.meta-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag {
  background: #6c757d;
  color: white;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.85em;
  font-weight: bold;
  border: 1px solid #333;
}

.dependencies-list {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 6px;
  border: 1px solid #dee2e6;
}

.dependency-info {
  font-size: 0.9em;
  color: #666;
  font-family: monospace;
}

.modal-footer {
  padding: 15px 20px;
  border-top: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8f9fa;
  border-radius: 0 0 12px 12px;
}

.footer-left {
  display: flex;
  gap: 8px;
}

.btn-status {
  padding: 8px 16px;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.9em;
  transition: all 0.2s;
}

.btn-status:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-status.todo { background: #6c757d; color: white; }
.btn-status.in-progress { background: #ffc107; color: #333; }
.btn-status.validation { background: #17a2b8; color: white; }
.btn-status.done { background: #28a745; color: white; }

.btn-status:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.footer-right {
  display: flex;
  gap: 10px;
}

.btn-validate-task {
  background: #17a2b8;
  color: white;
  border: 3px solid #333;
  border-radius: 8px;
  padding: 10px 20px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-validate-task:hover {
  background: #138496;
  transform: translateY(-1px);
}

.btn-close {
  background: #6c757d;
  color: white;
  border: 3px solid #333;
  border-radius: 8px;
  padding: 10px 20px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-close:hover {
  background: #5a6268;
  transform: translateY(-1px);
}

@media (max-width: 768px) {
  .task-info-grid {
    grid-template-columns: 1fr;
  }
  
  .meta-section {
    grid-template-columns: 1fr;
  }
  
  .modal-footer {
    flex-direction: column;
    gap: 15px;
  }
  
  .footer-left {
    flex-wrap: wrap;
    justify-content: center;
  }
}
</style>