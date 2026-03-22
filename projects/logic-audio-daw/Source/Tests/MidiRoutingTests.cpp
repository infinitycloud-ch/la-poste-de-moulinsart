#include "../Core/AudioEngine.h"
#include "../Core/MidiProcessor.h"
#include <iostream>
#include <cassert>
#include <set>

class MidiRoutingTests {
public:
    static void runAll() {
        std::cout << "=== MIDI ROUTING TESTS - NO OVERLAP ===" << std::endl;

        testMidiChannelRouting();
        testNoMidiOverlap();
        testMidiToTrackMapping();
        testMidiFiltering();
        testMidiThroughput();

        std::cout << "=== ALL MIDI ROUTING TESTS PASSED ===" << std::endl;
    }

private:
    static void testMidiChannelRouting() {
        std::cout << "Test: MIDI channel routing..." << std::endl;

        MidiProcessor processor;
        juce::MidiBuffer inputBuffer;

        // Create MIDI notes on different channels
        inputBuffer.addEvent(juce::MidiMessage::noteOn(1, 60, 0.8f), 0);
        inputBuffer.addEvent(juce::MidiMessage::noteOn(2, 64, 0.8f), 10);
        inputBuffer.addEvent(juce::MidiMessage::noteOn(3, 67, 0.8f), 20);
        inputBuffer.addEvent(juce::MidiMessage::noteOn(4, 72, 0.8f), 30);

        // Process and verify routing
        juce::MidiBuffer outputBuffer;
        processor.processBlock(inputBuffer, outputBuffer, 512);

        // Count events per channel
        std::map<int, int> channelCounts;
        for (const auto metadata : outputBuffer) {
            auto message = metadata.getMessage();
            if (message.isNoteOn()) {
                channelCounts[message.getChannel()]++;
            }
        }

        assert(channelCounts[1] == 1);
        assert(channelCounts[2] == 1);
        assert(channelCounts[3] == 1);
        assert(channelCounts[4] == 1);

        std::cout << "  PASS: Each MIDI channel routed correctly" << std::endl;
    }

    static void testNoMidiOverlap() {
        std::cout << "Test: No MIDI overlap validation..." << std::endl;

        MidiProcessor processor;
        juce::MidiBuffer buffer;

        // Add overlapping notes (same note, same channel)
        buffer.addEvent(juce::MidiMessage::noteOn(1, 60, 0.8f), 0);
        buffer.addEvent(juce::MidiMessage::noteOn(1, 60, 0.7f), 50);  // Overlap!

        // Process should handle overlap
        juce::MidiBuffer outputBuffer;
        processor.processBlock(buffer, outputBuffer, 512);

        // Verify no duplicate notes active
        std::set<std::pair<int, int>> activeNotes;  // channel, note
        bool overlapDetected = false;

        for (const auto metadata : outputBuffer) {
            auto message = metadata.getMessage();
            if (message.isNoteOn()) {
                auto key = std::make_pair(message.getChannel(), message.getNoteNumber());
                if (activeNotes.count(key) > 0) {
                    overlapDetected = true;
                }
                activeNotes.insert(key);
            } else if (message.isNoteOff()) {
                auto key = std::make_pair(message.getChannel(), message.getNoteNumber());
                activeNotes.erase(key);
            }
        }

        assert(!overlapDetected);
        std::cout << "  PASS: No MIDI overlap detected" << std::endl;
    }

    static void testMidiToTrackMapping() {
        std::cout << "Test: MIDI to track mapping..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);

        // Create 4 tracks
        for (int i = 0; i < 4; ++i) {
            engine.addTrack();
        }

        // Map MIDI channels to tracks
        engine.setMidiChannelMapping(1, 0);  // MIDI ch 1 -> Track 0
        engine.setMidiChannelMapping(2, 1);  // MIDI ch 2 -> Track 1
        engine.setMidiChannelMapping(3, 2);  // MIDI ch 3 -> Track 2
        engine.setMidiChannelMapping(4, 3);  // MIDI ch 4 -> Track 3

        // Create MIDI buffer with notes on different channels
        juce::MidiBuffer midiBuffer;
        midiBuffer.addEvent(juce::MidiMessage::noteOn(1, 60, 0.8f), 0);
        midiBuffer.addEvent(juce::MidiMessage::noteOn(2, 64, 0.8f), 0);
        midiBuffer.addEvent(juce::MidiMessage::noteOn(3, 67, 0.8f), 0);
        midiBuffer.addEvent(juce::MidiMessage::noteOn(4, 72, 0.8f), 0);

        // Process
        juce::AudioBuffer<float> audioBuffer(2, 512);
        engine.processBlock(audioBuffer, midiBuffer);

        // Verify each track received its MIDI
        auto& tracks = engine.getTracks();
        for (int i = 0; i < 4; ++i) {
            assert(tracks[i].hasMidiActivity());
        }

        std::cout << "  PASS: MIDI correctly mapped to tracks" << std::endl;
    }

    static void testMidiFiltering() {
        std::cout << "Test: MIDI filtering..." << std::endl;

        MidiProcessor processor;

        // Enable filtering for specific message types
        processor.setFilterControlChanges(true);
        processor.setFilterPitchBend(true);
        processor.setFilterAftertouch(true);

        juce::MidiBuffer inputBuffer;
        inputBuffer.addEvent(juce::MidiMessage::noteOn(1, 60, 0.8f), 0);
        inputBuffer.addEvent(juce::MidiMessage::controllerEvent(1, 1, 64), 10);
        inputBuffer.addEvent(juce::MidiMessage::pitchWheel(1, 8192), 20);
        inputBuffer.addEvent(juce::MidiMessage::noteOff(1, 60), 30);

        juce::MidiBuffer outputBuffer;
        processor.processBlock(inputBuffer, outputBuffer, 512);

        // Count message types
        int noteCount = 0;
        int ccCount = 0;
        int pitchCount = 0;

        for (const auto metadata : outputBuffer) {
            auto message = metadata.getMessage();
            if (message.isNoteOnOrOff()) noteCount++;
            if (message.isController()) ccCount++;
            if (message.isPitchWheel()) pitchCount++;
        }

        assert(noteCount == 2);  // Note on and off
        assert(ccCount == 0);    // Filtered out
        assert(pitchCount == 0); // Filtered out

        std::cout << "  PASS: MIDI filtering working correctly" << std::endl;
    }

    static void testMidiThroughput() {
        std::cout << "Test: MIDI throughput performance..." << std::endl;

        MidiProcessor processor;
        juce::MidiBuffer buffer;

        // Add 1000 MIDI events
        for (int i = 0; i < 1000; ++i) {
            int channel = (i % 16) + 1;
            int note = 36 + (i % 48);
            int time = i % 512;
            buffer.addEvent(juce::MidiMessage::noteOn(channel, note, 0.8f), time);
        }

        // Measure processing time
        auto start = std::chrono::high_resolution_clock::now();

        juce::MidiBuffer outputBuffer;
        processor.processBlock(buffer, outputBuffer, 512);

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);

        // Should process 1000 events in under 1ms
        assert(duration.count() < 1000);

        std::cout << "  PASS: Processed 1000 MIDI events in "
                  << duration.count() << " microseconds" << std::endl;
    }
};

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;
    MidiRoutingTests::runAll();
    return 0;
}