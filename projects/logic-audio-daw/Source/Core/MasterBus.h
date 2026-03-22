#pragma once

#include <JuceHeader.h>
#include <memory>
#include <atomic>

class MasterBus : public juce::AudioProcessor {
public:
    MasterBus();
    ~MasterBus() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    const juce::String getName() const override { return "MasterBus"; }
    bool acceptsMidi() const override { return false; }
    bool producesMidi() const override { return false; }
    bool isMidiEffect() const override { return false; }
    double getTailLengthSeconds() const override { return 0.0; }

    int getNumPrograms() override { return 1; }
    int getCurrentProgram() override { return 0; }
    void setCurrentProgram(int) override {}
    const juce::String getProgramName(int) override { return {}; }
    void changeProgramName(int, const juce::String&) override {}

    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    bool hasEditor() const override { return false; }
    juce::AudioProcessorEditor* createEditor() override { return nullptr; }

    void setMasterVolume(float volume);
    float getMasterVolume() const { return masterVolume; }

    void setLimiterEnabled(bool enabled) { limiterEnabled = enabled; }
    bool isLimiterEnabled() const { return limiterEnabled; }

    void addMasterEffect(std::unique_ptr<juce::AudioProcessor> effect);
    void removeMasterEffect(int index);
    void clearMasterEffects();

    float getCurrentRMS(int channel) const;
    float getCurrentPeak(int channel) const;

    bool exportToWAV(const juce::File& outputFile,
                     juce::AudioBuffer<float>& sourceBuffer,
                     double sampleRate,
                     int bitDepth = 24);

    bool exportToWAVRealtime(const juce::File& outputFile,
                            std::function<void(juce::AudioBuffer<float>&, juce::MidiBuffer&)> renderCallback,
                            double sampleRate,
                            int lengthInSamples,
                            int bitDepth = 24);

private:
    float masterVolume = 1.0f;
    bool limiterEnabled = true;

    std::unique_ptr<juce::AudioProcessorGraph> effectsGraph;
    std::vector<std::unique_ptr<juce::AudioProcessor>> masterEffects;
    std::vector<juce::AudioProcessorGraph::NodeID> effectNodes;

    juce::AudioProcessorGraph::NodeID inputNode;
    juce::AudioProcessorGraph::NodeID outputNode;

    std::atomic<float> leftRMS{0.0f};
    std::atomic<float> rightRMS{0.0f};
    std::atomic<float> leftPeak{0.0f};
    std::atomic<float> rightPeak{0.0f};

    double currentSampleRate = 44100.0;
    int currentBlockSize = 512;

    void applyLimiter(juce::AudioBuffer<float>& buffer);
    void updateMeters(const juce::AudioBuffer<float>& buffer);
    void rebuildEffectChain();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MasterBus)
};