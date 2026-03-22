#!/usr/bin/env bun
/**
 * Oracle Observability Server - Version minimale pour Moulinsart
 * Capture et diffuse les événements des hooks Claude
 */

import { Database } from "bun:sqlite";
import { serve } from "bun";
import { join } from "path";

const PORT = 3001; // Port différent pour ne pas confliter avec l'autre Oracle
const db = new Database(join(import.meta.dir, "../data/oracle.db"));

// Initialiser la base de données
db.run(`
  CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    type TEXT NOT NULL,
    source TEXT,
    data JSON,
    project TEXT,
    project_path TEXT,
    agent TEXT
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    path TEXT,
    prd TEXT,
    status TEXT DEFAULT 'active',
    created_by TEXT DEFAULT 'commandant',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_active DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Task Management Tables
db.run(`
  CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    project_id INTEGER,
    assigned_to TEXT,
    status TEXT DEFAULT 'TODO',
    priority TEXT DEFAULT 'medium',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    due_date DATETIME,
    estimated_hours INTEGER,
    actual_hours INTEGER,
    tags TEXT,
    dependencies TEXT,
    FOREIGN KEY (project_id) REFERENCES projects(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS checkboxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    label TEXT NOT NULL,
    required BOOLEAN DEFAULT 1,
    completed BOOLEAN DEFAULT 0,
    evidence_url TEXT,
    evidence_type TEXT,
    completed_at DATETIME,
    completed_by TEXT,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS validations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    screenshot_path TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    validated_by TEXT,
    validation_status TEXT DEFAULT 'pending',
    validation_notes TEXT,
    build_log_url TEXT,
    test_results TEXT,
    languages_tested TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
  )
`);

db.run(`
  CREATE TABLE IF NOT EXISTS task_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    status_from TEXT,
    status_to TEXT,
    changed_by TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id)
  )
`);

// WebSocket clients
const wsClients = new Set<WebSocket>();

console.log("🔮 Moulinsart Oracle Observability starting...");

const server = serve({
  port: PORT,
  
  async fetch(req, server) {
    const url = new URL(req.url);
    
    // CORS headers
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    
    // Handle OPTIONS for CORS
    if (req.method === "OPTIONS") {
      return new Response(null, { headers });
    }
    
    // WebSocket upgrade
    if (url.pathname === "/ws") {
      const success = server.upgrade(req);
      if (success) {
        return undefined;
      }
      return new Response("WebSocket upgrade failed", { status: 400 });
    }
    
    // API endpoint pour recevoir les events des hooks
    if (url.pathname === "/api/events" && req.method === "POST") {
      try {
        const body = await req.json();
        
        // Enregistrer dans la base
        const stmt = db.prepare(`
          INSERT INTO events (type, source, data, project, project_path, agent)
          VALUES (?, ?, ?, ?, ?, ?)
        `);
        
        // S'assurer que body.data est bien un objet
        const eventData = typeof body.data === 'string' ? JSON.parse(body.data) : (body.data || {});
        
        stmt.run(
          body.type || "unknown",
          body.source || "hook",
          JSON.stringify(eventData),
          body.project || "unknown",
          body.project_path || "",
          body.agent || "claude"
        );
        
        // Gérer le projet
        if (body.project && body.project !== "unknown") {
          const existingProject = db.query("SELECT id FROM projects WHERE name = ?").get(body.project);
          
          if (!existingProject) {
            db.run(
              "INSERT INTO projects (name, path) VALUES (?, ?)",
              body.project,
              body.project_path || ""
            );
            console.log(`🆕 New project: ${body.project}`);
          } else {
            db.run(
              "UPDATE projects SET last_active = CURRENT_TIMESTAMP WHERE name = ?",
              body.project
            );
          }
        }
        
        // Diffuser aux clients WebSocket
        const eventMessage = JSON.stringify({
          type: "event",
          data: body,
          timestamp: new Date().toISOString()
        });
        
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(eventMessage);
          }
        });
        
        console.log(`📝 Event: ${body.type} from ${body.project || "unknown"}`);
        
        return Response.json({ success: true }, { headers });
      } catch (error) {
        console.error("Error processing event:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // GET events with filtering
    if (url.pathname === "/api/events" && req.method === "GET") {
      const limit = url.searchParams.get("limit") || "100";
      const agent = url.searchParams.get("agent");
      const type = url.searchParams.get("type");
      const project = url.searchParams.get("project");
      const search = url.searchParams.get("search");
      const startDate = url.searchParams.get("startDate");
      const endDate = url.searchParams.get("endDate");
      
      let query = "SELECT * FROM events WHERE 1=1";
      const params: any[] = [];
      
      if (agent && agent !== "all") {
        query += " AND agent = ?";
        params.push(agent);
      }
      
      if (type && type !== "all") {
        query += " AND type = ?";
        params.push(type);
      }
      
      if (project && project !== "all") {
        query += " AND project = ?";
        params.push(project);
      }
      
      if (search) {
        query += " AND (data LIKE ? OR type LIKE ? OR project LIKE ?)";
        const searchPattern = `%${search}%`;
        params.push(searchPattern, searchPattern, searchPattern);
      }
      
      if (startDate) {
        query += " AND timestamp >= ?";
        params.push(startDate);
      }
      
      if (endDate) {
        query += " AND timestamp <= ?";
        params.push(endDate);
      }
      
      query += " ORDER BY id DESC LIMIT ?";
      params.push(parseInt(limit));
      
      const events = db.query(query).all(...params);
      
      // Also get distinct values for filters
      const agents = db.query("SELECT DISTINCT agent FROM events WHERE agent IS NOT NULL").all();
      const types = db.query("SELECT DISTINCT type FROM events WHERE type IS NOT NULL").all();
      const projects = db.query("SELECT DISTINCT project FROM events WHERE project IS NOT NULL").all();
      
      return Response.json({
        events,
        filters: {
          agents: agents.map((a: any) => a.agent),
          types: types.map((t: any) => t.type),
          projects: projects.map((p: any) => p.project)
        }
      }, { headers });
    }
    
    // GET projects
    if (url.pathname === "/api/projects" && req.method === "GET") {
      const projects = db.query(`
        SELECT * FROM projects 
        ORDER BY last_active DESC
      `).all();
      
      return Response.json(projects, { headers });
    }
    
    // Health check
    if (url.pathname === "/health") {
      return Response.json({ 
        status: "ok", 
        clients: wsClients.size,
        port: PORT 
      }, { headers });
    }
    
    // API pour réveiller un agent
    if (url.pathname === '/api/wake-agent' && req.method === 'POST') {
      try {
        const { panel, agent } = await req.json();
        console.log(`🔔 Réveil de l'agent ${agent} (panel ${panel})`);
        
        // Exécuter la commande tmux pour réveiller l'agent
        const command = `tmux send-keys -t moulinsart-agents:agents.${panel} C-c && sleep 0.1 && tmux send-keys -t moulinsart-agents:agents.${panel} Enter`;
        
        const proc = Bun.spawn(["bash", "-c", command], {
          env: process.env
        });
        
        const exitCode = await proc.exited;
        
        if (exitCode === 0) {
          console.log(`✅ Agent ${agent} réveillé`);
          return Response.json({ 
            success: true, 
            message: `Agent ${agent} débloqué` 
          }, { headers });
        } else {
          return Response.json({ 
            error: 'Erreur lors du réveil de l\'agent' 
          }, { status: 500, headers });
        }
      } catch (error) {
        console.error('❌ Erreur wake-agent:', error);
        return Response.json({ 
          error: 'Erreur serveur' 
        }, { status: 500, headers });
      }
    }
    
    // API pour créer un nouveau projet
    if (url.pathname === '/api/projects/create' && req.method === 'POST') {
      try {
        const projectData = await req.json();
        console.log('📦 Création projet:', projectData);
        
        // Créer le projet via le script bash
        const command = `~/moulinsart/project-manager.sh create-api "${projectData.name}" "${projectData.type}" "${projectData.agents.agent1}" "${projectData.agents.agent2}" "${projectData.agents.agent3}" "${projectData.agents.agent4}"`;
        
        // Utiliser Bun.spawn pour exécuter la commande
        const proc = Bun.spawn(["bash", "-c", command], {
          cwd: "~/moulinsart",
          env: process.env
        });
        
        const output = await new Response(proc.stdout).text();
        const exitCode = await proc.exited;
        
        if (exitCode !== 0) {
          const error = await new Response(proc.stderr).text();
          console.error('❌ Erreur création projet:', error);
          return Response.json({ 
            error: 'Erreur lors de la création du projet',
            details: error 
          }, { status: 500, headers });
        }
        
        console.log('✅ Projet créé:', output);
        
        // Enregistrer dans la base
        db.run(`
          INSERT OR REPLACE INTO projects (name, created_at, last_active)
          VALUES (?, datetime('now'), datetime('now'))
        `, [projectData.name]);
        
        return Response.json({ 
          success: true, 
          project: projectData.name,
          domain: projectData.domain,
          output: output
        }, { headers });
      } catch (err: any) {
        console.error('❌ Erreur création projet:', err);
        return Response.json({ 
          error: 'Erreur lors de la création du projet',
          message: err.message 
        }, { status: 500, headers });
      }
    }
    
    // API pour lister les projets
    if (url.pathname === '/api/projects' && req.method === 'GET') {
      try {
        // Lister seulement les projets qui ont un dossier dans /projects
        const fs = await import('fs/promises');
        const projectsDir = '~/moulinsart/projects';
        
        // Vérifier si le dossier existe
        try {
          await fs.access(projectsDir);
        } catch {
          // Le dossier projects n'existe pas encore
          return Response.json({ projects: [] }, { headers });
        }
        
        const dirs = await fs.readdir(projectsDir);
        
        // Enrichir avec les infos de configuration
        const enrichedProjects = await Promise.all(dirs.map(async (projectName: string) => {
          const configPath = `${projectsDir}/${projectName}/config.json`;
          try {
            const file = Bun.file(configPath);
            const config = await file.json();
            
            // Obtenir la date de création depuis le système de fichiers
            const stats = await fs.stat(`${projectsDir}/${projectName}`);
            
            return {
              name: projectName,
              created: stats.birthtime.toISOString(),
              domain: config.domain,
              session: config.session,
              type: config.type,
              agents: config.agents,
              active: false, // TODO: vérifier si la session tmux existe
              icon: getProjectIcon(config.type)
            };
          } catch (err) {
            console.error(`Erreur lecture config ${projectName}:`, err);
            return null;
          }
        }));
        
        // Filtrer les nulls et retourner
        const validProjects = enrichedProjects.filter(p => p !== null);
        
        return Response.json({ projects: validProjects }, { headers });
      } catch (err: any) {
        console.error('Erreur listing projets:', err);
        return Response.json({ projects: [], error: err.message }, { headers });
      }
    }
    
    // Helper function pour obtenir l'icône du projet
    function getProjectIcon(type: string) {
      const icons: { [key: string]: string } = {
        ios: '🍎',
        web: '🌐',
        python: '🐍',
        custom: '✨'
      };
      return icons[type] || '📁';
    }
    
    // Sauvegarder le CLAUDE.md d'un agent
    if (url.pathname === '/api/save-claude-md' && req.method === 'POST') {
      try {
        const { agent, content } = await req.json();
        const filePath = `~/moulinsart/agents/${agent}/CLAUDE.md`;
        
        // Écrire le fichier
        await Bun.write(filePath, content);
        
        console.log(`💾 CLAUDE.md sauvegardé pour ${agent}`);
        return Response.json({ success: true, message: `CLAUDE.md sauvegardé pour ${agent}` }, { headers });
      } catch (err) {
        console.error('Erreur sauvegarde CLAUDE.md:', err);
        return Response.json({ error: err.message }, { status: 500, headers });
      }
    }
    
    // Lire le CLAUDE.md d'un agent
    if (url.pathname.match(/^\/api\/get-claude-md\/(\w+)$/) && req.method === 'GET') {
      try {
        const agent = url.pathname.split('/').pop();
        const filePath = `~/moulinsart/agents/${agent}/CLAUDE.md`;
        
        const file = Bun.file(filePath);
        if (await file.exists()) {
          const content = await file.text();
          return Response.json({ content }, { headers });
        } else {
          return Response.json({ content: '' }, { headers });
        }
      } catch (err) {
        console.error('Erreur lecture CLAUDE.md:', err);
        return Response.json({ error: err.message }, { status: 500, headers });
      }
    }
    
    // Capture tmux session output
    if (url.pathname === "/api/tmux-capture" && req.method === "POST") {
      const body = await req.json();
      const { session } = body;
      
      try {
        // Capture les 30 dernières lignes de la session tmux
        const { exec } = require('child_process');
        const output = await new Promise((resolve, reject) => {
          exec(`tmux capture-pane -t ${session} -p | tail -30`, (error: any, stdout: string) => {
            if (error) {
              resolve('');
            } else {
              resolve(stdout);
            }
          });
        });
        
        return Response.json({ output }, { headers });
      } catch (err) {
        return Response.json({ output: '' }, { headers });
      }
    }
    
    // Send command to tmux session
    if (url.pathname === "/api/tmux-send" && req.method === "POST") {
      const body = await req.json();
      const { session, command } = body;
      
      try {
        const { exec } = require('child_process');
        // Gérer Ctrl+C spécialement
        if (command === 'C-c') {
          exec(`tmux send-keys -t ${session} C-c`, (error: any) => {
            if (!error) {
              console.log(`⏹️ Ctrl+C sent to ${session}`);
            }
          });
        } else {
          exec(`tmux send-keys -t ${session} "${command}" Enter`, (error: any) => {
            if (!error) {
              console.log(`📤 Command sent to ${session}: ${command}`);
            }
          });
        }
        
        return Response.json({ success: true }, { headers });
      } catch (err) {
        return Response.json({ success: false }, { headers });
      }
    }
    
    // Agent management endpoints
    if (url.pathname === "/api/agents/status" && req.method === "GET") {
      const { exec } = require('child_process');
      const agents = ["nestor", "tintin", "dupont1", "dupont2"];
      const statuses: any = {};
      
      // D'abord vérifier si la session tmux existe
      const tmuxSessionExists = await new Promise((resolve) => {
        exec(`tmux has-session -t moulinsart-agents 2>/dev/null`, (error: any) => {
          resolve(!error);
        });
      });
      
      for (const agent of agents) {
        try {
          let isRunning = false;
          
          if (tmuxSessionExists) {
            // Si tmux existe, vérifier si Claude est lancé dans le panel de l'agent
            const panelIndex = agents.indexOf(agent);
            isRunning = await new Promise((resolve) => {
              exec(`tmux capture-pane -t moulinsart-agents:agents.${panelIndex} -p | grep -q "Welcome to Claude" && echo "1" || echo "0"`, (error: any, stdout: string) => {
                resolve(stdout.trim() === "1");
              });
            });
          }
          
          // Sinon vérifier les processus individuels (ancienne méthode)
          if (!isRunning) {
            isRunning = await new Promise((resolve) => {
              exec(`ps aux | grep -v grep | grep "claude --dangerously" | grep "${agent}" | wc -l`, (error: any, stdout: string) => {
                resolve(parseInt(stdout.trim()) > 0);
              });
            });
          }
          
          statuses[agent] = {
            running: isRunning,
            directory: `~/moulinsart/agents/${agent}`,
            email: `${agent}@moulinsart.local`,
            inTmux: tmuxSessionExists && isRunning
          };
        } catch (err) {
          statuses[agent] = { running: false };
        }
      }
      
      return Response.json(statuses, { headers });
    }
    
    // Launch all agents in tmux
    if (url.pathname === "/api/agents/launch-tmux" && req.method === "POST") {
      const { exec } = require('child_process');
      
      const script = `~/moulinsart/launch-agents-tmux.sh`;
      
      exec(script, (error: any, stdout: string, stderr: string) => {
        if (error) {
          console.error(`Erreur lancement tmux:`, error);
        } else {
          console.log(`✅ Agents lancés en tmux`);
        }
      });
      
      return Response.json({ success: true, message: "Agents lancés en tmux" }, { headers });
    }
    
    // Launch agents and open Terminal with tmux attached
    // Ouvrir le gestionnaire Moulinsart
    if (url.pathname === "/api/agents/open-manager" && req.method === "POST") {
      const { exec } = require('child_process');
      
      // AppleScript pour ouvrir Terminal et lancer le gestionnaire
      const appleScript = `
tell application "Terminal"
    activate
    do script "cd ~/moulinsart && ./moulinsart-manager-simple.sh"
end tell`;
      
      exec(`osascript -e '${appleScript.replace(/'/g, "'\"'\"'")}'`, (error: any) => {
        if (error) {
          console.error(`Erreur lancement Gestionnaire:`, error);
        } else {
          console.log(`✅ Gestionnaire Moulinsart ouvert dans Terminal`);
        }
      });
      
      return Response.json({ success: true, message: "Gestionnaire ouvert" }, { headers });
    }
    
    // Stop agent
    if (url.pathname === "/api/agents/stop" && req.method === "POST") {
      const { agent } = await req.json();
      const { exec } = require('child_process');
      
      // Kill all Claude processes for this agent
      exec(`pkill -f "claude.*${agent}"`, (error: any) => {
        if (!error) {
          console.log(`⏹️ Agent ${agent} arrêté`);
        }
      });
      
      // Also try to close the Terminal window
      const appleScript = `
tell application "Terminal"
    set windowList to windows
    repeat with w in windowList
        if custom title of w contains "${agent.toUpperCase()}" then
            close w
        end if
    end repeat
end tell`;
      
      exec(`osascript -e '${appleScript.replace(/'/g, "'\"'\"'")}'`);
      
      return Response.json({ success: true, message: `Agent ${agent} arrêté` }, { headers });
    }
    
    // Stop all agents
    if (url.pathname === "/api/agents/stop-all" && req.method === "POST") {
      const { exec } = require('child_process');
      
      // Kill tmux session and all Claude processes
      exec(`tmux kill-session -t moulinsart-agents 2>/dev/null; pkill -f "claude --dangerously" 2>/dev/null`, (error: any) => {
        console.log("🛑 Session tmux et tous les agents arrêtés");
      });
      
      return Response.json({ success: true, message: "Tous les agents arrêtés" }, { headers });
    }
    
    // ================== TASK MANAGEMENT API ENDPOINTS ==================
    
    // GET all tasks with filters
    if (url.pathname === "/api/tasks" && req.method === "GET") {
      try {
        const project_id = url.searchParams.get("project_id");
        const assigned_to = url.searchParams.get("assigned_to");
        const status = url.searchParams.get("status");
        const priority = url.searchParams.get("priority");
        
        let query = `
          SELECT t.*, p.name as project_name,
                 COUNT(c.id) as total_checkboxes,
                 COUNT(CASE WHEN c.completed = 1 THEN 1 END) as completed_checkboxes
          FROM tasks t
          LEFT JOIN projects p ON t.project_id = p.id
          LEFT JOIN checkboxes c ON t.id = c.task_id
          WHERE 1=1
        `;
        const params: any[] = [];
        
        if (project_id) {
          query += " AND t.project_id = ?";
          params.push(project_id);
        }
        
        if (assigned_to && assigned_to !== "all") {
          query += " AND t.assigned_to = ?";
          params.push(assigned_to);
        }
        
        if (status && status !== "all") {
          query += " AND t.status = ?";
          params.push(status);
        }
        
        if (priority && priority !== "all") {
          query += " AND t.priority = ?";
          params.push(priority);
        }
        
        query += " GROUP BY t.id ORDER BY t.updated_at DESC";
        
        const tasks = db.query(query).all(...params);
        
        // Get checkboxes for each task
        const tasksWithCheckboxes = tasks.map((task: any) => {
          const checkboxes = db.query("SELECT * FROM checkboxes WHERE task_id = ? ORDER BY id").all(task.id);
          return {
            ...task,
            checkboxes,
            progress: task.total_checkboxes > 0 ? (task.completed_checkboxes / task.total_checkboxes) * 100 : 0
          };
        });
        
        return Response.json(tasksWithCheckboxes, { headers });
      } catch (error) {
        console.error("Error fetching tasks:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // GET tasks for specific agent
    if (url.pathname.match(/^\/api\/tasks\/agent\/(\w+)$/) && req.method === "GET") {
      try {
        const agentName = url.pathname.split('/').pop();
        const tasks = db.query(`
          SELECT t.*, p.name as project_name,
                 COUNT(c.id) as total_checkboxes,
                 COUNT(CASE WHEN c.completed = 1 THEN 1 END) as completed_checkboxes
          FROM tasks t
          LEFT JOIN projects p ON t.project_id = p.id
          LEFT JOIN checkboxes c ON t.id = c.task_id
          WHERE t.assigned_to = ?
          GROUP BY t.id
          ORDER BY t.updated_at DESC
        `).all(agentName);
        
        const tasksWithCheckboxes = tasks.map((task: any) => {
          const checkboxes = db.query("SELECT * FROM checkboxes WHERE task_id = ? ORDER BY id").all(task.id);
          const validations = db.query("SELECT * FROM validations WHERE task_id = ? ORDER BY timestamp DESC").all(task.id);
          return {
            ...task,
            checkboxes,
            validations,
            progress: task.total_checkboxes > 0 ? (task.completed_checkboxes / task.total_checkboxes) * 100 : 0
          };
        });
        
        return Response.json(tasksWithCheckboxes, { headers });
      } catch (error) {
        console.error("Error fetching agent tasks:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST create new task
    if (url.pathname === "/api/tasks" && req.method === "POST") {
      try {
        const taskData = await req.json();
        
        const result = db.query(`
          INSERT INTO tasks (title, description, project_id, assigned_to, status, priority, due_date, estimated_hours, tags)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          taskData.title,
          taskData.description || '',
          taskData.project_id,
          taskData.assigned_to || null,
          taskData.status || 'TODO',
          taskData.priority || 'medium',
          taskData.due_date || null,
          taskData.estimated_hours || null,
          taskData.tags || ''
        );
        
        const taskId = result.lastInsertRowid;
        
        // Create default checkboxes for every task
        const defaultCheckboxes = [
          { label: 'Code/Implementation complete', required: true },
          { label: 'Screenshot taken', required: true },
          { label: 'Build successful', required: true },
          { label: 'Visual validation passed (3+ languages)', required: true },
          { label: 'Documentation updated', required: true }
        ];
        
        for (const checkbox of defaultCheckboxes) {
          db.query(`
            INSERT INTO checkboxes (task_id, label, required)
            VALUES (?, ?, ?)
          `).run(taskId, checkbox.label, checkbox.required);
        }
        
        // Add custom checkboxes if provided
        if (taskData.checkboxes) {
          for (const checkbox of taskData.checkboxes) {
            db.query(`
              INSERT INTO checkboxes (task_id, label, required)
              VALUES (?, ?, ?)
            `).run(taskId, checkbox.label, checkbox.required || false);
          }
        }
        
        // Log task creation
        db.query(`
          INSERT INTO task_history (task_id, status_from, status_to, changed_by, notes)
          VALUES (?, ?, ?, ?, ?)
        `).run(taskId, null, taskData.status || 'TODO', 'system', 'Task created');
        
        // Broadcast task creation via WebSocket
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "task_created",
              data: { taskId, ...taskData },
              timestamp: new Date().toISOString()
            }));
          }
        });
        
        return Response.json({ success: true, taskId }, { headers });
      } catch (error) {
        console.error("Error creating task:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // PUT update task status
    if (url.pathname.match(/^\/api\/tasks\/(\d+)\/status$/) && req.method === "PUT") {
      try {
        const taskId = url.pathname.split('/')[3];
        const { status, notes, updated_by } = await req.json();
        
        // Get current status for history
        const currentTask = db.query("SELECT status FROM tasks WHERE id = ?").get(taskId) as any;
        
        // Update task status and timestamp
        db.query(`
          UPDATE tasks 
          SET status = ?, updated_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `).run(status, taskId);
        
        // Log status change
        db.query(`
          INSERT INTO task_history (task_id, status_from, status_to, changed_by, notes)
          VALUES (?, ?, ?, ?, ?)
        `).run(taskId, currentTask?.status, status, updated_by || 'unknown', notes || '');
        
        // Broadcast status change
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "task_status_updated",
              data: { taskId, status, updated_by },
              timestamp: new Date().toISOString()
            }));
          }
        });
        
        return Response.json({ success: true }, { headers });
      } catch (error) {
        console.error("Error updating task status:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST validate task with evidence
    if (url.pathname.match(/^\/api\/tasks\/(\d+)\/validate$/) && req.method === "POST") {
      try {
        const taskId = url.pathname.split('/')[3];
        const validationData = await req.json();
        
        // Insert validation record
        db.query(`
          INSERT INTO validations (task_id, screenshot_path, validated_by, validation_status, validation_notes, build_log_url, test_results, languages_tested)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          taskId,
          validationData.screenshot_path || '',
          validationData.validated_by || 'unknown',
          validationData.validation_status || 'pending',
          validationData.validation_notes || '',
          validationData.build_log_url || '',
          validationData.test_results || '',
          validationData.languages_tested || ''
        );
        
        // Update checkbox completion if provided
        if (validationData.checkbox_updates) {
          for (const update of validationData.checkbox_updates) {
            db.query(`
              UPDATE checkboxes 
              SET completed = ?, evidence_url = ?, evidence_type = ?, completed_at = CURRENT_TIMESTAMP, completed_by = ?, notes = ?
              WHERE id = ?
            `).run(
              update.completed ? 1 : 0,
              update.evidence_url || '',
              update.evidence_type || '',
              validationData.validated_by,
              update.notes || '',
              update.checkbox_id
            );
          }
        }
        
        // Check if all required checkboxes are completed
        const incompleteRequired = db.query(`
          SELECT COUNT(*) as count FROM checkboxes 
          WHERE task_id = ? AND required = 1 AND completed = 0
        `).get(taskId) as any;
        
        // If all required checkboxes are completed, auto-move to DONE
        if (incompleteRequired.count === 0 && validationData.validation_status === 'approved') {
          db.query("UPDATE tasks SET status = 'DONE', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(taskId);
          
          // Log automatic status change
          db.query(`
            INSERT INTO task_history (task_id, status_from, status_to, changed_by, notes)
            VALUES (?, ?, ?, ?, ?)
          `).run(taskId, 'VALIDATION', 'DONE', 'system', 'All validations completed');
        }
        
        // Broadcast validation
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "task_validated",
              data: { taskId, ...validationData },
              timestamp: new Date().toISOString()
            }));
          }
        });
        
        return Response.json({ success: true }, { headers });
      } catch (error) {
        console.error("Error validating task:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST split PRD into tasks
    if (url.pathname === "/api/projects/split" && req.method === "POST") {
      try {
        const { project_id, prd_content, task_breakdown } = await req.json();
        
        // Update project with PRD content
        db.query("UPDATE projects SET prd = ? WHERE id = ?").run(prd_content, project_id);
        
        // Create tasks from breakdown
        const createdTasks = [];
        for (const taskInfo of task_breakdown) {
          const result = db.query(`
            INSERT INTO tasks (title, description, project_id, assigned_to, status, priority, estimated_hours)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          `).run(
            taskInfo.title,
            taskInfo.description,
            project_id,
            taskInfo.assigned_to,
            'TODO',
            taskInfo.priority || 'medium',
            taskInfo.estimated_hours || null
          );
          
          const taskId = result.lastInsertRowid;
          createdTasks.push({ id: taskId, ...taskInfo });
          
          // Create default checkboxes for each task
          const defaultCheckboxes = [
            { label: 'Code/Implementation complete', required: true },
            { label: 'Screenshot taken', required: true },
            { label: 'Build successful', required: true },
            { label: 'Visual validation passed (3+ languages)', required: true },
            { label: 'Documentation updated', required: true }
          ];
          
          for (const checkbox of defaultCheckboxes) {
            db.query(`
              INSERT INTO checkboxes (task_id, label, required)
              VALUES (?, ?, ?)
            `).run(taskId, checkbox.label, checkbox.required);
          }
        }
        
        return Response.json({ success: true, tasks: createdTasks }, { headers });
      } catch (error) {
        console.error("Error splitting PRD:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // GET task validation queue
    if (url.pathname === "/api/validations/queue" && req.method === "GET") {
      try {
        const validationsQueue = db.query(`
          SELECT v.*, t.title as task_title, t.assigned_to, p.name as project_name
          FROM validations v
          JOIN tasks t ON v.task_id = t.id
          JOIN projects p ON t.project_id = p.id
          WHERE v.validation_status = 'pending'
          ORDER BY v.timestamp DESC
        `).all();
        
        return Response.json(validationsQueue, { headers });
      } catch (error) {
        console.error("Error fetching validation queue:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // GET task statistics dashboard
    if (url.pathname === "/api/tasks/stats" && req.method === "GET") {
      try {
        const stats = {
          total_tasks: db.query("SELECT COUNT(*) as count FROM tasks").get()?.count || 0,
          tasks_by_status: db.query(`
            SELECT status, COUNT(*) as count 
            FROM tasks 
            GROUP BY status
          `).all(),
          tasks_by_agent: db.query(`
            SELECT assigned_to, COUNT(*) as count 
            FROM tasks 
            WHERE assigned_to IS NOT NULL
            GROUP BY assigned_to
          `).all(),
          validation_queue_size: db.query(`
            SELECT COUNT(*) as count 
            FROM validations 
            WHERE validation_status = 'pending'
          `).get()?.count || 0,
          overdue_tasks: db.query(`
            SELECT COUNT(*) as count 
            FROM tasks 
            WHERE due_date < datetime('now') AND status != 'DONE'
          `).get()?.count || 0
        };
        
        return Response.json(stats, { headers });
      } catch (error) {
        console.error("Error fetching task stats:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST upload evidence file
    if (url.pathname === "/api/upload/evidence" && req.method === "POST") {
      try {
        // TODO: Implement file upload handling for screenshots and evidence
        // For now, return a placeholder response
        const formData = await req.formData();
        const file = formData.get('file') as File;
        const taskId = formData.get('taskId') as string;
        
        if (!file) {
          return Response.json({ error: 'No file provided' }, { status: 400, headers });
        }
        
        // Save file to evidence directory
        const evidenceDir = '~/moulinsart/oracle-observability/evidence';
        const fileName = `task-${taskId}-${Date.now()}-${file.name}`;
        const filePath = `${evidenceDir}/${fileName}`;
        
        // Create directory if it doesn't exist
        await Bun.write(filePath, file);
        
        const evidenceUrl = `/evidence/${fileName}`;
        
        return Response.json({ 
          success: true, 
          evidenceUrl,
          fileName,
          size: file.size
        }, { headers });
      } catch (error) {
        console.error("Error uploading evidence:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // Page d'accueil simple
    if (url.pathname === "/") {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Moulinsart Oracle</title>
          <style>
            body { 
              font-family: monospace; 
              background: #1a1a1a; 
              color: #0f0; 
              padding: 20px;
            }
            pre { 
              background: #000; 
              padding: 10px; 
              border: 1px solid #0f0;
            }
          </style>
        </head>
        <body>
          <h1>🔮 Moulinsart Oracle Observability</h1>
          <pre>
Status: ONLINE
Port: ${PORT}
WebSocket: ws://localhost:${PORT}/ws
API: http://localhost:${PORT}/api/events

Connected clients: <span id="clients">0</span>
          </pre>
          <script>
            const ws = new WebSocket('ws://localhost:${PORT}/ws');
            ws.onmessage = (e) => {
              const data = JSON.parse(e.data);
              if (data.type === 'status') {
                document.getElementById('clients').textContent = data.clients || 0;
              }
            };
          </script>
        </body>
        </html>
      `, {
        headers: { "Content-Type": "text/html" }
      });
    }
    
    return new Response("Not Found", { status: 404 });
  },
  
  websocket: {
    open(ws) {
      wsClients.add(ws);
      console.log(`Client connected. Total: ${wsClients.size}`);
      
      // Envoyer le statut
      ws.send(JSON.stringify({
        type: "status",
        clients: wsClients.size,
        timestamp: new Date().toISOString()
      }));
    },
    
    close(ws) {
      wsClients.delete(ws);
      console.log(`Client disconnected. Total: ${wsClients.size}`);
    },
    
    message(ws, message) {
      // Echo pour les tests
      ws.send(message);
    }
  }
});

console.log(`🔮 Moulinsart Oracle running on http://localhost:${PORT}`);
console.log(`📡 WebSocket available at ws://localhost:${PORT}/ws`);