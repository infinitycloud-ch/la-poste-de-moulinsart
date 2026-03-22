#!/bin/bash
# Tintin Task Poller - QA Lead

export AGENT_NAME="tintin"
export AGENT_WORK_DIR="~/moulinsart/agents/tintin"

echo "🚀 Starting Tintin task poller..."
node ~/moulinsart/oracle-observability/agent-task-poller.js