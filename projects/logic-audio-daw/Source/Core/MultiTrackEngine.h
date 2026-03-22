#pragma once

#include <JuceHeader.h>
#include "Track.h"
#include "MidiRouter.h"
#include "FXChain.h"
#include "MasterBus.h"
#include <vector>
#include <memory>

class MultiTrackEngine : public juce::AudioProcessor {
public:
    MultiTrackEngine();
    ~MultiTrackEngine() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override;

    const juce::String getName() const override { return "MultiTrackDAW"; }
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
    void removeTrack(int index);
    int getNumTracks() const { return tracks.size(); }
    Track* getTrack(int index);

    void setTrackInstrument(int trackIndex, std::unique_ptr<juce::AudioProcessor> instrument);
    void addTrackEffect(int trackIndex, std::unique_ptr<juce::AudioProcessor> effect);
    void removeTrackEffect(int trackIndex, int effectIndex);

    void setTrackVolume(int trackIndex, float volume);
    void setTrackMute(int trackIndex, bool muted);
    void setTrackSolo(int trackIndex, bool solo);
    void setTrackArmed(int trackIndex, bool armed);

    MidiRouter& getMidiRouter() { return midiRouter; }
    MasterBus& getMasterBus() { return *masterBus; }

    bool exportMix(const juce::File& outputFile, int lengthInSeconds = 30, int bitDepth = 24);

    float getTrackRMS(int trackIndex, int channel = 0) const;
    float getTrackPeak(int trackIndex, int channel = 0) const;
    float getMasterRMS(int channel = 0) const;
    float getMasterPeak(int channel = 0) const;

private:
    std::vector<std::unique_ptr<Track>> tracks;
    std::unique_ptr<MasterBus> masterBus;
    MidiRouter midiRouter;

    juce::AudioBuffer<float> mixBuffer;
    std::vector<juce::AudioBuffer<float>> trackBuffers;

    double currentSampleRate = 44100.0;
    int currentBlockSize = 512;

    void mixTracks(juce::AudioBuffer<float>& outputBuffer);
    void updateSoloStates();

    std::vector<bool> soloStates;
    bool anySolo = false;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MultiTrackEngine)
};