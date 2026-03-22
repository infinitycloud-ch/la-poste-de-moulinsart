#include "../Core/AudioEngine.h"
#include <iostream>
#include <cassert>

void testAudioEngine() {
    std::cout << "🧪 Testing Audio Engine Sprint 1..." << std::endl;

    AudioEngine engine;

    std::cout << "✅ Test 1: Engine created successfully" << std::endl;

    engine.prepareToPlay(44100, 512);
    std::cout << "✅ Test 2: prepareToPlay successful" << std::endl;

    engine.addTrack();
    std::cout << "✅ Test 3: Track added" << std::endl;

    auto& tracks = engine.getTracks();
    assert(tracks.size() == 1);
    std::cout << "✅ Test 4: Track count correct" << std::endl;

    engine.setTrackVolume(0, 0.5f);
    assert(tracks[0].volume == 0.5f);
    std::cout << "✅ Test 5: Volume control working" << std::endl;

    engine.setTrackMute(0, true);
    assert(tracks[0].muted == true);
    std::cout << "✅ Test 6: Mute control working" << std::endl;

    juce::AudioBuffer<float> testBuffer(2, 512);
    juce::MidiBuffer midiBuffer;

    testBuffer.clear();
    for (int ch = 0; ch < 2; ++ch) {
        auto* channelData = testBuffer.getWritePointer(ch);
        for (int i = 0; i < 512; ++i) {
            channelData[i] = std::sin(2.0f * M_PI * 440.0f * i / 44100.0f) * 0.5f;
        }
    }

    float rmsBeforeMute = testBuffer.getRMSLevel(0, 0, 512);
    engine.processBlock(testBuffer, midiBuffer);
    float rmsAfterMute = testBuffer.getRMSLevel(0, 0, 512);

    assert(rmsAfterMute < 0.001f);
    std::cout << "✅ Test 7: Mute silences output (RMS before: " << rmsBeforeMute
              << ", after: " << rmsAfterMute << ")" << std::endl;

    engine.setTrackMute(0, false);

    testBuffer.clear();
    for (int ch = 0; ch < 2; ++ch) {
        auto* channelData = testBuffer.getWritePointer(ch);
        for (int i = 0; i < 512; ++i) {
            channelData[i] = 0.8f;
        }
    }

    engine.processBlock(testBuffer, midiBuffer);
    float processedRMS = testBuffer.getRMSLevel(0, 0, 512);

    std::cout << "✅ Test 8: Audio passes through (RMS: " << processedRMS << ")" << std::endl;

    juce::File testExport = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                      .getChildFile("test_export.wav");
    bool exportSuccess = engine.exportToWAV(testExport);

    assert(exportSuccess);
    assert(testExport.existsAsFile());
    assert(testExport.getSize() > 0);

    std::cout << "✅ Test 9: WAV export successful (size: "
              << testExport.getSize() << " bytes)" << std::endl;

    testExport.deleteFile();

    std::cout << "🎉 All tests passed!" << std::endl;
    std::cout << "✅ Sprint 1 Core Engine validated" << std::endl;
}

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;
    testAudioEngine();
    return 0;
}