#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"
#include "UI/TrackComponent.h"

class LogicAudioDAWEditor : public juce::AudioProcessorEditor,
                           private juce::Timer {
public:
    LogicAudioDAWEditor(LogicAudioDAWProcessor&);
    ~LogicAudioDAWEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;

private:
    LogicAudioDAWProcessor& audioProcessor;

    juce::TextButton exportButton;
    juce::Label statusLabel;

    std::vector<std::unique_ptr<TrackComponent>> trackComponents;

    void exportAudio();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(LogicAudioDAWEditor)
};