#pragma once

#include <JuceHeader.h>
#include <vector>

class Track;

enum class MidiRoutingMode {
    Selected,
    Armed,
    Omni
};

class MidiRouter {
public:
    MidiRouter();
    ~MidiRouter();

    void setMode(MidiRoutingMode newMode);
    MidiRoutingMode getMode() const { return mode; }

    void setSelectedTrack(int index);
    int getSelectedTrack() const { return selectedTrackIndex; }

    void routeMidiToTracks(juce::MidiBuffer& midiMessages,
                          std::vector<Track>& tracks);

    void processMidiChannel(juce::MidiBuffer& buffer, int channel);

private:
    MidiRoutingMode mode;
    int selectedTrackIndex = 0;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MidiRouter)
};