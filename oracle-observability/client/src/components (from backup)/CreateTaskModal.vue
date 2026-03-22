<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>➕ Create New Task</h2>
        <button @click="$emit('close')" class="modal-close">×</button>
      </div>
      
      <div class="modal-body">
        <form @submit.prevent="createTask" class="task-form">
          <div class="form-row">
            <div class="form-group">
              <label>Task Title *</label>
              <input 
                v-model="taskData.title"
                type="text"
                placeholder="Enter task title..."
                required
              />
            </div>
            
            <div class="form-group">
              <label>Priority</label>
              <select v-model="taskData.priority">
                <option value="low">🟢 Low</option>
                <option value="medium" selected>🟡 Medium</option>
                <option value="high">🟠 High</option>
                <option value="urgent">🔴 Urgent</option>
              </select>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Project *</label>
              <select v-model="taskData.project_id" required>
                <option value="">Select project...</option>
                <option 
                  v-for="project in projects" 
                  :key="project.id" 
                  :value="project.id"
                >
                  {{ project.name }}
                </option>
              </select>
            </div>
            
            <div class="form-group">
              <label>Assign To</label>
              <select v-model="taskData.assigned_to">
                <option value="">Unassigned</option>
                <option value="nestor">🎩 Nestor</option>
                <option value="tintin">🚀 Tintin</option>
                <option value="dupont1">🎨 Dupont1</option>
                <option value="dupont2">🔍 Dupont2</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label>Description</label>
            <textarea 
              v-model="taskData.description"
              rows="4"
              placeholder="Describe what needs to be done..."
            ></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Due Date</label>
              <input 
                v-model="taskData.due_date"
                type="datetime-local"
              />
            </div>
            
            <div class="form-group">
              <label>Estimated Hours</label>
              <input 
                v-model="taskData.estimated_hours"
                type="number"
                min="0.5"
                step="0.5"
                placeholder="e.g. 2.5"
              />
            </div>
          </div>

          <div class="form-group">
            <label>Tags</label>
            <input 
              v-model="taskData.tags"
              type="text"
              placeholder="frontend, ui, bug-fix (comma separated)"
            />
          </div>

          <!-- Custom Checkboxes Section -->
          <div class="checkboxes-section">
            <h3>📋 Custom Validation Checkboxes</h3>
            <p class="help-text">
              Default validations (Code complete, Screenshot, Build success, Visual validation, Documentation) 
              are automatically added. Add any additional custom validations:
            </p>
            
            <div class="custom-checkboxes">
              <div 
                v-for="(checkbox, index) in customCheckboxes" 
                :key="index"
                class="checkbox-row"
              >
                <input 
                  v-model="checkbox.label"
                  type="text"
                  placeholder="Custom validation requirement..."
                  class="checkbox-input"
                />
                <label class="checkbox-required">
                  <input 
                    v-model="checkbox.required"
                    type="checkbox"
                  />
                  Required
                </label>
                <button 
                  @click="removeCheckbox(index)"
                  type="button"
                  class="btn-remove-checkbox"
                >
                  🗑️
                </button>
              </div>
            </div>
            
            <button 
              @click="addCheckbox"
              type="button"
              class="btn-add-checkbox"
            >
              ➕ Add Custom Checkbox
            </button>
          </div>

          <!-- Task Templates -->
          <div class="templates-section">
            <h3>📝 Quick Templates</h3>
            <div class="template-buttons">
              <button @click="loadTemplate('feature')" type="button" class="btn-template">
                🚀 Feature Development
              </button>
              <button @click="loadTemplate('bugfix')" type="button" class="btn-template">
                🐛 Bug Fix
              </button>
              <button @click="loadTemplate('research')" type="button" class="btn-template">
                🔍 Research Task
              </button>
              <button @click="loadTemplate('testing')" type="button" class="btn-template">
                🧪 Testing Task
              </button>
            </div>
          </div>
        </form>
      </div>
      
      <div class="modal-footer">
        <button @click="createTask" :disabled="!isFormValid()" class="btn-create">
          🚀 Create Task
        </button>
        <button @click="$emit('close')" class="btn-cancel">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive } from 'vue'

export default {
  name: 'CreateTaskModal',
  props: {
    projects: {
      type: Array,
      default: () => []
    }
  },
  emits: ['close', 'created'],
  setup(props, { emit }) {
    const taskData = reactive({
      title: '',
      description: '',
      project_id: '',
      assigned_to: '',
      priority: 'medium',
      due_date: '',
      estimated_hours: '',
      tags: ''
    })

    const customCheckboxes = ref([])
    const isSubmitting = ref(false)

    const addCheckbox = () => {
      customCheckboxes.value.push({
        label: '',
        required: false
      })
    }

    const removeCheckbox = (index) => {
      customCheckboxes.value.splice(index, 1)
    }

    const loadTemplate = (templateType) => {
      switch (templateType) {
        case 'feature':
          taskData.title = 'Feature: '
          taskData.description = `## Feature Requirements
- User story: As a user, I want to...
- Acceptance criteria:
  - [ ] Requirement 1
  - [ ] Requirement 2
  - [ ] Requirement 3

## Implementation Notes
- Technical approach: 
- Dependencies: 
- Files to modify: `
          taskData.tags = 'feature, development'
          taskData.estimated_hours = 8
          customCheckboxes.value = [
            { label: 'User acceptance testing completed', required: true },
            { label: 'Performance impact assessed', required: false },
            { label: 'Accessibility standards met', required: true }
          ]
          break
          
        case 'bugfix':
          taskData.title = 'Bug Fix: '
          taskData.description = `## Bug Report
- Issue: 
- Steps to reproduce:
  1. 
  2. 
  3. 

## Expected Behavior

## Actual Behavior

## Root Cause

## Solution`
          taskData.tags = 'bug-fix, maintenance'
          taskData.estimated_hours = 2
          customCheckboxes.value = [
            { label: 'Bug reproduction confirmed', required: true },
            { label: 'Root cause identified', required: true },
            { label: 'Regression testing completed', required: true }
          ]
          break
          
        case 'research':
          taskData.title = 'Research: '
          taskData.description = `## Research Objectives
- Primary question: 
- Secondary questions:
  - 
  - 

## Methodology
- Approach: 
- Resources to investigate: 
- Timeline: 

## Expected Deliverables
- [ ] Research report
- [ ] Recommendations
- [ ] Next steps identified`
          taskData.tags = 'research, documentation'
          taskData.estimated_hours = 4
          customCheckboxes.value = [
            { label: 'Research sources documented', required: true },
            { label: 'Findings presented to team', required: false }
          ]
          break
          
        case 'testing':
          taskData.title = 'Testing: '
          taskData.description = `## Testing Scope
- Feature/component to test: 
- Test types needed:
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] E2E tests
  - [ ] Performance tests
  - [ ] Security tests

## Test Cases
- Happy path scenarios: 
- Edge cases: 
- Error conditions: 

## Coverage Requirements
- Minimum coverage: %`
          taskData.tags = 'testing, qa'
          taskData.estimated_hours = 3
          customCheckboxes.value = [
            { label: 'Test plan approved', required: true },
            { label: 'All tests passing', required: true },
            { label: 'Coverage threshold met', required: true }
          ]
          break
      }
    }

    const isFormValid = () => {
      return taskData.title.trim() && taskData.project_id
    }

    const createTask = async () => {
      if (!isFormValid() || isSubmitting.value) return

      isSubmitting.value = true

      try {
        const payload = {
          ...taskData,
          checkboxes: customCheckboxes.value.filter(cb => cb.label.trim())
        }

        const response = await fetch('http://localhost:3001/api/tasks', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })

        if (response.ok) {
          emit('created')
        } else {
          const error = await response.json()
          alert(`Error creating task: ${error.error}`)
        }
      } catch (error) {
        console.error('Error creating task:', error)
        alert('Failed to create task. Please try again.')
      } finally {
        isSubmitting.value = false
      }
    }

    return {
      taskData,
      customCheckboxes,
      isSubmitting,
      addCheckbox,
      removeCheckbox,
      loadTemplate,
      isFormValid,
      createTask
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
  background: rgba(0, 0, 0, 0.7);
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
  max-width: 800px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
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
}

.task-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.form-group label {
  font-weight: bold;
  color: #333;
  font-size: 0.95em;
}

.form-group input,
.form-group textarea,
.form-group select {
  padding: 12px;
  border: 2px solid #333;
  border-radius: 8px;
  font-family: 'Arial', sans-serif;
  font-size: 0.95em;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #4CAF50;
  box-shadow: 0 0 5px rgba(76, 175, 80, 0.3);
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
  font-family: monospace;
}

.checkboxes-section {
  border: 2px dashed #333;
  border-radius: 10px;
  padding: 20px;
  background: #f8f9fa;
}

.checkboxes-section h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
}

.help-text {
  color: #666;
  font-size: 0.9em;
  margin-bottom: 15px;
  line-height: 1.4;
}

.custom-checkboxes {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 15px;
}

.checkbox-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  background: white;
  border: 2px solid #dee2e6;
  border-radius: 8px;
}

.checkbox-input {
  flex: 1;
  padding: 8px 12px !important;
  border: 2px solid #ccc !important;
  border-radius: 6px !important;
}

.checkbox-required {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 0.9em;
  cursor: pointer;
  white-space: nowrap;
}

.checkbox-required input[type="checkbox"] {
  margin: 0;
  padding: 0;
  width: auto;
  height: auto;
}

.btn-remove-checkbox {
  background: #dc3545;
  color: white;
  border: 2px solid #333;
  border-radius: 6px;
  padding: 6px 10px;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.2s;
}

.btn-remove-checkbox:hover {
  background: #c82333;
  transform: scale(1.05);
}

.btn-add-checkbox {
  background: #17a2b8;
  color: white;
  border: 3px solid #333;
  border-radius: 8px;
  padding: 10px 20px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-add-checkbox:hover {
  background: #138496;
  transform: translateY(-1px);
}

.templates-section {
  border: 2px dashed #6c757d;
  border-radius: 10px;
  padding: 20px;
  background: #f1f3f4;
}

.templates-section h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
}

.template-buttons {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.btn-template {
  background: linear-gradient(145deg, #6c757d, #5a6268);
  color: white;
  border: 2px solid #333;
  border-radius: 8px;
  padding: 12px 16px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-template:hover {
  background: linear-gradient(145deg, #5a6268, #545b62);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.modal-footer {
  padding: 20px;
  border-top: 3px solid #333;
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  background: #f8f9fa;
  border-radius: 0 0 12px 12px;
}

.btn-create {
  background: linear-gradient(145deg, #4CAF50, #45a049);
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  padding: 12px 30px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-create:hover:not(:disabled) {
  background: linear-gradient(145deg, #45a049, #3e8e41);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.btn-create:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
}

.btn-cancel {
  background: #6c757d;
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  padding: 12px 30px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel:hover {
  background: #5a6268;
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .template-buttons {
    grid-template-columns: 1fr;
  }
  
  .modal-content {
    width: 95%;
    max-height: 95vh;
  }
}
</style>