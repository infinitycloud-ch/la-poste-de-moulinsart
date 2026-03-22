#include "PluginProcessor.h"
#include "PluginEditor.h"

class SimpleSynthProcessor : public juce::AudioProcessor {
public:
    SimpleSynthProcessor() {
        for (int i = 0; i < 8; ++i) {
            synth.addVoice(new juce::SynthesiserVoice() {
                bool canPlaySound(juce::SynthesiserSound* sound) override {
                    return dynamic_cast<SynthSound*>(sound) != nullptr;
                }

                void startNote(int midiNoteNumber, float velocity,
                             juce::SynthesiserSound*, int) override {
                    frequency = juce::MidiMessage::getMidiNoteInHertz(midiNoteNumber);
                    level = velocity * 0.15;
                    tailOff = 0.0;
                    phase = 0.0;
                }

                void stopNote(float, bool allowTailOff) override {
                    if (allowTailOff) {
                        if (tailOff == 0.0) tailOff = 1.0;
                    } else {
                        level = 0.0;
                    }
                }

                void pitchWheelMoved(int) override {}
                void controllerMoved(int, int) override {}

                void renderNextBlock(juce::AudioBuffer<float>& outputBuffer,
                                   int startSample, int numSamples) override {
                    if (level > 0.0) {
                        if (tailOff > 0.0) {
                            while (--numSamples >= 0) {
                                auto currentSample = (float)(std::sin(phase) * level * tailOff);

                                for (auto i = outputBuffer.getNumChannels(); --i >= 0;)
                                    outputBuffer.addSample(i, startSample, currentSample);

                                phase += phaseIncrement;
                                if (phase > juce::MathConstants<double>::twoPi)
                                    phase -= juce::MathConstants<double>::twoPi;

                                ++startSample;
                                tailOff *= 0.99;
                                if (tailOff <= 0.005) {
                                    level = 0.0;
                                    break;
                                }
                            }
                        } else {
                            while (--numSamples >= 0) {
                                auto currentSample = (float)(std::sin(phase) * level);

                                for (auto i = outputBuffer.getNumChannels(); --i >= 0;)
                                    outputBuffer.addSample(i, startSample, currentSample);

                                phase += phaseIncrement;
                                if (phase > juce::MathConstants<double>::twoPi)
                                    phase -= juce::MathConstants<double>::twoPi;

                                ++startSample;
                            }
                        }
                    }
                }

                double frequency = 440.0, phase = 0.0, level = 0.0, tailOff = 0.0;
                double phaseIncrement = 0.0;

                void updatePhaseIncrement() {
                    phaseIncrement = frequency * juce::MathConstants<double>::twoPi / getSampleRate();
                }
            });
        }

        synth.addSound(new SynthSound());
    }

    const juce::String getName() const override { return "SimpleSynth"; }
    void prepareToPlay(double sampleRate, int samplesPerBlock) override {
        synth.setCurrentPlaybackSampleRate(sampleRate);
        juce::ignoreUnused(samplesPerBlock);
    }
    void releaseResources() override {}
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override {
        buffer.clear();
        synth.renderNextBlock(buffer, midiMessages, 0, buffer.getNumSamples());
    }
    double getTailLengthSeconds() const override { return 0.0; }
    bool acceptsMidi() const override { return true; }
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
    struct SynthSound : public juce::SynthesiserSound {
        bool appliesToNote(int) override { return true; }
        bool appliesToChannel(int) override { return true; }
    };

    juce::Synthesiser synth;
};

class SimpleCompressorProcessor : public juce::AudioProcessor {
public:
    SimpleCompressorProcessor() {}

    const juce::String getName() const override { return "SimpleCompressor"; }
    void prepareToPlay(double sampleRate, int) override {
        attackTime = std::exp(-1.0 / (0.001 * sampleRate));
        releaseTime = std::exp(-1.0 / (0.1 * sampleRate));
    }
    void releaseResources() override {}
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) override {
        const float threshold = 0.5f;
        const float ratio = 4.0f;

        for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
            auto* channelData = buffer.getWritePointer(ch);

            for (int i = 0; i < buffer.getNumSamples(); ++i) {
                float input = std::abs(channelData[i]);

                if (input > envelope) {
                    envelope = attackTime * envelope + (1.0f - attackTime) * input;
                } else {
                    envelope = releaseTime * envelope + (1.0f - releaseTime) * input;
                }

                float gain = 1.0f;
                if (envelope > threshold) {
                    float excess = envelope - threshold;
                    float compressedExcess = excess / ratio;
                    gain = (threshold + compressedExcess) / envelope;
                }

                channelData[i] *= gain;
            }
        }
    }
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
    float envelope = 0.0f;
    float attackTime = 0.0f;
    float releaseTime = 0.0f;
};

LogicAudioDAWProcessor::LogicAudioDAWProcessor() : AudioEngine() {
    setupDefaultTrack();
}

LogicAudioDAWProcessor::~LogicAudioDAWProcessor() {
}

void LogicAudioDAWProcessor::setupDefaultTrack() {
    addTrack();

    addInstrumentToTrack(0, std::make_unique<SimpleSynthProcessor>());
    addFXToTrack(0, std::make_unique<SimpleCompressorProcessor>());

    getTracks()[0].armed = true;
}

juce::AudioProcessorEditor* LogicAudioDAWProcessor::createEditor() {
    return new LogicAudioDAWEditor(*this);
}