#!/usr/bin/env node

/**
 * Agent Task Poller - Replaces email-based coordination
 * Agents run this script to poll for their assigned tasks
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Agent configuration
const AGENT_NAME = process.env.AGENT_NAME || process.argv[2] || 'unknown';
const API_BASE = 'http://localhost:3001';
const POLL_INTERVAL = 30000; // 30 seconds
const WORK_DIR = process.env.AGENT_WORK_DIR || process.cwd();

console.log(`🤖 Agent ${AGENT_NAME} task poller starting...`);
console.log(`📁 Working directory: ${WORK_DIR}`);
console.log(`⏰ Poll interval: ${POLL_INTERVAL / 1000}s`);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Agent icons
const agentIcons = {
  nestor: '🎩',
  tintin: '🚀',
  dupont1: '🎨',
  dupont2: '🔍'
};

const getAgentIcon = (name) => agentIcons[name] || '🤖';

// HTTP request helper
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? require('https') : require('http');
    
    const req = lib.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          resolve(result);
        } catch (e) {
          resolve(data);
        }
      });
    });
    
    req.on('error', reject);
    
    if (options.body) {
      req.write(JSON.stringify(options.body));
    }
    
    req.end();
  });
}

// Fetch tasks for this agent
async function fetchTasks() {
  try {
    const tasks = await makeRequest(`${API_BASE}/api/tasks/agent/${AGENT_NAME}`);
    return Array.isArray(tasks) ? tasks : [];
  } catch (error) {
    console.error(`${colors.red}❌ Error fetching tasks:${colors.reset}`, error.message);
    return [];
  }
}

// Update task status
async function updateTaskStatus(taskId, status, notes = '') {
  try {
    await makeRequest(`${API_BASE}/api/tasks/${taskId}/status`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: {
        status,
        notes,
        updated_by: `agent-${AGENT_NAME}`
      }
    });
    console.log(`${colors.green}✅ Task ${taskId} status updated to ${status}${colors.reset}`);
  } catch (error) {
    console.error(`${colors.red}❌ Error updating task status:${colors.reset}`, error.message);
  }
}

// Submit validation for a task
async function submitValidation(taskId, validationData) {
  try {
    await makeRequest(`${API_BASE}/api/tasks/${taskId}/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: {
        ...validationData,
        validated_by: `agent-${AGENT_NAME}`,
        timestamp: new Date().toISOString()
      }
    });
    console.log(`${colors.cyan}🔍 Validation submitted for task ${taskId}${colors.reset}`);
  } catch (error) {
    console.error(`${colors.red}❌ Error submitting validation:${colors.reset}`, error.message);
  }
}

// Display task summary
function displayTaskSummary(tasks) {
  const icon = getAgentIcon(AGENT_NAME);
  
  console.log(`\n${colors.bright}${icon} ${AGENT_NAME.toUpperCase()} - Task Summary${colors.reset}`);
  console.log(`${'='.repeat(50)}`);
  
  if (tasks.length === 0) {
    console.log(`${colors.yellow}📭 No tasks assigned${colors.reset}`);
    return;
  }
  
  const statusCounts = tasks.reduce((acc, task) => {
    acc[task.status] = (acc[task.status] || 0) + 1;
    return acc;
  }, {});
  
  console.log(`📊 Total: ${tasks.length} tasks`);
  Object.entries(statusCounts).forEach(([status, count]) => {
    const statusIcon = {
      'TODO': '📋',
      'IN_PROGRESS': '🚀',
      'VALIDATION': '🔍',
      'DONE': '✅'
    }[status] || '❓';
    
    console.log(`   ${statusIcon} ${status}: ${count}`);
  });
  
  console.log(`\n${colors.bright}📋 Task Details:${colors.reset}`);
  
  tasks.forEach((task, index) => {
    const statusColor = {
      'TODO': colors.yellow,
      'IN_PROGRESS': colors.blue,
      'VALIDATION': colors.magenta,
      'DONE': colors.green
    }[task.status] || colors.reset;
    
    const progress = Math.round(task.progress || 0);
    const progressBar = '█'.repeat(Math.floor(progress / 10)) + '░'.repeat(10 - Math.floor(progress / 10));
    
    console.log(`\n${index + 1}. ${colors.bright}${task.title}${colors.reset}`);
    console.log(`   ${statusColor}Status: ${task.status}${colors.reset} | Progress: ${progress}% [${progressBar}]`);
    console.log(`   Project: ${task.project_name || 'Unknown'} | Priority: ${task.priority}`);
    
    if (task.due_date) {
      const dueDate = new Date(task.due_date);
      const isOverdue = dueDate < new Date() && task.status !== 'DONE';
      const dueDateColor = isOverdue ? colors.red : colors.reset;
      console.log(`   ${dueDateColor}Due: ${dueDate.toLocaleDateString()}${colors.reset}`);
    }
    
    // Show incomplete required validations
    const incompleteRequired = task.checkboxes?.filter(cb => cb.required && !cb.completed) || [];
    if (incompleteRequired.length > 0) {
      console.log(`   ${colors.red}⚠️  ${incompleteRequired.length} required validation(s) pending${colors.reset}`);
    }
    
    // Show recent activity
    if (task.updated_at) {
      const updatedAt = new Date(task.updated_at);
      const timeDiff = Date.now() - updatedAt.getTime();
      const hoursAgo = Math.floor(timeDiff / (1000 * 60 * 60));
      
      if (hoursAgo < 24) {
        console.log(`   🕒 Updated: ${hoursAgo}h ago`);
      } else {
        console.log(`   🕒 Updated: ${updatedAt.toLocaleDateString()}`);
      }
    }
  });
}

// Generate action suggestions
function suggestActions(tasks) {
  const suggestions = [];
  
  // Find tasks that need attention
  const todoTasks = tasks.filter(t => t.status === 'TODO');
  const inProgressTasks = tasks.filter(t => t.status === 'IN_PROGRESS');
  const validationTasks = tasks.filter(t => t.status === 'VALIDATION');
  
  if (todoTasks.length > 0) {
    suggestions.push(`🚀 Start working on: "${todoTasks[0].title}"`);
  }
  
  if (inProgressTasks.length > 0) {
    const stuckTasks = inProgressTasks.filter(t => {
      const updatedAt = new Date(t.updated_at);
      const hoursAgo = (Date.now() - updatedAt.getTime()) / (1000 * 60 * 60);
      return hoursAgo > 4; // Stuck if no update in 4+ hours
    });
    
    if (stuckTasks.length > 0) {
      suggestions.push(`⚠️  Update progress on: "${stuckTasks[0].title}"`);
    }
  }
  
  if (validationTasks.length > 0) {
    const taskWithIncompleteValidations = validationTasks.find(t => {
      const incompleteRequired = t.checkboxes?.filter(cb => cb.required && !cb.completed) || [];
      return incompleteRequired.length > 0;
    });
    
    if (taskWithIncompleteValidations) {
      suggestions.push(`🔍 Complete validations for: "${taskWithIncompleteValidations.title}"`);
    }
  }
  
  // Overdue tasks
  const overdueTasks = tasks.filter(t => {
    return t.due_date && new Date(t.due_date) < new Date() && t.status !== 'DONE';
  });
  
  if (overdueTasks.length > 0) {
    suggestions.push(`🚨 URGENT: Complete overdue task: "${overdueTasks[0].title}"`);
  }
  
  if (suggestions.length > 0) {
    console.log(`\n${colors.bright}💡 Suggested Actions:${colors.reset}`);
    suggestions.forEach((suggestion, index) => {
      console.log(`   ${index + 1}. ${suggestion}`);
    });
  }
}

// Save task data to file for other scripts to use
function saveTaskData(tasks) {
  const taskFile = path.join(WORK_DIR, `.tasks-${AGENT_NAME}.json`);
  
  const taskData = {
    agent: AGENT_NAME,
    lastUpdate: new Date().toISOString(),
    tasks: tasks.map(task => ({
      id: task.id,
      title: task.title,
      status: task.status,
      priority: task.priority,
      progress: task.progress,
      due_date: task.due_date,
      project_name: task.project_name,
      incompleteValidations: task.checkboxes?.filter(cb => cb.required && !cb.completed).length || 0
    }))
  };
  
  try {
    fs.writeFileSync(taskFile, JSON.stringify(taskData, null, 2));
  } catch (error) {
    console.error(`${colors.red}❌ Error saving task data:${colors.reset}`, error.message);
  }
}

// Interactive mode commands
function showHelp() {
  console.log(`\n${colors.bright}Available Commands:${colors.reset}`);
  console.log(`  ${colors.cyan}status${colors.reset}     - Show current task status`);
  console.log(`  ${colors.cyan}start <id>${colors.reset} - Start working on task (move to IN_PROGRESS)`);
  console.log(`  ${colors.cyan}done <id>${colors.reset}  - Mark task as done (if validations complete)`);
  console.log(`  ${colors.cyan}valid <id>${colors.reset} - Submit task for validation`);
  console.log(`  ${colors.cyan}help${colors.reset}      - Show this help`);
  console.log(`  ${colors.cyan}quit${colors.reset}      - Exit poller`);
}

// Handle interactive commands
async function handleCommand(command, args, tasks) {
  switch (command.toLowerCase()) {
    case 'status':
      const freshTasks = await fetchTasks();
      displayTaskSummary(freshTasks);
      suggestActions(freshTasks);
      break;
      
    case 'start':
      if (args.length === 0) {
        console.log(`${colors.red}❌ Usage: start <task-id>${colors.reset}`);
        break;
      }
      
      const taskId = parseInt(args[0]);
      const task = tasks.find(t => t.id === taskId);
      
      if (!task) {
        console.log(`${colors.red}❌ Task ${taskId} not found${colors.reset}`);
        break;
      }
      
      if (task.status !== 'TODO') {
        console.log(`${colors.yellow}⚠️  Task is already ${task.status}${colors.reset}`);
        break;
      }
      
      await updateTaskStatus(taskId, 'IN_PROGRESS', `Started by agent ${AGENT_NAME}`);
      break;
      
    case 'done':
      if (args.length === 0) {
        console.log(`${colors.red}❌ Usage: done <task-id>${colors.reset}`);
        break;
      }
      
      const doneTaskId = parseInt(args[0]);
      const doneTask = tasks.find(t => t.id === doneTaskId);
      
      if (!doneTask) {
        console.log(`${colors.red}❌ Task ${doneTaskId} not found${colors.reset}`);
        break;
      }
      
      const incompleteRequired = doneTask.checkboxes?.filter(cb => cb.required && !cb.completed) || [];
      if (incompleteRequired.length > 0) {
        console.log(`${colors.red}❌ Cannot mark as done: ${incompleteRequired.length} required validation(s) incomplete${colors.reset}`);
        break;
      }
      
      await updateTaskStatus(doneTaskId, 'DONE', `Completed by agent ${AGENT_NAME}`);
      break;
      
    case 'valid':
      if (args.length === 0) {
        console.log(`${colors.red}❌ Usage: valid <task-id>${colors.reset}`);
        break;
      }
      
      const validTaskId = parseInt(args[0]);
      const validTask = tasks.find(t => t.id === validTaskId);
      
      if (!validTask) {
        console.log(`${colors.red}❌ Task ${validTaskId} not found${colors.reset}`);
        break;
      }
      
      await updateTaskStatus(validTaskId, 'VALIDATION', `Submitted for validation by agent ${AGENT_NAME}`);
      
      // Submit basic validation data
      await submitValidation(validTaskId, {
        validation_status: 'pending',
        validation_notes: `Submitted by ${AGENT_NAME} - ready for review`,
        checkbox_updates: validTask.checkboxes?.map(cb => ({
          checkbox_id: cb.id,
          completed: true, // Mark as completed by agent
          evidence_url: '',
          notes: `Completed by ${AGENT_NAME}`
        })) || []
      });
      break;
      
    case 'help':
      showHelp();
      break;
      
    case 'quit':
    case 'exit':
      console.log(`${colors.yellow}👋 Agent ${AGENT_NAME} poller stopping...${colors.reset}`);
      process.exit(0);
      break;
      
    default:
      console.log(`${colors.red}❌ Unknown command: ${command}${colors.reset}`);
      console.log(`Type 'help' for available commands`);
  }
}

// Main polling loop
async function pollTasks() {
  const tasks = await fetchTasks();
  displayTaskSummary(tasks);
  suggestActions(tasks);
  saveTaskData(tasks);
  
  // Show separator
  console.log(`\n${'─'.repeat(50)}`);
  console.log(`${colors.bright}Next poll in ${POLL_INTERVAL / 1000}s | Type 'help' for commands${colors.reset}`);
  
  return tasks;
}

// Interactive mode
function startInteractiveMode() {
  const readline = require('readline');
  
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    prompt: `${getAgentIcon(AGENT_NAME)} ${AGENT_NAME}> `
  });
  
  let currentTasks = [];
  
  // Initial poll
  pollTasks().then(tasks => {
    currentTasks = tasks;
    rl.prompt();
  });
  
  // Set up polling interval
  const pollInterval = setInterval(async () => {
    console.log(`\n${colors.cyan}🔄 Polling for updates...${colors.reset}`);
    currentTasks = await pollTasks();
    rl.prompt();
  }, POLL_INTERVAL);
  
  // Handle user input
  rl.on('line', async (input) => {
    const [command, ...args] = input.trim().split(' ');
    
    if (command) {
      await handleCommand(command, args, currentTasks);
    }
    
    rl.prompt();
  });
  
  rl.on('close', () => {
    clearInterval(pollInterval);
    console.log(`\n${colors.yellow}👋 Agent ${AGENT_NAME} poller stopped${colors.reset}`);
    process.exit(0);
  });
  
  // Show initial help
  console.log(`\n${colors.bright}🤖 Agent ${AGENT_NAME} Task Poller${colors.reset}`);
  console.log(`Type 'help' for commands or 'quit' to exit\n`);
}

// Handle command line arguments
if (process.argv.includes('--once')) {
  // Run once and exit
  pollTasks().then(() => process.exit(0));
} else if (process.argv.includes('--daemon')) {
  // Run as daemon (no interactive mode)
  pollTasks();
  setInterval(pollTasks, POLL_INTERVAL);
} else {
  // Default: interactive mode
  startInteractiveMode();
}