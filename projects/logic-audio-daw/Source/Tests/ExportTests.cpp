#include "../Core/AudioEngine.h"
#include "../Core/WavExporter.h"
#include <iostream>
#include <cassert>
#include <cstring>

struct WAVHeader {
    char riff[4];
    uint32_t fileSize;
    char wave[4];
    char fmt[4];
    uint32_t fmtSize;
    uint16_t audioFormat;
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t byteRate;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
    char data[4];
    uint32_t dataSize;
};

class ExportTests {
public:
    static void runAll() {
        std::cout << "=== EXPORT WAV VALIDATION TESTS ===" << std::endl;

        testWAVHeaderFormat();
        testSampleRateExport();
        testMultiChannelExport();
        testBitDepthExport();
        testLargeFileExport();

        std::cout << "=== ALL EXPORT TESTS PASSED ===" << std::endl;
    }

private:
    static void testWAVHeaderFormat() {
        std::cout << "Test: WAV header format validation..." << std::endl;

        AudioEngine engine;
        engine.prepareToPlay(44100, 512);
        engine.addTrack();

        // Generate test signal
        juce::AudioBuffer<float> testBuffer(2, 44100);
        for (int ch = 0; ch < 2; ++ch) {
            auto* data = testBuffer.getWritePointer(ch);
            for (int i = 0; i < 44100; ++i) {
                data[i] = std::sin(2.0f * M_PI * 440.0f * i / 44100.0f) * 0.5f;
            }
        }

        // Export to WAV
        juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                          .getChildFile("test_export_validation.wav");

        WavExporter exporter;
        bool success = exporter.exportBuffer(testBuffer, exportFile, 44100, 16);
        assert(success);

        // Read and validate header
        juce::FileInputStream stream(exportFile);
        WAVHeader header;
        stream.read(&header, sizeof(WAVHeader));

        // Validate RIFF chunk
        assert(std::memcmp(header.riff, "RIFF", 4) == 0);
        assert(std::memcmp(header.wave, "WAVE", 4) == 0);

        // Validate fmt chunk
        assert(std::memcmp(header.fmt, "fmt ", 4) == 0);
        assert(header.fmtSize == 16);
        assert(header.audioFormat == 1);  // PCM

        // Validate audio format
        assert(header.numChannels == 2);
        assert(header.sampleRate == 44100);
        assert(header.bitsPerSample == 16);
        assert(header.byteRate == 44100 * 2 * 2);  // sampleRate * channels * bytes

        // Validate data chunk
        assert(std::memcmp(header.data, "data", 4) == 0);

        exportFile.deleteFile();

        std::cout << "  PASS: WAV header format correct" << std::endl;
    }

    static void testSampleRateExport() {
        std::cout << "Test: Multiple sample rate export..." << std::endl;

        std::vector<uint32_t> sampleRates = {22050, 44100, 48000, 96000};
        WavExporter exporter;

        for (uint32_t rate : sampleRates) {
            // Create test buffer
            int numSamples = rate;  // 1 second
            juce::AudioBuffer<float> buffer(2, numSamples);

            // Generate test tone
            for (int ch = 0; ch < 2; ++ch) {
                auto* data = buffer.getWritePointer(ch);
                for (int i = 0; i < numSamples; ++i) {
                    data[i] = std::sin(2.0f * M_PI * 1000.0f * i / rate) * 0.3f;
                }
            }

            // Export
            juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                              .getChildFile("test_" + juce::String(rate) + "hz.wav");

            bool success = exporter.exportBuffer(buffer, exportFile, rate, 16);
            assert(success);

            // Verify file size
            int expectedDataSize = numSamples * 2 * 2;  // samples * channels * bytes
            int expectedFileSize = 44 + expectedDataSize;  // header + data

            assert(exportFile.getSize() == expectedFileSize);

            exportFile.deleteFile();
        }

        std::cout << "  PASS: All sample rates exported correctly" << std::endl;
    }

    static void testMultiChannelExport() {
        std::cout << "Test: Multi-channel export..." << std::endl;

        WavExporter exporter;

        // Test mono, stereo, and multi-channel
        std::vector<int> channelCounts = {1, 2, 4, 6};

        for (int channels : channelCounts) {
            juce::AudioBuffer<float> buffer(channels, 44100);

            // Generate different signal for each channel
            for (int ch = 0; ch < channels; ++ch) {
                auto* data = buffer.getWritePointer(ch);
                float freq = 220.0f * (ch + 1);
                for (int i = 0; i < 44100; ++i) {
                    data[i] = std::sin(2.0f * M_PI * freq * i / 44100.0f) * 0.2f;
                }
            }

            juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                              .getChildFile("test_" + juce::String(channels) + "ch.wav");

            bool success = exporter.exportBuffer(buffer, exportFile, 44100, 16);
            assert(success);

            // Verify header shows correct channel count
            juce::FileInputStream stream(exportFile);
            WAVHeader header;
            stream.read(&header, sizeof(WAVHeader));

            assert(header.numChannels == channels);

            exportFile.deleteFile();
        }

        std::cout << "  PASS: Multi-channel export successful" << std::endl;
    }

    static void testBitDepthExport() {
        std::cout << "Test: Bit depth export validation..." << std::endl;

        WavExporter exporter;
        std::vector<int> bitDepths = {16, 24, 32};

        for (int bits : bitDepths) {
            juce::AudioBuffer<float> buffer(2, 44100);

            // Generate test signal with full dynamic range
            for (int ch = 0; ch < 2; ++ch) {
                auto* data = buffer.getWritePointer(ch);
                for (int i = 0; i < 44100; ++i) {
                    // Use different amplitude to test bit depth
                    float amplitude = (bits == 16) ? 0.9f : (bits == 24) ? 0.99f : 1.0f;
                    data[i] = std::sin(2.0f * M_PI * 440.0f * i / 44100.0f) * amplitude;
                }
            }

            juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                              .getChildFile("test_" + juce::String(bits) + "bit.wav");

            bool success = exporter.exportBuffer(buffer, exportFile, 44100, bits);
            assert(success);

            // Verify bit depth in header
            juce::FileInputStream stream(exportFile);
            WAVHeader header;
            stream.read(&header, sizeof(WAVHeader));

            assert(header.bitsPerSample == bits);

            // Verify file size matches bit depth
            int bytesPerSample = bits / 8;
            int expectedDataSize = 44100 * 2 * bytesPerSample;
            assert(header.dataSize == expectedDataSize);

            exportFile.deleteFile();
        }

        std::cout << "  PASS: All bit depths exported correctly" << std::endl;
    }

    static void testLargeFileExport() {
        std::cout << "Test: Large file export (10 seconds)..." << std::endl;

        WavExporter exporter;

        // Create 10 second buffer
        int numSamples = 44100 * 10;
        juce::AudioBuffer<float> buffer(2, numSamples);

        // Generate varying test signal
        for (int ch = 0; ch < 2; ++ch) {
            auto* data = buffer.getWritePointer(ch);
            for (int i = 0; i < numSamples; ++i) {
                // Sweep frequency over time
                float t = static_cast<float>(i) / 44100.0f;
                float freq = 220.0f + (880.0f - 220.0f) * (t / 10.0f);
                data[i] = std::sin(2.0f * M_PI * freq * i / 44100.0f) * 0.5f;
            }
        }

        juce::File exportFile = juce::File::getSpecialLocation(juce::File::tempDirectory)
                                          .getChildFile("test_large_10sec.wav");

        auto startTime = std::chrono::high_resolution_clock::now();

        bool success = exporter.exportBuffer(buffer, exportFile, 44100, 16);
        assert(success);

        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);

        // Should export 10 seconds in under 500ms
        assert(duration.count() < 500);

        // Verify file size
        int expectedDataSize = numSamples * 2 * 2;  // samples * channels * bytes
        int expectedFileSize = 44 + expectedDataSize;  // header + data
        assert(std::abs(static_cast<int>(exportFile.getSize()) - expectedFileSize) < 100);

        exportFile.deleteFile();

        std::cout << "  PASS: Large file exported in " << duration.count() << "ms" << std::endl;
    }
};

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;
    ExportTests::runAll();
    return 0;
}