# 🎯 Moulinsart Task Management System

A modern visual task management system that replaces email-based coordination with a dynamic dashboard where agents check for tasks and must complete validation checkboxes.

## 🚀 Quick Start

### 1. Start the Oracle Server
```bash
cd ~/moulinsart/oracle-observability
bun run server/index.ts
```

### 2. Start the Vue Interface
```bash
cd client && bun run dev
```

### 3. Create Sample Data (Optional)
```bash
node sample-data.js
```

### 4. Access the Task Dashboard
- **Task Dashboard**: http://localhost:5175 (click "🎯 Task Dashboard")
- **Email Workflow**: http://localhost:5175 (click "📧 Email Workflow")

## 📊 System Overview

### Core Features

✅ **Visual Task Board** - Kanban-style board with TODO, IN_PROGRESS, VALIDATION, DONE columns  
✅ **Validation System** - Mandatory checkboxes with evidence requirements  
✅ **Real-time Updates** - WebSocket-powered live dashboard  
✅ **Agent Task Polling** - Command-line tools for agents to check their tasks  
✅ **PRD Splitting** - Break down Product Requirements into manageable tasks  
✅ **Evidence Upload** - Screenshot and file upload for validation  
✅ **Enforcement Logic** - Cannot move to DONE without completing required validations  

### Agent Color Coding
- 🎩 **Nestor** (Purple) - Chef d'orchestre, project coordination
- 🚀 **Tintin** (Blue) - QA Lead, testing and validation
- 🎨 **Dupont1** (Green) - Swift/iOS Development
- 🔍 **Dupont2** (Orange) - Research & Documentation

## 🗄️ Database Schema

### Core Tables

```sql
-- Enhanced projects table
CREATE TABLE projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    path TEXT,
    prd TEXT,                    -- Product Requirements Document
    status TEXT DEFAULT 'active',
    created_by TEXT DEFAULT 'commandant',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_active DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    project_id INTEGER,
    assigned_to TEXT,            -- Agent name (nestor, tintin, dupont1, dupont2)
    status TEXT DEFAULT 'TODO',  -- TODO, IN_PROGRESS, VALIDATION, DONE
    priority TEXT DEFAULT 'medium', -- low, medium, high, urgent
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    due_date DATETIME,
    estimated_hours INTEGER,
    actual_hours INTEGER,
    tags TEXT,
    dependencies TEXT,           -- Comma-separated task IDs
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Validation checkboxes
CREATE TABLE checkboxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    label TEXT NOT NULL,         -- e.g., "Screenshot taken"
    required BOOLEAN DEFAULT 1,  -- Must be completed to mark task DONE
    completed BOOLEAN DEFAULT 0,
    evidence_url TEXT,           -- Link to uploaded evidence
    evidence_type TEXT,          -- file, url, screenshot
    completed_at DATETIME,
    completed_by TEXT,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Validation submissions
CREATE TABLE validations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    screenshot_path TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    validated_by TEXT,
    validation_status TEXT DEFAULT 'pending', -- pending, approved, rejected, conditional
    validation_notes TEXT,
    build_log_url TEXT,
    test_results TEXT,
    languages_tested TEXT,       -- Comma-separated list
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Task history tracking
CREATE TABLE task_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    status_from TEXT,
    status_to TEXT,
    changed_by TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);
```

## 🎛️ API Endpoints

### Task Management
- `GET /api/tasks` - Get all tasks with filters
- `GET /api/tasks/agent/{name}` - Get tasks for specific agent
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}/status` - Update task status
- `POST /api/tasks/{id}/validate` - Submit validation evidence

### Project Management
- `GET /api/projects` - List all projects
- `POST /api/projects/split` - Split PRD into tasks

### Validation & Evidence
- `GET /api/validations/queue` - Get pending validations
- `POST /api/upload/evidence` - Upload evidence files
- `GET /api/tasks/stats` - Get task statistics

## 🎨 Vue Components

### Main Components

**TaskBoard.vue** - Main Kanban board interface
- Drag & drop task movement
- Real-time WebSocket updates
- Task filtering and search
- Statistics dashboard

**TaskCard.vue** - Individual task cards
- Progress indicators
- Validation status
- Evidence previews
- Agent assignments

**ValidationModal.vue** - Task validation interface
- Checkbox completion
- Evidence upload (drag & drop)
- Build status reporting
- Multi-language testing

**CreateTaskModal.vue** - Task creation interface
- Template-based task generation
- Custom checkbox creation
- Agent assignment
- Priority and estimation

**PRDSplitterModal.vue** - PRD breakdown tool
- Automatic task generation from requirements
- Workload balancing
- Sprint planning
- Dependency management

## 🤖 Agent Task Polling

### Interactive Command-Line Interface

Each agent can use a dedicated polling script:

```bash
# Start agent task pollers
./scripts/nestor-tasks.sh
./scripts/tintin-tasks.sh
./scripts/dupont1-tasks.sh
./scripts/dupont2-tasks.sh
```

### Available Commands

```bash
# In the agent task poller
status              # Show current tasks
start <task-id>     # Start working on task
done <task-id>      # Mark task complete (if validations pass)
valid <task-id>     # Submit task for validation
help               # Show command help
quit               # Exit poller
```

### Usage Example

```bash
🎩 nestor> status
🎩 NESTOR - Task Summary
==================================================
📊 Total: 3 tasks
   📋 TODO: 1
   🚀 IN_PROGRESS: 1
   🔍 VALIDATION: 1

📋 Task Details:

1. Setup Project Architecture
   Status: TODO | Progress: 0% [░░░░░░░░░░]
   Project: TaskMaster iOS App | Priority: high
   ⚠️  3 required validation(s) pending

🎩 nestor> start 1
✅ Task 1 status updated to IN_PROGRESS

🎩 nestor> valid 1
✅ Task 1 status updated to VALIDATION
🔍 Validation submitted for task 1
```

## 🔒 Validation & Enforcement System

### Mandatory Validation Checkboxes

Every task automatically gets these required checkboxes:

1. ✅ **Code/Implementation complete** - Core functionality finished
2. 📸 **Screenshot taken** - Visual proof of completion  
3. 🔨 **Build successful** - Code compiles without errors
4. 🌐 **Visual validation passed (3+ languages)** - Multi-language testing
5. 📖 **Documentation updated** - Relevant docs updated

### Enforcement Rules

❌ **Cannot move to DONE unless:**
- All required checkboxes are completed
- Evidence is provided (screenshots, build logs, etc.)
- No build failures reported

⚠️ **Warning alerts for:**
- Tasks stuck in VALIDATION > 30 minutes
- Missing screenshots for approved validations
- Incomplete required validations

🚨 **Auto-notifications when:**
- Required validations are missing
- Build status shows failures
- Tasks become overdue

## 📸 Evidence System

### Supported Evidence Types
- **Screenshots** (PNG, JPG, GIF)
- **Build logs** (URLs or text files)
- **Documentation** (PDF, MD, TXT)
- **External links** (GitHub PRs, test reports)

### Upload Methods
- Drag & drop in ValidationModal
- File picker interface
- URL input for external resources
- Command-line uploads via API

## 🎯 PRD Splitting Features

### Automatic Task Generation
The PRD Splitter can analyze a Product Requirements Document and automatically:

1. **Parse Requirements** - Extract features and acceptance criteria
2. **Generate Tasks** - Create appropriate tasks for each requirement
3. **Assign Agents** - Balance workload across team members
4. **Set Priorities** - Determine task importance and urgency
5. **Plan Sprints** - Organize tasks into development sprints
6. **Manage Dependencies** - Identify task relationships

### Task Templates

Pre-built templates for common task types:
- 🚀 **Feature Development** - New functionality implementation
- 🐛 **Bug Fix** - Issue resolution and testing
- 🔍 **Research Task** - Investigation and documentation
- 🧪 **Testing Task** - Quality assurance and validation

## 📊 Real-time Dashboard Features

### Live Statistics
- Total tasks across all statuses
- Pending validation queue size
- Overdue task count
- Agent workload distribution

### Visual Progress Tracking
- Kanban board with live updates
- Progress bars for task completion
- Color-coded priority indicators
- Agent assignment visualization

### WebSocket Events
- Task status changes
- New task creation
- Validation submissions
- Agent activity updates

## 🚀 Getting Started Workflow

### 1. Create a New Project
1. Click "📋 Split PRD" in the task dashboard
2. Select or create a project
3. Paste your Product Requirements Document
4. Click "⚡ Auto-Split" to generate tasks
5. Review and adjust task assignments
6. Click "🚀 Create Tasks"

### 2. Assign Tasks to Agents
- Tasks are automatically assigned based on type and workload
- Drag tasks between agents to rebalance
- Use the "⚖️ Balance Workload" feature for optimal distribution

### 3. Agents Start Working
- Agents run their task poller: `./scripts/{agent}-tasks.sh`
- Use `start <id>` command to begin work
- Update progress regularly
- Submit for validation with `valid <id>`

### 4. Validation Process
1. Tasks move to VALIDATION column
2. Team leads review in the dashboard
3. Click "🔍" on task cards to validate
4. Upload screenshots and evidence
5. Complete required checkboxes
6. Approve or reject with notes

### 5. Task Completion
- Tasks automatically move to DONE when all validations pass
- Enforcement prevents premature completion
- History is tracked for audit purposes

## 🎨 Customization

### Adding Custom Validation Checkboxes
When creating tasks, add project-specific validations:
- Performance benchmarks met
- Security audit completed  
- User acceptance testing passed
- Accessibility standards verified

### Extending Agent Types
To add new agent types:
1. Add agent configuration in `TaskBoard.vue`
2. Create polling script in `scripts/`
3. Add color coding in CSS
4. Update agent assignment dropdowns

### Custom Task Templates
Extend the template system in `CreateTaskModal.vue`:
- Define template structure
- Add to template buttons
- Include custom checkboxes
- Set default assignments

## 🛠️ Development Setup

### Prerequisites
- Bun runtime
- Node.js 16+
- SQLite3

### Installation
```bash
# Clone repository
cd ~/moulinsart/oracle-observability

# Install dependencies
bun install
cd client && bun install

# Start development servers
bun run server/index.ts        # API server (port 3001)
cd client && bun run dev       # Vue app (port 5175)
```

### Database Management
```bash
# View database structure
sqlite3 data/oracle.db ".schema"

# Query tasks
sqlite3 data/oracle.db "SELECT * FROM tasks;"

# Reset database (caution!)
rm data/oracle.db && restart server
```

## 📈 Monitoring & Analytics

### Task Metrics
- Completion rates by agent
- Average task duration
- Validation turnaround time
- Overdue task trends

### System Health
- WebSocket connection status
- API response times
- Database query performance
- Evidence storage usage

## 🔧 Troubleshooting

### Common Issues

**Tasks not showing in dashboard:**
- Check server is running on port 3001
- Verify WebSocket connection in browser dev tools
- Refresh dashboard or restart server

**Agent poller not working:**
- Ensure agent names match exactly (case-sensitive)
- Check API endpoint accessibility
- Verify task assignments in database

**Validation uploads failing:**
- Check evidence directory permissions
- Verify file size limits
- Ensure supported file types

**Build fails or dependencies missing:**
```bash
# Reinstall dependencies
rm -rf node_modules && bun install
cd client && rm -rf node_modules && bun install

# Check Bun version
bun --version  # Should be 1.0+
```

## 🎯 Best Practices

### Task Creation
- Write clear, actionable titles
- Include acceptance criteria in descriptions
- Set realistic time estimates  
- Add relevant tags for filtering
- Define custom validations when needed

### Validation Process
- Always upload screenshots for UI work
- Include build logs for technical issues
- Test in multiple languages/environments
- Provide detailed validation notes
- Reject with constructive feedback

### Agent Workflow
- Check tasks regularly (every 30 minutes)
- Update status promptly when starting work
- Submit for validation as soon as ready
- Keep evidence organized and accessible
- Communicate blockers immediately

## 🏗️ Architecture

### System Components
```
┌─────────────────┐    ┌──────────────────┐
│   Vue.js App    │    │  Agent Pollers   │
│  (Task Board)   │    │  (CLI Scripts)   │
└─────────────────┘    └──────────────────┘
         │                       │
         │ WebSocket/HTTP        │ HTTP API
         │                       │
    ┌─────────────────────────────────┐
    │        Bun Server              │
    │    • API Endpoints             │
    │    • WebSocket Handler         │
    │    • File Upload               │
    │    • Validation Logic          │
    └─────────────────────────────────┘
                    │
              ┌─────────────┐
              │   SQLite    │
              │  Database   │
              └─────────────┘
```

### Data Flow
1. **Task Creation** → API → Database → WebSocket → Dashboard
2. **Agent Polling** → API → Database → Console Display  
3. **Validation** → API → Evidence Storage → Database → WebSocket
4. **Status Updates** → API → Database → History → WebSocket

## 🚀 Future Enhancements

### Planned Features
- [ ] Mobile agent app (React Native)
- [ ] Slack/Teams integration
- [ ] Advanced analytics dashboard
- [ ] Custom validation workflows
- [ ] Time tracking integration
- [ ] Automated testing triggers
- [ ] Git commit linking
- [ ] Performance benchmarking

### Integration Possibilities
- CI/CD pipeline triggers
- Jira/Linear synchronization
- GitHub issue management
- Automated screenshot comparison
- AI-powered task estimation
- Voice command interface

## 📞 Support

For issues or questions:
1. Check this documentation first
2. Review console logs for errors
3. Inspect database state if needed
4. Test with sample data script

The Task Management System represents a modern evolution of the Moulinsart workflow, providing visual clarity, enforced quality gates, and real-time coordination without email dependency.

🎯 **Ready to manage tasks like never before!**