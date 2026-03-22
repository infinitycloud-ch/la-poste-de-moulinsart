#!/usr/bin/env bun
/**
 * Oracle Observability Server - Version minimale pour Moulinsart
 * Capture et diffuse les événements des hooks Claude
 */

import { Database } from "bun:sqlite";
import { serve } from "bun";
import { join } from "path";
import * as fs from "fs";
import nodemailer from "nodemailer";
import { homedir } from "os";

// ASCII-only sanitizer for persistent content
function sanitizeToASCII(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
    .replace(/[^\x00-\x7F]/g, '?');  // Replace non-ASCII with ?
}

// ISO date formatter
function toISODate(date: Date = new Date()): string {
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}

// Centralized paths configuration
const PATHS = {
  MOULINSART_ROOT: join(homedir(), "moulinsart"),
  PROJECTS: join(homedir(), "moulinsart", "projects"),
  AGENTS: join(homedir(), "moulinsart", "agents"),
  EXPORTS: join(homedir(), "moulinsart", "exports")
};

// Sprint validation
function validateSprint(sprint: string): boolean {
  return /^Sprint\s+\d+$/.test(sprint);
}

// Check if tasks exist for project/sprint
function hasTasksForSprint(project_id: number, sprint: string): boolean {
  const tasks = db.query("SELECT COUNT(*) as count FROM tasks WHERE project_id = ? AND sprint = ?").get(project_id, sprint) as { count: number };
  return tasks.count > 0;
}
import * as path from "path";

const PORT = 3001; // Port différent pour ne pas confliter avec l'autre Oracle
const db = new Database(join(import.meta.dir, "../data/oracle.db"));

// Configurer SQLite en mode WAL pour les accès concurrents
db.run("PRAGMA journal_mode = WAL");
db.run("PRAGMA synchronous = NORMAL");
db.run("PRAGMA cache_size = 1000");
db.run("PRAGMA temp_store = memory");

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

// Table pour les commandes TMUX personnalisées
db.run(`
  CREATE TABLE IF NOT EXISTS tmux_commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    icon TEXT DEFAULT '💬',
    category TEXT DEFAULT 'Général',
    message TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// WebSocket clients
const wsClients = new Set<WebSocket>();

// Function to broadcast messages to all WebSocket clients
const broadcastMessage = (message: any) => {
  const eventMessage = JSON.stringify({
    type: "event",
    data: message,
    timestamp: new Date().toISOString()
  });

  console.log(`🔴 Broadcasting to ${wsClients.size} clients:`, eventMessage);

  wsClients.forEach(ws => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(eventMessage);
      console.log(`🔴 Message sent to client`);
    } else {
      console.log(`🔴 Client not ready, readyState:`, ws.readyState);
    }
  });
};

console.log("🔮 Moulinsart Oracle Observability starting...");

const server = serve({
  port: PORT,
  
  async fetch(req, server) {
    const url = new URL(req.url);
    
    // CORS headers - ZERO SECURITY
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "*",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Allow-Credentials": "true",
      "Access-Control-Max-Age": "86400"
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
        let eventData;
        try {
          eventData = typeof body.data === 'string' ? JSON.parse(body.data) : (body.data || {});
        } catch (e) {
          // Si ce n'est pas du JSON valide, traiter comme une chaîne simple
          eventData = body.data || {};
        }
        
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
        broadcastMessage(body);
        
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
    

    // GET specific project
    if (url.pathname.match(/^\/api\/projects\/(\d+)$/) && req.method === "GET") {
      try {
        const projectId = parseInt(url.pathname.split('/')[3]);
        const project = db.query("SELECT * FROM projects WHERE id = ?").get(projectId);

        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        return Response.json({ project }, { headers });
      } catch (error) {
        console.error("Error fetching project:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET /api/projects/:id/sprints - Get all sprints for a specific project
    const sprintsMatch = url.pathname.match(/^\/api\/projects\/(\d+)\/sprints$/);
    if (sprintsMatch && req.method === "GET") {
      const projectId = parseInt(sprintsMatch[1]);

      try {
        // Get distinct sprints for this project from tasks table
        const sprints = db.query(`
          SELECT DISTINCT sprint
          FROM tasks
          WHERE project_id = ?
          ORDER BY sprint
        `).all(projectId);

        const sprintNames = sprints.map(row => row.sprint);

        return Response.json({
          project_id: projectId,
          sprints: sprintNames
        }, { headers });
      } catch (error) {
        console.error('Error fetching sprints:', error);
        return Response.json({ error: "Failed to fetch sprints" }, { status: 500, headers });
      }
    }

    // POST projects/create - Créer dossier projet + PRD.md physiquement
    if (url.pathname === "/api/projects/create" && req.method === "POST") {
      try {
        const body = await req.json();
        const { name, prd_content } = body;

        if (!name || !prd_content) {
          return Response.json({ error: "name and prd_content are required" }, { status: 400, headers });
        }

        // Nettoyer le nom du projet (enlever caractères spéciaux)
        const cleanName = name.replace(/[^a-zA-Z0-9\-_]/g, '_').toLowerCase();
        const projectPath = join(PATHS.PROJECTS, cleanName);

        // Vérifier si le dossier existe déjà
        if (fs.existsSync(projectPath)) {
          return Response.json({ error: "Project folder already exists" }, { status: 409, headers });
        }

        // Créer le dossier projet
        fs.mkdirSync(projectPath, { recursive: true });

        // Créer le fichier PRD.md
        const prdFilePath = join(projectPath, `${cleanName}_prd.md`);
        fs.writeFileSync(prdFilePath, prd_content, 'utf-8');

        // Créer le projet en base
        const result = db.query(`
          INSERT INTO projects (name, path, prd, created_at, last_active)
          VALUES (?, ?, ?, datetime('now'), datetime('now'))
        `).run(cleanName, projectPath, prd_content);

        console.log(`📁 Nouveau projet créé: ${cleanName} dans ${projectPath}`);

        return Response.json({
          id: result.lastInsertRowid,
          name: cleanName,
          path: projectPath,
          prd_file: prdFilePath,
          message: "Project and PRD.md created successfully"
        }, { headers });
      } catch (error) {
        console.error("Error creating project:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // API pour récupérer les emails par expéditeur
    if (url.pathname === "/api/emails" && req.method === "GET") {
      const from = url.searchParams.get("from");
      const to = url.searchParams.get("to");
      const limit = url.searchParams.get("limit") || "50";

      try {
        let query = "SELECT * FROM emails WHERE deleted = 0";
        const params: any[] = [];

        if (from) {
          query += " AND from_address = ?";
          params.push(from);
        }

        if (to) {
          query += " AND to_address = ?";
          params.push(to);
        }

        query += " ORDER BY timestamp DESC LIMIT ?";
        params.push(parseInt(limit));

        const emails = db.query(query).all(...params);

        return Response.json({ emails }, { headers });
      } catch (error) {
        console.error("Error fetching emails:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
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
    
    // GET projects - Liste fixe des projets fonctionnels
    if (url.pathname === "/api/projects" && req.method === "GET") {
      // Afficher TOUS les projets (plus de limitation)
      const projects = db.query(`
        SELECT * FROM projects
        ORDER BY last_active DESC
      `).all();

      return Response.json(projects, { headers });
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
    
    // ================== TMUX CONFIGURATION API ENDPOINTS ==================
    
    // GET tmux notification configuration
    if (url.pathname === "/api/tmux-config" && req.method === "GET") {
      try {
        const configPath = path.join(process.cwd(), 'tmux-notification-config.json');
        if (fs.existsSync(configPath)) {
          const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
          return Response.json({ config }, { headers });
        } else {
          // Return default config if file doesn't exist
          const defaultConfig = {
            notification_template: {
              header: "🔔 NOTIFICATION SYSTÈME",
              separator: "━━━━━━━━━━━━━━━━━━━━",
              rules: [
                "📖 LIRE TON CLAUDE.md EN PREMIER",
                "🎯 FOCUS: Une tâche à la fois",
                "✅ TERMINÉ = STOP (pas de confirmation)",
                "🚫 PAS DE BOUCLES RE:RE:RE:"
              ],
              email_format: {
                from: "📧 Nouveau mail de {sender}",
                subject: "📬 Sujet: {subject}"
              },
              commands: {
                read: "📖 LIRE: curl http://localhost:1080/api/mailbox/{recipient}",
                reply: "✉️ RÉPONDRE: ./send-mail.sh destinataire@moulinsart.local \"Sujet\" \"Message\""
              }
            },
            send_reminder: false,
            reminder_delay: 3,
            clear_before_send: true
          };
          return Response.json({ config: defaultConfig }, { headers });
        }
      } catch (error) {
        console.error("Error fetching TMUX config:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST update tmux notification configuration
    if (url.pathname === "/api/tmux-config" && req.method === "POST") {
      try {
        const body = await req.json();
        const configPath = path.join(process.cwd(), 'tmux-notification-config.json');
        fs.writeFileSync(configPath, JSON.stringify(body.config, null, 2));
        
        return Response.json({ 
          success: true, 
          message: "Configuration TMUX mise à jour"
        }, { headers });
      } catch (error) {
        console.error("Error updating TMUX config:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST restart mail server to apply new config
    if (url.pathname === "/api/restart-mail-server" && req.method === "POST") {
      const { exec } = require('child_process');
      
      exec('pkill -f "bun.*mail-server" && sleep 1 && cd ~/moulinsart/oracle-observability && bun run server/mail-server.ts &', (error: any) => {
        if (error) {
          console.error("Error restarting mail server:", error);
        } else {
          console.log("✅ Mail server restarted");
        }
      });
      
      return Response.json({ 
        success: true, 
        message: "Serveur mail redémarré"
      }, { headers });
    }
    
    // ================== TMUX COMMANDS API ENDPOINTS ==================
    
    // GET all TMUX commands
    if (url.pathname === "/api/tmux-commands" && req.method === "GET") {
      try {
        const commands = db.query("SELECT * FROM tmux_commands ORDER BY category, name").all();
        return Response.json({ commands }, { headers });
      } catch (error) {
        console.error("Error fetching TMUX commands:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST new TMUX command
    if (url.pathname === "/api/tmux-commands" && req.method === "POST") {
      try {
        const body = await req.json();
        const { name, icon, category, message } = body;
        
        const result = db.query(`
          INSERT INTO tmux_commands (name, icon, category, message)
          VALUES (?, ?, ?, ?)
        `).run(name, icon || '💬', category || 'Général', message);
        
        return Response.json({ 
          success: true, 
          id: result.lastInsertRowid,
          message: "Commande TMUX créée"
        }, { headers });
      } catch (error) {
        console.error("Error creating TMUX command:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // PUT update TMUX command
    if (url.pathname.startsWith("/api/tmux-commands/") && req.method === "PUT") {
      try {
        const id = url.pathname.split('/').pop();
        const body = await req.json();
        const { name, icon, category, message } = body;
        
        db.query(`
          UPDATE tmux_commands 
          SET name = ?, icon = ?, category = ?, message = ?, updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).run(name, icon, category, message, id);
        
        return Response.json({ success: true, message: "Commande TMUX mise à jour" }, { headers });
      } catch (error) {
        console.error("Error updating TMUX command:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // DELETE TMUX command
    if (url.pathname.startsWith("/api/tmux-commands/") && req.method === "DELETE") {
      try {
        const id = url.pathname.split('/').pop();
        
        db.query("DELETE FROM tmux_commands WHERE id = ?").run(id);
        
        return Response.json({ success: true, message: "Commande TMUX supprimée" }, { headers });
      } catch (error) {
        console.error("Error deleting TMUX command:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // Execute bash command endpoint
    if (url.pathname === "/api/exec" && req.method === "POST") {
      try {
        const body = await req.json();
        const { command } = body;
        
        if (!command) {
          return Response.json({ error: "Command is required" }, { status: 400, headers });
        }
        
        const { exec } = require('child_process');
        
        return new Promise((resolve) => {
          exec(command, (error: any, stdout: string, stderr: string) => {
            if (error) {
              console.error(`Error executing command: ${error}`);
              resolve(Response.json({ 
                success: false, 
                error: error.message,
                stderr 
              }, { status: 500, headers }));
            } else {
              resolve(Response.json({ 
                success: true, 
                stdout,
                stderr 
              }, { headers }));
            }
          });
        });
      } catch (error) {
        console.error("Error executing command:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // ================== SHELL EXECUTION API ENDPOINTS ==================

    // POST execute shell command (pour le Commandant)
    if (url.pathname === "/api/execute-shell" && req.method === "POST") {
      try {
        const body = await req.json();
        const { command, args } = body;

        if (!command) {
          return Response.json({
            success: false,
            error: "Command is required"
          }, { status: 400, headers });
        }

        const { exec } = require('child_process');
        const { spawn } = require('child_process');

        // Construire la commande avec les arguments
        const fullCommand = args && args.length > 0
          ? `${command} ${args.map(arg => `"${arg}"`).join(' ')}`
          : command;

        console.log(`🔧 Exécution commande shell: ${fullCommand}`);

        return new Promise((resolve) => {
          exec(fullCommand, (error: any, stdout: string, stderr: string) => {
            if (error) {
              console.error(`Erreur exécution: ${error.message}`);
              resolve(Response.json({
                success: false,
                error: error.message,
                stderr
              }, { status: 500, headers }));
            } else {
              console.log(`✅ Commande exécutée avec succès`);
              resolve(Response.json({
                success: true,
                stdout: stdout.trim(),
                stderr: stderr.trim()
              }, { headers }));
            }
          });
        });
      } catch (error) {
        console.error("Error executing shell command:", error);
        return Response.json({
          success: false,
          error: error.message
        }, { status: 500, headers });
      }
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
    
    // PUT update task (general update)
    if (url.pathname.match(/^\/api\/tasks\/(\d+)$/) && req.method === "PUT") {
      try {
        const taskId = url.pathname.split('/')[3];
        const taskData = await req.json();

        // Get current task for history
        const currentTask = db.query("SELECT * FROM tasks WHERE id = ?").get(taskId) as any;

        if (!currentTask) {
          return Response.json({ error: "Task not found" }, { status: 404, headers });
        }

        // Update task
        const updates = [];
        const values = [];

        if (taskData.title !== undefined) {
          updates.push("title = ?");
          values.push(taskData.title);
        }
        if (taskData.description !== undefined) {
          updates.push("description = ?");
          values.push(taskData.description);
        }
        if (taskData.status !== undefined) {
          updates.push("status = ?");
          values.push(taskData.status);
        }
        if (taskData.priority !== undefined) {
          updates.push("priority = ?");
          values.push(taskData.priority);
        }
        if (taskData.assigned_to !== undefined) {
          updates.push("assigned_to = ?");
          values.push(taskData.assigned_to);
        }
        if (taskData.sprint !== undefined) {
          updates.push("sprint = ?");
          values.push(taskData.sprint);
        }
        if (taskData.notes !== undefined) {
          updates.push("notes = ?");
          values.push(taskData.notes);
        }

        if (updates.length > 0) {
          updates.push("updated_at = CURRENT_TIMESTAMP");
          values.push(taskId);

          db.query(`UPDATE tasks SET ${updates.join(", ")} WHERE id = ?`).run(...values);

          // Log changes in history if status changed
          if (taskData.status && taskData.status !== currentTask.status) {
            db.query(`
              INSERT INTO task_history (task_id, status_from, status_to, changed_by, notes)
              VALUES (?, ?, ?, ?, ?)
            `).run(taskId, currentTask.status, taskData.status, taskData.updated_by || 'unknown', taskData.notes || '');
          }

          // Broadcast update
          wsClients.forEach(ws => {
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(JSON.stringify({
                type: "task_updated",
                data: { taskId, updates: taskData },
                timestamp: new Date().toISOString()
              }));
            }
          });
        }

        return Response.json({ success: true }, { headers });
      } catch (error) {
        console.error("Error updating task:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // PUT update task status (legacy endpoint for compatibility)
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

    // DELETE single task
    if (url.pathname.match(/^\/api\/tasks\/(\d+)$/) && req.method === "DELETE") {
      try {
        const taskId = url.pathname.split('/')[3];

        // Get task info before deletion
        const task = db.query("SELECT * FROM tasks WHERE id = ?").get(taskId) as any;

        if (!task) {
          return Response.json({ error: "Task not found" }, { status: 404, headers });
        }

        // Delete related records first (foreign key constraints)
        db.query("DELETE FROM checkboxes WHERE task_id = ?").run(taskId);
        db.query("DELETE FROM validations WHERE task_id = ?").run(taskId);
        db.query("DELETE FROM task_history WHERE task_id = ?").run(taskId);

        // Delete the task
        db.query("DELETE FROM tasks WHERE id = ?").run(taskId);

        // Broadcast deletion
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "task_deleted",
              data: { taskId, title: task.title },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({ success: true, message: `Task "${task.title}" deleted` }, { headers });
      } catch (error) {
        console.error("Error deleting task:", error);
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

    // API simple pour créer un projet avec nomenclature id_nom
    if (url.pathname === '/api/projects/create-simple' && req.method === 'POST') {
      try {
        const { name, folder_name, prd_content } = await req.json();
        console.log('📁 Création projet simple:', { name, folder_name });

        if (!name || !folder_name) {
          return Response.json({ error: 'Nom et folder_name requis' }, { status: 400, headers });
        }

        const projectPath = `~/moulinsart/projects/${folder_name}`;

        // Créer le dossier du projet
        if (!fs.existsSync(projectPath)) {
          fs.mkdirSync(projectPath, { recursive: true });
        }

        // Créer le fichier PRD.md
        const prdPath = path.join(projectPath, 'PRD.md');
        const prdContent = prd_content || `# PRD - ${name}\n\n## Description\n\nNouveau projet créé le ${new Date().toLocaleDateString()}\n`;
        fs.writeFileSync(prdPath, prdContent, 'utf-8');

        // Créer config.json avec métadonnées
        const configPath = path.join(projectPath, 'config.json');
        const config = {
          id: folder_name,
          name: name,
          domain: "general",
          session: "standalone",
          type: "project",
          agents: [],
          created_at: new Date().toISOString()
        };
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf-8');

        // NOUVEAU: Insérer en base SQLite avec gestion d'erreur
        let projectId;
        try {
          const result = db.run(
            "INSERT INTO projects (name, path, prd) VALUES (?, ?, ?)",
            name,
            projectPath,
            prdContent
          );
          projectId = result.lastInsertRowid;
          console.log(`✅ Projet créé en base SQLite: ${name} (ID: ${projectId})`);
        } catch (dbError: any) {
          console.error(`❌ Erreur insertion SQLite pour ${name}:`, dbError.message);
          // Si c'est une contrainte UNIQUE, on continue quand même
          if (dbError.message.includes('UNIQUE constraint failed')) {
            console.log(`⚠️ Projet ${name} existe déjà en base, création fichier seulement`);
            projectId = null;
          } else {
            throw dbError; // Autres erreurs remontent
          }
        }

        return Response.json({
          success: true,
          project: {
            id: projectId,
            name: name,
            path: projectPath
          }
        }, { headers });

      } catch (error: any) {
        console.error('❌ Erreur création projet simple:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // API pour supprimer un projet
    if (url.pathname.match(/^\/api\/projects\/(.+)$/) && req.method === 'DELETE') {
      try {
        const projectId = parseInt(url.pathname.split('/').pop());
        console.log('🗑️ Suppression projet:', projectId);

        if (!projectId) {
          return Response.json({ error: 'ID projet requis' }, { status: 400, headers });
        }

        // Récupérer le projet depuis la base
        const project = db.query("SELECT * FROM projects WHERE id = ?").get(projectId);
        if (!project) {
          return Response.json({ error: 'Projet non trouvé en base' }, { status: 404, headers });
        }

        // Supprimer d'abord toutes les tâches du projet
        db.query("DELETE FROM tasks WHERE project_id = ?").run(projectId);

        // Supprimer le projet de la base
        db.query("DELETE FROM projects WHERE id = ?").run(projectId);

        // Si le projet a un dossier physique, le supprimer aussi
        if (project.path && project.path.startsWith('~/moulinsart/projects/')) {
          try {
            if (fs.existsSync(project.path)) {
              fs.rmSync(project.path, { recursive: true, force: true });
              console.log(`✅ Dossier supprimé: ${project.path}`);
            }
          } catch (fsError) {
            console.log(`⚠️ Erreur suppression dossier: ${fsError}`);
          }
        }

        console.log(`✅ Projet ${project.name} supprimé de la base`);

        return Response.json({
          success: true,
          message: `Projet ${project.name} supprimé`
        }, { headers });

      } catch (error: any) {
        console.error('❌ Erreur suppression projet:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // API pour synchroniser projets (database vs filesystem)
    if (url.pathname === '/api/projects/sync' && req.method === 'POST') {
      try {
        console.log('🔄 Synchronisation projets database <-> filesystem');

        const projectsPath = '~/moulinsart/projects';
        let syncReport = {
          added: [],
          removed: [],
          errors: []
        };

        // 1. Récupérer projets en base
        const dbProjects = db.query("SELECT * FROM projects").all();
        const dbProjectPaths = new Set(dbProjects.map(p => p.path).filter(Boolean));

        // 2. Scanner le dossier projects
        let fsProjects = [];
        if (fs.existsSync(projectsPath)) {
          const folders = fs.readdirSync(projectsPath, { withFileTypes: true })
            .filter(dirent => dirent.isDirectory())
            .map(dirent => dirent.name);

          fsProjects = folders.map(folder => ({
            name: folder,
            path: path.join(projectsPath, folder)
          }));
        }
        const fsProjectPaths = new Set(fsProjects.map(p => p.path));

        // 3. Supprimer de la DB les projets dont le dossier n'existe plus OU qui ne sont pas dans le dossier projects
        for (const dbProject of dbProjects) {
          if (dbProject.path && (!fs.existsSync(dbProject.path) || !dbProject.path.startsWith(projectsPath))) {
            try {
              // Supprimer les tâches du projet
              db.query("DELETE FROM tasks WHERE project_id = ?").run(dbProject.id);
              // Supprimer le projet
              db.query("DELETE FROM projects WHERE id = ?").run(dbProject.id);

              syncReport.removed.push({
                name: dbProject.name,
                path: dbProject.path,
                reason: dbProject.path.startsWith(projectsPath) ? 'Dossier supprimé' : 'Hors dossier projects'
              });
              console.log(`🗑️ Supprimé de la DB: ${dbProject.name} (${dbProject.path.startsWith(projectsPath) ? 'dossier n\'existe plus' : 'hors dossier projects'})`);
            } catch (error) {
              console.error(`❌ Erreur suppression ${dbProject.name}:`, error);
              syncReport.errors.push({
                name: dbProject.name,
                error: error.message
              });
            }
          }
        }

        // 4. Ajouter à la DB les dossiers qui n'y sont pas
        for (const fsProject of fsProjects) {
          if (!dbProjectPaths.has(fsProject.path)) {
            try {
              // Créer PRD par défaut
              const prdContent = `# PRD - ${fsProject.name}\n\n## Description\n\nProjet synchronisé automatiquement le ${new Date().toLocaleDateString()}\n`;

              const result = db.run(
                "INSERT INTO projects (name, path, prd) VALUES (?, ?, ?)",
                fsProject.name,
                fsProject.path,
                prdContent
              );

              syncReport.added.push({
                name: fsProject.name,
                path: fsProject.path,
                id: result.lastInsertRowid
              });
              console.log(`✅ Ajouté à la DB: ${fsProject.name} (ID: ${result.lastInsertRowid})`);
            } catch (error) {
              console.error(`❌ Erreur ajout ${fsProject.name}:`, error);
              syncReport.errors.push({
                name: fsProject.name,
                error: error.message
              });
            }
          }
        }

        console.log('🎯 Synchronisation terminée:', syncReport);

        return Response.json({
          success: true,
          message: 'Synchronisation terminée',
          report: syncReport
        }, { headers });

      } catch (error: any) {
        console.error('❌ Erreur synchronisation:', error);
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

    // DELETE all tasks (reset)
    if (url.pathname === "/api/tasks/reset" && req.method === "DELETE") {
      try {
        // Get count before deletion for logging
        const taskCount = db.query("SELECT COUNT(*) as count FROM tasks").get()?.count || 0;

        // Delete all related records first (foreign key constraints)
        db.query("DELETE FROM checkboxes").run();
        db.query("DELETE FROM validations").run();
        db.query("DELETE FROM task_history").run();

        // Delete all tasks
        db.query("DELETE FROM tasks").run();

        // Broadcast reset
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "tasks_reset",
              data: { deletedCount: taskCount },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({
          success: true,
          message: `All ${taskCount} tasks deleted`,
          deletedCount: taskCount
        }, { headers });
      } catch (error) {
        console.error("Error resetting tasks:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // DELETE tasks by project
    if (url.pathname.match(/^\/api\/projects\/(\d+)\/tasks\/reset$/) && req.method === "DELETE") {
      try {
        const projectId = url.pathname.split('/')[3];

        // Get count before deletion for logging
        const taskCount = db.query("SELECT COUNT(*) as count FROM tasks WHERE project_id = ?").get(projectId)?.count || 0;

        if (taskCount === 0) {
          return Response.json({
            success: true,
            message: "No tasks found for this project",
            deletedCount: 0
          }, { headers });
        }

        // Get task IDs for deletion of related records
        const taskIds = db.query("SELECT id FROM tasks WHERE project_id = ?").all(projectId);

        // Delete related records first
        for (const task of taskIds) {
          db.query("DELETE FROM checkboxes WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM validations WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM task_history WHERE task_id = ?").run(task.id);
        }

        // Delete tasks for the project
        db.query("DELETE FROM tasks WHERE project_id = ?").run(projectId);

        // Broadcast project tasks reset
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "project_tasks_reset",
              data: { projectId, deletedCount: taskCount },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({
          success: true,
          message: `All ${taskCount} tasks deleted for project ${projectId}`,
          deletedCount: taskCount
        }, { headers });
      } catch (error) {
        console.error("Error resetting project tasks:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // DELETE tasks by agent
    if (url.pathname.match(/^\/api\/agents\/(.+)\/tasks\/reset$/) && req.method === "DELETE") {
      try {
        const agent = decodeURIComponent(url.pathname.split('/')[3]);

        // Get count before deletion for logging
        const taskCount = db.query("SELECT COUNT(*) as count FROM tasks WHERE assigned_to = ?").get(agent)?.count || 0;

        if (taskCount === 0) {
          return Response.json({
            success: true,
            message: `No tasks found for agent ${agent}`,
            deletedCount: 0
          }, { headers });
        }

        // Get task IDs for deletion of related records
        const taskIds = db.query("SELECT id FROM tasks WHERE assigned_to = ?").all(agent);

        // Delete related records first
        for (const task of taskIds) {
          db.query("DELETE FROM checkboxes WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM validations WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM task_history WHERE task_id = ?").run(task.id);
        }

        // Delete tasks for the agent
        db.query("DELETE FROM tasks WHERE assigned_to = ?").run(agent);

        // Broadcast agent tasks reset
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "agent_tasks_reset",
              data: { agent, deletedCount: taskCount },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({
          success: true,
          message: `All ${taskCount} tasks deleted for agent ${agent}`,
          deletedCount: taskCount
        }, { headers });
      } catch (error) {
        console.error("Error resetting agent tasks:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // DELETE tasks by sprint
    if (url.pathname.match(/^\/api\/tasks\/sprint\/(.+)$/) && req.method === "DELETE") {
      try {
        const sprintName = decodeURIComponent(url.pathname.split('/')[4]);

        // Get count before deletion for logging
        const taskCount = db.query("SELECT COUNT(*) as count FROM tasks WHERE sprint = ?").get(sprintName)?.count || 0;

        if (taskCount === 0) {
          return Response.json({
            success: true,
            message: `No tasks found for sprint ${sprintName}`,
            deletedCount: 0
          }, { headers });
        }

        // Get task IDs for deletion of related records
        const taskIds = db.query("SELECT id FROM tasks WHERE sprint = ?").all(sprintName);

        // Delete related records first
        for (const task of taskIds) {
          db.query("DELETE FROM checkboxes WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM validations WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM task_history WHERE task_id = ?").run(task.id);
        }

        // Delete tasks for the sprint
        db.query("DELETE FROM tasks WHERE sprint = ?").run(sprintName);

        // Broadcast sprint deletion
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "sprint_deleted",
              data: { sprint: sprintName, deletedCount: taskCount },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({
          success: true,
          message: `Sprint "${sprintName}" deleted with ${taskCount} tasks`,
          deletedCount: taskCount
        }, { headers });
      } catch (error) {
        console.error("Error deleting sprint:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // DELETE tasks by sprint (clear only)
    if (url.pathname.match(/^\/api\/tasks\/sprint\/(.+)\/clear$/) && req.method === "DELETE") {
      try {
        const sprintName = decodeURIComponent(url.pathname.split('/')[4]);

        // Get count before deletion for logging
        const taskCount = db.query("SELECT COUNT(*) as count FROM tasks WHERE sprint = ?").get(sprintName)?.count || 0;

        if (taskCount === 0) {
          return Response.json({
            success: true,
            message: `No tasks found for sprint ${sprintName}`,
            deletedCount: 0
          }, { headers });
        }

        // Get task IDs for deletion of related records
        const taskIds = db.query("SELECT id FROM tasks WHERE sprint = ?").all(sprintName);

        // Delete related records first
        for (const task of taskIds) {
          db.query("DELETE FROM checkboxes WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM validations WHERE task_id = ?").run(task.id);
          db.query("DELETE FROM task_history WHERE task_id = ?").run(task.id);
        }

        // Delete tasks for the sprint
        db.query("DELETE FROM tasks WHERE sprint = ?").run(sprintName);

        // Broadcast sprint tasks cleared
        wsClients.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
              type: "sprint_tasks_cleared",
              data: { sprint: sprintName, deletedCount: taskCount },
              timestamp: new Date().toISOString()
            }));
          }
        });

        return Response.json({
          success: true,
          message: `${taskCount} tasks cleared from sprint "${sprintName}"`,
          deletedCount: taskCount
        }, { headers });
      } catch (error) {
        console.error("Error clearing sprint tasks:", error);
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
    
    // ===== PRD Management Endpoints =====
    
    // GET list all PRD files (recursive scan)
    if (url.pathname === "/api/prds" && req.method === "GET") {
      try {
        // Fonction récursive pour scanner les répertoires
        const findPRDFiles = (dir: string, baseDir: string = dir): any[] => {
          const results: any[] = [];
          
          try {
            const items = fs.readdirSync(dir, { withFileTypes: true });
            
            for (const item of items) {
              const fullPath = path.join(dir, item.name);
              
              // Ignorer certains dossiers
              if (item.isDirectory()) {
                const skipDirs = ['node_modules', '.git', 'dist', 'build', '.next', 'coverage', 'tmp'];
                if (!skipDirs.includes(item.name)) {
                  results.push(...findPRDFiles(fullPath, baseDir));
                }
              } else if (item.isFile() && item.name.endsWith('_prd.md')) {
                try {
                  const content = fs.readFileSync(fullPath, 'utf-8');
                  const stats = fs.statSync(fullPath);
                  const relativePath = path.relative(baseDir, fullPath);
                  const projectPath = path.dirname(relativePath);
                  
                  results.push({
                    name: item.name.replace('_prd.md', ''),
                    filename: item.name,
                    fullPath: fullPath,
                    projectPath: projectPath === '.' ? 'root' : projectPath,
                    size: stats.size,
                    created: stats.birthtime,
                    modified: stats.mtime,
                    preview: content.substring(0, 200)
                  });
                } catch (err) {
                  console.error(`Error reading PRD file ${fullPath}:`, err);
                }
              }
            }
          } catch (err) {
            console.error(`Error scanning directory ${dir}:`, err);
          }
          
          return results;
        };
        
        // Scanner depuis le répertoire home de l'utilisateur
        const scanRoot = '~';
        const prdFiles = findPRDFiles(scanRoot);
        
        // Trier par date de modification (plus récent en premier)
        prdFiles.sort((a, b) => new Date(b.modified).getTime() - new Date(a.modified).getTime());
        
        return Response.json({ prds: prdFiles }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // GET specific PRD content
    if (url.pathname.match(/^\/api\/prds\/(.+)$/) && req.method === "GET") {
      try {
        const filename = url.pathname.split('/').pop();
        const filepath = path.join(process.cwd(), 'prds', filename);
        
        if (!fs.existsSync(filepath)) {
          return Response.json({ error: "PRD not found" }, { status: 404, headers });
        }
        
        const content = fs.readFileSync(filepath, 'utf-8');
        return Response.json({ 
          name: filename.replace('_prd.md', ''),
          content 
        }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST save new PRD
    if (url.pathname === "/api/prds" && req.method === "POST") {
      try {
        const { name, content } = await req.json();
        
        if (!name || !content) {
          return Response.json({ error: "Name and content required" }, { status: 400, headers });
        }
        
        const filename = `${name}_prd.md`;
        const filepath = path.join(process.cwd(), 'prds', filename);
        
        fs.writeFileSync(filepath, content);
        
        return Response.json({ 
          success: true,
          filename,
          message: `PRD saved as ${filename}` 
        }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // DELETE specific PRD
    if (url.pathname.match(/^\/api\/prds\/(.+)$/) && req.method === "DELETE") {
      try {
        const filename = url.pathname.split('/').pop();
        const filepath = path.join(process.cwd(), 'prds', filename);

        if (!fs.existsSync(filepath)) {
          return Response.json({ error: "PRD not found" }, { status: 404, headers });
        }

        fs.unlinkSync(filepath);

        return Response.json({
          success: true,
          message: `PRD ${filename} deleted`
        }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST attach PRD to project
    if (url.pathname.match(/^\/api\/projects\/(\d+)\/attach-prd$/) && req.method === "POST") {
      try {
        const projectId = parseInt(url.pathname.split('/')[3]);
        const { prd_name, prd_content } = await req.json();

        if (!prd_name || !prd_content) {
          return Response.json({ error: "PRD name and content required" }, { status: 400, headers });
        }

        // Update project with PRD content
        const result = db.query("UPDATE projects SET prd = ? WHERE id = ?").run(prd_content, projectId);

        if (result.changes === 0) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        // Broadcast WebSocket update
        broadcastMessage({
          type: 'project_updated',
          project_id: projectId,
          prd_attached: prd_name
        });

        return Response.json({
          success: true,
          message: `PRD ${prd_name} attached to project ${projectId}`
        }, { headers });
      } catch (error) {
        console.error("Error attaching PRD:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // ===== MCP API for Nestor =====

    // POST create task via MCP (for Nestor)
    if (url.pathname === "/api/mcp/tasks" && req.method === "POST") {
      try {
        const {
          title,
          description,
          project_id,
          assigned_to,
          priority = 'medium',
          estimated_hours,
          tags,
          checkboxes = []
        } = await req.json();

        if (!title || !project_id || !assigned_to) {
          return Response.json({
            error: "Title, project_id, and assigned_to are required"
          }, { status: 400, headers });
        }

        // Insert task
        const taskResult = db.query(`
          INSERT INTO tasks (title, description, project_id, assigned_to, priority, estimated_hours, tags)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `).run(title, description, project_id, assigned_to, priority, estimated_hours, tags || '');

        const taskId = taskResult.lastInsertRowid;

        // Insert checkboxes
        if (checkboxes.length > 0) {
          const checkboxInsert = db.query(`
            INSERT INTO checkboxes (task_id, label, required)
            VALUES (?, ?, ?)
          `);

          for (const checkbox of checkboxes) {
            checkboxInsert.run(taskId, checkbox.label, checkbox.required || true);
          }
        }

        // Default checkboxes if none provided
        if (checkboxes.length === 0) {
          const defaultCheckboxes = [
            { label: "Code/Implementation complete", required: true },
            { label: "Screenshot taken", required: true },
            { label: "Build successful", required: true },
            { label: "Visual validation passed (3+ languages)", required: true },
            { label: "Documentation updated", required: true }
          ];

          const checkboxInsert = db.query(`
            INSERT INTO checkboxes (task_id, label, required)
            VALUES (?, ?, ?)
          `);

          for (const checkbox of defaultCheckboxes) {
            checkboxInsert.run(taskId, checkbox.label, checkbox.required);
          }
        }

        // Broadcast WebSocket update
        broadcastMessage({
          type: 'task_created',
          task_id: taskId,
          project_id,
          assigned_to,
          created_by: 'nestor_mcp'
        });

        return Response.json({
          success: true,
          task_id: taskId,
          message: `Task "${title}" created and assigned to ${assigned_to}`
        }, { headers });

      } catch (error) {
        console.error("Error creating task via MCP:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET project PRD via MCP (for Nestor)
    if (url.pathname.match(/^\/api\/mcp\/projects\/(\d+)\/prd$/) && req.method === "GET") {
      try {
        const projectId = parseInt(url.pathname.split('/')[4]);
        const project = db.query("SELECT name, prd FROM projects WHERE id = ?").get(projectId);

        if (!project || !project.prd) {
          return Response.json({
            error: "Project not found or no PRD attached"
          }, { status: 404, headers });
        }

        return Response.json({
          project_name: project.name,
          prd_content: project.prd
        }, { headers });

      } catch (error) {
        console.error("Error fetching PRD via MCP:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // ===== Tmux Notification Config Endpoints =====
    
    // GET tmux notification config
    if (url.pathname === "/api/tmux-config" && req.method === "GET") {
      try {
        const configPath = path.join(process.cwd(), 'tmux-notification-config.json');
        if (fs.existsSync(configPath)) {
          const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
          return Response.json(config, { headers });
        } else {
          // Return default config if file doesn't exist
          return Response.json({
            notification_template: {
              header: "🔔 NOTIFICATION SYSTÈME",
              separator: "━━━━━━━━━━━━━━━━━━━━",
              rules: [
                "📖 LIRE TON CLAUDE.md EN PREMIER",
                "🎯 FOCUS: Une tâche à la fois",
                "✅ TERMINÉ = STOP (pas de confirmation)",
                "🚫 PAS DE BOUCLES RE:RE:RE:"
              ],
              email_format: {
                from: "📧 Nouveau mail de {sender}",
                subject: "📬 Sujet: {subject}"
              },
              commands: {
                read: "📖 LIRE: curl http://localhost:1080/api/mailbox/{recipient}",
                reply: "✉️ RÉPONDRE: ./send-mail.sh destinataire@moulinsart.local \"Sujet\" \"Message\""
              }
            },
            send_reminder: false,
            reminder_delay: 3,
            clear_before_send: true
          }, { headers });
        }
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST save tmux notification config
    if (url.pathname === "/api/tmux-config" && req.method === "POST") {
      try {
        const config = await req.json();
        const configPath = path.join(process.cwd(), 'tmux-notification-config.json');
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
        return Response.json({ success: true, message: "Configuration saved" }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }
    
    // POST restart mail server
    if (url.pathname === "/api/restart-mail-server" && req.method === "POST") {
      try {
        const { exec } = require('child_process');
        exec('pkill -f "bun.*mail-server" && sleep 1 && bun run server/mail-server.ts &', (error: any) => {
          if (error) {
            console.error('Error restarting mail server:', error);
          } else {
            console.log('Mail server restarted');
          }
        });
        return Response.json({ success: true, message: "Mail server restart initiated" }, { headers });
      } catch (error) {
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST start orbite du silence
    if (url.pathname === "/api/start-orbite-silence" && req.method === "POST") {
      try {
        const { spawn } = require('child_process');

        // Démarrer inactivity-trigger.sh en arrière-plan
        const orbiteProcess = spawn('bash', ['./inactivity-trigger.sh'], {
          cwd: '~/moulinsart/oracle-observability',
          detached: true,
          stdio: ['ignore', 'pipe', 'pipe']
        });

        // Écrire le PID dans un fichier pour pouvoir l'arrêter plus tard
        const fs = require('fs');
        fs.writeFileSync('/tmp/orbite-silence.pid', orbiteProcess.pid.toString());

        console.log(`🌌 Orbite du Silence démarrée (PID: ${orbiteProcess.pid})`);

        return Response.json({
          success: true,
          message: "Trigger Inactivité activé",
          pid: orbiteProcess.pid
        }, { headers });
      } catch (error) {
        console.error('Erreur démarrage Orbite du Silence:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST start trigger moulinsart
    if (url.pathname === "/api/start-trigger-moulinsart" && req.method === "POST") {
      try {
        const { spawn } = require('child_process');

        // Démarrer inactivity-trigger-moulinsart.sh en arrière-plan
        const triggerProcess = spawn('bash', ['./inactivity-trigger-moulinsart.sh'], {
          cwd: '~/moulinsart/oracle-observability',
          detached: true,
          stdio: ['ignore', 'pipe', 'pipe']
        });

        // Écrire le PID dans un fichier pour pouvoir l'arrêter plus tard
        const fs = require('fs');
        fs.writeFileSync('/tmp/trigger-moulinsart.pid', triggerProcess.pid.toString());

        console.log(`🎩 Trigger Moulinsart démarré (PID: ${triggerProcess.pid})`);

        return Response.json({
          success: true,
          message: "Trigger Moulinsart activé",
          pid: triggerProcess.pid
        }, { headers });
      } catch (error) {
        console.error('Erreur démarrage Trigger Moulinsart:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST stop trigger moulinsart
    if (url.pathname === "/api/stop-trigger-moulinsart" && req.method === "POST") {
      try {
        const fs = require('fs');
        const { exec } = require('child_process');

        // Lire le PID et tuer le processus
        if (fs.existsSync('/tmp/trigger-moulinsart.pid')) {
          const pid = fs.readFileSync('/tmp/trigger-moulinsart.pid', 'utf8').trim();

          exec(`kill ${pid}`, (error: any) => {
            if (error) {
              console.error('Erreur arrêt Trigger Moulinsart:', error);
            } else {
              console.log(`🎩 Trigger Moulinsart arrêté (PID: ${pid})`);
            }
          });

          // Supprimer le fichier PID
          fs.unlinkSync('/tmp/trigger-moulinsart.pid');
        }

        return Response.json({
          success: true,
          message: "Trigger Moulinsart arrêté"
        }, { headers });
      } catch (error) {
        console.error('Erreur arrêt Trigger Moulinsart:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST stop orbite du silence
    if (url.pathname === "/api/stop-orbite-silence" && req.method === "POST") {
      try {
        const fs = require('fs');
        const { exec } = require('child_process');

        // Lire le PID et tuer le processus
        if (fs.existsSync('/tmp/orbite-silence.pid')) {
          const pid = fs.readFileSync('/tmp/orbite-silence.pid', 'utf8').trim();

          exec(`kill ${pid}`, (error: any) => {
            if (error) {
              console.error('Erreur arrêt Orbite du Silence:', error);
            } else {
              console.log(`🌌 Orbite du Silence arrêtée (PID: ${pid})`);
            }
          });

          // Supprimer le fichier PID
          fs.unlinkSync('/tmp/orbite-silence.pid');
        }

        return Response.json({
          success: true,
          message: "Trigger Inactivité arrêté"
        }, { headers });
      } catch (error) {
        console.error('Erreur arrêt Orbite du Silence:', error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // ================== MEMORY & ARCHIVE ENDPOINTS ==================

    // POST generate memory for sprint
    if (url.pathname === "/api/memory/generate" && req.method === "POST") {
      try {
        const { project_id, sprint } = await req.json();

        if (!project_id || !sprint) {
          return Response.json({ error: "project_id and sprint required" }, { status: 400, headers });
        }

        // Validate sprint format
        if (!validateSprint(sprint)) {
          return Response.json({ error: "Invalid sprint format. Expected: 'Sprint N'" }, { status: 400, headers });
        }

        console.log(`🧠 Génération mémoire: project_id=${project_id}, sprint=${sprint}`);

        // 1. Récupérer projet
        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        // 2. Récupérer tâches du sprint
        const tasks = db.query("SELECT * FROM tasks WHERE project_id = ? AND sprint = ?").all(project_id, sprint);

        // 3. Handle empty tasks case - generate empty but explicit artifact
        if (tasks.length === 0) {
          const emptyMemory = {
            project_id,
            sprint,
            time_range: { start: null, end: new Date().toISOString() },
            summary: {
              goals: [`Aucune tâche trouvée pour ${sprint}`],
              decisions: [],
              done_tasks: [],
              issues: ["Sprint vide - aucune tâche définie"],
              risks: [],
              dod: { all_done: false, checks: [] }
            },
            ground_truth: {
              ports: { oracle: 3001, mail: 1080, vue_client: 5175 },
              paths: ["~/moulinsart/oracle-observability/data/oracle.db"],
              rules: [`project_id=${project_id} obligatoire`, "status ∈ {TODO,IN_PROGRESS,DONE}", "sprint format: 'Sprint N'"],
              configs: { oracle_db: { mode: "WAL" }, project_name: project.name }
            },
            journal: `${new Date().toISOString()} → Sprint ${sprint} créé sans tâches`,
            artifacts: { files: [], exports: [] }
          };

          console.log(`⚠️ Mémoire générée pour sprint vide: ${sprint}`);
          return Response.json(emptyMemory, { headers });
        }

        // 4. Séparer tâches par status
        const doneTasks = tasks.filter(t => t.status === 'DONE');
        const todoTasks = tasks.filter(t => t.status === 'TODO');
        const inProgressTasks = tasks.filter(t => t.status === 'IN_PROGRESS');

        // 5. Construire les 3 couches
        const timeRange = {
          start: tasks.reduce((earliest, t) => t.created_at < earliest ? t.created_at : earliest, tasks[0].created_at),
          end: new Date().toISOString()
        };

        // Layer 1 - Journal brut condensé
        const journalEntries = [];
        tasks.forEach(task => {
          journalEntries.push(`${task.created_at} → Tâche créée #${task.id}: ${task.title} (${task.assigned_to})`);
          if (task.status === 'DONE') {
            journalEntries.push(`${task.updated_at} → Tâche terminée #${task.id}: ${task.title}`);
          }
        });

        // Layer 2 - Résumé structuré
        const summary = {
          goals: [`Compléter ${sprint} avec ${tasks.length} tâches`],
          decisions: ["Utilisation project_id = " + project_id + " obligatoire", "Sprint organisé par équipes agents"],
          done_tasks: doneTasks.map(t => ({ id: t.id, title: t.title })),
          issues: todoTasks.length > 0 ? [`${todoTasks.length} tâches restent en TODO`] : [],
          risks: inProgressTasks.length > 0 ? [`${inProgressTasks.length} tâches en cours risquent retard`] : [],
          dod: {
            all_done: todoTasks.length === 0 && inProgressTasks.length === 0,
            checks: [
              { name: "Toutes tâches terminées", ok: doneTasks.length === tasks.length },
              { name: "Pas de blockers", ok: true }
            ]
          }
        };

        // Layer 3 - Vérité opérationnelle
        const groundTruth = {
          ports: { oracle: 3001, mail: 1080, vue_client: 5175 },
          paths: [
            "~/moulinsart/oracle-observability/data/oracle.db",
            "~/moulinsart/projects/" + project.name.toLowerCase().replace(/[^a-z0-9\-_]/g, '_')
          ],
          rules: [
            "project_id=" + project_id + " obligatoire",
            "status ∈ {TODO,IN_PROGRESS,DONE}",
            "sprint format: 'Sprint N'",
            "agents: nestor,tintin,dupont1,dupont2,haddock,rastapopoulos,tournesol1,tournesol2"
          ],
          configs: {
            "oracle.db": { "mode": "WAL", "sqlite_version": "3.x" },
            "project_name": project.name
          }
        };

        const memoryData = {
          project_id,
          sprint,
          time_range: timeRange,
          summary,
          ground_truth: groundTruth,
          journal: journalEntries.join('\n'),
          artifacts: {
            files: [],
            exports: []
          }
        };

        // Log event Oracle
        db.run(`
          INSERT INTO events (type, source, data, project, agent)
          VALUES (?, ?, ?, ?, ?)
        `, 'memory_event', 'oracle', JSON.stringify({
          kind: "generate",
          status: "ok",
          project_id,
          sprint,
          tasks_count: tasks.length,
          message: `Memoire generee: ${doneTasks.length}/${tasks.length} taches terminees`
        }), project.name, 'oracle');

        console.log(`✅ Mémoire générée: ${doneTasks.length}/${tasks.length} tâches terminées`);

        return Response.json(memoryData, { headers });
      } catch (error) {
        console.error("Error generating memory:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST write PROJECT_MEMORY.md
    if (url.pathname === "/api/memory/write-project" && req.method === "POST") {
      try {
        const reqBody = await req.json();
        const { project_id, sprint } = reqBody;
        const data = reqBody.data || reqBody;

        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        // Créer le dossier projet si nécessaire
        const projectSlug = project.name.replace(/[^a-zA-Z0-9\-_]/g, '_').toLowerCase();
        const projectDir = join(PATHS.PROJECTS, projectSlug);
        const memoryFile = join(projectDir, "PROJECT_MEMORY.md");

        if (!fs.existsSync(projectDir)) {
          fs.mkdirSync(projectDir, { recursive: true });
        }

        // Contenu Markdown (ASCII-only + ISO date)
        const content = `
## ${sanitizeToASCII(sprint)} - ${toISODate()}

### Objectifs
${data.summary.goals.map(g => `- ${sanitizeToASCII(g)}`).join('\n')}

### Taches Terminees
${data.summary.done_tasks.map(t => `- #${t.id}: ${sanitizeToASCII(t.title)}`).join('\n')}

### Problemes Identifies
${data.summary.issues.map(i => `- ${sanitizeToASCII(i)}`).join('\n')}

### Verite Operationnelle
- **Ports**: ${Object.entries(data.ground_truth.ports).map(([k,v]) => `${k}:${v}`).join(', ')}
- **Regles**: ${data.ground_truth.rules.map(r => `"${sanitizeToASCII(r)}"`).join(', ')}

### Journal Condense
\`\`\`
${sanitizeToASCII(data.journal)}
\`\`\`

---
`;

        // Vérifier dé-duplication avant append
        if (fs.existsSync(memoryFile)) {
          const existingContent = fs.readFileSync(memoryFile, 'utf8');
          const sprintMarker = `## ${sanitizeToASCII(sprint)} -`;

          if (existingContent.includes(sprintMarker)) {
            return Response.json({
              success: false,
              error: "Sprint section already exists",
              already_exists: true,
              message: `Section ${sprint} déjà présente dans PROJECT_MEMORY.md`
            }, { headers });
          }

          fs.appendFileSync(memoryFile, content);
        } else {
          const header = `# PROJECT MEMORY - ${sanitizeToASCII(project.name)}\n\n`;
          fs.writeFileSync(memoryFile, header + content);
        }

        // Écrire aussi le JSON snapshot (ASCII-only)
        const jsonFile = join(projectDir, "PROJECT_MEMORY.json");
        const sanitizedData = JSON.parse(JSON.stringify(data, (key, value) =>
          typeof value === 'string' ? sanitizeToASCII(value) : value
        ));
        fs.writeFileSync(jsonFile, JSON.stringify(sanitizedData, null, 2));

        console.log(`📝 PROJECT_MEMORY.md écrit: ${memoryFile}`);
        console.log(`💾 PROJECT_MEMORY.json écrit: ${jsonFile}`);

        return Response.json({
          success: true,
          file: memoryFile,
          json_file: jsonFile,
          message: "PROJECT_MEMORY.md et JSON mis à jour"
        }, { headers });
      } catch (error) {
        console.error("Error writing project memory:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET read PROJECT_MEMORY.json
    if (url.pathname === "/api/memory/read-project" && req.method === "GET") {
      try {
        const url_params = new URL(req.url).searchParams;
        const project_id = url_params.get('project_id');
        const sprint = url_params.get('sprint');

        if (!project_id || !sprint) {
          return Response.json({ error: "project_id and sprint required" }, { status: 400, headers });
        }

        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        // Chemin vers le fichier PROJECT_MEMORY.json
        const projectSlug = project.name.replace(/[^a-zA-Z0-9\-_]/g, '_').toLowerCase();
        const projectDir = join(PATHS.PROJECTS, projectSlug);
        const jsonFile = join(projectDir, "PROJECT_MEMORY.json");

        if (!fs.existsSync(jsonFile)) {
          return Response.json({ error: "PROJECT_MEMORY.json not found" }, { status: 404, headers });
        }

        // Lire et retourner le contenu JSON
        const content = fs.readFileSync(jsonFile, 'utf8');
        const data = JSON.parse(content);

        console.log(`📖 PROJECT_MEMORY.json lu: ${jsonFile}`);

        return Response.json(data, { headers });
      } catch (error) {
        console.error("Error reading project memory:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST write CLAUDE_MEMORY.md for agents
    if (url.pathname === "/api/memory/write-agents" && req.method === "POST") {
      try {
        const reqBody = await req.json();
        const { project_id, sprint } = reqBody;
        const data = reqBody.data || reqBody;

        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        const tasks = db.query("SELECT * FROM tasks WHERE project_id = ? AND sprint = ?").all(project_id, sprint);

        // Agents avec tâches assignées pour ce sprint
        const assignedAgents = [...new Set(tasks.map(t => t.assigned_to).filter(Boolean))];

        // Agents principaux de l'équipe TMUX (toujours inclure)
        const coreAgents = ['haddock', 'rastapopoulos', 'tournesol1', 'tournesol2'];

        // Union des agents assignés + agents principaux
        const involvedAgents = [...new Set([...assignedAgents, ...coreAgents])];

        const filesWritten = [];

        for (const agent of involvedAgents) {
          const agentDir = join(PATHS.AGENTS, agent);
          const memoryFile = join(agentDir, "CLAUDE.md");

          if (!fs.existsSync(agentDir)) {
            console.log(`⚠️ Agent directory not found: ${agentDir}`);
            continue;
          }

          const agentTasks = tasks.filter(t => t.assigned_to === agent);
          const taskSection = agentTasks.length > 0
            ? agentTasks.map(t => `- #${t.id}: ${t.title} (${t.status})`).join('\n')
            : `- Aucune tâche assignée pour ${sprint} (rôle de coordination/supervision)`;

          const content = `
## ${sprint} - ${project.name}

### Mes Tâches
${taskSection}

### Règles Importantes
${data.ground_truth.rules.map(r => `- ${r}`).join('\n')}

---
`;

          // Toujours append - CLAUDE.md existe déjà avec les instructions de base
          fs.appendFileSync(memoryFile, content);

          filesWritten.push(`${agent}/CLAUDE.md`);
        }

        console.log(`🤖 CLAUDE.md mis à jour: ${filesWritten.join(', ')}`);

        return Response.json({
          success: true,
          files: filesWritten,
          message: `${filesWritten.length} fichiers CLAUDE.md mis à jour`
        }, { headers });
      } catch (error) {
        console.error("Error writing agent memories:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST export ZIP
    if (url.pathname === "/api/memory/export-zip" && req.method === "POST") {
      try {
        const reqBody = await req.json();
        const { project_id, sprint } = reqBody;
        const data = reqBody.data || reqBody;

        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        const projectSlug = project.name.replace(/[^a-zA-Z0-9\-_]/g, '_').toLowerCase();
        const exportDir = PATHS.EXPORTS;
        const zipName = `${projectSlug}_${sprint.replace(' ', '')}_memory.zip`;
        const zipPath = join(exportDir, zipName);

        if (!fs.existsSync(exportDir)) {
          fs.mkdirSync(exportDir, { recursive: true });
        }

        // Créer fichiers temporaires
        const tempDir = `/tmp/memory_export_${Date.now()}`;
        fs.mkdirSync(tempDir, { recursive: true });

        // Écrire JSON
        fs.writeFileSync(`${tempDir}/memory.json`, JSON.stringify(data, null, 2));

        // Écrire Markdown
        const mdContent = `# ${sprint} Memory - ${project.name}

## Summary
**Goals:** ${data.summary.goals.join(', ')}
**Done Tasks:** ${data.summary.done_tasks.length}
**Issues:** ${data.summary.issues.join(', ')}

## Ground Truth
**Ports:** ${Object.entries(data.ground_truth.ports).map(([k,v]) => `${k}:${v}`).join(', ')}
**Rules:** ${data.ground_truth.rules.join(', ')}

## Journal
\`\`\`
${data.journal}
\`\`\`
`;
        fs.writeFileSync(`${tempDir}/memory.md`, mdContent);

        // Créer ZIP (simulation - dans un vrai projet, utiliser une lib comme archiver)
        const { exec } = require('child_process');
        await new Promise((resolve, reject) => {
          exec(`cd ${tempDir} && zip -r ${zipPath} .`, (error: any) => {
            if (error) reject(error);
            else resolve(true);
          });
        });

        // Nettoyage
        fs.rmSync(tempDir, { recursive: true, force: true });

        console.log(`📦 ZIP exporté: ${zipPath}`);

        // Retourner le fichier
        const zipContent = fs.readFileSync(zipPath);
        return new Response(zipContent, {
          headers: {
            ...headers,
            'Content-Type': 'application/zip',
            'Content-Disposition': `attachment; filename="${zipName}"`
          }
        });
      } catch (error) {
        console.error("Error exporting ZIP:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST purge emails for sprint
    if (url.pathname === "/api/memory/purge-mails" && req.method === "POST") {
      try {
        const { project_id, sprint } = await req.json();

        if (!project_id || !sprint) {
          return Response.json({ error: "project_id and sprint required" }, { status: 400, headers });
        }

        const project = db.query("SELECT * FROM projects WHERE id = ?").get(project_id);
        if (!project) {
          return Response.json({ error: "Project not found" }, { status: 404, headers });
        }

        // Purger emails contenant le nom du sprint dans subject ou body
        // Extraction du numéro de sprint pour recherche flexible
        const sprintNumber = sprint.match(/Sprint\s*(\d+)/i)?.[1];

        let result;
        if (sprintNumber) {
          // Purger emails mentionnant ce sprint spécifique
          result = db.query(`
            UPDATE emails
            SET deleted = 1
            WHERE deleted = 0
            AND (
              subject LIKE ? OR
              subject LIKE ? OR
              body LIKE ? OR
              body LIKE ?
            )
          `).run(
            `%Sprint ${sprintNumber}%`,
            `%Sprint%${sprintNumber}%`,
            `%Sprint ${sprintNumber}%`,
            `%Sprint%${sprintNumber}%`
          );
        } else {
          // Fallback: purger par période si format sprint invalide
          const tasks = db.query("SELECT MIN(created_at) as start, MAX(updated_at) as end FROM tasks WHERE project_id = ? AND sprint = ?").get(project_id, sprint);

          if (!tasks.start) {
            return Response.json({
              success: true,
              emails_purged: 0,
              message: "No tasks found for sprint and invalid sprint format - no emails to purge"
            }, { headers });
          }

          result = db.query(`
            UPDATE emails
            SET deleted = 1
            WHERE timestamp >= ? AND timestamp <= ?
          `).run(tasks.start, tasks.end);
        }

        console.log(`🗑️ ${result.changes} emails purgés pour ${sprint}`);

        // Log event
        db.run(`
          INSERT INTO events (type, source, data, project, agent)
          VALUES (?, ?, ?, ?, ?)
        `, 'memory_purge', 'oracle', JSON.stringify({ project_id, sprint, emails_purged: result.changes }), project.name, 'oracle');

        return Response.json({
          success: true,
          emails_purged: result.changes,
          message: `${result.changes} emails purgés pour ${sprint}`
        }, { headers });
      } catch (error) {
        console.error("Error purging emails:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST heartbeat to all agents
    if (url.pathname === "/api/agents/heartbeat" && req.method === "POST") {
      try {
        const { project_id = 22, sprint = "Sprint 7" } = await req.json();
        const timestamp = new Date().toISOString();

        // Setup nodemailer for Mailhog
        const transporter = nodemailer.createTransport({
          host: "localhost",
          port: 1025,
          secure: false
        });

        // Liste des agents
        const agents = ["nestor", "tintin", "dupont1", "dupont2", "haddock", "rastapopoulos", "tournesol1", "tournesol2"];

        // Envoyer heartbeat à tous les agents
        const promises = agents.map(agent =>
          transporter.sendMail({
            from: "oracle@moulinsart.local",
            to: `${agent}@moulinsart.local`,
            subject: `[HEARTBEAT] ${project_id}/${sprint} ${timestamp}`,
            text: `Heartbeat system check for project ${project_id}, sprint ${sprint}\nTimestamp: ${timestamp}\nOracle operational.`
          })
        );

        await Promise.all(promises);

        // Log event
        db.run(`
          INSERT INTO events (type, source, data, project, agent)
          VALUES (?, ?, ?, ?, ?)
        `, "memory_event", "oracle", JSON.stringify({
          kind: "heartbeat_all",
          status: "ok",
          project_id,
          sprint,
          timestamp,
          agents_count: agents.length
        }), project_id.toString(), "oracle");

        console.log(`💓 Heartbeat envoyé à ${agents.length} agents pour ${project_id}/${sprint}`);

        return Response.json({
          success: true,
          agents_count: agents.length,
          agents,
          timestamp,
          message: "Heartbeat envoyé à tous les agents"
        }, { headers });

      } catch (error) {
        console.error("Error sending heartbeat:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET emails proxy for timeline (Mailhog integration)
    if (url.pathname === "/api/memory/emails" && req.method === "GET") {
      try {
        const searchParams = new URL(req.url).searchParams;
        const project_id = parseInt(searchParams.get("project_id") || "22");
        const sprint = searchParams.get("sprint") || "Sprint 7";

        // Récupérer fenêtre temporelle du sprint
        const tasks = db.query("SELECT MIN(created_at) as start, MAX(updated_at) as end FROM tasks WHERE project_id = ? AND sprint = ?").get(project_id, sprint);

        if (!tasks.start) {
          return Response.json({ emails: [] }, { headers });
        }

        // Appeler Mailhog API
        try {
          const mailhogResponse = await fetch("http://localhost:1080/api/v2/messages?limit=1000");
          const mailhogData = await mailhogResponse.json();

          // Filtrer emails dans l'intervalle de temps
          const sprintStart = new Date(tasks.start);
          const sprintEnd = new Date(tasks.end);

          const filteredEmails = mailhogData.items
            .filter(email => {
              const emailDate = new Date(email.Created);
              return emailDate >= sprintStart && emailDate <= sprintEnd;
            })
            .map(email => ({
              id: email.ID,
              from: email.From?.Mailbox + "@" + email.From?.Domain,
              to: email.To?.map(t => t.Mailbox + "@" + t.Domain).join(", "),
              subject: email.Content?.Headers?.Subject?.[0] || "No Subject",
              created_at: email.Created
            }));

          return Response.json({ emails: filteredEmails }, { headers });
        } catch (mailhogError) {
          console.error("Mailhog API error:", mailhogError);
          return Response.json({ emails: [], error: "Mailhog unavailable" }, { headers });
        }
      } catch (error) {
        console.error("Error fetching emails:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET existing sprints in CLAUDE.md files for Mode Full
    if (url.pathname === "/api/memory/existing-sprints" && req.method === "GET") {
      try {
        const searchParams = new URL(req.url).searchParams;
        const project_id = searchParams.get("project_id");

        if (!project_id) {
          return Response.json({ error: "project_id required" }, { status: 400, headers });
        }

        const agents = ["nestor", "tintin", "dupont1", "dupont2", "haddock", "rastapopoulos", "tournesol1", "tournesol2"];
        const existingSprints = new Set<string>();

        // Parser chaque fichier CLAUDE.md des agents
        for (const agent of agents) {
          const claudePath = join(PATHS.AGENTS, agent, "CLAUDE.md");
          try {
            if (fs.existsSync(claudePath)) {
              const content = fs.readFileSync(claudePath, "utf-8");

              // Détecter les sections sprint: ## Sprint N - nom
              const sprintMatches = content.match(/^## Sprint (\d+)/gm);
              if (sprintMatches) {
                sprintMatches.forEach(match => {
                  const sprintNumber = match.match(/Sprint (\d+)/)?.[1];
                  if (sprintNumber) {
                    existingSprints.add(sprintNumber);
                  }
                });
              }
            }
          } catch (fileError) {
            console.warn(`Erreur lecture ${claudePath}:`, fileError);
          }
        }

        // Convertir en tableau trié numériquement
        const sortedSprints = Array.from(existingSprints)
          .map(Number)
          .sort((a, b) => a - b);

        console.log(`[Mode Full] Sprints détectés pour projet ${project_id}:`, sortedSprints);

        return Response.json({
          project_id: parseInt(project_id),
          existing_sprints: sortedSprints
        }, { headers });

      } catch (error) {
        console.error("Error detecting existing sprints:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // ===========================================
    // BRIEFING CONSOLE APIs
    // ===========================================

    // GET instructions for an agent
    if (url.pathname === "/api/briefing/instructions" && req.method === "GET") {
      try {
        const searchParams = new URL(req.url).searchParams;
        const agent = searchParams.get("agent");
        const team = searchParams.get("team");

        if (!agent || !team) {
          return Response.json({ error: "agent and team required" }, { status: 400, headers });
        }

        const instructionsPath = join(PATHS.MOULINSART_ROOT, "instructions-equipes-tmux", team, agent);

        if (fs.existsSync(instructionsPath)) {
          const content = fs.readFileSync(instructionsPath, "utf-8");
          return Response.json({ content }, { headers });
        } else {
          return Response.json({ content: "" }, { headers });
        }

      } catch (error) {
        console.error("Error loading instructions:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST save instructions for an agent
    if (url.pathname === "/api/briefing/save-instructions" && req.method === "POST") {
      try {
        const { agent, team, content } = await req.json();

        if (!agent || !team) {
          return Response.json({ error: "agent and team required" }, { status: 400, headers });
        }

        const instructionsPath = join(PATHS.MOULINSART_ROOT, "instructions-equipes-tmux", team, agent);

        // Créer le répertoire si nécessaire
        const dir = path.dirname(instructionsPath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }

        fs.writeFileSync(instructionsPath, content || "", "utf-8");

        console.log(`Instructions sauvegardées pour ${agent} (${team})`);
        return Response.json({ success: true }, { headers });

      } catch (error) {
        console.error("Error saving instructions:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST execute briefing script
    if (url.pathname === "/api/briefing/execute" && req.method === "POST") {
      try {
        const { agent, project_id } = await req.json();

        if (!agent) {
          return Response.json({ error: "agent required" }, { status: 400, headers });
        }

        const scriptPath = join(PATHS.MOULINSART_ROOT, "instructions-equipes-tmux", "reset-briefing.sh");

        if (!fs.existsSync(scriptPath)) {
          return Response.json({ error: "Script de briefing introuvable" }, { status: 404, headers });
        }

        // Exécuter le script
        const { spawn } = require("child_process");
        const process = spawn("bash", [scriptPath, agent], {
          cwd: join(PATHS.MOULINSART_ROOT, "instructions-equipes-tmux")
        });

        let output = "";
        let error = "";

        process.stdout.on('data', (data) => {
          output += data.toString();
        });

        process.stderr.on('data', (data) => {
          error += data.toString();
        });

        await new Promise((resolve) => {
          process.on('close', resolve);
        });

        console.log(`Briefing exécuté pour ${agent}: ${output}`);

        return Response.json({
          success: true,
          output: output || "Briefing exécuté",
          error: error || null
        }, { headers });

      } catch (error) {
        console.error("Error executing briefing:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST save version with comment
    if (url.pathname === "/api/briefing/save-version" && req.method === "POST") {
      try {
        const { project_id, agent, comment, instructions } = await req.json();

        if (!project_id || !agent) {
          return Response.json({ error: "project_id and agent required" }, { status: 400, headers });
        }

        // Créer table briefing_versions si elle n'existe pas
        db.run(`
          CREATE TABLE IF NOT EXISTS briefing_versions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            agent TEXT NOT NULL,
            comment TEXT,
            instructions TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            is_current INTEGER DEFAULT 0
          )
        `);

        // Marquer toutes les versions existantes comme non-courantes
        db.run("UPDATE briefing_versions SET is_current = 0 WHERE project_id = ? AND agent = ?",
               project_id, agent);

        // Insérer la nouvelle version
        const insert = db.query(`
          INSERT INTO briefing_versions (project_id, agent, comment, instructions, is_current)
          VALUES (?, ?, ?, ?, 1)
        `);

        const result = insert.run(project_id, agent, comment || "", instructions || "");

        console.log(`Version sauvegardée pour ${agent} (projet ${project_id}): ${comment}`);

        return Response.json({
          success: true,
          version_id: result.lastInsertRowid
        }, { headers });

      } catch (error) {
        console.error("Error saving version:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // GET briefing history for an agent
    if (url.pathname === "/api/briefing/history" && req.method === "GET") {
      try {
        const searchParams = new URL(req.url).searchParams;
        const project_id = searchParams.get("project_id");
        const agent = searchParams.get("agent");

        if (!project_id || !agent) {
          return Response.json({ error: "project_id and agent required" }, { status: 400, headers });
        }

        const versions = db.query(`
          SELECT id, project_id, agent, comment, instructions, created_at, is_current
          FROM briefing_versions
          WHERE project_id = ? AND agent = ?
          ORDER BY created_at DESC
        `).all(project_id, agent);

        return Response.json(versions.map(v => ({
          ...v,
          current: Boolean(v.is_current)
        })), { headers });

      } catch (error) {
        console.error("Error loading briefing history:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST restore version
    if (url.pathname === "/api/briefing/restore-version" && req.method === "POST") {
      try {
        const { version_id, agent } = await req.json();

        if (!version_id || !agent) {
          return Response.json({ error: "version_id and agent required" }, { status: 400, headers });
        }

        // Récupérer la version
        const version = db.query(`
          SELECT * FROM briefing_versions WHERE id = ?
        `).get(version_id);

        if (!version) {
          return Response.json({ error: "Version introuvable" }, { status: 404, headers });
        }

        // Déterminer l'équipe
        const team = ["nestor", "tintin", "dupont1", "dupont2"].includes(agent) ? "nestor-equipe" : "haddock-equipe";

        // Sauvegarder les instructions
        const instructionsPath = join(PATHS.MOULINSART_ROOT, "instructions-equipes-tmux", team, agent);
        const dir = path.dirname(instructionsPath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }

        fs.writeFileSync(instructionsPath, version.instructions || "", "utf-8");

        // Marquer cette version comme courante
        db.run("UPDATE briefing_versions SET is_current = 0 WHERE project_id = ? AND agent = ?",
               version.project_id, agent);
        db.run("UPDATE briefing_versions SET is_current = 1 WHERE id = ?", version_id);

        console.log(`Version restaurée pour ${agent}: ${version.created_at}`);

        return Response.json({ success: true }, { headers });

      } catch (error) {
        console.error("Error restoring version:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // DELETE version
    if (url.pathname.startsWith("/api/briefing/delete-version/") && req.method === "DELETE") {
      try {
        const version_id = url.pathname.split("/").pop();

        if (!version_id) {
          return Response.json({ error: "version_id required" }, { status: 400, headers });
        }

        const result = db.query("DELETE FROM briefing_versions WHERE id = ?").run(version_id);

        if (result.changes === 0) {
          return Response.json({ error: "Version introuvable" }, { status: 404, headers });
        }

        console.log(`Version supprimée: ${version_id}`);
        return Response.json({ success: true }, { headers });

      } catch (error) {
        console.error("Error deleting version:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST purge emails from Oracle database
    if (url.pathname === "/api/purge-emails" && req.method === "POST") {
      try {
        const { emails } = await req.json();

        if (!emails || !Array.isArray(emails)) {
          return Response.json({ error: "emails array required" }, { status: 400, headers });
        }

        console.log(`🗑️ Oracle DB: purge emails pour ${emails.length} adresses`);

        // Purger les emails de la base Oracle
        const placeholders = emails.map(() => '?').join(',');
        const result = db.query(`UPDATE emails SET deleted = 1 WHERE from_address IN (${placeholders}) OR to_address IN (${placeholders})`).run(...emails, ...emails);

        // Log event
        db.run(`
          INSERT INTO events (type, source, data, project, agent)
          VALUES (?, ?, ?, ?, ?)
        `, 'email_purge', 'oracle', JSON.stringify({
          emails_purged: result.changes,
          addresses: emails,
          timestamp: new Date().toISOString()
        }), 'system', 'oracle');

        console.log(`✅ Oracle DB: ${result.changes} emails marqués comme supprimés`);

        return Response.json({
          success: true,
          emails_purged: result.changes,
          addresses: emails
        }, { headers });

      } catch (error) {
        console.error("Error purging emails from Oracle DB:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
    }

    // POST purge commandant emails
    if (url.pathname === "/api/emails/purge-commandant" && req.method === "POST") {
      try {
        const result = db.query(`UPDATE emails SET deleted = 1 WHERE from_address = 'author@moulinsart.local' OR to_address = 'author@moulinsart.local'`).run();

        console.log(`✅ Oracle DB: ${result.changes} emails Commandant marqués comme supprimés`);

        return Response.json({
          success: true,
          emails_purged: result.changes,
          message: "Emails Commandant purgés"
        }, { headers });

      } catch (error) {
        console.error("Error purging commandant emails:", error);
        return Response.json({ error: error.message }, { status: 500, headers });
      }
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