# Moulinsart vs Claude Code — Who Innovated First?

**Chronological analysis — Nuage Supreme Strategiste, April 2026**

> **Summary:** La Poste de Moulinsart (September 2025) implemented a multi-agent farm in tmux with asynchronous communication, a real-time dashboard, and persistent memory — **5 months before** Claude Code introduced Agent Teams (February 2026). The foundational concepts are identical.

---

## Comparative Timeline

| Date | Event | Source |
|------|-------|--------|
| Feb 2025 | Claude Code launched (research preview). Basic: file editing, bash, CLAUDE.md | Anthropic |
| May 2025 | Claude Code GA. Single agent, no multi-agent. | Anthropic |
| Jul 2025 | Subagents / Task tool. One agent can launch sub-tasks. | Anthropic |
| **Sept 2025** | **MOULINSART.** 4+4 agents in tmux. SMTP email. Oracle dashboard. IEEE paper. 0 crash/1000 ops. 100% local. | Infinity Cloud |
| Sept 2025 | Hooks system added to Claude Code. | Anthropic |
| Oct 2025 | Skills and Plugins. | Anthropic |
| Dec 2025 | Background agents, named sessions. | Anthropic |
| **Jan 2026** | **DAPA v1.0** — Dual-Agent Polling Architecture. Emergent behavior documented. | Infinity Cloud |
| **Feb 2026** | **Agent Teams** (research preview). Lead + teammates in tmux. Messaging. Shared tasks. | Anthropic |
| Feb 2026 | Auto-memory (v2.1.59). Persistent memory between sessions. | Anthropic |
| **Mar 2026** | PANDA complete: 9 sessions, daemon lifecycle, memory, Kanban, multi-project, local model education. | Infinity Cloud |

---

## Feature-by-Feature Comparison

| Feature | Moulinsart / PANDA | Claude Code | Who First? |
|---------|-------------------|-------------|------------|
| **Multi-agents in tmux** | 4+4 agents, tmux panels — *Sept 2025* | Agent Teams, lead + teammates — *Feb 2026* | **Moulinsart (+5 months)** |
| **Specialized roles** | Orchestrator, Dev, QA, Specialist — *Sept 2025* | Lead + subagent types (Explore, Plan) — *Feb 2026* | **Moulinsart (+5 months)** |
| **Inter-agent communication** | Local SMTP email (async, persistent) — *Sept 2025* | Mailbox messaging (Agent Teams) — *Feb 2026* | **Moulinsart (+5 months)** |
| **Real-time dashboard** | Oracle (Vue.js + WebSocket + SQLite) — *Sept 2025* | No equivalent (internal Datadog telemetry) | **Moulinsart (unique)** |
| **100% local** | Foundational architecture — *Sept 2025* | Cloud-first (Anthropic API required) | **Moulinsart (unique)** |
| **Project instructions** | PRD injected at root — *Sept 2025* | CLAUDE.md — *Feb 2025* | Claude Code (+7 months) |
| **Persistent memory** | SQLite events + KB — *Sept 2025* | Auto-memory MEMORY.md — *Feb 2026* | **Moulinsart (+5 months)** |
| **Agent lifecycle monitoring** | Daemon (context %, auto-refresh, rescue) — *Mar 2026* | No equivalent | **PANDA (unique)** |
| **Polling / observing agents** | DAPA tmux capture-pane — *Jan 2026* | run_in_background + notifications — *Dec 2025* | Parallel (~1 month) |
| **Local model education** | Opus educates Nemotron/Qwen3 — *Mar 2026* | No equivalent | **PANDA (unique)** |
| **Agentic loop (tool loop)** | Linear playbooks — *in progress* | query.ts while(true) — *Feb 2025* | Claude Code (+13 months) |
| **Sustainability manifesto** | IEEE + Manifesto published — *Sept 2025* | No equivalent | **Moulinsart (unique)** |
| **Shared task list** | Kanban API (Nestor) — *early 2026* | Agent Teams shared tasks — *Feb 2026* | Parallel |
| **Hooks / events** | Events API changelog — *early 2026* | Hooks system — *Sept 2025* | Claude Code (+4 months) |

---

## Score

|  | Moulinsart / PANDA | Claude Code |
|--|-------------------|-------------|
| **First** | **5 features** | 3 features |
| **Unique (other doesn't have)** | **4 features** | 0 |
| **Parallel** | 2 features | 2 features |

> Out of 14 compared features, Moulinsart/PANDA was first on **5**, has **4 unique features** that Claude Code still doesn't have, and was parallel on 2. Claude Code was first on 3 features (CLAUDE.md, agentic loop, hooks).

---

## Analysis

### What Moulinsart Had Before Everyone

- **Multi-agents with roles** — Nestor (orchestrator), Tintin (QA), Dupont (dev), in tmux. Claude Code only got Agent Teams in February 2026.
- **Persistent asynchronous communication** — Local SMTP email creates an auditable history. Claude Code uses ephemeral messages.
- **Real-time dashboard** — Oracle with WebSocket. Claude Code still has nothing equivalent (only internal Datadog telemetry).
- **Persistent memory** — SQLite with events, KB, clusters. Claude Code only got auto-memory in February 2026.

### What PANDA Has That Claude Code Never Will

- **100% local** — Claude Code depends on the Anthropic API. PANDA runs entirely on the user's own hardware.
- **Agent lifecycle monitoring** — A daemon that monitors each agent's context, triggers automatic refreshes, and rescues crashed agents.
- **Local model education** — Opus educating Nemotron/Qwen3 via structured context. Claude Code IS the model — it doesn't educate anyone.
- **Sustainability manifesto** — An ethical and ecological philosophy for agentic AI.

### What Claude Code Did Better

- **The agentic loop** — The while(true) tool_calls is in Claude Code since day 1. This is what we are currently implementing in MonoCLI.
- **CLAUDE.md** — The concept of project instructions loaded at boot is native since February 2025.
- **Hooks** — Well-integrated shell event system since September 2025.

---

> *"Each crash is a scar. Each scar is knowledge. And this knowledge, we preserve."*
> — Agentic Sustainability Manifesto, Infinity Cloud, September 2025

---

## Conclusion

Moulinsart is not a copy of Claude Code. It is an **independent precursor** that solved the same problems with a different approach (email vs API, dashboard vs telemetry, local vs cloud). The convergence of solutions — specialized roles, tmux, persistent memory, asynchronous communication — shows that these patterns are **natural laws** of multi-agent orchestration, discovered independently by Infinity Cloud and Anthropic.

The difference: Anthropic has hundreds of engineers and billions of dollars. Infinity Cloud has one builder, an agent farm, and **5 months of lead time**.

---

*Nuage Supreme Strategiste — Infinity Cloud Sarl — April 2026*
*Sources: IEEE paper PrivExpensIA (Sept 2025), Claude Code CHANGELOG, code.claude.com/docs, GitHub anthropics/claude-code*

---

## References

- [IEEE Paper (PDF)](https://github.com/infinitycloud-ch/la-poste-de-moulinsart/blob/main/docs/PrivExpensIA_Moulinsart_IEEE_v3.pdf)
- [RESEARCH.md — Full Paper Summary](https://github.com/infinitycloud-ch/la-poste-de-moulinsart/blob/main/RESEARCH.md)
- [Agentic Sustainability Manifesto](https://github.com/infinitycloud-ch/la-poste-de-moulinsart/blob/main/MANIFESTO.md)
- [Main Repository](https://github.com/infinitycloud-ch/la-poste-de-moulinsart)
