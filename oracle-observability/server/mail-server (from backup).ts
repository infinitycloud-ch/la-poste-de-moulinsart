#!/usr/bin/env bun
/**
 * Serveur Mail Local pour Moulinsart
 * SMTP sur port 1025, stockage persistant avec SQLite
 */

import { createServer } from "net";
import { Database } from "bun:sqlite";
import { join } from "path";

const SMTP_PORT = 1025;
const db = new Database(join(import.meta.dir, "../data/oracle.db"));

// Créer la table emails si elle n'existe pas
db.run(`
  CREATE TABLE IF NOT EXISTS emails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    subject TEXT,
    body TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    read_status INTEGER DEFAULT 0,
    deleted INTEGER DEFAULT 0,
    project_domain TEXT
  )
`);

// Index pour améliorer les performances
db.run(`CREATE INDEX IF NOT EXISTS idx_emails_to ON emails(to_address)`);
db.run(`CREATE INDEX IF NOT EXISTS idx_emails_deleted ON emails(deleted)`);

// Structure pour stocker les emails
interface Email {
  id: number;
  from: string;
  to: string;
  subject: string;
  body: string;
  timestamp: Date;
  attachments?: any[];
}

// Boîtes mail des agents
const mailboxes = new Map<string, Email[]>();
const agents = ['nestor', 'tintin', 'dupont1', 'dupont2'];

// Domaines acceptés (tous les .local)
function isValidDomain(email: string): boolean {
  return email.endsWith('.local');
}

// Extraire le domaine d'une adresse email
function getDomain(email: string): string {
  const parts = email.split('@');
  return parts.length === 2 ? parts[1] : '';
}

// Charger les emails depuis la base au démarrage
function loadEmailsFromDB() {
  const emails = db.query(`
    SELECT id, from_address as 'from', to_address as 'to', subject, body, timestamp
    FROM emails 
    WHERE deleted = 0
    ORDER BY timestamp DESC
  `).all();
  
  // Réinitialiser les boîtes pour tous les domaines
  mailboxes.clear();
  
  // Créer les boîtes de base pour moulinsart.local
  agents.forEach(agent => {
    mailboxes.set(`${agent}@moulinsart.local`, []);
  });
  
  // Charger les emails dans les boîtes appropriées
  emails.forEach((email: any) => {
    // Créer la boîte si elle n'existe pas
    if (!mailboxes.has(email.to)) {
      mailboxes.set(email.to, []);
    }
    
    const mailbox = mailboxes.get(email.to);
    if (mailbox) {
      mailbox.push({
        ...email,
        timestamp: new Date(email.timestamp)
      });
    }
  });
  
  const total = emails.length;
  if (total > 0) {
    console.log(`📂 ${total} email(s) restauré(s) depuis la base de données`);
    
    // Afficher les domaines détectés
    const domains = new Set(emails.map((e: any) => getDomain(e.to)));
    console.log(`🌐 Domaines actifs: ${Array.from(domains).join(', ')}`);
  }
}

// Charger au démarrage
loadEmailsFromDB();

console.log("📧 Moulinsart Mail Server starting...");
console.log("💾 Using SQLite for email persistence");
const emailsInDB = db.query("SELECT COUNT(*) as count FROM emails WHERE deleted = 0").get() as any;
console.log(`📊 Database contains ${emailsInDB?.count || 0} email(s)`);

// Parser SMTP simple
class SMTPSession {
  private from: string = '';
  private to: string[] = [];
  private data: string = '';
  private state: 'INIT' | 'MAIL' | 'RCPT' | 'DATA' | 'BODY' = 'INIT';
  
  handleCommand(command: string): string {
    const cmd = command.trim().toUpperCase();
    
    if (cmd.startsWith('HELO') || cmd.startsWith('EHLO')) {
      this.state = 'MAIL';
      return '250 moulinsart.local Hello';
    }
    
    if (cmd.startsWith('MAIL FROM:')) {
      this.from = this.extractEmail(command);
      this.state = 'RCPT';
      return '250 Ok';
    }
    
    if (cmd.startsWith('RCPT TO:')) {
      const recipient = this.extractEmail(command);
      this.to.push(recipient);
      return '250 Ok';
    }
    
    if (cmd === 'DATA') {
      this.state = 'BODY';
      return '354 End data with <CR><LF>.<CR><LF>';
    }
    
    if (cmd === 'QUIT') {
      return '221 Bye';
    }
    
    if (cmd === 'RSET') {
      this.reset();
      return '250 Ok';
    }
    
    return '250 Ok';
  }
  
  handleData(data: string): string | null {
    if (this.state !== 'BODY') return null;
    
    if (data.trim() === '.') {
      // Fin du message, sauvegarder l'email
      this.saveEmail();
      this.reset();
      return '250 Message accepted for delivery';
    }
    
    this.data += data + '\n';
    return null;
  }
  
  private extractEmail(command: string): string {
    const match = command.match(/<(.+?)>/) || command.match(/:\s*(.+)/);
    return match ? match[1].trim() : '';
  }
  
  private saveEmail() {
    const subject = this.extractSubject(this.data);
    const timestamp = new Date();
    
    // Sauvegarder dans la base ET les boîtes mail
    this.to.forEach(recipient => {
      const domain = getDomain(recipient);
      
      // Insérer dans la base
      const result = db.run(`
        INSERT INTO emails (from_address, to_address, subject, body)
        VALUES (?, ?, ?, ?)
      `, [this.from, recipient, subject, this.data]);
      
      const email: Email = {
        id: result.lastInsertRowid as number,
        from: this.from,
        to: recipient,
        subject: subject,
        body: this.data,
        timestamp: timestamp
      };
      
      if (mailboxes.has(recipient)) {
        mailboxes.get(recipient)!.push(email);
        console.log(`📬 New mail for ${recipient} from ${this.from} (ID: ${email.id})`);
        
        // Injecter dans tmux pour l'agent concerné
        this.injectToTmux(recipient, email);
        
        // Déclencher un event Oracle
        this.notifyOracle(email, recipient);
      }
    });
  }
  
  private injectToTmux(recipient: string, email: Email) {
    // Extraire le nom de l'agent et le domaine
    const [agent, domain] = recipient.split('@');
    
    // Déterminer la session tmux selon le domaine
    let sessionName = 'moulinsart-agents'; // Par défaut pour moulinsart.local
    
    if (domain && domain !== 'moulinsart.local') {
      // Pour les autres domaines, extraire le nom du projet
      const projectName = domain.replace('.local', '');
      sessionName = `moulinsart-${projectName}`;
    }
    
    // Déterminer le numéro du panel (0-3 pour les 4 agents)
    // On utilise l'ordre de création peu importe le nom
    let panelNumber = 0; // Par défaut panel 0
    
    // Pour les agents standards de moulinsart.local
    if (domain === 'moulinsart.local') {
      switch(agent) {
        case 'nestor': panelNumber = 0; break;
        case 'tintin': panelNumber = 1; break;
        case 'dupont1': panelNumber = 2; break;
        case 'dupont2': panelNumber = 3; break;
        default: return;
      }
    }
    
    // Message de notification pour tmux
    const notification = `
=====================================
📧 NOUVEAU MAIL REÇU!
De: ${email.from}
Sujet: ${email.subject}
-------------------------------------
Pour lire: curl http://localhost:1080/api/mailbox/${recipient}
=====================================`;
    
    // Injecter dans la session tmux appropriée
    const { exec } = require('child_process');
    // Utiliser display-message pour notification temporaire (plus propre)
    const mainCommand = `tmux display-message -t ${sessionName}:agents.${panelNumber} -d 3000 "📧 Mail de ${email.from.split('@')[0]} | ${email.subject}" 2>/dev/null`;
    
    exec(mainCommand, (error: any) => {
      if (!error) {
        console.log(`💉 Notification affichée dans panel ${panelNumber} (${agent}) de ${sessionName}`);
      } else {
        // Fallback sur la session par défaut si le projet n'existe pas
        const fallbackCommand = `tmux display-message -t moulinsart-agents:agents.${panelNumber} -d 3000 "📧 Mail de ${email.from.split('@')[0]} | ${email.subject}" 2>/dev/null`;
        exec(fallbackCommand, (fallbackError: any) => {
          if (!fallbackError) {
            console.log(`💉 Notification affichée dans panel ${panelNumber} (${agent}) de la session par défaut`);
          } else {
            // Dernier fallback: envoyer dans le status bar global
            const globalCommand = `tmux display-message -d 3000 "📧 Mail: ${email.subject}" 2>/dev/null`;
            exec(globalCommand, () => {
              console.log(`📢 Notification globale affichée pour ${agent}`);
            });
          }
        });
      }
    });
  }
  
  private extractSubject(data: string): string {
    const match = data.match(/Subject:\s*(.+)/i);
    return match ? match[1].trim() : 'No subject';
  }
  
  private notifyOracle(email: Email, recipient: string) {
    // Envoyer un event à Oracle pour tracking
    const agent = recipient.split('@')[0];
    
    try {
      fetch('http://localhost:3001/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: 'email',
          source: 'mail-server',
          data: {
            from: email.from,
            to: recipient,
            subject: email.subject,
            timestamp: email.timestamp
          },
          agent: agent,
          project: 'moulinsart-mail'
        })
      });
    } catch (err) {
      console.error('Failed to notify Oracle:', err);
    }
  }
  
  private reset() {
    this.from = '';
    this.to = [];
    this.data = '';
    this.state = 'INIT';
  }
}

// Créer le serveur SMTP
const smtpServer = createServer((socket) => {
  console.log('📨 New SMTP connection');
  const session = new SMTPSession();
  
  socket.write('220 moulinsart.local SMTP Server Ready\r\n');
  
  let buffer = '';
  
  socket.on('data', (data) => {
    buffer += data.toString();
    const lines = buffer.split('\r\n');
    buffer = lines.pop() || '';
    
    lines.forEach(line => {
      if (line) {
        const response = session.handleData(line) || session.handleCommand(line);
        if (response) {
          socket.write(response + '\r\n');
          // Si c'est un QUIT, fermer proprement la connexion
          if (response.startsWith('221')) {
            socket.end();
          }
        }
      }
    });
  });
  
  socket.on('end', () => {
    console.log('📪 SMTP connection closed');
    // Nettoyer la session
    session.reset();
  });
  
  socket.on('error', (err) => {
    console.error('SMTP error:', err);
    // Nettoyer la session en cas d'erreur
    session.reset();
  });
  
  socket.on('close', () => {
    // Nettoyer la session à la fermeture
    session.reset();
  });
});

smtpServer.listen(SMTP_PORT, () => {
  console.log(`📧 SMTP Server listening on port ${SMTP_PORT}`);
});

// API HTTP pour consulter les boîtes mail
const httpServer = Bun.serve({
  port: 1080,
  
  async fetch(req) {
    const url = new URL(req.url);
    
    // CORS
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };
    
    // Handle OPTIONS for CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers });
    }
    
    // GET /api/mailbox/:email
    const mailboxMatch = url.pathname.match(/^\/api\/mailbox\/(.+)$/);
    if (mailboxMatch && req.method === 'GET') {
      const emailAddress = decodeURIComponent(mailboxMatch[1]);
      const emails = mailboxes.get(emailAddress) || [];
      
      // AUTO-DELETE DÉSACTIVÉ - Les emails restent disponibles
      // if (emails.length > 0) {
      //   // Supprimer de la base de données
      //   db.run(`
      //     UPDATE emails 
      //     SET deleted = 1 
      //     WHERE to_address = ? AND deleted = 0
      //   `, [emailAddress]);
      //   
      //   // Vider la mailbox en mémoire
      //   mailboxes.set(emailAddress, []);
      //   
      //   console.log(`🗑️ Auto-deleted ${emails.length} emails after reading for ${emailAddress}`);
      // }
      
      return Response.json({ address: emailAddress, emails }, { headers });
    }
    
    // GET /api/mailboxes - Pour le status check
    if (url.pathname === '/api/mailboxes' && req.method === 'GET') {
      const status = {
        agents: agents.map(agent => ({
          name: agent,
          email: `${agent}@moulinsart.local`,
          count: mailboxes.get(`${agent}@moulinsart.local`)?.length || 0
        })),
        total: Array.from(mailboxes.values()).reduce((sum, mails) => sum + mails.length, 0)
      };
      return Response.json(status, { headers });
    }
    
    // GET /agents
    if (url.pathname === '/agents') {
      const agentList = agents.map(agent => ({
        name: agent,
        email: `${agent}@moulinsart.local`,
        inbox: mailboxes.get(`${agent}@moulinsart.local`)?.length || 0
      }));
      
      return Response.json(agentList, { headers });
    }
    
    // DELETE /api/reset-all-emails
    if (url.pathname === '/api/reset-all-emails' && req.method === 'DELETE') {
      const hardDelete = url.searchParams.get('hard') === 'true';
      
      // Compter les emails avant suppression
      const emailCount = Array.from(mailboxes.values()).reduce((sum, mails) => sum + mails.length, 0);
      
      if (hardDelete) {
        // Suppression définitive
        db.run(`DELETE FROM emails`);
        console.log('🗑️ Emails supprimés définitivement de la base');
      } else {
        // Soft delete - marquer comme supprimés
        db.run(`UPDATE emails SET deleted = 1 WHERE deleted = 0`);
        console.log('🗑️ Emails marqués comme supprimés (récupérables)');
      }
      
      // Vider toutes les boîtes mail en mémoire
      agents.forEach(agent => {
        mailboxes.set(`${agent}@moulinsart.local`, []);
      });
      
      // Forcer le garbage collection des connexions SMTP en attente
      smtpServer.getConnections((err, count) => {
        if (!err && count > 0) {
          console.log(`⚠️ ${count} connexion(s) SMTP active(s) détectée(s)`);
        }
      });
      
      console.log(`🗑️ ${emailCount} email(s) vidé(s)`);
      return Response.json({ 
        success: true, 
        message: hardDelete ? 'All emails permanently deleted' : 'All emails soft deleted',
        cleared: emailCount,
        mode: hardDelete ? 'hard' : 'soft',
        servers: { smtp: 'running', api: 'running' } 
      }, { headers });
    }
    
    // POST /api/restore - Restaurer les emails supprimés
    if (url.pathname === '/api/restore' && req.method === 'POST') {
      try {
        // Restaurer les emails soft-deleted
        const result = db.run(`UPDATE emails SET deleted = 0 WHERE deleted = 1`);
        const restored = result.changes;
        
        // Recharger depuis la base
        loadEmailsFromDB();
        
        return Response.json({ 
          success: true, 
          message: `${restored} email(s) restored`,
          restored: restored 
        }, { headers });
      } catch (err) {
        return Response.json({ 
          success: false, 
          message: 'Failed to restore emails',
          error: String(err)
        }, { status: 500, headers });
      }
    }
    
    // POST /api/send - Envoyer un email via API
    if (url.pathname === '/api/send' && req.method === 'POST') {
      const { from, to, subject, body } = await req.json();
      
      // Sauvegarder dans la base de données
      const result = db.run(`
        INSERT INTO emails (from_address, to_address, subject, body)
        VALUES (?, ?, ?, ?)
      `, [from, to, subject, body]);
      
      // Créer l'email avec l'ID de la base
      const email = {
        id: result.lastInsertRowid as number,
        from,
        to,
        subject,
        body,
        timestamp: new Date().toISOString()
      };
      
      // Ajouter à la boîte du destinataire
      if (!mailboxes.has(to)) {
        mailboxes.set(to, []);
      }
      mailboxes.get(to)?.push(email);
      
      console.log(`📬 New mail for ${to} from ${from} (ID: ${email.id})`);
      
      // Injecter notification tmux si c'est un agent
      const recipientAgent = to.split('@')[0];
      if (agents.includes(recipientAgent)) {
        // Déterminer le numéro du panel
        let panelNumber: number;
        switch(recipientAgent) {
          case 'nestor': panelNumber = 0; break;
          case 'tintin': panelNumber = 1; break;
          case 'dupont1': panelNumber = 2; break;
          case 'dupont2': panelNumber = 3; break;
          default: panelNumber = 0;
        }
        
        const notification = `🔔 NOTIFICATION SYSTÈME
━━━━━━━━━━━━━━━━━━━━
📧 Nouveau mail reçu!
📬 Consulte ta boîte: http://localhost:1080/api/mailbox/${recipientAgent}@moulinsart.local
💡 Lis l'email pour connaître ton rôle et tes instructions.
━━━━━━━━━━━━━━━━━━━━`;
        
        const { exec } = require('child_process');
        // Envoyer la commande echo puis un retour chariot (C-m) pour l'exécuter
        // Envoyer la notification deux fois avec 3 secondes d'intervalle
        const command = `tmux send-keys -t moulinsart-agents:agents.${panelNumber} C-m && sleep 0.1 && tmux send-keys -t moulinsart-agents:agents.${panelNumber} "echo '${notification}'" && sleep 0.1 && tmux send-keys -t moulinsart-agents:agents.${panelNumber} C-m && sleep 3 && tmux send-keys -t moulinsart-agents:agents.${panelNumber} C-m && sleep 0.1 && tmux send-keys -t moulinsart-agents:agents.${panelNumber} "echo '${notification} (rappel)'" && sleep 0.1 && tmux send-keys -t moulinsart-agents:agents.${panelNumber} C-m 2>/dev/null`;
        exec(command, (error: any) => {
          if (!error) {
            console.log(`💉 Notification injectée dans panel ${panelNumber} (${recipientAgent})`);
          } else {
            // Fallback sur session individuelle
            const fallback = `tmux send-keys -t ${recipientAgent} "${notification}" Enter 2>/dev/null`;
            exec(fallback, () => {});
          }
        });
      }
      
      return Response.json({ success: true, message: 'Email sent' }, { headers });
    }
    
    // GET /api/emails - Récupérer tous les emails (pour le EmailSplitView)
    if (url.pathname === '/api/emails' && req.method === 'GET') {
      try {
        // Récupérer tous les emails non supprimés depuis la base
        const emails = db.query(`
          SELECT id, from_address as 'from', to_address as 'to', subject, body, timestamp
          FROM emails 
          WHERE deleted = 0
          ORDER BY timestamp DESC
          LIMIT 200
        `).all();
        
        return Response.json({ 
          emails: emails.map((email: any) => ({
            ...email,
            timestamp: email.timestamp
          }))
        }, { headers });
      } catch (err) {
        console.error('Error fetching emails:', err);
        return Response.json({ 
          success: false, 
          message: 'Failed to fetch emails',
          error: String(err)
        }, { status: 500, headers });
      }
    }
    
    // Page d'accueil
    if (url.pathname === '/') {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>📧 Moulinsart Mail Server</title>
          <style>
            body { 
              font-family: monospace; 
              background: #1a1a1a; 
              color: #0f0; 
              padding: 20px;
            }
            h1 { color: #0ff; }
            .agent { 
              background: #000; 
              padding: 10px; 
              margin: 10px 0;
              border: 1px solid #0f0;
            }
          </style>
        </head>
        <body>
          <h1>📧 Moulinsart Mail Server</h1>
          <p>SMTP: localhost:${SMTP_PORT}</p>
          <h2>Agent Mailboxes:</h2>
          ${agents.map(agent => `
            <div class="agent">
              📮 ${agent}@moulinsart.local 
              (${mailboxes.get(`${agent}@moulinsart.local`)?.length || 0} emails)
            </div>
          `).join('')}
        </body>
        </html>
      `, {
        headers: { "Content-Type": "text/html" }
      });
    }
    
    return new Response("Not Found", { status: 404 });
  }
});

console.log(`📮 Mail API running on http://localhost:1080`);
console.log(`📧 Agent emails configured:`);
agents.forEach(agent => {
  console.log(`   - ${agent}@moulinsart.local`);
});