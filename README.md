# Moulinsart — The First AI Agent Farm

**September 2025** — A pioneering multi-agent AI orchestration system where 4 autonomous agents collaborate via tmux sessions and email-based communication. Built 2 months before multi-agent frameworks became mainstream.

![TypeScript](https://img.shields.io/badge/TypeScript-Bun-blue)
![Vue](https://img.shields.io/badge/Dashboard-Vue.js-green)
![Agents](https://img.shields.io/badge/Agents-4+4-purple)
![Status](https://img.shields.io/badge/Status-Archive-lightgrey)

> **This is an archive showcase.** Moulinsart is preserved as a historical snapshot of the first "Ferme Agentique" (Agent Farm) — a fully functional multi-agent system that predates mainstream adoption. It is not intended to be installed or run independently.

## Academic Paper (September 12, 2025)

This project is documented in an **IEEE-format research paper**, providing timestamped, peer-reviewable evidence of the architecture and results — **two months before** multi-agent frameworks like OpenClaw became mainstream:

> **"PrivExpensIA: Observational Study of a Multi-Agent Orchestration Framework Based on Local Claude CLI with Email-mediated Communication"**
>
> *This paper documents the experimental deployment of a local multi-agent orchestration system, nicknamed La Poste de Moulinsart. Unlike cloud-based agent frameworks (CrewAI, LangGraph, AutoGen), this architecture leverages parallel Claude CLI instances orchestrated via email-based communication and tmux integration. Results: **95.4% accuracy, <300ms latency, 0 crashes/1000 ops** — production-level artefacts delivered in under 48 hours.*

| Document | Description |
|----------|-------------|
| [**RESEARCH.md**](RESEARCH.md) | Full paper summary: abstract, architecture, results, comparison table |
| [`docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf`](docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf) | Original IEEE paper (PDF) |
| [**MANIFESTO.md**](MANIFESTO.md) | Agentic Sustainability Manifesto (English) |
| [`docs/InfinityCloud_AgenticSustainabilityManifesto.pdf`](docs/InfinityCloud_AgenticSustainabilityManifesto.pdf) | Original manifesto (PDF) |
| [`docs/MOULINSART_VS_CLAUDE_CODE.md`](docs/MOULINSART_VS_CLAUDE_CODE.md) | Moulinsart vs Claude Code — chronological comparison (April 2026) |

### Measured Results vs. Other Frameworks

| Framework | Communication | Context | Observability | Resilience | Deployment |
|-----------|--------------|---------|---------------|------------|------------|
| AutoGPT (2023) | API calls | Reset each loop | File logs | Medium | Cloud / PC |
| CrewAI (2024) | API orchestrator | Shared prompt | Minimal | Variable | Cloud |
| LangChain Agents (2024) | Chained API calls | Partial reset | Basic logging | Variable | Cloud / Hybrid |
| **Moulinsart (Sept 2025)** | **Emails + tmux CLI** | **200k ctx/agent** | **Real-time dashboard** | **0 crash / 1000 ops** | **100% Local** |

<!--
## Screenshots

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="700" alt="Oracle Dashboard">
  <img src="docs/screenshots/tmux-agents.png" width="700" alt="Agents in tmux">
</p>
-->

## What is Moulinsart?

Moulinsart is a **multi-agent AI coordination system** inspired by Hergé's Tintin universe. It demonstrates that autonomous AI agents can work as a team — communicating via email, sharing tasks, monitoring each other's health, and delivering real software.

The system orchestrates **two independent teams of 4 agents each**, running in parallel tmux sessions:

### Team Moulinsart
| Agent | Role | Specialty |
|-------|------|-----------|
| **Nestor** | Orchestrator | Team lead, task coordination |
| **Tintin** | Reporter | QA, testing, validation |
| **Dupont1** | Developer | iOS development (Swift) |
| **Dupont2** | Specialist | Documentation, i18n |

### Team Manitoba
| Agent | Role | Specialty |
|-------|------|-----------|
| **Haddock** | Team Lead | Architecture decisions |
| **Rastapopoulos** | Reporter | QA, adversarial testing |
| **Tournesol1** | Developer | Full-stack development |
| **Tournesol2** | Specialist | Documentation, research |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              ORACLE OBSERVABILITY CENTER                 │
│         (Bun + TypeScript — Central API)                │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐   │
│  │ REST API │  │WebSocket │  │ SQLite (WAL mode)  │   │
│  │ Port 3001│  │Real-time │  │ Events, Tasks,     │   │
│  └──────────┘  └──────────┘  │ Emails, State      │   │
│                               └────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│              MAIL SERVER (Inter-Agent)                   │
│         SMTP Port 1025 / HTTP Port 1080                 │
├─────────────────────────────────────────────────────────┤
│              VUE.JS DASHBOARD                            │
│         Real-time monitoring — Port 5175                 │
│         Liquid Glass design / Agent avatars              │
└──────────┬──────────────────────────────┬───────────────┘
           │                              │
    ┌──────┴──────┐               ┌──────┴──────┐
    │  TMUX       │               │  TMUX       │
    │ nestor-     │               │ haddock-    │
    │ agents      │               │ agents      │
    │             │               │             │
    │ P0: Nestor  │               │ P0: Haddock │
    │ P1: Tintin  │               │ P1: Rasta   │
    │ P2: Dupont1 │               │ P2: Tourn.1 │
    │ P3: Dupont2 │               │ P3: Tourn.2 │
    └─────────────┘               └─────────────┘
```

## Key Innovations

### 1. Email-Based Agent Communication
Agents communicate through a **local SMTP server**, sending structured emails to each other. This provides:
- Asynchronous, decoupled messaging
- Full audit trail of all agent interactions
- Natural queuing and retry semantics

### 2. Real-Time Observability
The Oracle dashboard provides live monitoring:
- Agent health heartbeats
- Task progress across teams
- Email flow visualization
- Sprint and milestone tracking

### 3. Automated Validation
An MCP (Mobile Command Platform) system uses **Gemini 1.5 Pro** for:
- Video analysis of running applications
- Frame-by-frame screenshot validation
- Automated scoring of UI correctness (0-100)
- Dispatch of issues to the correct agent

### 4. Team Isolation with Cross-Team Coordination
Each team runs in its own tmux session with isolated workspaces, yet they can coordinate through the shared Oracle API and email system.

## What It Built

During its active period, Moulinsart successfully delivered:
- **PrivExpensIA** — A fully localized iOS expense tracking app (8 languages)
- **Logic Audio DAW** — Foundations for a C++/JUCE digital audio workstation
- Complete documentation, test reports, and validation artifacts

## Tech Stack

| Component | Technology |
|-----------|------------|
| Runtime | Bun (TypeScript) |
| API Server | Bun HTTP (port 3001) |
| Mail Server | Custom SMTP/HTTP (ports 1025/1080) |
| Dashboard | Vue.js + Vite |
| Database | SQLite with WAL mode |
| Real-time | WebSocket |
| Agent Hosting | tmux sessions |
| Validation AI | Gemini 1.5 Pro |
| Design System | Liquid Glass (Apple iOS 26 aesthetic) |

## Key Files

| File | Description |
|------|-------------|
| [`RESEARCH.md`](RESEARCH.md) | IEEE paper summary with results, architecture, and comparison table |
| [`MANIFESTO.md`](MANIFESTO.md) | Agentic Sustainability Manifesto (English) |
| [`docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf`](docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf) | Original IEEE research paper (September 12, 2025) |
| [`docs/InfinityCloud_AgenticSustainabilityManifesto.pdf`](docs/InfinityCloud_AgenticSustainabilityManifesto.pdf) | Original manifesto (PDF) |
| `oracle-observability/server/index.ts` | Oracle API server (127KB) |
| `oracle-observability/server/mail-server.ts` | SMTP email server for inter-agent communication |
| `moulinsart-manager.sh` | Service orchestrator (start/stop teams, health, backup) |

## Repository Structure

```
moulinsart/
├── RESEARCH.md                  # IEEE paper summary
├── MANIFESTO.md                 # Agentic Sustainability Manifesto
├── docs/                        # Research papers (PDFs)
│   ├── PrivExpensIA_Moulinsart_IEEE_v3.pdf
│   └── InfinityCloud_AgenticSustainabilityManifesto.pdf
├── agents/                      # 8 agent workspaces (4 per team)
│   ├── nestor/                  # Orchestrator
│   ├── tintin/                  # Reporter/QA
│   ├── dupont1/                 # iOS Developer
│   ├── dupont2/                 # i18n Specialist
│   ├── haddock/                 # Team 2 Lead
│   ├── rastapopoulos/          # Team 2 QA
│   ├── tournesol1/              # Team 2 Developer
│   └── tournesol2/              # Team 2 Specialist
├── oracle-observability/        # Central monitoring system
│   ├── server/index.ts          # API server (127KB)
│   ├── server/mail-server.ts    # SMTP server
│   └── client/                  # Vue.js dashboard
├── projects/                    # Delivered project artifacts
├── ARCHIVES/                    # Final reports & snapshots
├── moulinsart-manager.sh        # Service orchestrator
└── instructions-equipes-tmux/   # Team briefing documents
```

## Historical Context

Moulinsart was created in **September 2025**, demonstrating autonomous multi-agent AI coordination at a time when the concept was largely theoretical. The accompanying [IEEE-format paper](docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf) provides dated, peer-reviewable evidence of the architecture and results. The system proved that:

1. **AI agents can self-organize** — Given clear roles and communication channels, agents coordinate without constant human oversight
2. **Email is a natural protocol for agent communication** — Asynchronous, structured, auditable
3. **Observability is critical** — Real-time dashboards prevent silent failures
4. **Team isolation scales** — Independent teams can work on different projects simultaneously

This work preceded the mainstream wave of multi-agent frameworks (OpenClaw, etc.) by approximately 2 months.

## Timeline

- **September 2025** — Moulinsart v1: 4 agents, email communication, Oracle dashboard
- **October 2025** — Team Manitoba added (8 agents total), MCP video validation
- **November 2025** — OpenClaw and similar frameworks emerge publicly
- **2026** — Evolution into the production-grade "Ferme Agentique" with Nestor orchestrator

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Built by **Mr D** — Founder of [Infinity Cloud](https://infinitycloud.ch), Switzerland.

Part of the **Ferme Agentique** ecosystem — autonomous AI agent orchestration.
