#pragma once

#include <JuceHeader.h>
#include "Core/AudioEngine.h"

class LogicAudioDAWProcessor : public AudioEngine {
public:
    LogicAudioDAWProcessor();
    ~LogicAudioDAWProcessor() override;

    juce::AudioProcessorEditor* createEditor() override;

    void setupDefaultTrack();

private:
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(LogicAudioDAWProcessor)
};