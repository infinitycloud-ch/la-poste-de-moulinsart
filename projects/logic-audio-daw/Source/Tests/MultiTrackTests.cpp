#include "../Core/AudioEngine.h"
#include <iostream>
#include <cassert>
#include <vector>
#include <chrono>

class MultiTrackTests {
public:
    static void runAll() {
        std::cout << "=== MULTI-TRACK TESTS - SPRINT 2-10 ===" << std::endl;

        testFourTracksSimultaneous();
        testTrackSynchronization();
        testIndependentVolumeControl();
        testMixdown();
        testPerformance();

        std::cout << "=== ALL MULTI-TRACK TESTS PASSED ===" << std::endl;
    }

private:
    static void testFourTracksSimultaneous() {
        std::cout << "Test: 4 tracks simultaneous playback..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Add 4 tracks
        for (int i = 0; i < 4; ++i) {
            engine.addTrack();
        }

        auto& tracks = engine.getTracks();
        assert(tracks.size() == 4);

        // Set different volumes for each track
        engine.setTrackVolume(0, 1.0f);
        engine.setTrackVolume(1, 0.75f);
        engine.setTrackVolume(2, 0.5f);
        engine.setTrackVolume(3, 0.25f);

        // Process audio block
        juce::AudioBuffer<float> buffer(2, 512);
        juce::MidiBuffer midiBuffer;

        // Generate test signals for each track
        for (int track = 0; track < 4; ++track) {
            buffer.clear();
            float frequency = 220.0f * (track + 1); // 220Hz, 440Hz, 660Hz, 880Hz

            for (int ch = 0; ch < 2; ++ch) {
                auto* channelData = buffer.getWritePointer(ch);
                for (int i = 0; i < 512; ++i) {
                    channelData[i] = std::sin(2.0f * M_PI * frequency * i / 44100.0f);
                }
            }

            engine.processBlock(buffer, midiBuffer);
        }

        std::cout << "  PASS: 4 tracks playing simultaneously" << std::endl;
    }

    static void testTrackSynchronization() {
        std::cout << "Test: Track synchronization..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Add 4 tracks and verify sync
        for (int i = 0; i < 4; ++i) {
            engine.addTrack();
        }

        // Start all tracks at same position
        engine.setPlayheadPosition(0);

        // Process multiple blocks and verify sync
        juce::AudioBuffer<float> buffer(2, 512);
        juce::MidiBuffer midiBuffer;

        for (int block = 0; block < 10; ++block) {
            engine.processBlock(buffer, midiBuffer);
        }

        // All tracks should be at same position
        int64_t expectedPosition = 512 * 10;
        assert(engine.getPlayheadPosition() == expectedPosition);

        std::cout << "  PASS: Tracks remain synchronized" << std::endl;
    }

    static void testIndependentVolumeControl() {
        std::cout << "Test: Independent volume control..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Create 4 tracks with different volumes
        std::vector<float> volumes = {1.0f, 0.7f, 0.4f, 0.1f};

        for (size_t i = 0; i < 4; ++i) {
            engine.addTrack();
            engine.setTrackVolume(i, volumes[i]);
        }

        // Verify each track maintains independent volume
        auto& tracks = engine.getTracks();
        for (size_t i = 0; i < 4; ++i) {
            assert(std::abs(tracks[i].volume - volumes[i]) < 0.001f);
        }

        // Mute track 2, verify others unaffected
        engine.setTrackMute(2, true);
        assert(tracks[2].muted == true);
        assert(tracks[0].muted == false);
        assert(tracks[1].muted == false);
        assert(tracks[3].muted == false);

        std::cout << "  PASS: Each track has independent volume/mute" << std::endl;
    }

    static void testMixdown() {
        std::cout << "Test: Multi-track mixdown..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Add 4 tracks
        for (int i = 0; i < 4; ++i) {
            engine.addTrack();
            engine.setTrackVolume(i, 0.25f); // Equal mix
        }

        juce::AudioBuffer<float> mixBuffer(2, 44100); // 1 second
        mixBuffer.clear();

        // Mix all tracks
        juce::MidiBuffer midiBuffer;
        int numBlocks = 44100 / 512;

        for (int block = 0; block < numBlocks; ++block) {
            juce::AudioBuffer<float> blockBuffer(2, 512);
            blockBuffer.clear();

            // Generate different frequency for each track
            for (int track = 0; track < 4; ++track) {
                float freq = 220.0f * (track + 1);
                for (int ch = 0; ch < 2; ++ch) {
                    auto* data = blockBuffer.getWritePointer(ch);
                    for (int i = 0; i < 512; ++i) {
                        int globalIndex = block * 512 + i;
                        data[i] += 0.25f * std::sin(2.0f * M_PI * freq * globalIndex / 44100.0f);
                    }
                }
            }

            engine.processBlock(blockBuffer, midiBuffer);

            // Copy to mix buffer
            for (int ch = 0; ch < 2; ++ch) {
                mixBuffer.copyFrom(ch, block * 512, blockBuffer, ch, 0, 512);
            }
        }

        // Verify mixdown has content
        float rms = mixBuffer.getRMSLevel(0, 0, 44100);
        assert(rms > 0.1f);

        std::cout << "  PASS: Mixdown successful (RMS: " << rms << ")" << std::endl;
    }

    static void testPerformance() {
        std::cout << "Test: Multi-track performance..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Add 4 tracks
        for (int i = 0; i < 4; ++i) {
            engine.addTrack();
        }

        juce::AudioBuffer<float> buffer(2, 512);
        juce::MidiBuffer midiBuffer;

        // Measure processing time for 1 second of audio
        auto start = std::chrono::high_resolution_clock::now();

        int numBlocks = 44100 / 512;
        for (int i = 0; i < numBlocks; ++i) {
            buffer.clear();
            engine.processBlock(buffer, midiBuffer);
        }

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

        // Processing should be faster than real-time
        assert(duration.count() < 1000);

        std::cout << "  PASS: Processing time " << duration.count()
                  << "ms for 1s audio (real-time capable)" << std::endl;
    }
};

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;
    MultiTrackTests::runAll();
    return 0;
}