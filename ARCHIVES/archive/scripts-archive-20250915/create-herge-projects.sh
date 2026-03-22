#!/bin/bash

# 🚀 Création de 3 environnements Hergé pré-configurés

echo "🎯 Création des projets Hergé..."

# Projet 1: Équipe Lune (Objectif Lune)
echo "1️⃣ Création projet: objectif-lune"
tmux new-session -d -s objectif-lune-agents -n agents
tmux split-window -t objectif-lune-agents:agents -h
tmux split-window -t objectif-lune-agents:agents -v
tmux select-pane -t objectif-lune-agents:agents.0
tmux split-window -t objectif-lune-agents:agents -v

# Agents: Tournesol, Haddock, Milou, Wolff
tmux send-keys -t objectif-lune-agents:agents.0 "echo '🔬 Agent: Professeur Tournesol'" C-m
tmux send-keys -t objectif-lune-agents:agents.1 "echo '⚓ Agent: Capitaine Haddock'" C-m
tmux send-keys -t objectif-lune-agents:agents.2 "echo '🐕 Agent: Milou'" C-m
tmux send-keys -t objectif-lune-agents:agents.3 "echo '👨‍🔬 Agent: Wolff'" C-m

echo "   ✅ Session tmux: objectif-lune-agents créée"

# Projet 2: Équipe Trésor (Trésor de Rackham)
echo "2️⃣ Création projet: tresor-rackham"
tmux new-session -d -s tresor-rackham-agents -n agents
tmux split-window -t tresor-rackham-agents:agents -h
tmux split-window -t tresor-rackham-agents:agents -v
tmux select-pane -t tresor-rackham-agents:agents.0
tmux split-window -t tresor-rackham-agents:agents -v

# Agents: Rackham, Haddock, Tournesol, Tintin
tmux send-keys -t tresor-rackham-agents:agents.0 "echo '🏴‍☠️ Agent: Rackham le Rouge'" C-m
tmux send-keys -t tresor-rackham-agents:agents.1 "echo '⚓ Agent: Capitaine Haddock'" C-m
tmux send-keys -t tresor-rackham-agents:agents.2 "echo '🔬 Agent: Professeur Tournesol'" C-m
tmux send-keys -t tresor-rackham-agents:agents.3 "echo '🕵️ Agent: Tintin'" C-m

echo "   ✅ Session tmux: tresor-rackham-agents créée"

# Projet 3: Équipe Amérique (Tintin en Amérique)
echo "3️⃣ Création projet: amerique"
tmux new-session -d -s amerique-agents -n agents
tmux split-window -t amerique-agents:agents -h
tmux split-window -t amerique-agents:agents -v
tmux select-pane -t amerique-agents:agents.0
tmux split-window -t amerique-agents:agents -v

# Agents: AlCapone, Bobby, Tintin, Milou
tmux send-keys -t amerique-agents:agents.0 "echo '🎩 Agent: Al Capone'" C-m
tmux send-keys -t amerique-agents:agents.1 "echo '👮 Agent: Bobby Smiles'" C-m
tmux send-keys -t amerique-agents:agents.2 "echo '🕵️ Agent: Tintin'" C-m
tmux send-keys -t amerique-agents:agents.3 "echo '🐕 Agent: Milou'" C-m

echo "   ✅ Session tmux: amerique-agents créée"

echo ""
echo "🎯 3 ENVIRONNEMENTS CRÉÉS !"
echo "=========================="
echo ""
echo "📍 Pour voir les sessions:"
echo "   tmux ls | grep agents"
echo ""
echo "📍 Pour attacher à un projet:"
echo "   tmux attach -t objectif-lune-agents"
echo "   tmux attach -t tresor-rackham-agents"
echo "   tmux attach -t amerique-agents"
echo ""
echo "📍 Configuration email:"
echo "   objectif-lune: tournesol@objectif-lune.local"
echo "   tresor-rackham: rackham@tresor-rackham.local"
echo "   amerique: alcapone@amerique.local"
echo ""
echo "🚀 Prêt à travailler avec les personnages d'Hergé !"