<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>📋 PRD Splitter - Break Down Project into Tasks</h2>
        <button @click="$emit('close')" class="modal-close">×</button>
      </div>
      
      <div class="modal-body">
        <!-- Project Selection -->
        <div class="project-section">
          <h3>🎯 Select Project</h3>
          <select v-model="selectedProject" @change="loadProjectPRD" class="project-select">
            <option value="">Choose a project...</option>
            <option 
              v-for="project in projects" 
              :key="project.id" 
              :value="project"
            >
              {{ project.name }}
            </option>
          </select>
        </div>

        <!-- PRD Input -->
        <div v-if="selectedProject" class="prd-section">
          <h3>📄 Product Requirements Document</h3>
          
          <!-- PRD File Selector -->
          <div class="prd-file-selector">
            <label>📁 Load PRD from File:</label>
            <select v-model="selectedPRDFile" @change="loadPRDFile" class="prd-file-select">
              <option value="">-- Select a PRD file --</option>
              <option v-for="prd in availablePRDs" :key="prd.filename" :value="prd.filename">
                {{ prd.name }} ({{ new Date(prd.modified).toLocaleDateString() }})
              </option>
            </select>
            <button @click="refreshPRDList" class="btn-refresh">🔄 Refresh</button>
          </div>
          
          <div class="prd-input-area">
            <textarea 
              v-model="prdContent"
              rows="12"
              placeholder="Paste your PRD here or type the requirements..."
              class="prd-textarea"
            ></textarea>
            
            <div class="prd-actions">
              <button @click="loadSamplePRD" class="btn-sample">📝 Load Sample PRD</button>
              <button @click="analyzeComplexity" class="btn-analyze">🔍 Analyze Complexity</button>
              <button @click="splitIntoParts" class="btn-split">⚡ Auto-Split</button>
            </div>
          </div>
          
          <!-- Complexity Analysis -->
          <div v-if="complexityAnalysis" class="complexity-display">
            <h4>📊 Complexity Analysis</h4>
            <div class="complexity-stats">
              <div class="stat-item">
                <span class="stat-label">Estimated Tasks:</span>
                <span class="stat-value">{{ complexityAnalysis.estimated_tasks }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">Total Hours:</span>
                <span class="stat-value">{{ complexityAnalysis.total_hours }}h</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">Sprint Duration:</span>
                <span class="stat-value">{{ complexityAnalysis.sprint_weeks }} weeks</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Task Breakdown -->
        <div v-if="generatedTasks.length > 0" class="tasks-section">
          <h3>🎯 Generated Tasks</h3>
          <div class="tasks-list">
            <div 
              v-for="(task, index) in generatedTasks" 
              :key="index"
              class="task-item"
              :class="{ 'invalid': !isTaskValid(task) }"
            >
              <div class="task-header">
                <input 
                  v-model="task.title"
                  placeholder="Task title..."
                  class="task-title-input"
                  :class="{ 'error': !task.title.trim() }"
                />
                <select v-model="task.priority" class="task-priority">
                  <option value="low">🟢 Low</option>
                  <option value="medium">🟡 Medium</option>
                  <option value="high">🟠 High</option>
                  <option value="urgent">🔴 Urgent</option>
                </select>
                <button @click="removeTask(index)" class="btn-remove-task">🗑️</button>
              </div>
              
              <textarea 
                v-model="task.description"
                rows="3"
                placeholder="Task description and acceptance criteria..."
                class="task-description"
              ></textarea>
              
              <div class="task-meta">
                <div class="meta-group">
                  <label>Assign to:</label>
                  <select v-model="task.assigned_to" class="task-assignee">
                    <option value="">Unassigned</option>
                    <option value="nestor">🎩 Nestor</option>
                    <option value="tintin">🚀 Tintin</option>
                    <option value="dupont1">🎨 Dupont1</option>
                    <option value="dupont2">🔍 Dupont2</option>
                  </select>
                </div>
                
                <div class="meta-group">
                  <label>Est. Hours:</label>
                  <input 
                    v-model="task.estimated_hours"
                    type="number"
                    min="0.5"
                    step="0.5"
                    class="task-hours"
                  />
                </div>
                
                <div class="meta-group">
                  <label>Sprint:</label>
                  <select v-model="task.sprint" class="task-sprint">
                    <option value="1">Sprint 1</option>
                    <option value="2">Sprint 2</option>
                    <option value="3">Sprint 3</option>
                    <option value="4">Sprint 4</option>
                  </select>
                </div>
              </div>
              
              <!-- Task Dependencies -->
              <div class="task-dependencies">
                <label>Dependencies (task indices):</label>
                <input 
                  v-model="task.dependencies"
                  placeholder="e.g. 0,1,3 (depends on tasks at those indices)"
                  class="dependencies-input"
                />
              </div>
            </div>
          </div>
          
          <div class="tasks-actions">
            <button @click="addNewTask" class="btn-add-task">➕ Add Task</button>
            <button @click="balanceWorkload" class="btn-balance">⚖️ Balance Workload</button>
            <button @click="suggestSprints" class="btn-sprints">📅 Suggest Sprints</button>
          </div>
        </div>

        <!-- Sprint Planning Overview -->
        <div v-if="generatedTasks.length > 0" class="sprint-overview">
          <h3>📅 Sprint Planning Overview</h3>
          <div class="sprints-grid">
            <div v-for="sprint in getSprintBreakdown()" :key="sprint.number" class="sprint-card">
              <h4>Sprint {{ sprint.number }}</h4>
              <div class="sprint-stats">
                <div class="stat">{{ sprint.tasks.length }} tasks</div>
                <div class="stat">{{ sprint.total_hours }}h total</div>
              </div>
              <div class="sprint-agents">
                <div v-for="agent in sprint.agents" :key="agent.name" class="agent-workload">
                  <span class="agent-icon">{{ getAgentIcon(agent.name) }}</span>
                  <span class="agent-name">{{ agent.name }}</span>
                  <span class="agent-hours">{{ agent.hours }}h</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Validation Summary -->
        <div v-if="generatedTasks.length > 0" class="validation-summary">
          <h3>✅ Validation Summary</h3>
          <div class="validation-checks">
            <div class="check-item" :class="{ 'pass': allTasksValid(), 'fail': !allTasksValid() }">
              <span class="check-icon">{{ allTasksValid() ? '✅' : '❌' }}</span>
              <span>All tasks have titles and descriptions</span>
            </div>
            <div class="check-item" :class="{ 'pass': isWorkloadBalanced(), 'fail': !isWorkloadBalanced() }">
              <span class="check-icon">{{ isWorkloadBalanced() ? '✅' : '⚠️' }}</span>
              <span>Workload is reasonably balanced</span>
            </div>
            <div class="check-item" :class="{ 'pass': hasDependencyOrder(), 'fail': !hasDependencyOrder() }">
              <span class="check-icon">{{ hasDependencyOrder() ? '✅' : '⚠️' }}</span>
              <span>Dependencies are in logical order</span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="modal-footer">
        <div class="footer-stats">
          <span>{{ generatedTasks.length }} tasks • {{ getTotalHours() }}h total</span>
        </div>
        <div class="footer-actions">
          <button 
            @click="createTasks" 
            :disabled="!canCreateTasks()" 
            class="btn-create-tasks"
          >
            🚀 Create {{ generatedTasks.length }} Tasks
          </button>
          <button @click="$emit('close')" class="btn-cancel">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed } from 'vue'

export default {
  name: 'PRDSplitterModal',
  props: {
    projects: {
      type: Array,
      default: () => []
    }
  },
  emits: ['close', 'tasks-created'],
  setup(props, { emit }) {
    const selectedProject = ref(null)
    const prdContent = ref('')
    const generatedTasks = ref([])
    const complexityAnalysis = ref(null)
    const isCreating = ref(false)
    const availablePRDs = ref([])
    const selectedPRDFile = ref('')

    const loadProjectPRD = async () => {
      if (selectedProject.value?.prd) {
        prdContent.value = selectedProject.value.prd
      }
      // Load available PRD files
      await refreshPRDList()
    }
    
    const refreshPRDList = async () => {
      try {
        const response = await fetch('http://localhost:3001/api/prds')
        if (response.ok) {
          const data = await response.json()
          availablePRDs.value = data.prds || []
        }
      } catch (error) {
        console.error('Error loading PRD files:', error)
      }
    }
    
    const loadPRDFile = async () => {
      if (!selectedPRDFile.value) return
      
      try {
        const response = await fetch(`http://localhost:3001/api/prds/${selectedPRDFile.value}`)
        if (response.ok) {
          const data = await response.json()
          prdContent.value = data.content
          // Auto-analyze after loading
          analyzeComplexity()
        } else {
          console.error('Failed to load PRD file')
        }
      } catch (error) {
        console.error('Error loading PRD file:', error)
      }
    }

    const loadSamplePRD = () => {
      prdContent.value = `# iOS Task Management App

## Overview
Build a modern task management application for iOS using SwiftUI that allows users to create, organize, and track their daily tasks with a clean, intuitive interface.

## Core Features

### 1. Task Management
- Create new tasks with title, description, due date, and priority
- Edit existing tasks
- Mark tasks as complete/incomplete
- Delete tasks with confirmation
- Task categories/tags

### 2. User Interface
- Clean, modern SwiftUI design
- Dark/light mode support
- Smooth animations and transitions
- Accessibility features (VoiceOver, Dynamic Type)
- iPad optimized layout

### 3. Data Persistence
- Core Data for local storage
- iCloud sync for multi-device access
- Export tasks to CSV/JSON
- Backup/restore functionality

### 4. Advanced Features
- Search and filter tasks
- Task reminders/notifications
- Statistics and productivity metrics
- Widget support for home screen
- Siri shortcuts integration

## Technical Requirements
- iOS 15.0+ target
- SwiftUI framework
- Core Data for persistence
- CloudKit for sync
- Combine for reactive programming
- Unit tests with 80%+ coverage
- UI tests for critical flows

## Acceptance Criteria
- App launches in under 2 seconds
- All animations are smooth (60fps)
- Supports iPhone and iPad
- Passes Apple's accessibility audit
- No memory leaks or crashes
- Follows iOS Human Interface Guidelines

## Timeline
Estimated 4-6 weeks of development with a team of 4 developers.`
    }

    const analyzeComplexity = () => {
      const words = prdContent.value.split(/\s+/).length
      const features = (prdContent.value.match(/#{1,3}\s+\d+\./g) || []).length
      const requirements = (prdContent.value.match(/^-\s+/gm) || []).length
      
      const estimated_tasks = Math.max(6, Math.ceil(features * 2.5 + requirements * 0.5))
      const total_hours = estimated_tasks * 6 // Average 6 hours per task
      const sprint_weeks = Math.ceil(total_hours / 160) // 4 people * 40 hours

      complexityAnalysis.value = {
        estimated_tasks,
        total_hours,
        sprint_weeks,
        features,
        requirements,
        complexity: words > 500 ? 'High' : words > 200 ? 'Medium' : 'Low'
      }
    }

    const splitIntoParts = () => {
      if (!prdContent.value.trim()) return

      // Simple PRD parsing logic
      const lines = prdContent.value.split('\n')
      const tasks = []
      
      let currentSection = ''
      let currentDescription = ''
      
      for (const line of lines) {
        const trimmed = line.trim()
        
        // Main headers (# ## ###)
        if (trimmed.match(/^#{1,3}\s+(.+)/)) {
          if (currentSection && currentDescription.length > 20) {
            tasks.push(createTaskFromSection(currentSection, currentDescription))
          }
          currentSection = trimmed.replace(/^#+\s+/, '')
          currentDescription = ''
        }
        // List items
        else if (trimmed.match(/^[-*]\s+(.+)/)) {
          const item = trimmed.replace(/^[-*]\s+/, '')
          if (item.length > 10) {
            tasks.push(createTaskFromItem(currentSection, item))
          }
        }
        // Regular content
        else if (trimmed) {
          currentDescription += trimmed + ' '
        }
      }
      
      // Add final section
      if (currentSection && currentDescription.length > 20) {
        tasks.push(createTaskFromSection(currentSection, currentDescription))
      }

      // Add some default tasks if too few were generated
      if (tasks.length < 3) {
        tasks.push(
          {
            title: 'Project Setup & Architecture',
            description: 'Set up the project structure, configure dependencies, and establish coding standards.',
            assigned_to: 'dupont1',
            priority: 'high',
            estimated_hours: 8,
            sprint: '1',
            dependencies: ''
          },
          {
            title: 'Core Data Model Implementation',
            description: 'Design and implement the data models using Core Data.',
            assigned_to: 'dupont1',
            priority: 'high',
            estimated_hours: 6,
            sprint: '1',
            dependencies: '0'
          },
          {
            title: 'UI Testing & Quality Assurance',
            description: 'Comprehensive testing of all features and user flows.',
            assigned_to: 'tintin',
            priority: 'medium',
            estimated_hours: 12,
            sprint: '4',
            dependencies: ''
          }
        )
      }

      generatedTasks.value = tasks
    }

    const createTaskFromSection = (section, description) => {
      const agents = ['dupont1', 'tintin', 'dupont2', 'nestor']
      return {
        title: `Implement ${section}`,
        description: description.trim(),
        assigned_to: agents[Math.floor(Math.random() * agents.length)],
        priority: section.toLowerCase().includes('core') ? 'high' : 'medium',
        estimated_hours: Math.ceil(Math.random() * 6 + 2),
        sprint: Math.ceil(Math.random() * 3).toString(),
        dependencies: ''
      }
    }

    const createTaskFromItem = (section, item) => {
      const agents = ['dupont1', 'tintin', 'dupont2']
      return {
        title: item.length > 50 ? item.substring(0, 47) + '...' : item,
        description: `Implement: ${item}\n\nAs part of ${section}, this task involves detailed implementation of the specified feature.`,
        assigned_to: agents[Math.floor(Math.random() * agents.length)],
        priority: 'medium',
        estimated_hours: Math.ceil(Math.random() * 4 + 1),
        sprint: Math.ceil(Math.random() * 3).toString(),
        dependencies: ''
      }
    }

    const addNewTask = () => {
      generatedTasks.value.push({
        title: '',
        description: '',
        assigned_to: '',
        priority: 'medium',
        estimated_hours: 4,
        sprint: '1',
        dependencies: ''
      })
    }

    const removeTask = (index) => {
      generatedTasks.value.splice(index, 1)
    }

    const balanceWorkload = () => {
      const agents = ['nestor', 'tintin', 'dupont1', 'dupont2']
      const workload = agents.reduce((acc, agent) => ({ ...acc, [agent]: 0 }), {})
      
      // Calculate current workload
      generatedTasks.value.forEach(task => {
        if (task.assigned_to) {
          workload[task.assigned_to] += parseFloat(task.estimated_hours) || 0
        }
      })
      
      // Reassign tasks to balance workload
      const sortedTasks = [...generatedTasks.value]
        .sort((a, b) => (parseFloat(b.estimated_hours) || 0) - (parseFloat(a.estimated_hours) || 0))
      
      sortedTasks.forEach(task => {
        const leastBusyAgent = Object.keys(workload)
          .reduce((min, agent) => workload[agent] < workload[min] ? agent : min)
        
        if (task.assigned_to) {
          workload[task.assigned_to] -= parseFloat(task.estimated_hours) || 0
        }
        
        task.assigned_to = leastBusyAgent
        workload[leastBusyAgent] += parseFloat(task.estimated_hours) || 0
      })
    }

    const suggestSprints = () => {
      const tasksPerSprint = Math.ceil(generatedTasks.value.length / 3)
      
      generatedTasks.value.forEach((task, index) => {
        task.sprint = Math.ceil((index + 1) / tasksPerSprint).toString()
      })
    }

    const getSprintBreakdown = () => {
      const sprints = {}
      
      generatedTasks.value.forEach(task => {
        const sprintNum = task.sprint || '1'
        if (!sprints[sprintNum]) {
          sprints[sprintNum] = {
            number: sprintNum,
            tasks: [],
            total_hours: 0,
            agents: {}
          }
        }
        
        sprints[sprintNum].tasks.push(task)
        sprints[sprintNum].total_hours += parseFloat(task.estimated_hours) || 0
        
        const agent = task.assigned_to || 'unassigned'
        if (!sprints[sprintNum].agents[agent]) {
          sprints[sprintNum].agents[agent] = { name: agent, hours: 0 }
        }
        sprints[sprintNum].agents[agent].hours += parseFloat(task.estimated_hours) || 0
      })
      
      // Convert to array and sort agents by hours
      return Object.values(sprints).map(sprint => ({
        ...sprint,
        agents: Object.values(sprint.agents).sort((a, b) => b.hours - a.hours)
      }))
    }

    const getAgentIcon = (agentName) => {
      const icons = {
        nestor: '🎩',
        tintin: '🚀',
        dupont1: '🎨',
        dupont2: '🔍'
      }
      return icons[agentName] || '👤'
    }

    const isTaskValid = (task) => {
      return task.title.trim() && task.description.trim()
    }

    const allTasksValid = () => {
      return generatedTasks.value.length > 0 && generatedTasks.value.every(isTaskValid)
    }

    const isWorkloadBalanced = () => {
      const workload = {}
      generatedTasks.value.forEach(task => {
        const agent = task.assigned_to || 'unassigned'
        workload[agent] = (workload[agent] || 0) + (parseFloat(task.estimated_hours) || 0)
      })
      
      const hours = Object.values(workload)
      const max = Math.max(...hours)
      const min = Math.min(...hours)
      
      return hours.length > 1 ? (max - min) / max < 0.5 : true
    }

    const hasDependencyOrder = () => {
      // Simple check: no task depends on a task with higher index
      return generatedTasks.value.every((task, index) => {
        if (!task.dependencies) return true
        const deps = task.dependencies.split(',').map(d => parseInt(d.trim())).filter(d => !isNaN(d))
        return deps.every(dep => dep < index)
      })
    }

    const getTotalHours = () => {
      return generatedTasks.value.reduce((total, task) => total + (parseFloat(task.estimated_hours) || 0), 0)
    }

    const canCreateTasks = () => {
      return selectedProject.value && allTasksValid() && !isCreating.value
    }

    const createTasks = async () => {
      if (!canCreateTasks()) return

      isCreating.value = true

      try {
        const response = await fetch('http://localhost:3001/api/projects/split', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            project_id: selectedProject.value.id,
            prd_content: prdContent.value,
            task_breakdown: generatedTasks.value
          })
        })

        if (response.ok) {
          emit('tasks-created')
        } else {
          const error = await response.json()
          alert(`Error creating tasks: ${error.error}`)
        }
      } catch (error) {
        console.error('Error creating tasks:', error)
        alert('Failed to create tasks. Please try again.')
      } finally {
        isCreating.value = false
      }
    }

    return {
      selectedProject,
      prdContent,
      generatedTasks,
      complexityAnalysis,
      isCreating,
      availablePRDs,
      selectedPRDFile,
      loadProjectPRD,
      refreshPRDList,
      loadPRDFile,
      loadSamplePRD,
      analyzeComplexity,
      splitIntoParts,
      addNewTask,
      removeTask,
      balanceWorkload,
      suggestSprints,
      getSprintBreakdown,
      getAgentIcon,
      isTaskValid,
      allTasksValid,
      isWorkloadBalanced,
      hasDependencyOrder,
      getTotalHours,
      canCreateTasks,
      createTasks
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
  width: 95%;
  max-width: 1200px;
  max-height: 95vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
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
  font-size: 1.4em;
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

.project-section h3,
.prd-section h3,
.tasks-section h3,
.sprint-overview h3,
.validation-summary h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
  font-size: 1.3em;
}

.project-select {
  width: 100%;
  padding: 12px;
  border: 3px solid #333;
  border-radius: 10px;
  font-size: 1.1em;
  font-weight: bold;
  background: white;
}

.prd-file-selector {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
  padding: 16px;
  background: #f0f8ff;
  border: 2px solid #333;
  border-radius: 8px;
}

.prd-file-selector label {
  font-weight: bold;
  color: #333;
}

.prd-file-select {
  flex: 1;
  padding: 8px 12px;
  border: 2px solid #333;
  border-radius: 6px;
  background: white;
  font-size: 14px;
  cursor: pointer;
}

.btn-refresh {
  padding: 8px 16px;
  background: #4CAF50;
  color: white;
  border: 2px solid #333;
  border-radius: 6px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-refresh:hover {
  background: #45a049;
  transform: translateY(-2px);
}

.prd-input-area {
  border: 3px solid #333;
  border-radius: 12px;
  overflow: hidden;
}

.prd-textarea {
  width: 100%;
  padding: 15px;
  border: none;
  font-family: monospace;
  font-size: 0.95em;
  line-height: 1.5;
  resize: vertical;
  min-height: 200px;
}

.prd-textarea:focus {
  outline: none;
}

.prd-actions {
  background: #f8f9fa;
  padding: 10px 15px;
  border-top: 2px solid #333;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.btn-sample,
.btn-analyze,
.btn-split {
  padding: 8px 16px;
  border: 2px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-sample {
  background: #17a2b8;
  color: white;
}

.btn-analyze {
  background: #ffc107;
  color: #333;
}

.btn-split {
  background: #28a745;
  color: white;
}

.btn-sample:hover,
.btn-analyze:hover,
.btn-split:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.complexity-display {
  background: #e3f2fd;
  border: 2px solid #2196F3;
  border-radius: 10px;
  padding: 15px;
}

.complexity-display h4 {
  margin: 0 0 10px 0;
  color: #1976D2;
  font-family: 'Comic Sans MS', cursive;
}

.complexity-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 0.9em;
  color: #666;
  margin-bottom: 4px;
}

.stat-value {
  display: block;
  font-size: 1.5em;
  font-weight: bold;
  color: #1976D2;
}

.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.task-item {
  border: 3px solid #333;
  border-radius: 12px;
  padding: 15px;
  background: white;
  transition: all 0.2s;
}

.task-item.invalid {
  border-color: #dc3545;
  background: #f8d7da;
}

.task-header {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
  align-items: center;
}

.task-title-input {
  flex: 1;
  padding: 8px 12px;
  border: 2px solid #ccc;
  border-radius: 6px;
  font-weight: bold;
  font-size: 1em;
}

.task-title-input.error {
  border-color: #dc3545;
}

.task-priority {
  padding: 6px 10px;
  border: 2px solid #333;
  border-radius: 6px;
  font-weight: bold;
}

.btn-remove-task {
  background: #dc3545;
  color: white;
  border: 2px solid #333;
  border-radius: 6px;
  padding: 6px 10px;
  cursor: pointer;
  font-size: 0.9em;
}

.task-description {
  width: 100%;
  padding: 10px;
  border: 2px solid #ccc;
  border-radius: 8px;
  font-family: monospace;
  font-size: 0.9em;
  resize: vertical;
  margin-bottom: 10px;
}

.task-meta {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 15px;
  margin-bottom: 10px;
}

.meta-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.meta-group label {
  font-size: 0.85em;
  font-weight: bold;
  color: #666;
}

.task-assignee,
.task-hours,
.task-sprint {
  padding: 6px 8px;
  border: 2px solid #ccc;
  border-radius: 6px;
}

.task-dependencies {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.task-dependencies label {
  font-size: 0.85em;
  font-weight: bold;
  color: #666;
}

.dependencies-input {
  padding: 6px 8px;
  border: 2px solid #ccc;
  border-radius: 6px;
  font-family: monospace;
}

.tasks-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.btn-add-task,
.btn-balance,
.btn-sprints {
  padding: 10px 20px;
  border: 3px solid #333;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s;
}

.btn-add-task {
  background: #28a745;
  color: white;
}

.btn-balance {
  background: #ffc107;
  color: #333;
}

.btn-sprints {
  background: #17a2b8;
  color: white;
}

.sprints-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 15px;
}

.sprint-card {
  border: 3px solid #333;
  border-radius: 10px;
  padding: 15px;
  background: #f8f9fa;
}

.sprint-card h4 {
  margin: 0 0 10px 0;
  color: #333;
  font-family: 'Comic Sans MS', cursive;
}

.sprint-stats {
  display: flex;
  gap: 15px;
  margin-bottom: 10px;
}

.stat {
  font-size: 0.9em;
  color: #666;
  font-weight: bold;
}

.sprint-agents {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.agent-workload {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 8px;
  background: white;
  border-radius: 6px;
  border: 1px solid #dee2e6;
}

.agent-icon {
  font-size: 1.1em;
}

.agent-name {
  flex: 1;
  font-weight: bold;
  text-transform: capitalize;
}

.agent-hours {
  font-size: 0.9em;
  color: #666;
}

.validation-checks {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.check-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  border-radius: 8px;
  font-weight: bold;
}

.check-item.pass {
  background: #d4edda;
  color: #155724;
}

.check-item.fail {
  background: #f8d7da;
  color: #721c24;
}

.check-icon {
  font-size: 1.2em;
}

.modal-footer {
  padding: 20px;
  border-top: 3px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8f9fa;
  border-radius: 0 0 12px 12px;
}

.footer-stats {
  font-weight: bold;
  color: #666;
}

.footer-actions {
  display: flex;
  gap: 10px;
}

.btn-create-tasks {
  background: linear-gradient(145deg, #28a745, #20c997);
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  padding: 12px 25px;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-create-tasks:hover:not(:disabled) {
  background: linear-gradient(145deg, #20c997, #17a2b8);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.btn-create-tasks:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
}

.btn-cancel {
  background: #6c757d;
  color: white;
  border: 3px solid #333;
  border-radius: 10px;
  padding: 12px 25px;
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
  .complexity-stats {
    grid-template-columns: 1fr;
  }
  
  .task-meta {
    grid-template-columns: 1fr;
  }
  
  .sprints-grid {
    grid-template-columns: 1fr;
  }
  
  .modal-footer {
    flex-direction: column;
    gap: 15px;
  }
}
</style>