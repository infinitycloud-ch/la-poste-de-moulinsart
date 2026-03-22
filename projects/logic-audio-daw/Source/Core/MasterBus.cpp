#include "MasterBus.h"

MasterBus::MasterBus() {
    effectsGraph = std::make_unique<juce::AudioProcessorGraph>();
}

MasterBus::~MasterBus() {
}

void MasterBus::prepareToPlay(double sampleRate, int samplesPerBlock) {
    currentSampleRate = sampleRate;
    currentBlockSize = samplesPerBlock;

    effectsGraph->setPlayConfigDetails(2, 2, sampleRate, samplesPerBlock);
    effectsGraph->prepareToPlay(sampleRate, samplesPerBlock);

    effectsGraph->clear();

    auto input = effectsGraph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioInputNode));
    inputNode = input->nodeID;

    auto output = effectsGraph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioOutputNode));
    outputNode = output->nodeID;

    rebuildEffectChain();
}

void MasterBus::releaseResources() {
    effectsGraph->releaseResources();
}

void MasterBus::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    juce::ignoreUnused(midiMessages);

    effectsGraph->processBlock(buffer, midiMessages);

    buffer.applyGain(masterVolume);

    if (limiterEnabled) {
        applyLimiter(buffer);
    }

    updateMeters(buffer);
}

void MasterBus::setMasterVolume(float volume) {
    masterVolume = juce::jlimit(0.0f, 2.0f, volume);
}

void MasterBus::addMasterEffect(std::unique_ptr<juce::AudioProcessor> effect) {
    if (effect) {
        effect->setPlayConfigDetails(2, 2, currentSampleRate, currentBlockSize);
        effect->prepareToPlay(currentSampleRate, currentBlockSize);
        masterEffects.push_back(std::move(effect));
        rebuildEffectChain();
    }
}

void MasterBus::removeMasterEffect(int index) {
    if (index >= 0 && index < masterEffects.size()) {
        if (index < effectNodes.size()) {
            effectsGraph->removeNode(effectNodes[index]);
        }
        masterEffects.erase(masterEffects.begin() + index);
        rebuildEffectChain();
    }
}

void MasterBus::clearMasterEffects() {
    for (auto& node : effectNodes) {
        effectsGraph->removeNode(node);
    }
    masterEffects.clear();
    effectNodes.clear();
    rebuildEffectChain();
}

float MasterBus::getCurrentRMS(int channel) const {
    if (channel == 0) return leftRMS.load();
    if (channel == 1) return rightRMS.load();
    return 0.0f;
}

float MasterBus::getCurrentPeak(int channel) const {
    if (channel == 0) return leftPeak.load();
    if (channel == 1) return rightPeak.load();
    return 0.0f;
}

void MasterBus::applyLimiter(juce::AudioBuffer<float>& buffer) {
    const float threshold = 0.95f;
    const float ratio = 10.0f;
    const float attack = 0.001f;
    const float release = 0.05f;

    static float envelope = 0.0f;

    for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
        auto* channelData = buffer.getWritePointer(ch);

        for (int i = 0; i < buffer.getNumSamples(); ++i) {
            float sample = std::abs(channelData[i]);

            float targetEnv = sample > threshold ? sample : 0.0f;
            float rate = targetEnv > envelope ? attack : release;
            envelope += (targetEnv - envelope) * rate;

            if (envelope > threshold) {
                float gain = threshold + (envelope - threshold) / ratio;
                gain = gain / envelope;
                channelData[i] *= gain;
            }

            channelData[i] = juce::jlimit(-1.0f, 1.0f, channelData[i]);
        }
    }
}

void MasterBus::updateMeters(const juce::AudioBuffer<float>& buffer) {
    if (buffer.getNumChannels() >= 1) {
        leftRMS = buffer.getRMSLevel(0, 0, buffer.getNumSamples());
        leftPeak = buffer.getMagnitude(0, 0, buffer.getNumSamples());
    }

    if (buffer.getNumChannels() >= 2) {
        rightRMS = buffer.getRMSLevel(1, 0, buffer.getNumSamples());
        rightPeak = buffer.getMagnitude(1, 0, buffer.getNumSamples());
    }
}

void MasterBus::rebuildEffectChain() {
    for (auto& node : effectNodes) {
        effectsGraph->removeNode(node);
    }
    effectNodes.clear();

    for (auto& effect : masterEffects) {
        if (effect) {
            auto node = effectsGraph->addNode(effect->createInstanceFromDescription());
            if (node) {
                effectNodes.push_back(node->nodeID);
            }
        }
    }

    effectsGraph->removeIllegalConnections();

    if (effectNodes.empty()) {
        for (int ch = 0; ch < 2; ++ch) {
            effectsGraph->addConnection({{inputNode, ch}, {outputNode, ch}});
        }
    } else {
        for (int ch = 0; ch < 2; ++ch) {
            effectsGraph->addConnection({{inputNode, ch}, {effectNodes.front(), ch}});
        }

        for (size_t i = 0; i < effectNodes.size() - 1; ++i) {
            for (int ch = 0; ch < 2; ++ch) {
                effectsGraph->addConnection({{effectNodes[i], ch}, {effectNodes[i + 1], ch}});
            }
        }

        for (int ch = 0; ch < 2; ++ch) {
            effectsGraph->addConnection({{effectNodes.back(), ch}, {outputNode, ch}});
        }
    }
}

bool MasterBus::exportToWAV(const juce::File& outputFile,
                            juce::AudioBuffer<float>& sourceBuffer,
                            double sampleRate,
                            int bitDepth) {

    juce::WavAudioFormat wavFormat;
    std::unique_ptr<juce::FileOutputStream> fileStream(outputFile.createOutputStream());

    if (!fileStream) {
        return false;
    }

    std::unique_ptr<juce::AudioFormatWriter> writer(
        wavFormat.createWriterFor(fileStream.release(),
                                 sampleRate,
                                 sourceBuffer.getNumChannels(),
                                 bitDepth,
                                 {},
                                 0));

    if (!writer) {
        return false;
    }

    float maxLevel = 0.0f;
    for (int ch = 0; ch < sourceBuffer.getNumChannels(); ++ch) {
        float channelMax = sourceBuffer.getMagnitude(ch, 0, sourceBuffer.getNumSamples());
        if (channelMax > maxLevel) {
            maxLevel = channelMax;
        }
    }

    if (maxLevel > 0.001f && maxLevel < 0.95f) {
        float normalizationGain = 0.95f / maxLevel;
        sourceBuffer.applyGain(normalizationGain);
    }

    writer->writeFromAudioSampleBuffer(sourceBuffer, 0, sourceBuffer.getNumSamples());
    writer->flush();

    return true;
}

bool MasterBus::exportToWAVRealtime(const juce::File& outputFile,
                                   std::function<void(juce::AudioBuffer<float>&, juce::MidiBuffer&)> renderCallback,
                                   double sampleRate,
                                   int lengthInSamples,
                                   int bitDepth) {

    const int blockSize = 512;
    juce::AudioBuffer<float> renderBuffer(2, lengthInSamples);
    renderBuffer.clear();

    prepareToPlay(sampleRate, blockSize);

    int samplesProcessed = 0;
    while (samplesProcessed < lengthInSamples) {
        int samplesToProcess = juce::jmin(blockSize, lengthInSamples - samplesProcessed);

        juce::AudioBuffer<float> tempBuffer(renderBuffer.getArrayOfWritePointers(),
                                           2, samplesProcessed, samplesToProcess);
        juce::MidiBuffer midiBuffer;

        if (renderCallback) {
            renderCallback(tempBuffer, midiBuffer);
        }

        processBlock(tempBuffer, midiBuffer);
        samplesProcessed += samplesToProcess;
    }

    return exportToWAV(outputFile, renderBuffer, sampleRate, bitDepth);
}

void MasterBus::getStateInformation(juce::MemoryBlock& destData) {
    juce::ignoreUnused(destData);
}

void MasterBus::setStateInformation(const void* data, int sizeInBytes) {
    juce::ignoreUnused(data, sizeInBytes);
}