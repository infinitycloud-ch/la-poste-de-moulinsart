#pragma once

#include <JuceHeader.h>
#include <vector>
#include <memory>

class FXChain : public juce::AudioProcessor {
public:
    FXChain();
    ~FXChain() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    const juce::String getName() const override { return "FXChain"; }
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

    void addEffect(std::unique_ptr<juce::AudioProcessor> effect);
    void removeEffect(int index);
    void moveEffect(int from, int to);
    void clearEffects();
    void bypassEffect(int index, bool shouldBypass);

    int getNumEffects() const { return effects.size(); }
    juce::AudioProcessor* getEffect(int index);
    void rebuildChain();

private:
    std::unique_ptr<juce::AudioProcessorGraph> graph;
    std::vector<std::unique_ptr<juce::AudioProcessor>> effects;
    std::vector<juce::AudioProcessorGraph::NodeID> effectNodes;
    std::vector<bool> bypassStates;

    juce::AudioProcessorGraph::NodeID inputNode;
    juce::AudioProcessorGraph::NodeID outputNode;

    double currentSampleRate = 44100.0;
    int currentBlockSize = 512;

    void connectNodes();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(FXChain)
};