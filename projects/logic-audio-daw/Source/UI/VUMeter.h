#pragma once

#include <JuceHeader.h>

class VUMeter : public juce::Component {
public:
    VUMeter();
    ~VUMeter() override;

    void paint(juce::Graphics&) override;
    void setLevel(float rms, float peak);

private:
    float currentRMS = 0.0f;
    float currentPeak = 0.0f;
    float displayRMS = 0.0f;
    float displayPeak = 0.0f;

    const float smoothingFactor = 0.8f;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(VUMeter)
};