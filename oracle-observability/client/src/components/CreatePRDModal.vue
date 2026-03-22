<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-container">
      <div class="modal-header">
        <h2>📝 Create New PRD</h2>
        <button class="btn-close" @click="$emit('close')">✕</button>
      </div>

      <div class="modal-content">
        <div class="form-group">
          <label>PRD Name</label>
          <input 
            v-model="prdName" 
            type="text" 
            placeholder="e.g., mobile_app, user_dashboard"
            class="form-input"
            @input="validateName"
          >
          <small>Will be saved as: {{ filename }}</small>
        </div>

        <div class="form-group">
          <label>PRD Content (Markdown)</label>
          <textarea 
            v-model="prdContent" 
            class="form-textarea"
            placeholder="# 📱 Project Title

## 🎯 Objective
Describe the main goal...

## 📋 Features
### Feature 1
- Detail 1
- Detail 2

### Feature 2
- Detail 1
- Detail 2

## 🛠️ Technical Specifications
- Technology stack
- Architecture
- Dependencies

## 📅 Timeline
- Phase 1: ...
- Phase 2: ...

## ✅ Success Criteria
- Criteria 1
- Criteria 2"
            rows="20"
          ></textarea>
        </div>

        <div class="form-actions">
          <button @click="$emit('close')" class="btn-cancel">
            Cancel
          </button>
          <button @click="savePRD" class="btn-save" :disabled="!isValid">
            💾 Save PRD
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'

export default {
  name: 'CreatePRDModal',
  emits: ['close', 'created'],
  setup(props, { emit }) {
    const prdName = ref('')
    const prdContent = ref('')

    const filename = computed(() => {
      if (!prdName.value) return '[name]_prd.md'
      const sanitized = prdName.value
        .toLowerCase()
        .replace(/[^a-z0-9_-]/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_|_$/g, '')
      return `${sanitized}_prd.md`
    })

    const isValid = computed(() => {
      return prdName.value.trim().length > 0 && prdContent.value.trim().length > 0
    })

    const validateName = () => {
      // Remove spaces and special characters except underscore and hyphen
      prdName.value = prdName.value.replace(/[^a-zA-Z0-9_-]/g, '_')
    }

    const savePRD = async () => {
      if (!isValid.value) return

      try {
        const sanitizedName = prdName.value
          .toLowerCase()
          .replace(/[^a-z0-9_-]/g, '_')
          .replace(/_+/g, '_')
          .replace(/^_|_$/g, '')

        const response = await fetch('http://localhost:3001/api/prds', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: sanitizedName,
            content: prdContent.value
          })
        })

        if (response.ok) {
          const result = await response.json()
          emit('created', result)
          emit('close')
        } else {
          const error = await response.json()
          alert(`Error saving PRD: ${error.error || 'Unknown error'}`)
        }
      } catch (error) {
        console.error('Error saving PRD:', error)
        alert('Failed to save PRD. Please try again.')
      }
    }

    // Set a default template
    prdContent.value = `# 📱 [Project Title]

## 🎯 Objective
[Describe the main goal and purpose of this project]

## 📋 Features

### 1. [Feature Name]
- [Feature description]
- [Key functionality]
- [User benefit]

### 2. [Feature Name]
- [Feature description]
- [Key functionality]
- [User benefit]

### 3. [Feature Name]
- [Feature description]
- [Key functionality]
- [User benefit]

## 🛠️ Technical Specifications
- **Framework**: [e.g., React Native, Vue.js]
- **Backend**: [e.g., Node.js, Python]
- **Database**: [e.g., PostgreSQL, MongoDB]
- **APIs**: [List of APIs needed]

## 📅 Timeline
- **Phase 1**: [Description] (X days)
- **Phase 2**: [Description] (X days)
- **Phase 3**: [Description] (X days)

## ✅ Success Criteria
- [Measurable criteria 1]
- [Measurable criteria 2]
- [Measurable criteria 3]
`

    return {
      prdName,
      prdContent,
      filename,
      isValid,
      validateName,
      savePRD
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
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-container {
  background: white;
  border-radius: 15px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
  border: 3px solid #333;
}

.modal-header {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 12px 12px 0 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 3px solid #333;
}

.modal-header h2 {
  margin: 0;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.5em;
}

.btn-close {
  background: white;
  color: #333;
  border: 2px solid #333;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  font-size: 1.2em;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-close:hover {
  transform: rotate(90deg);
  background: #ff6b6b;
  color: white;
}

.modal-content {
  padding: 30px;
  overflow-y: auto;
  flex: 1;
}

.form-group {
  margin-bottom: 25px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: bold;
  color: #333;
  font-size: 1.1em;
}

.form-group small {
  display: block;
  margin-top: 5px;
  color: #666;
  font-style: italic;
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 12px;
  border: 2px solid #333;
  border-radius: 8px;
  font-size: 1em;
  font-family: inherit;
  transition: all 0.3s ease;
}

.form-textarea {
  font-family: 'Courier New', monospace;
  resize: vertical;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 15px;
  padding-top: 20px;
  border-top: 2px solid #f0f0f0;
  margin-top: 30px;
}

.btn-cancel,
.btn-save {
  padding: 12px 24px;
  border: 3px solid #333;
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1em;
}

.btn-cancel {
  background: #f8f9fa;
  color: #333;
}

.btn-cancel:hover {
  background: #e9ecef;
  transform: translateY(-2px);
}

.btn-save {
  background: linear-gradient(145deg, #667eea, #764ba2);
  color: white;
}

.btn-save:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(102, 126, 234, 0.3);
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>