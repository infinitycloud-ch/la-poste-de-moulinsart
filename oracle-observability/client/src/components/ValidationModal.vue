<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>🔍 Task Validation</h2>
        <button @click="$emit('close')" class="modal-close">×</button>
      </div>
      
      <div class="modal-body">
        <!-- Task Info -->
        <div class="task-info">
          <h3>{{ task.title }}</h3>
          <div class="task-meta">
            <span class="meta-item">📋 {{ task.project_name }}</span>
            <span class="meta-item">👤 {{ task.assigned_to }}</span>
            <span class="meta-item">⚡ {{ task.priority }}</span>
          </div>
        </div>

        <!-- Validation Checkboxes -->
        <div class="validation-section">
          <h4>📝 Validation Checklist</h4>
          <div class="checkbox-list">
            <div 
              v-for="checkbox in task.checkboxes" 
              :key="checkbox.id"
              class="checkbox-item"
              :class="{ 
                'completed': checkbox.completed, 
                'required': checkbox.required,
                'missing-evidence': checkbox.required && !checkbox.completed && !checkbox.evidence_url
              }"
            >
              <label class="checkbox-label">
                <input 
                  type="checkbox" 
                  v-model="checkboxStates[checkbox.id]"
                  @change="updateCheckbox(checkbox.id)"
                />
                <span class="checkbox-text">
                  {{ checkbox.label }}
                  <span v-if="checkbox.required" class="required-badge">REQUIRED</span>
                </span>
              </label>
              
              <!-- Evidence Upload Section -->
              <div v-if="checkboxStates[checkbox.id]" class="evidence-section">
                <div class="evidence-controls">
                  <input 
                    type="file" 
                    :id="`file-${checkbox.id}`"
                    @change="handleFileUpload(checkbox.id, $event)"
                    accept="image/*,.pdf,.txt,.log"
                    class="file-input"
                  />
                  <label 
                    :for="`file-${checkbox.id}`" 
                    class="btn-upload"
                  >
                    📎 Upload Evidence
                  </label>
                  
                  <input 
                    type="url"
                    v-model="evidenceUrls[checkbox.id]"
                    placeholder="Or paste URL to evidence..."
                    class="evidence-url"
                  />
                </div>
                
                <textarea 
                  v-model="checkboxNotes[checkbox.id]"
                  placeholder="Add validation notes..."
                  rows="2"
                  class="evidence-notes"
                ></textarea>
                
                <!-- Evidence Preview -->
                <div v-if="evidenceUrls[checkbox.id]" class="evidence-preview">
                  <div class="evidence-item">
                    <span class="evidence-type">🔗</span>
                    <a :href="evidenceUrls[checkbox.id]" target="_blank" class="evidence-link">
                      View Evidence
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Screenshot Upload -->
        <div class="screenshot-section">
          <h4>📸 Primary Screenshot</h4>
          <div class="upload-area" 
               @drop="handleScreenshotDrop" 
               @dragover.prevent 
               @dragenter.prevent>
            <input 
              type="file" 
              id="screenshot-upload"
              @change="handleScreenshotUpload"
              accept="image/*"
              class="file-input"
            />
            
            <div v-if="!screenshotFile" class="upload-placeholder">
              <div class="upload-icon">📸</div>
              <p>Drag & drop screenshot or 
                <label for="screenshot-upload" class="upload-link">click to browse</label>
              </p>
              <p class="upload-hint">Required for validation completion</p>
            </div>
            
            <div v-else class="screenshot-preview">
              <img :src="screenshotPreview" alt="Screenshot preview" />
              <div class="screenshot-info">
                <span class="filename">{{ screenshotFile.name }}</span>
                <button @click="removeScreenshot" class="btn-remove">🗑️</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Build Logs -->
        <div class="build-section">
          <h4>🔨 Build Information</h4>
          <div class="form-row">
            <div class="form-group">
              <label>Build Status</label>
              <select v-model="validationData.build_status">
                <option value="success">✅ Success</option>
                <option value="failed">❌ Failed</option>
                <option value="warning">⚠️ Warning</option>
                <option value="not_run">⚪ Not Run</option>
              </select>
            </div>
            
            <div class="form-group">
              <label>Build Log URL</label>
              <input 
                type="url"
                v-model="validationData.build_log_url"
                placeholder="Link to build logs..."
              />
            </div>
          </div>
        </div>

        <!-- Test Results -->
        <div class="test-section">
          <h4>🧪 Test Results</h4>
          <textarea 
            v-model="validationData.test_results"
            rows="4"
            placeholder="Paste test results or summary..."
            class="test-results"
          ></textarea>
          
          <div class="form-group">
            <label>Languages Tested</label>
            <div class="language-checkboxes">
              <label v-for="lang in availableLanguages" :key="lang" class="language-option">
                <input 
                  type="checkbox" 
                  :value="lang"
                  v-model="selectedLanguages"
                />
                <span>{{ lang }}</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Validation Notes -->
        <div class="notes-section">
          <h4>📝 Overall Validation Notes</h4>
          <textarea 
            v-model="validationData.validation_notes"
            rows="3"
            placeholder="Summary of validation, issues found, recommendations..."
            class="validation-notes"
          ></textarea>
        </div>

        <!-- Validation Status -->
        <div class="status-section">
          <h4>⚖️ Final Validation Status</h4>
          <div class="status-options">
            <label class="status-option approved">
              <input 
                type="radio" 
                value="approved" 
                v-model="validationData.validation_status"
              />
              <span class="status-text">✅ Approved - All validations passed</span>
            </label>
            
            <label class="status-option rejected">
              <input 
                type="radio" 
                value="rejected" 
                v-model="validationData.validation_status"
              />
              <span class="status-text">❌ Rejected - Issues found</span>
            </label>
            
            <label class="status-option conditional">
              <input 
                type="radio" 
                value="conditional" 
                v-model="validationData.validation_status"
              />
              <span class="status-text">⚠️ Conditional - Minor issues, can proceed</span>
            </label>
          </div>
        </div>

        <!-- Enforcement Warnings -->
        <div v-if="getEnforcementWarnings().length > 0" class="enforcement-warnings">
          <h4>🚨 Validation Enforcement</h4>
          <div v-for="warning in getEnforcementWarnings()" :key="warning" class="warning-item">
            ⚠️ {{ warning }}
          </div>
        </div>
      </div>
      
      <div class="modal-footer">
        <button 
          @click="submitValidation" 
          :disabled="!canSubmitValidation()" 
          class="btn-validate"
          :class="validationData.validation_status"
        >
          {{ getSubmitButtonText() }}
        </button>
        <button @click="$emit('close')" class="btn-cancel">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted } from 'vue'

export default {
  name: 'ValidationModal',
  props: {
    task: {
      type: Object,
      required: true
    }
  },
  emits: ['close', 'validated'],
  setup(props, { emit }) {
    const checkboxStates = ref({})
    const checkboxNotes = ref({})
    const evidenceUrls = ref({})
    const screenshotFile = ref(null)
    const screenshotPreview = ref('')
    const selectedLanguages = ref([])
    const isSubmitting = ref(false)

    const availableLanguages = [
      'English', 'Spanish', 'French', 'German', 
      'Italian', 'Portuguese', 'Japanese', 'Chinese'
    ]

    const validationData = reactive({
      validation_status: 'pending',
      validation_notes: '',
      build_status: 'not_run',
      build_log_url: '',
      test_results: '',
      languages_tested: ''
    })

    // Initialize checkbox states
    onMounted(() => {
      if (props.task.checkboxes) {
        props.task.checkboxes.forEach(checkbox => {
          checkboxStates.value[checkbox.id] = checkbox.completed
          checkboxNotes.value[checkbox.id] = checkbox.notes || ''
          evidenceUrls.value[checkbox.id] = checkbox.evidence_url || ''
        })
      }
    })

    const updateCheckbox = (checkboxId) => {
      // Logic for when checkbox state changes
      console.log(`Checkbox ${checkboxId} updated:`, checkboxStates.value[checkboxId])
    }

    const handleFileUpload = async (checkboxId, event) => {
      const file = event.target.files[0]
      if (!file) return

      try {
        const formData = new FormData()
        formData.append('file', file)
        formData.append('taskId', props.task.id)

        const response = await fetch('http://localhost:3001/api/upload/evidence', {
          method: 'POST',
          body: formData
        })

        if (response.ok) {
          const result = await response.json()
          evidenceUrls.value[checkboxId] = result.evidenceUrl
        } else {
          alert('Failed to upload file')
        }
      } catch (error) {
        console.error('Upload error:', error)
        alert('Upload failed')
      }
    }

    const handleScreenshotUpload = (event) => {
      const file = event.target.files[0]
      if (!file) return

      screenshotFile.value = file
      screenshotPreview.value = URL.createObjectURL(file)
    }

    const handleScreenshotDrop = (event) => {
      event.preventDefault()
      const file = event.dataTransfer.files[0]
      
      if (file && file.type.startsWith('image/')) {
        screenshotFile.value = file
        screenshotPreview.value = URL.createObjectURL(file)
      }
    }

    const removeScreenshot = () => {
      if (screenshotPreview.value) {
        URL.revokeObjectURL(screenshotPreview.value)
      }
      screenshotFile.value = null
      screenshotPreview.value = ''
    }

    const getEnforcementWarnings = () => {
      const warnings = []
      
      // Check required checkboxes
      const requiredIncomplete = props.task.checkboxes?.filter(cb => 
        cb.required && !checkboxStates.value[cb.id]
      ) || []
      
      if (requiredIncomplete.length > 0) {
        warnings.push(`${requiredIncomplete.length} required validation(s) not completed`)
      }

      // Check screenshot requirement
      if (!screenshotFile.value && validationData.validation_status === 'approved') {
        warnings.push('Screenshot is required for approved validations')
      }

      // Check build status
      if (validationData.build_status === 'failed' && validationData.validation_status === 'approved') {
        warnings.push('Cannot approve with failed build status')
      }

      return warnings
    }

    const canSubmitValidation = () => {
      if (isSubmitting.value) return false
      
      // Must have validation status selected
      if (validationData.validation_status === 'pending') return false

      // For approved status, must have screenshot and all required checkboxes
      if (validationData.validation_status === 'approved') {
        const requiredIncomplete = props.task.checkboxes?.some(cb => 
          cb.required && !checkboxStates.value[cb.id]
        ) || false
        
        if (requiredIncomplete || !screenshotFile.value) return false
      }

      return true
    }

    const getSubmitButtonText = () => {
      const statusTexts = {
        approved: '✅ Approve Task',
        rejected: '❌ Reject Task', 
        conditional: '⚠️ Conditionally Approve',
        pending: 'Select Status'
      }
      return statusTexts[validationData.validation_status] || 'Submit Validation'
    }

    const submitValidation = async () => {
      if (!canSubmitValidation()) return

      isSubmitting.value = true

      try {
        // Upload screenshot if provided
        let screenshotPath = ''
        if (screenshotFile.value) {
          const formData = new FormData()
          formData.append('file', screenshotFile.value)
          formData.append('taskId', props.task.id)

          const uploadResponse = await fetch('http://localhost:3001/api/upload/evidence', {
            method: 'POST',
            body: formData
          })

          if (uploadResponse.ok) {
            const result = await uploadResponse.json()
            screenshotPath = result.evidenceUrl
          }
        }

        // Prepare checkbox updates
        const checkboxUpdates = props.task.checkboxes?.map(checkbox => ({
          checkbox_id: checkbox.id,
          completed: checkboxStates.value[checkbox.id] || false,
          evidence_url: evidenceUrls.value[checkbox.id] || '',
          evidence_type: evidenceUrls.value[checkbox.id] ? 'url' : '',
          notes: checkboxNotes.value[checkbox.id] || ''
        })) || []

        // Submit validation
        const payload = {
          screenshot_path: screenshotPath,
          validated_by: 'dashboard-user', // TODO: Get actual user
          validation_status: validationData.validation_status,
          validation_notes: validationData.validation_notes,
          build_log_url: validationData.build_log_url,
          test_results: validationData.test_results,
          languages_tested: selectedLanguages.value.join(', '),
          checkbox_updates: checkboxUpdates
        }

        const response = await fetch(`http://localhost:3001/api/tasks/${props.task.id}/validate`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })

        if (response.ok) {
          emit('validated')
        } else {
          const error = await response.json()
          alert(`Validation failed: ${error.error}`)
        }
      } catch (error) {
        console.error('Validation error:', error)
        alert('Failed to submit validation')
      } finally {
        isSubmitting.value = false
      }
    }

    return {
      checkboxStates,
      checkboxNotes,
      evidenceUrls,
      screenshotFile,
      screenshotPreview,
      selectedLanguages,
      availableLanguages,
      validationData,
      isSubmitting,
      updateCheckbox,
      handleFileUpload,
      handleScreenshotUpload,
      handleScreenshotDrop,
      removeScreenshot,
      getEnforcementWarnings,
      canSubmitValidation,
      getSubmitButtonText,
      submitValidation
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
  max-width: 900px;
  max-height: 95vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #17a2b8 0%, #138496 100%);
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
  gap: 25px;
}

.task-info {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 10px;
  border: 2px solid #dee2e6;
}

.task-info h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
}

.task-meta {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
}

.meta-item {
  font-size: 0.9em;
  color: #666;
  font-weight: bold;
}

.validation-section h4,
.screenshot-section h4,
.build-section h4,
.test-section h4,
.notes-section h4,
.status-section h4,
.enforcement-warnings h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.2em;
}

.checkbox-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.checkbox-item {
  border: 2px solid #dee2e6;
  border-radius: 10px;
  padding: 15px;
  background: white;
  transition: all 0.2s;
}

.checkbox-item.completed {
  background: #d4edda;
  border-color: #c3e6cb;
}

.checkbox-item.required {
  border-left: 6px solid #ffc107;
}

.checkbox-item.missing-evidence {
  border-color: #dc3545;
  background: #f8d7da;
}

.checkbox-label {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  cursor: pointer;
  margin-bottom: 10px;
}

.checkbox-label input[type="checkbox"] {
  margin: 0;
  transform: scale(1.2);
}

.checkbox-text {
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

.evidence-section {
  background: #f1f3f4;
  padding: 10px;
  border-radius: 8px;
  border: 1px solid #dee2e6;
}

.evidence-controls {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
  flex-wrap: wrap;
}

.file-input {
  display: none;
}

.btn-upload {
  background: #6c757d;
  color: white;
  border: 2px solid #333;
  border-radius: 6px;
  padding: 6px 12px;
  cursor: pointer;
  font-size: 0.85em;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-upload:hover {
  background: #5a6268;
  transform: translateY(-1px);
}

.evidence-url {
  flex: 1;
  padding: 6px 10px;
  border: 2px solid #ccc;
  border-radius: 6px;
  font-size: 0.85em;
  min-width: 200px;
}

.evidence-notes {
  width: 100%;
  padding: 8px;
  border: 2px solid #ccc;
  border-radius: 6px;
  font-family: monospace;
  font-size: 0.85em;
  resize: vertical;
}

.evidence-preview {
  margin-top: 8px;
}

.evidence-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px;
  background: white;
  border-radius: 6px;
  border: 1px solid #dee2e6;
}

.evidence-link {
  color: #007bff;
  text-decoration: none;
  font-weight: bold;
}

.evidence-link:hover {
  text-decoration: underline;
}

.upload-area {
  border: 3px dashed #ccc;
  border-radius: 10px;
  padding: 30px;
  text-align: center;
  transition: all 0.2s;
  cursor: pointer;
}

.upload-area:hover {
  border-color: #17a2b8;
  background: #f8f9fa;
}

.upload-placeholder {
  color: #6c757d;
}

.upload-icon {
  font-size: 3em;
  margin-bottom: 10px;
}

.upload-link {
  color: #007bff;
  cursor: pointer;
  text-decoration: underline;
}

.upload-hint {
  font-size: 0.9em;
  color: #999;
  margin-top: 5px;
}

.screenshot-preview {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.screenshot-preview img {
  max-width: 300px;
  max-height: 200px;
  object-fit: contain;
  border: 2px solid #333;
  border-radius: 8px;
}

.screenshot-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.filename {
  font-weight: bold;
  color: #333;
}

.btn-remove {
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 4px 8px;
  cursor: pointer;
  font-size: 0.9em;
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
}

.form-group input,
.form-group select {
  padding: 8px;
  border: 2px solid #ccc;
  border-radius: 6px;
}

.test-results,
.validation-notes {
  width: 100%;
  padding: 10px;
  border: 2px solid #ccc;
  border-radius: 8px;
  font-family: monospace;
  font-size: 0.9em;
  resize: vertical;
}

.language-checkboxes {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin-top: 8px;
}

.language-option {
  display: flex;
  align-items: center;
  gap: 5px;
  cursor: pointer;
  font-size: 0.9em;
}

.status-options {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.status-option {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  border: 2px solid #dee2e6;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.status-option:hover {
  background: #f8f9fa;
}

.status-option.approved {
  border-color: #28a745;
}

.status-option.rejected {
  border-color: #dc3545;
}

.status-option.conditional {
  border-color: #ffc107;
}

.status-text {
  font-weight: bold;
  font-size: 1.1em;
}

.enforcement-warnings {
  background: #fff3cd;
  border: 2px solid #ffeaa7;
  border-radius: 10px;
  padding: 15px;
}

.warning-item {
  color: #856404;
  font-weight: bold;
  margin-bottom: 5px;
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

.btn-validate {
  border: 3px solid #333;
  border-radius: 10px;
  padding: 12px 30px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
  color: white;
}

.btn-validate.approved {
  background: linear-gradient(145deg, #28a745, #20c997);
}

.btn-validate.rejected {
  background: linear-gradient(145deg, #dc3545, #c82333);
}

.btn-validate.conditional {
  background: linear-gradient(145deg, #ffc107, #fd7e14);
}

.btn-validate.pending {
  background: #6c757d;
}

.btn-validate:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.btn-validate:disabled {
  background: #ccc !important;
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
  
  .language-checkboxes {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .evidence-controls {
    flex-direction: column;
  }
  
  .evidence-url {
    min-width: auto;
  }
}
</style>