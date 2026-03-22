#pragma once

#include <JuceHeader.h>
#include "TrackComponent.h"
#include "../Audio/AudioEngine.h"

class MultiTrackView : public juce::Component, private juce::Timer
{
public:
    MultiTrackView(AudioEngine* engine = nullptr);
    ~MultiTrackView();

    void paint(juce::Graphics& g) override;
    void resized() override;

    void selectTrack(int index);
    TrackComponent* getTrack(int index);
    int getSelectedTrackIndex() const;

    void loadInstrumentIntoTrack(int trackIndex, const juce::String& instrumentName);
    void addEffectToTrack(int trackIndex, int slotIndex, const juce::String& effectName);

    std::function<void(int)> onTrackSelectionChanged;

private:
    void timerCallback() override;
    void updateSoloStates();

    juce::OwnedArray<TrackComponent> tracks;
    AudioEngine* audioEngine;
    int selectedTrack;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MultiTrackView)
};