#!/usr/bin/env node

/**
 * Sample Data Generator for Task Management System
 * Creates sample projects and tasks for demonstration
 */

const API_BASE = 'http://localhost:3001';

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

// Create a project
async function createProject(projectData) {
  try {
    const result = await makeRequest(`${API_BASE}/api/projects/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: projectData
    });
    console.log(`✅ Created project: ${projectData.name}`);
    return result;
  } catch (error) {
    console.error(`❌ Error creating project ${projectData.name}:`, error.message);
    return null;
  }
}

// Create a task
async function createTask(taskData) {
  try {
    const result = await makeRequest(`${API_BASE}/api/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: taskData
    });
    console.log(`✅ Created task: ${taskData.title}`);
    return result;
  } catch (error) {
    console.error(`❌ Error creating task ${taskData.title}:`, error.message);
    return null;
  }
}

// Get projects
async function getProjects() {
  try {
    const result = await makeRequest(`${API_BASE}/api/projects`);
    return result.projects || result;
  } catch (error) {
    console.error(`❌ Error fetching projects:`, error.message);
    return [];
  }
}

// Sample project data
const sampleProjects = [
  {
    name: 'TaskMaster iOS App',
    type: 'ios',
    domain: 'taskmaster.moulinsart.local',
    agents: {
      agent1: 'nestor',
      agent2: 'tintin', 
      agent3: 'dupont1',
      agent4: 'dupont2'
    }
  },
  {
    name: 'Moulinsart Web Portal',
    type: 'web',
    domain: 'portal.moulinsart.local',
    agents: {
      agent1: 'nestor',
      agent2: 'tintin',
      agent3: 'dupont2',
      agent4: 'dupont1'
    }
  }
];

// Sample task data
const sampleTasks = [
  {
    title: 'Setup Project Architecture',
    description: `Initialize the iOS project with proper folder structure and dependencies.

## Requirements
- Create Xcode project with SwiftUI
- Configure CocoaPods/SPM dependencies
- Set up folder structure (Models, Views, ViewModels, Services)
- Configure build settings for development and production

## Acceptance Criteria
- [x] Project compiles without errors
- [x] Basic app structure is in place
- [x] Dependencies are properly configured`,
    assigned_to: 'dupont1',
    priority: 'high',
    estimated_hours: 6,
    tags: 'setup, architecture, ios',
    checkboxes: [
      { label: 'Xcode project configured', required: true },
      { label: 'Dependencies added', required: true },
      { label: 'Project structure documented', required: false }
    ]
  },
  {
    title: 'Design Task List UI',
    description: `Create the main task list interface with SwiftUI.

## Requirements
- List view with task cards
- Task status indicators (TODO, IN_PROGRESS, DONE)
- Priority visual indicators
- Search and filter functionality
- Pull-to-refresh support

## Design Specs
- Follow iOS Human Interface Guidelines
- Support dark/light mode
- Smooth animations for state changes`,
    assigned_to: 'dupont1',
    priority: 'medium',
    estimated_hours: 8,
    tags: 'ui, swiftui, design',
    checkboxes: [
      { label: 'UI mockups approved', required: true },
      { label: 'Dark mode support verified', required: true },
      { label: 'Accessibility tested', required: true }
    ]
  },
  {
    title: 'Implement Core Data Model',
    description: `Set up Core Data stack for persistent storage.

## Requirements
- Task entity with all required fields
- Category/Project entity
- User preferences entity
- Data migration support
- CloudKit sync preparation

## Technical Details
- Use NSPersistentCloudKitContainer
- Configure predicates and sort descriptors
- Add data validation`,
    assigned_to: 'dupont2',
    priority: 'high',
    estimated_hours: 10,
    tags: 'backend, coredata, persistence',
    checkboxes: [
      { label: 'Data model designed', required: true },
      { label: 'Migration strategy tested', required: true },
      { label: 'Performance benchmarked', required: false }
    ]
  },
  {
    title: 'Write Unit Tests',
    description: `Comprehensive unit test suite for core functionality.

## Test Coverage
- Model layer (Core Data)
- Business logic (ViewModels)
- Utility functions
- API service layer

## Requirements
- Minimum 80% code coverage
- Test all critical user flows
- Mock external dependencies
- Continuous integration ready`,
    assigned_to: 'tintin',
    priority: 'medium',
    estimated_hours: 12,
    tags: 'testing, quality, ci',
    checkboxes: [
      { label: 'Test plan approved', required: true },
      { label: 'All critical flows tested', required: true },
      { label: 'CI pipeline configured', required: true },
      { label: 'Performance tests added', required: false }
    ]
  },
  {
    title: 'API Integration Setup',
    description: `Set up networking layer for API communication.

## Requirements
- RESTful API client
- Authentication handling
- Offline support with sync
- Error handling and retry logic
- Network reachability monitoring

## Technical Stack
- URLSession or Alamofire
- Codable for JSON parsing
- Keychain for secure storage`,
    assigned_to: 'dupont2',
    priority: 'medium',
    estimated_hours: 8,
    tags: 'networking, api, sync',
    checkboxes: [
      { label: 'API endpoints documented', required: true },
      { label: 'Offline mode tested', required: true },
      { label: 'Security audit passed', required: true }
    ]
  },
  {
    title: 'Create Project Documentation',
    description: `Comprehensive documentation for the project.

## Deliverables
- README with setup instructions
- Architecture decision records (ADRs)
- API documentation
- Deployment guide
- User manual

## Requirements
- Clear and concise writing
- Code examples where appropriate
- Diagrams for complex flows
- Keep documentation up to date`,
    assigned_to: 'dupont2',
    priority: 'low',
    estimated_hours: 6,
    tags: 'documentation, readme, guides',
    checkboxes: [
      { label: 'Setup guide tested by new developer', required: true },
      { label: 'Architecture diagrams created', required: false },
      { label: 'API docs auto-generated', required: false }
    ]
  },
  {
    title: 'Performance Optimization',
    description: `Optimize app performance and memory usage.

## Focus Areas
- List scrolling performance
- Image loading and caching
- Battery usage optimization
- Network request efficiency
- Memory leak detection

## Success Metrics
- 60fps scrolling
- < 2 second app launch
- No memory leaks
- Efficient battery usage`,
    assigned_to: 'tintin',
    priority: 'low',
    estimated_hours: 10,
    tags: 'performance, optimization, profiling',
    checkboxes: [
      { label: 'Instruments profiling completed', required: true },
      { label: 'Performance benchmarks met', required: true },
      { label: 'Memory leaks fixed', required: true },
      { label: 'Battery usage analyzed', required: false }
    ]
  },
  {
    title: 'App Store Submission Prep',
    description: `Prepare app for App Store submission.

## Requirements
- App icons in all required sizes
- App Store screenshots
- App Store description and keywords
- Privacy policy and terms of service
- TestFlight beta testing
- App review guidelines compliance

## Final Checklist
- No crashes or major bugs
- Passes App Store review guidelines
- Metadata and assets ready`,
    assigned_to: 'nestor',
    priority: 'medium',
    estimated_hours: 8,
    tags: 'appstore, submission, release',
    checkboxes: [
      { label: 'All assets prepared', required: true },
      { label: 'Beta testing completed', required: true },
      { label: 'Review guidelines checked', required: true },
      { label: 'Marketing materials ready', required: false }
    ]
  }
];

async function createSampleData() {
  console.log('🚀 Creating sample data for Task Management System...\n');
  
  // Create projects first
  const createdProjects = [];
  for (const projectData of sampleProjects) {
    const result = await createProject(projectData);
    if (result && result.success) {
      createdProjects.push({ ...projectData, id: result.project });
    }
    
    // Wait a bit to avoid overwhelming the server
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  console.log('\n📋 Creating sample tasks...\n');
  
  // Get existing projects to use their IDs
  const existingProjects = await getProjects();
  const taskMasterProject = existingProjects.find(p => p.name.includes('TaskMaster') || p.name.includes('iOS'));
  
  if (!taskMasterProject) {
    console.error('❌ Could not find TaskMaster project to assign tasks to');
    return;
  }
  
  // Create tasks for the TaskMaster project
  for (const [index, taskData] of sampleTasks.entries()) {
    const taskWithProject = {
      ...taskData,
      project_id: taskMasterProject.id,
      status: ['TODO', 'IN_PROGRESS', 'VALIDATION', 'DONE'][index % 4] // Distribute across statuses
    };
    
    await createTask(taskWithProject);
    
    // Wait a bit between tasks
    await new Promise(resolve => setTimeout(resolve, 300));
  }
  
  console.log('\n✅ Sample data creation completed!');
  console.log('\nYou can now:');
  console.log('1. Open the task dashboard: http://localhost:5175');
  console.log('2. Start an agent task poller:');
  console.log('   - ./scripts/nestor-tasks.sh');
  console.log('   - ./scripts/tintin-tasks.sh');
  console.log('   - ./scripts/dupont1-tasks.sh');
  console.log('   - ./scripts/dupont2-tasks.sh');
  console.log('\n🎯 The task management system is ready to use!');
}

// Check if server is running
async function checkServer() {
  try {
    await makeRequest(`${API_BASE}/health`);
    return true;
  } catch (error) {
    return false;
  }
}

async function main() {
  console.log('🔍 Checking if server is running...');
  
  const serverRunning = await checkServer();
  if (!serverRunning) {
    console.error('❌ Server is not running on http://localhost:3001');
    console.error('Please start the server first:');
    console.error('   cd /Users/studio_m3/moulinsart/oracle-observability');
    console.error('   bun run server/index.ts');
    process.exit(1);
  }
  
  console.log('✅ Server is running\n');
  await createSampleData();
}

if (require.main === module) {
  main().catch(console.error);
}