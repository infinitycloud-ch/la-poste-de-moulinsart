#include "FXChain.h"

FXChain::FXChain() {
    graph = std::make_unique<juce::AudioProcessorGraph>();
}

FXChain::~FXChain() {
}

void FXChain::prepareToPlay(double sampleRate, int samplesPerBlock) {
    currentSampleRate = sampleRate;
    currentBlockSize = samplesPerBlock;

    graph->setPlayConfigDetails(2, 2, sampleRate, samplesPerBlock);
    graph->prepareToPlay(sampleRate, samplesPerBlock);

    graph->clear();

    auto input = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioInputNode));
    inputNode = input->nodeID;

    auto output = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioOutputNode));
    outputNode = output->nodeID;

    rebuildChain();
}

void FXChain::releaseResources() {
    graph->releaseResources();
}

void FXChain::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    graph->processBlock(buffer, midiMessages);
}

void FXChain::addEffect(std::unique_ptr<juce::AudioProcessor> effect) {
    if (effect) {
        effect->setPlayConfigDetails(2, 2, currentSampleRate, currentBlockSize);
        effect->prepareToPlay(currentSampleRate, currentBlockSize);

        effects.push_back(std::move(effect));
        bypassStates.push_back(false);

        rebuildChain();
    }
}

void FXChain::removeEffect(int index) {
    if (index >= 0 && index < effects.size()) {
        effects.erase(effects.begin() + index);
        bypassStates.erase(bypassStates.begin() + index);

        if (index < effectNodes.size()) {
            graph->removeNode(effectNodes[index]);
            effectNodes.erase(effectNodes.begin() + index);
        }

        rebuildChain();
    }
}

void FXChain::moveEffect(int from, int to) {
    if (from >= 0 && from < effects.size() && to >= 0 && to < effects.size() && from != to) {
        std::swap(effects[from], effects[to]);
        std::swap(bypassStates[from], bypassStates[to]);
        rebuildChain();
    }
}

void FXChain::clearEffects() {
    for (auto& node : effectNodes) {
        graph->removeNode(node);
    }

    effects.clear();
    effectNodes.clear();
    bypassStates.clear();

    connectNodes();
}

void FXChain::bypassEffect(int index, bool shouldBypass) {
    if (index >= 0 && index < bypassStates.size()) {
        bypassStates[index] = shouldBypass;
        rebuildChain();
    }
}

juce::AudioProcessor* FXChain::getEffect(int index) {
    if (index >= 0 && index < effects.size()) {
        return effects[index].get();
    }
    return nullptr;
}

void FXChain::rebuildChain() {
    for (auto& node : effectNodes) {
        graph->removeNode(node);
    }
    effectNodes.clear();

    for (size_t i = 0; i < effects.size(); ++i) {
        if (!bypassStates[i] && effects[i]) {
            auto node = graph->addNode(effects[i]->createInstanceFromDescription());
            if (node) {
                effectNodes.push_back(node->nodeID);
            }
        }
    }

    connectNodes();
}

void FXChain::connectNodes() {
    graph->removeIllegalConnections();

    if (effectNodes.empty()) {
        for (int ch = 0; ch < 2; ++ch) {
            graph->addConnection({{inputNode, ch}, {outputNode, ch}});
        }
    } else {
        for (int ch = 0; ch < 2; ++ch) {
            graph->addConnection({{inputNode, ch}, {effectNodes.front(), ch}});
        }

        for (size_t i = 0; i < effectNodes.size() - 1; ++i) {
            for (int ch = 0; ch < 2; ++ch) {
                graph->addConnection({{effectNodes[i], ch}, {effectNodes[i + 1], ch}});
            }
        }

        for (int ch = 0; ch < 2; ++ch) {
            graph->addConnection({{effectNodes.back(), ch}, {outputNode, ch}});
        }
    }
}

void FXChain::getStateInformation(juce::MemoryBlock& destData) {
    juce::ignoreUnused(destData);
}

void FXChain::setStateInformation(const void* data, int sizeInBytes) {
    juce::ignoreUnused(data, sizeInBytes);
}