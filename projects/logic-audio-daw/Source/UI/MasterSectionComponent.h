#pragma once

#include <JuceHeader.h>
#include "VUMeter.h"
#include "../Audio/AudioEngine.h"

class MasterSectionComponent : public juce::Component, private juce::Timer
{
public:
    MasterSectionComponent(AudioEngine* engine = nullptr);
    ~MasterSectionComponent();

    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    void timerCallback() override;
    void showExportDialog();
    void exportToFile(const juce::File& file);

    AudioEngine* audioEngine;

    juce::Slider volumeFader;
    juce::TextButton muteButton;
    juce::TextButton exportButton;

    std::unique_ptr<VUMeter> vuMeterLeft;
    std::unique_ptr<VUMeter> vuMeterRight;

    float masterVolume;
    bool isMuted;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MasterSectionComponent)
};