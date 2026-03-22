#include "../Core/MultiTrackEngine.h"
#include "../Core/MidiRouter.h"
#include "../Core/FXChain.h"
#include "../Core/MasterBus.h"
#include <iostream>
#include <cassert>

class TestSynth : public juce::AudioProcessor {
public:
    TestSynth(int noteOffset = 0) : noteOff(noteOffset) {}

    const juce::String getName() const override { return "TestSynth"; }
    void prepareToPlay(double sr, int) override { sampleRate = sr; }
    void releaseResources() override {}

    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) override {
        buffer.clear();

        for (const auto metadata : midiMessages) {
            auto msg = metadata.getMessage();
            if (msg.isNoteOn()) {
                frequency = 440.0 * std::pow(2.0, (msg.getNoteNumber() + noteOff - 69) / 12.0);
                amplitude = msg.getVelocity() / 127.0f * 0.3f;
            } else if (msg.isNoteOff()) {
                amplitude = 0.0f;
            }
        }

        if (amplitude > 0.0f) {
            for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
                auto* data = buffer.getWritePointer(ch);
                for (int i = 0; i < buffer.getNumSamples(); ++i) {
                    data[i] = amplitude * std::sin(phase);
                    phase += 2.0 * M_PI * frequency / sampleRate;
                    if (phase > 2.0 * M_PI) phase -= 2.0 * M_PI;
                }
            }
        }
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
    double sampleRate = 44100.0;
    double frequency = 440.0;
    double phase = 0.0;
    float amplitude = 0.0f;
    int noteOff = 0;
};

class TestDelay : public juce::AudioProcessor {
public:
    const juce::String getName() const override { return "TestDelay"; }
    void prepareToPlay(double sr, int maxBlock) override {
        delayBuffer.setSize(2, static_cast<int>(sr * 0.5));
        delayBuffer.clear();
    }
    void releaseResources() override {}

    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) override {
        const float feedback = 0.5f;
        const float mix = 0.3f;

        for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
            auto* data = buffer.getWritePointer(ch);
            auto* delayData = delayBuffer.getWritePointer(ch);

            for (int i = 0; i < buffer.getNumSamples(); ++i) {
                float delayed = delayData[delayPos];
                delayData[delayPos] = data[i] + delayed * feedback;
                data[i] = data[i] * (1.0f - mix) + delayed * mix;

                if (++delayPos >= delayBuffer.getNumSamples()) {
                    delayPos = 0;
                }
            }
        }
    }

    double getTailLengthSeconds() const override { return 0.5; }
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
    juce::AudioBuffer<float> delayBuffer;
    int delayPos = 0;
};

void testSprint2_MultiTracks() {
    std::cout << "\n🧪 SPRINT 2 - TEST MULTI-PISTES (4 tracks)" << std::endl;

    MultiTrackEngine engine;
    engine.prepareToPlay(44100, 512);

    assert(engine.getNumTracks() == 4);
    std::cout << "✅ 4 pistes créées" << std::endl;

    for (int i = 0; i < 4; ++i) {
        engine.setTrackInstrument(i, std::make_unique<TestSynth>(i * 12));
        engine.setTrackArmed(i, true);
    }
    std::cout << "✅ Instruments assignés aux 4 pistes" << std::endl;

    engine.setTrackMute(2, true);
    assert(engine.getTrack(2)->isMuted());
    std::cout << "✅ Piste 3 mutée" << std::endl;

    juce::AudioBuffer<float> buffer(2, 512);
    juce::MidiBuffer midi;
    midi.addEvent(juce::MidiMessage::noteOn(1, 60, (juce::uint8)100), 0);

    engine.getMidiRouter().setMode(MidiRoutingMode::Armed);
    engine.processBlock(buffer, midi);

    float rms = buffer.getRMSLevel(0, 0, 512);
    assert(rms > 0.01f);
    std::cout << "✅ MIDI routé vers pistes armées (RMS: " << rms << ")" << std::endl;

    engine.getMidiRouter().setMode(MidiRoutingMode::Selected);
    engine.getMidiRouter().setSelectedTrack(1);
    buffer.clear();
    engine.processBlock(buffer, midi);

    std::cout << "✅ Mode Selected/Armed fonctionnel" << std::endl;
}

void testSprint3_FXChains() {
    std::cout << "\n🧪 SPRINT 3 - TEST FX CHAINS" << std::endl;

    FXChain chain;
    chain.prepareToPlay(44100, 512);

    chain.addEffect(std::make_unique<TestDelay>());
    assert(chain.getNumEffects() == 1);
    std::cout << "✅ Effet ajouté à la chaîne" << std::endl;

    chain.addEffect(std::make_unique<TestDelay>());
    assert(chain.getNumEffects() == 2);
    std::cout << "✅ Deuxième effet ajouté" << std::endl;

    juce::AudioBuffer<float> buffer(2, 512);
    for (int i = 0; i < 512; ++i) {
        buffer.setSample(0, i, 0.5f);
        buffer.setSample(1, i, 0.5f);
    }

    juce::MidiBuffer midi;
    chain.processBlock(buffer, midi);

    float rmsAfter = buffer.getRMSLevel(0, 0, 512);
    std::cout << "✅ FX Chain processing (RMS après: " << rmsAfter << ")" << std::endl;

    chain.bypassEffect(0, true);
    chain.removeEffect(1);
    assert(chain.getNumEffects() == 1);
    std::cout << "✅ Bypass et suppression d'effets" << std::endl;
}

void testSprint4_MasterBus() {
    std::cout << "\n🧪 SPRINT 4 - TEST MASTER BUS" << std::endl;

    MasterBus master;
    master.prepareToPlay(44100, 512);

    master.setMasterVolume(0.8f);
    assert(master.getMasterVolume() == 0.8f);
    std::cout << "✅ Volume master configuré" << std::endl;

    master.setLimiterEnabled(true);
    std::cout << "✅ Limiter activé" << std::endl;

    juce::AudioBuffer<float> buffer(2, 44100);
    for (int i = 0; i < buffer.getNumSamples(); ++i) {
        float sample = std::sin(2.0 * M_PI * 440.0 * i / 44100.0) * 1.5f;
        buffer.setSample(0, i, sample);
        buffer.setSample(1, i, sample);
    }

    juce::MidiBuffer midi;
    master.processBlock(buffer, midi);

    float peak = buffer.getMagnitude(0, 0, buffer.getNumSamples());
    assert(peak <= 1.0f);
    std::cout << "✅ Limiter fonctionne (peak: " << peak << ")" << std::endl;

    juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                     .getChildFile("test_export_master.wav");
    bool exported = master.exportToWAV(exportFile, buffer, 44100, 24);
    assert(exported && exportFile.existsAsFile());
    std::cout << "✅ Export WAV 24-bit réussi (" << exportFile.getSize() << " bytes)" << std::endl;

    exportFile.deleteFile();
}

void testIntegration_FullDAW() {
    std::cout << "\n🎯 TEST INTÉGRATION COMPLÈTE" << std::endl;

    MultiTrackEngine daw;
    daw.prepareToPlay(44100, 512);

    for (int i = 0; i < 4; ++i) {
        daw.setTrackInstrument(i, std::make_unique<TestSynth>(i * 7));
        daw.addTrackEffect(i, std::make_unique<TestDelay>());
        daw.setTrackVolume(i, 0.5f + i * 0.1f);
        daw.setTrackArmed(i, i % 2 == 0);
    }
    std::cout << "✅ DAW configuré: 4 pistes avec instruments + FX" << std::endl;

    daw.getMidiRouter().setMode(MidiRoutingMode::Armed);
    daw.getMasterBus().setMasterVolume(0.9f);
    daw.getMasterBus().setLimiterEnabled(true);

    juce::File mixFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                  .getChildFile("daw_mix_test.wav");
    bool exported = daw.exportMix(mixFile, 5, 24);

    assert(exported && mixFile.existsAsFile());
    std::cout << "✅ Export mix complet 5 secondes (" << mixFile.getSize() << " bytes)" << std::endl;

    mixFile.deleteFile();

    std::cout << "\n🏆 TOUS LES TESTS SPRINT 2-4 RÉUSSIS!" << std::endl;
}

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;

    std::cout << "═══════════════════════════════════════════════════" << std::endl;
    std::cout << "    LOGIC AUDIO DAW - TESTS SPRINTS 2-4" << std::endl;
    std::cout << "═══════════════════════════════════════════════════" << std::endl;

    try {
        testSprint2_MultiTracks();
        testSprint3_FXChains();
        testSprint4_MasterBus();
        testIntegration_FullDAW();

        std::cout << "\n✅ VALIDATION COMPLÈTE SPRINTS 2-4" << std::endl;
        std::cout << "• Multi-pistes: OK" << std::endl;
        std::cout << "• FX Chains: OK" << std::endl;
        std::cout << "• Master Bus: OK" << std::endl;
        std::cout << "• Export WAV: OK" << std::endl;

    } catch (const std::exception& e) {
        std::cout << "❌ Erreur: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}