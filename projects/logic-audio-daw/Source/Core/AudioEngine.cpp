#include "AudioEngine.h"

void AudioEngine::TrackGainProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) {
    if (trackRef->muted) {
        buffer.clear();
        trackRef->currentRMS = 0.0f;
        trackRef->currentPeak = 0.0f;
        return;
    }

    buffer.applyGain(trackRef->volume);

    float rms = 0.0f;
    float peak = 0.0f;
    for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
        rms += buffer.getRMSLevel(ch, 0, buffer.getNumSamples());
        float channelPeak = buffer.getMagnitude(ch, 0, buffer.getNumSamples());
        if (channelPeak > peak) peak = channelPeak;
    }

    if (buffer.getNumChannels() > 0) {
        rms /= buffer.getNumChannels();
    }

    trackRef->currentRMS = rms;
    trackRef->currentPeak = peak;
}

AudioEngine::AudioEngine() {
    graph = std::make_unique<juce::AudioProcessorGraph>();
}

AudioEngine::~AudioEngine() {
}

void AudioEngine::prepareToPlay(double sampleRate, int samplesPerBlock) {
    graph->setPlayConfigDetails(2, 2, sampleRate, samplesPerBlock);
    graph->prepareToPlay(sampleRate, samplesPerBlock);

    graph->clear();

    audioInputNode = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioInputNode))->nodeID;

    midiInputNode = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::midiInputNode))->nodeID;

    masterInputNode = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioOutputNode))->nodeID;

    masterOutputNode = graph->addNode(std::make_unique<juce::AudioProcessorGraph::AudioGraphIOProcessor>(
        juce::AudioProcessorGraph::AudioGraphIOProcessor::audioOutputNode))->nodeID;

    for (int ch = 0; ch < 2; ++ch) {
        graph->addConnection({{masterInputNode, ch}, {masterOutputNode, ch}});
    }
}

void AudioEngine::releaseResources() {
    graph->releaseResources();
}

void AudioEngine::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    for (auto& track : tracks) {
        if (track.armed && !track.muted) {
            track.midiBuffer = midiMessages;
        } else {
            track.midiBuffer.clear();
        }
    }

    graph->processBlock(buffer, midiMessages);
    updateVUMeters();
}

void AudioEngine::addTrack() {
    tracks.emplace_back();
}

void AudioEngine::addInstrumentToTrack(int trackIndex, std::unique_ptr<juce::AudioProcessor> instrument) {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        auto& track = tracks[trackIndex];

        if (track.instrumentNode.uid != 0) {
            graph->removeNode(track.instrumentNode);
        }

        auto node = graph->addNode(std::move(instrument));
        track.instrumentNode = node->nodeID;

        rebuildTrackChain(trackIndex);
    }
}

void AudioEngine::addFXToTrack(int trackIndex, std::unique_ptr<juce::AudioProcessor> effect) {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        auto& track = tracks[trackIndex];

        auto node = graph->addNode(std::move(effect));
        track.fxNodes.push_back(node->nodeID);

        rebuildTrackChain(trackIndex);
    }
}

void AudioEngine::rebuildTrackChain(int trackIndex) {
    if (trackIndex < 0 || trackIndex >= tracks.size()) return;

    auto& track = tracks[trackIndex];

    if (track.gainNode.uid != 0) {
        graph->removeNode(track.gainNode);
    }
    auto gainProcessor = std::make_unique<TrackGainProcessor>(&track);
    auto gainNode = graph->addNode(std::move(gainProcessor));
    track.gainNode = gainNode->nodeID;

    juce::AudioProcessorGraph::NodeID previousNode = track.instrumentNode;

    if (track.instrumentNode.uid != 0) {
        graph->addConnection({{midiInputNode, juce::AudioProcessorGraph::midiChannelIndex},
                             {track.instrumentNode, juce::AudioProcessorGraph::midiChannelIndex}});
    }

    for (const auto& fxNode : track.fxNodes) {
        if (previousNode.uid != 0 && fxNode.uid != 0) {
            for (int ch = 0; ch < 2; ++ch) {
                graph->addConnection({{previousNode, ch}, {fxNode, ch}});
            }
        }
        previousNode = fxNode;
    }

    if (previousNode.uid != 0 && track.gainNode.uid != 0) {
        for (int ch = 0; ch < 2; ++ch) {
            graph->addConnection({{previousNode, ch}, {track.gainNode, ch}});
        }
    }

    connectTrackToMaster(trackIndex);
}

void AudioEngine::connectTrackToMaster(int trackIndex) {
    if (trackIndex < 0 || trackIndex >= tracks.size()) return;

    auto& track = tracks[trackIndex];

    if (track.gainNode.uid != 0 && masterInputNode.uid != 0) {
        for (int ch = 0; ch < 2; ++ch) {
            graph->addConnection({{track.gainNode, ch}, {masterInputNode, ch}});
        }
    }
}

void AudioEngine::setTrackVolume(int trackIndex, float volume) {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        tracks[trackIndex].volume = juce::jlimit(0.0f, 1.0f, volume);
    }
}

void AudioEngine::setTrackMute(int trackIndex, bool muted) {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        tracks[trackIndex].muted = muted;
    }
}

float AudioEngine::getTrackRMS(int trackIndex) const {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        return tracks[trackIndex].currentRMS.load();
    }
    return 0.0f;
}

float AudioEngine::getTrackPeak(int trackIndex) const {
    if (trackIndex >= 0 && trackIndex < tracks.size()) {
        return tracks[trackIndex].currentPeak.load();
    }
    return 0.0f;
}

void AudioEngine::updateVUMeters() {
}

bool AudioEngine::exportToWAV(const juce::File& outputFile) {
    const int sampleRate = 44100;
    const int blockSize = 512;
    const int totalSamples = sampleRate * 10;

    juce::AudioBuffer<float> renderBuffer(2, totalSamples);
    renderBuffer.clear();

    graph->prepareToPlay(sampleRate, blockSize);

    int samplesProcessed = 0;
    while (samplesProcessed < totalSamples) {
        int samplesToProcess = juce::jmin(blockSize, totalSamples - samplesProcessed);

        juce::AudioBuffer<float> tempBuffer(renderBuffer.getArrayOfWritePointers(),
                                           2, samplesProcessed, samplesToProcess);
        juce::MidiBuffer midiBuffer;

        midiBuffer.addEvent(juce::MidiMessage::noteOn(1, 60, (juce::uint8)100), 0);

        graph->processBlock(tempBuffer, midiBuffer);
        samplesProcessed += samplesToProcess;
    }

    std::unique_ptr<juce::AudioFormatWriter> writer(
        juce::WavAudioFormat().createWriterFor(new juce::FileOutputStream(outputFile),
                                               sampleRate, 2, 16, {}, 0));

    if (writer != nullptr) {
        writer->writeFromAudioSampleBuffer(renderBuffer, 0, totalSamples);
        return true;
    }

    return false;
}

void AudioEngine::getStateInformation(juce::MemoryBlock& destData) {
    juce::ignoreUnused(destData);
}

void AudioEngine::setStateInformation(const void* data, int sizeInBytes) {
    juce::ignoreUnused(data, sizeInBytes);
}

juce::AudioProcessorEditor* AudioEngine::createEditor() {
    return nullptr;
}