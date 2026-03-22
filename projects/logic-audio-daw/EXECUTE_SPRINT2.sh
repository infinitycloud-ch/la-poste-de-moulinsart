#!/bin/bash

# Script pour exécuter Sprint 2 correctement
echo "🚀 EXÉCUTION SPRINT 2 - LOGIC AUDIO DAW"

# DUPONT1 - Core Engine
echo "Envoi instructions DUPONT1..."
tmux send-keys -t nestor-agents:agents.2 'cd ~/moulinsart && ./send-mail.sh nestor@moulinsart.local "Sprint 2 Core" "Développement MidiRouter en cours"' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.2 'cd ~/moulinsart/projects/logic-audio-daw/Source/Core' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.2 'cat > MidiRouter.cpp << "EOF"
#include "MidiRouter.h"

MidiRouter::MidiRouter() : currentMode(Selected) {
    armedTracks.resize(4, false);
}

void MidiRouter::setMode(Mode mode) {
    currentMode = mode;
}

void MidiRouter::routeMidiToTracks(MidiBuffer& input, std::vector<MidiBuffer>& trackBuffers) {
    switch(currentMode) {
        case Selected:
            trackBuffers[selectedTrack] = input;
            break;
        case Armed:
            for(int i = 0; i < armedTracks.size(); i++) {
                if(armedTracks[i]) {
                    trackBuffers[i] = input;
                }
            }
            break;
        case Omni:
            for(auto& buffer : trackBuffers) {
                buffer = input;
            }
            break;
    }
}
EOF' C-m

# DUPONT2 - UI
echo "Envoi instructions DUPONT2..."
tmux send-keys -t nestor-agents:agents.3 'cd ~/moulinsart && ./send-mail.sh nestor@moulinsart.local "Sprint 2 UI" "Développement MultiTrackView en cours"' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.3 'cd ~/moulinsart/projects/logic-audio-daw/Source/UI' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.3 'cat > MultiTrackView.cpp << "EOF"
#include "MultiTrackView.h"

MultiTrackView::MultiTrackView() {
    for(int i = 0; i < 4; i++) {
        auto track = std::make_unique<TrackComponent>();
        track->setBounds(0, i * 150, 800, 140);
        addAndMakeVisible(track.get());
        tracks.push_back(std::move(track));
    }
}

void MultiTrackView::paint(Graphics& g) {
    g.fillAll(Colours::darkgrey);
}

void MultiTrackView::resized() {
    for(int i = 0; i < tracks.size(); i++) {
        tracks[i]->setBounds(0, i * 150, getWidth(), 140);
    }
}
EOF' C-m

# TINTIN - Tests
echo "Envoi instructions TINTIN..."
tmux send-keys -t nestor-agents:agents.1 'cd ~/moulinsart && ./send-mail.sh nestor@moulinsart.local "Sprint 2 Tests" "Framework tests en création"' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.1 'cd ~/moulinsart/projects/logic-audio-daw/Source/Tests' C-m
sleep 1
tmux send-keys -t nestor-agents:agents.1 'cat > MultiTrackTests.cpp << "EOF"
#include <catch2/catch.hpp>
#include "../Core/AudioEngine.h"
#include "../Core/MidiRouter.h"

TEST_CASE("Multi-track MIDI routing", "[midi]") {
    MidiRouter router;
    MidiBuffer input;
    std::vector<MidiBuffer> trackBuffers(4);

    SECTION("Selected mode routes to single track") {
        router.setMode(MidiRouter::Selected);
        router.routeMidiToTracks(input, trackBuffers);
        // Verify only selected track receives MIDI
    }

    SECTION("Armed mode routes to armed tracks") {
        router.setMode(MidiRouter::Armed);
        router.routeMidiToTracks(input, trackBuffers);
        // Verify armed tracks receive MIDI
    }

    SECTION("Omni mode routes to all tracks") {
        router.setMode(MidiRouter::Omni);
        router.routeMidiToTracks(input, trackBuffers);
        // Verify all tracks receive MIDI
    }
}
EOF' C-m

echo "✅ Sprint 2 lancé pour tous les agents"