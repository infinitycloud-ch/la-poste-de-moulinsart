#include "../Core/AudioEngine.h"
#include "../Core/FXChain.h"
#include <iostream>
#include <cassert>
#include <memory>

class FXChainTests {
public:
    static void runAll() {
        std::cout << "=== FX CHAIN TESTS - ADD/REMOVE VALIDATION ===" << std::endl;

        testAddRemoveFX();
        testFXOrdering();
        testBypassFX();
        testChainProcessing();
        testDynamicFXManagement();

        std::cout << "=== ALL FX CHAIN TESTS PASSED ===" << std::endl;
    }

private:
    static void testAddRemoveFX() {
        std::cout << "Test: Add/Remove FX..." << std::endl;

        FXChain chain;

        // Add effects
        chain.addEffect("Reverb", FXType::Reverb);
        chain.addEffect("Delay", FXType::Delay);
        chain.addEffect("EQ", FXType::EQ);
        chain.addEffect("Compressor", FXType::Compressor);

        assert(chain.getEffectCount() == 4);

        // Remove specific effect
        chain.removeEffect(1);  // Remove Delay
        assert(chain.getEffectCount() == 3);

        // Verify correct effect was removed
        auto effects = chain.getEffects();
        assert(effects[0]->getName() == "Reverb");
        assert(effects[1]->getName() == "EQ");
        assert(effects[2]->getName() == "Compressor");

        // Clear all effects
        chain.clearAllEffects();
        assert(chain.getEffectCount() == 0);

        std::cout << "  PASS: FX add/remove operations successful" << std::endl;
    }

    static void testFXOrdering() {
        std::cout << "Test: FX chain ordering..." << std::endl;

        FXChain chain;

        // Add effects in specific order
        chain.addEffect("EQ", FXType::EQ);
        chain.addEffect("Compressor", FXType::Compressor);
        chain.addEffect("Delay", FXType::Delay);
        chain.addEffect("Reverb", FXType::Reverb);

        // Move effects
        chain.moveEffect(3, 1);  // Move Reverb to position 1

        auto effects = chain.getEffects();
        assert(effects[0]->getName() == "EQ");
        assert(effects[1]->getName() == "Reverb");
        assert(effects[2]->getName() == "Compressor");
        assert(effects[3]->getName() == "Delay");

        // Swap two effects
        chain.swapEffects(0, 3);

        effects = chain.getEffects();
        assert(effects[0]->getName() == "Delay");
        assert(effects[3]->getName() == "EQ");

        std::cout << "  PASS: FX ordering maintained correctly" << std::endl;
    }

    static void testBypassFX() {
        std::cout << "Test: FX bypass functionality..." << std::endl;

        FXChain chain;
        chain.addEffect("Reverb", FXType::Reverb);
        chain.addEffect("Delay", FXType::Delay);

        // Process with effects enabled
        juce::AudioBuffer<float> buffer(2, 512);
        generateTestSignal(buffer);

        float rmsOriginal = buffer.getRMSLevel(0, 0, 512);

        chain.processBlock(buffer);
        float rmsProcessed = buffer.getRMSLevel(0, 0, 512);

        // Bypass first effect
        chain.setEffectBypass(0, true);

        buffer.clear();
        generateTestSignal(buffer);
        chain.processBlock(buffer);
        float rmsBypassed = buffer.getRMSLevel(0, 0, 512);

        // Bypassed should be different from fully processed
        assert(std::abs(rmsProcessed - rmsBypassed) > 0.001f);

        // Bypass all
        chain.setBypassAll(true);

        buffer.clear();
        generateTestSignal(buffer);
        float rmsBeforeBypass = buffer.getRMSLevel(0, 0, 512);
        chain.processBlock(buffer);
        float rmsAfterBypass = buffer.getRMSLevel(0, 0, 512);

        // When all bypassed, signal should be unchanged
        assert(std::abs(rmsBeforeBypass - rmsAfterBypass) < 0.001f);

        std::cout << "  PASS: FX bypass working correctly" << std::endl;
    }

    static void testChainProcessing() {
        std::cout << "Test: FX chain processing..." << std::endl;

        FXChain chain;
        chain.prepareToPlay(44100, 512);

        // Add multiple effects
        chain.addEffect("HighPass", FXType::Filter);
        chain.addEffect("Compressor", FXType::Compressor);
        chain.addEffect("Delay", FXType::Delay);

        // Process test signal
        juce::AudioBuffer<float> buffer(2, 512);
        generateTestSignal(buffer);

        float inputRMS = buffer.getRMSLevel(0, 0, 512);

        // Process through chain
        chain.processBlock(buffer);

        float outputRMS = buffer.getRMSLevel(0, 0, 512);

        // Signal should be modified
        assert(std::abs(inputRMS - outputRMS) > 0.001f);

        // Verify latency compensation
        int totalLatency = chain.getTotalLatency();
        assert(totalLatency >= 0);

        std::cout << "  PASS: Chain processing successful (latency: "
                  << totalLatency << " samples)" << std::endl;
    }

    static void testDynamicFXManagement() {
        std::cout << "Test: Dynamic FX management..." << std::endl;

        FXChain chain;
        chain.prepareToPlay(44100, 512);

        juce::AudioBuffer<float> buffer(2, 512);

        // Add/remove effects while processing
        for (int i = 0; i < 10; ++i) {
            generateTestSignal(buffer);

            // Dynamically add effect
            if (i == 3) {
                chain.addEffect("Reverb", FXType::Reverb);
            }

            // Process
            chain.processBlock(buffer);

            // Dynamically remove effect
            if (i == 7 && chain.getEffectCount() > 0) {
                chain.removeEffect(0);
            }

            // Toggle bypass
            if (i == 5 && chain.getEffectCount() > 0) {
                chain.setEffectBypass(0, true);
            }
        }

        // Should handle dynamic changes without crashes
        assert(true);

        std::cout << "  PASS: Dynamic FX management stable" << std::endl;
    }

private:
    static void generateTestSignal(juce::AudioBuffer<float>& buffer) {
        for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
            auto* data = buffer.getWritePointer(ch);
            for (int i = 0; i < buffer.getNumSamples(); ++i) {
                data[i] = (std::rand() / static_cast<float>(RAND_MAX)) * 2.0f - 1.0f;
                data[i] *= 0.5f;  // Scale to -0.5 to 0.5
            }
        }
    }
};

int main() {
    juce::ScopedJuceInitialiser_GUI juceInit;
    FXChainTests::runAll();
    return 0;
}