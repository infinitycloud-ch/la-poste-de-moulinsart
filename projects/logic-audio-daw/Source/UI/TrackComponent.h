#pragma once

#include <JuceHeader.h>
#include "../PluginProcessor.h"
#include "VUMeter.h"

class TrackComponent : public juce::Component {
public:
    TrackComponent(LogicAudioDAWProcessor& processor, int trackIndex);
    ~TrackComponent() override;

    void paint(juce::Graphics&) override;
    void resized() override;
    void updateMeters();

private:
    LogicAudioDAWProcessor& audioProcessor;
    int trackIdx;

    juce::Label instrumentLabel;
    juce::Label fxLabel;

    juce::Slider volumeSlider;
    juce::Label volumeLabel;

    juce::ToggleButton muteButton;
    juce::ToggleButton armButton;

    std::unique_ptr<VUMeter> vuMeter;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(TrackComponent)
};