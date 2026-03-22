#pragma once

#include <JuceHeader.h>
#include <memory>
#include <atomic>

class Track {
public:
    Track();
    ~Track();

    void setInstrument(std::unique_ptr<juce::AudioProcessor> newInstrument);
    void addEffect(std::unique_ptr<juce::AudioProcessor> effect);
    void removeEffect(int index);
    void clearEffects();

    void setVolume(float newVolume);
    float getVolume() const { return volume; }

    void setMuted(bool shouldBeMuted);
    bool isMuted() const { return muted; }

    void setArmed(bool shouldBeArmed);
    bool isArmed() const { return armed; }

    float getRMS() const { return currentRMS.load(); }
    float getPeak() const { return currentPeak.load(); }

    void updateMeters(float rms, float peak);

    juce::AudioProcessor* getInstrument() const { return instrument.get(); }
    juce::AudioProcessor* getEffect(int index) const;
    int getNumEffects() const { return effects.size(); }

    juce::MidiBuffer& getMidiBuffer() { return midiBuffer; }
    void clearMidiBuffer() { midiBuffer.clear(); }

    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midi);

private:
    std::unique_ptr<juce::AudioProcessor> instrument;
    std::vector<std::unique_ptr<juce::AudioProcessor>> effects;

    float volume{1.0f};
    bool muted{false};
    bool armed{false};

    std::atomic<float> currentRMS{0.0f};
    std::atomic<float> currentPeak{0.0f};

    juce::MidiBuffer midiBuffer;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(Track)
};