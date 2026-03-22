#!/bin/bash
# Nestor Task Poller - Chef d'orchestre

export AGENT_NAME="nestor"
export AGENT_WORK_DIR="~/moulinsart/agents/nestor"

echo "🎩 Starting Nestor task poller..."
node ~/moulinsart/oracle-observability/agent-task-poller.js