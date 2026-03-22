#include "MidiRouter.h"

MidiRouter::MidiRouter() : mode(MidiRoutingMode::Armed) {
}

MidiRouter::~MidiRouter() {
}

void MidiRouter::setMode(MidiRoutingMode newMode) {
    mode = newMode;
}

void MidiRouter::setSelectedTrack(int index) {
    selectedTrackIndex = index;
}

void MidiRouter::routeMidiToTracks(juce::MidiBuffer& midiMessages,
                                  std::vector<Track>& tracks) {
    if (midiMessages.isEmpty()) return;

    switch (mode) {
        case MidiRoutingMode::Selected:
            if (selectedTrackIndex >= 0 && selectedTrackIndex < tracks.size()) {
                tracks[selectedTrackIndex].getMidiBuffer() = midiMessages;
            }
            break;

        case MidiRoutingMode::Armed:
            for (auto& track : tracks) {
                if (track.isArmed()) {
                    track.getMidiBuffer() = midiMessages;
                }
            }
            break;

        case MidiRoutingMode::Omni:
            for (auto& track : tracks) {
                track.getMidiBuffer() = midiMessages;
            }
            break;
    }

    for (auto& track : tracks) {
        if (track.isMuted()) {
            track.clearMidiBuffer();
        }
    }
}

void MidiRouter::processMidiChannel(juce::MidiBuffer& buffer, int channel) {
    juce::MidiBuffer filteredBuffer;

    for (const auto metadata : buffer) {
        const auto msg = metadata.getMessage();
        if (msg.getChannel() == channel || channel == 0) {
            filteredBuffer.addEvent(msg, metadata.samplePosition);
        }
    }

    buffer = filteredBuffer;
}