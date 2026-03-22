#pragma once

#include <JuceHeader.h>
#include <vector>
#include <memory>

struct Track {
    juce::AudioProcessorGraph::NodeID instrumentNode;
    std::vector<juce::AudioProcessorGraph::NodeID> fxNodes;
    juce::AudioProcessorGraph::NodeID gainNode;

    float volume = 1.0f;
    bool muted = false;
    bool armed = false;

    juce::MidiBuffer midiBuffer;

    std::atomic<float> currentRMS{0.0f};
    std::atomic<float> currentPeak{0.0f};
};

class AudioEngine : public juce::AudioProcessor {
public:
    AudioEngine();
    ~AudioEngine() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    const juce::String getName() const override { return "LogicAudioDAW"; }
    bool acceptsMidi() const override { return true; }
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

    bool hasEditor() const override { return true; }
    juce::AudioProcessorEditor* createEditor() override;

    void addTrack();
    void addInstrumentToTrack(int trackIndex, std::unique_ptr<juce::AudioProcessor> instrument);
    void addFXToTrack(int trackIndex, std::unique_ptr<juce::AudioProcessor> effect);
    void rebuildTrackChain(int trackIndex);

    void setTrackVolume(int trackIndex, float volume);
    void setTrackMute(int trackIndex, bool muted);
    float getTrackRMS(int trackIndex) const;
    float getTrackPeak(int trackIndex) const;

    bool exportToWAV(const juce::File& outputFile);

    std::vector<Track>& getTracks() { return tracks; }

private:
    std::unique_ptr<juce::AudioProcessorGraph> graph;
    juce::AudioProcessorGraph::NodeID masterInputNode;
    juce::AudioProcessorGraph::NodeID masterOutputNode;
    juce::AudioProcessorGraph::NodeID audioInputNode;
    juce::AudioProcessorGraph::NodeID midiInputNode;

    std::vector<Track> tracks;

    void connectTrackToMaster(int trackIndex);
    void updateVUMeters();

    class TrackGainProcessor : public juce::AudioProcessor {
    public:
        TrackGainProcessor(Track* track) : trackRef(track) {}

        const juce::String getName() const override { return "TrackGain"; }
        void prepareToPlay(double, int) override {}
        void releaseResources() override {}
        void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) override;
        double getTailLengthSeconds() const override { return 0.0; }
        bool acceptsMidi() const override { return false; }
        bool producesMidi() const override { return false; }
        bool isMidiEffect() const override { return false; }
        int getNumPrograms() override { return 1; }
        int getCurrentProgram() override { return 0; }
        void setCurrentProgram(int) override {}
        const juce::String getProgramName(int) override { return {}; }
        void changeProgramName(int, const juce::String&) override {}
        void getStateInformation(juce::MemoryBlock&) override {}
        void setStateInformation(const void*, int) override {}
        bool hasEditor() const override { return false; }
        juce::AudioProcessorEditor* createEditor() override { return nullptr; }

    private:
        Track* trackRef;
    };

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(AudioEngine)
};