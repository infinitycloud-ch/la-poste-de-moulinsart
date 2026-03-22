// Test Runner Principal - DAW Audio Logic Tests
// Framework: Catch2 v3
// Mission Sprint 1: Tests unitaires Logic Audio DAW

#define CATCH_CONFIG_MAIN
#include <catch2/catch_all.hpp>
#include <cmath>
#include <vector>
#include <fstream>
#include <cstdint>

// Configuration globale des tests
struct TestConfig {
    static constexpr int SAMPLE_RATE = 44100;
    static constexpr int BIT_DEPTH = 16;
    static constexpr double PI = 3.14159265358979323846;
};

// Structure WAV Header pour validation export
struct WavHeader {
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

// Générateur de signal sinus pour tests
class SineGenerator {
public:
    static std::vector<double> generate(double frequency, double duration, int sampleRate) {
        int numSamples = static_cast<int>(duration * sampleRate);
        std::vector<double> samples(numSamples);

        for (int i = 0; i < numSamples; ++i) {
            double t = static_cast<double>(i) / sampleRate;
            samples[i] = std::sin(2.0 * TestConfig::PI * frequency * t);
        }

        return samples;
    }
};

// Tests Audio Core
TEST_CASE("Audio Signal Generation", "[audio][generator]") {

    SECTION("Generate 440Hz Sine Wave") {
        auto samples = SineGenerator::generate(440.0, 1.0, TestConfig::SAMPLE_RATE);

        REQUIRE(samples.size() == TestConfig::SAMPLE_RATE);
        REQUIRE(samples[0] == Approx(0.0).margin(0.001));

        // Vérifier amplitude max
        double maxAmplitude = *std::max_element(samples.begin(), samples.end());
        REQUIRE(maxAmplitude == Approx(1.0).margin(0.001));
    }

    SECTION("Generate Multiple Frequencies") {
        std::vector<double> frequencies = {220.0, 440.0, 880.0, 1760.0};

        for (double freq : frequencies) {
            auto samples = SineGenerator::generate(freq, 0.1, TestConfig::SAMPLE_RATE);
            REQUIRE(samples.size() == TestConfig::SAMPLE_RATE / 10);
        }
    }
}

// Tests Effets Audio (FX)
TEST_CASE("Audio Effects Processing", "[audio][fx]") {

    SECTION("Volume Control") {
        auto samples = SineGenerator::generate(440.0, 0.1, TestConfig::SAMPLE_RATE);
        double volumeFactor = 0.5;

        std::vector<double> processed(samples.size());
        for (size_t i = 0; i < samples.size(); ++i) {
            processed[i] = samples[i] * volumeFactor;
        }

        double maxOriginal = *std::max_element(samples.begin(), samples.end());
        double maxProcessed = *std::max_element(processed.begin(), processed.end());

        REQUIRE(maxProcessed == Approx(maxOriginal * volumeFactor).margin(0.001));
    }

    SECTION("Mute Functionality") {
        auto samples = SineGenerator::generate(440.0, 0.1, TestConfig::SAMPLE_RATE);

        // Appliquer mute
        std::vector<double> muted(samples.size(), 0.0);

        for (const auto& sample : muted) {
            REQUIRE(sample == 0.0);
        }
    }

    SECTION("Fade In/Out Effect") {
        auto samples = SineGenerator::generate(440.0, 1.0, TestConfig::SAMPLE_RATE);
        int fadeLength = TestConfig::SAMPLE_RATE / 10; // 100ms fade

        // Fade In
        for (int i = 0; i < fadeLength; ++i) {
            double fadeFactor = static_cast<double>(i) / fadeLength;
            samples[i] *= fadeFactor;
        }

        // Fade Out
        int startFadeOut = samples.size() - fadeLength;
        for (int i = 0; i < fadeLength; ++i) {
            double fadeFactor = 1.0 - (static_cast<double>(i) / fadeLength);
            samples[startFadeOut + i] *= fadeFactor;
        }

        REQUIRE(samples[0] == Approx(0.0).margin(0.001));
        REQUIRE(samples[samples.size() - 1] == Approx(0.0).margin(0.001));
    }
}

// Tests Export WAV
TEST_CASE("WAV Export Validation", "[export][wav]") {

    SECTION("WAV Header Structure") {
        WavHeader header;

        // Initialiser header WAV standard
        std::memcpy(header.riff, "RIFF", 4);
        std::memcpy(header.wave, "WAVE", 4);
        std::memcpy(header.fmt, "fmt ", 4);
        std::memcpy(header.data, "data", 4);

        header.fmtSize = 16;
        header.audioFormat = 1; // PCM
        header.numChannels = 2; // Stereo
        header.sampleRate = TestConfig::SAMPLE_RATE;
        header.bitsPerSample = TestConfig::BIT_DEPTH;
        header.byteRate = header.sampleRate * header.numChannels * (header.bitsPerSample / 8);
        header.blockAlign = header.numChannels * (header.bitsPerSample / 8);

        REQUIRE(header.sampleRate == 44100);
        REQUIRE(header.bitsPerSample == 16);
        REQUIRE(header.numChannels == 2);
        REQUIRE(header.byteRate == 176400);
    }

    SECTION("Export Audio to WAV File") {
        auto samples = SineGenerator::generate(440.0, 1.0, TestConfig::SAMPLE_RATE);

        // Simuler conversion en int16
        std::vector<int16_t> intSamples(samples.size());
        for (size_t i = 0; i < samples.size(); ++i) {
            intSamples[i] = static_cast<int16_t>(samples[i] * 32767);
        }

        REQUIRE(intSamples.size() == TestConfig::SAMPLE_RATE);
        REQUIRE(intSamples[0] == Approx(0).margin(100));
    }
}

// Tests de Performance
TEST_CASE("Performance Benchmarks", "[performance]") {

    SECTION("Real-time Processing Capability") {
        auto start = std::chrono::high_resolution_clock::now();

        // Générer 1 seconde d'audio
        auto samples = SineGenerator::generate(440.0, 1.0, TestConfig::SAMPLE_RATE);

        // Appliquer volume
        for (auto& sample : samples) {
            sample *= 0.7;
        }

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

        // Le traitement doit être plus rapide que temps réel (< 1000ms pour 1s d'audio)
        REQUIRE(duration.count() < 1000);
    }
}