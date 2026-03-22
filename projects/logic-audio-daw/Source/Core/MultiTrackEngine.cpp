#include "MultiTrackEngine.h"

MultiTrackEngine::MultiTrackEngine() {
    masterBus = std::make_unique<MasterBus>();

    for (int i = 0; i < 4; ++i) {
        addTrack();
    }
}

MultiTrackEngine::~MultiTrackEngine() {
}

void MultiTrackEngine::prepareToPlay(double sampleRate, int samplesPerBlock) {
    currentSampleRate = sampleRate;
    currentBlockSize = samplesPerBlock;

    masterBus->prepareToPlay(sampleRate, samplesPerBlock);

    trackBuffers.clear();
    trackBuffers.resize(tracks.size());

    for (size_t i = 0; i < tracks.size(); ++i) {
        trackBuffers[i].setSize(2, samplesPerBlock);

        if (tracks[i]->getInstrument()) {
            tracks[i]->getInstrument()->prepareToPlay(sampleRate, samplesPerBlock);
        }

        for (int fx = 0; fx < tracks[i]->getNumEffects(); ++fx) {
            if (auto* effect = tracks[i]->getEffect(fx)) {
                effect->prepareToPlay(sampleRate, samplesPerBlock);
            }
        }
    }

    mixBuffer.setSize(2, samplesPerBlock);
}

void MultiTrackEngine::releaseResources() {
    masterBus->releaseResources();

    for (auto& track : tracks) {
        if (track->getInstrument()) {
            track->getInstrument()->releaseResources();
        }

        for (int fx = 0; fx < track->getNumEffects(); ++fx) {
            if (auto* effect = track->getEffect(fx)) {
                effect->releaseResources();
            }
        }
    }
}

void MultiTrackEngine::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    buffer.clear();
    mixBuffer.clear();

    midiRouter.routeMidiToTracks(midiMessages, *reinterpret_cast<std::vector<Track>*>(&tracks));

    updateSoloStates();

    for (size_t i = 0; i < tracks.size(); ++i) {
        if (i >= trackBuffers.size()) continue;

        trackBuffers[i].clear();

        if (!tracks[i]->isMuted() && (!anySolo || soloStates[i])) {
            juce::MidiBuffer trackMidi = tracks[i]->getMidiBuffer();
            tracks[i]->processBlock(trackBuffers[i], trackMidi);

            for (int ch = 0; ch < mixBuffer.getNumChannels(); ++ch) {
                mixBuffer.addFrom(ch, 0, trackBuffers[i], ch, 0, trackBuffers[i].getNumSamples());
            }
        }

        tracks[i]->clearMidiBuffer();
    }

    masterBus->processBlock(mixBuffer, midiMessages);

    for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
        buffer.copyFrom(ch, 0, mixBuffer, ch, 0, buffer.getNumSamples());
    }
}

void MultiTrackEngine::addTrack() {
    auto newTrack = std::make_unique<Track>();
    tracks.push_back(std::move(newTrack));
    soloStates.push_back(false);

    if (trackBuffers.size() < tracks.size()) {
        trackBuffers.resize(tracks.size());
        trackBuffers.back().setSize(2, currentBlockSize);
    }
}

void MultiTrackEngine::removeTrack(int index) {
    if (index >= 0 && index < tracks.size()) {
        tracks.erase(tracks.begin() + index);
        soloStates.erase(soloStates.begin() + index);

        if (index < trackBuffers.size()) {
            trackBuffers.erase(trackBuffers.begin() + index);
        }
    }
}

Track* MultiTrackEngine::getTrack(int index) {
    if (index >= 0 && index < tracks.size()) {
        return tracks[index].get();
    }
    return nullptr;
}

void MultiTrackEngine::setTrackInstrument(int trackIndex, std::unique_ptr<juce::AudioProcessor> instrument) {
    if (auto* track = getTrack(trackIndex)) {
        if (instrument) {
            instrument->setPlayConfigDetails(0, 2, currentSampleRate, currentBlockSize);
            instrument->prepareToPlay(currentSampleRate, currentBlockSize);
        }
        track->setInstrument(std::move(instrument));
    }
}

void MultiTrackEngine::addTrackEffect(int trackIndex, std::unique_ptr<juce::AudioProcessor> effect) {
    if (auto* track = getTrack(trackIndex)) {
        if (effect) {
            effect->setPlayConfigDetails(2, 2, currentSampleRate, currentBlockSize);
            effect->prepareToPlay(currentSampleRate, currentBlockSize);
        }
        track->addEffect(std::move(effect));
    }
}

void MultiTrackEngine::removeTrackEffect(int trackIndex, int effectIndex) {
    if (auto* track = getTrack(trackIndex)) {
        track->removeEffect(effectIndex);
    }
}

void MultiTrackEngine::setTrackVolume(int trackIndex, float volume) {
    if (auto* track = getTrack(trackIndex)) {
        track->setVolume(volume);
    }
}

void MultiTrackEngine::setTrackMute(int trackIndex, bool muted) {
    if (auto* track = getTrack(trackIndex)) {
        track->setMuted(muted);
    }
}

void MultiTrackEngine::setTrackSolo(int trackIndex, bool solo) {
    if (trackIndex >= 0 && trackIndex < soloStates.size()) {
        soloStates[trackIndex] = solo;
        updateSoloStates();
    }
}

void MultiTrackEngine::setTrackArmed(int trackIndex, bool armed) {
    if (auto* track = getTrack(trackIndex)) {
        track->setArmed(armed);
    }
}

void MultiTrackEngine::updateSoloStates() {
    anySolo = false;
    for (bool solo : soloStates) {
        if (solo) {
            anySolo = true;
            break;
        }
    }
}

void MultiTrackEngine::mixTracks(juce::AudioBuffer<float>& outputBuffer) {
    outputBuffer.clear();

    for (size_t i = 0; i < tracks.size(); ++i) {
        if (!tracks[i]->isMuted() && (!anySolo || soloStates[i])) {
            for (int ch = 0; ch < outputBuffer.getNumChannels(); ++ch) {
                outputBuffer.addFrom(ch, 0, trackBuffers[i], ch, 0, outputBuffer.getNumSamples());
            }
        }
    }
}

bool MultiTrackEngine::exportMix(const juce::File& outputFile, int lengthInSeconds, int bitDepth) {
    const int totalSamples = static_cast<int>(currentSampleRate * lengthInSeconds);
    juce::AudioBuffer<float> exportBuffer(2, totalSamples);
    exportBuffer.clear();

    prepareToPlay(currentSampleRate, currentBlockSize);

    int samplesProcessed = 0;
    while (samplesProcessed < totalSamples) {
        int samplesToProcess = juce::jmin(currentBlockSize, totalSamples - samplesProcessed);

        juce::AudioBuffer<float> tempBuffer(exportBuffer.getArrayOfWritePointers(),
                                           2, samplesProcessed, samplesToProcess);
        juce::MidiBuffer midiBuffer;

        for (int i = 0; i < 4; ++i) {
            if (tracks[i]->isArmed()) {
                midiBuffer.addEvent(juce::MidiMessage::noteOn(1, 60 + i * 4, (juce::uint8)100), 0);
                midiBuffer.addEvent(juce::MidiMessage::noteOff(1, 60 + i * 4), samplesToProcess / 2);
            }
        }

        processBlock(tempBuffer, midiBuffer);
        samplesProcessed += samplesToProcess;
    }

    return masterBus->exportToWAV(outputFile, exportBuffer, currentSampleRate, bitDepth);
}

float MultiTrackEngine::getTrackRMS(int trackIndex, int channel) const {
    if (auto* track = const_cast<MultiTrackEngine*>(this)->getTrack(trackIndex)) {
        return track->getRMS();
    }
    return 0.0f;
}

float MultiTrackEngine::getTrackPeak(int trackIndex, int channel) const {
    if (auto* track = const_cast<MultiTrackEngine*>(this)->getTrack(trackIndex)) {
        return track->getPeak();
    }
    return 0.0f;
}

float MultiTrackEngine::getMasterRMS(int channel) const {
    return masterBus->getCurrentRMS(channel);
}

float MultiTrackEngine::getMasterPeak(int channel) const {
    return masterBus->getCurrentPeak(channel);
}

void MultiTrackEngine::getStateInformation(juce::MemoryBlock& destData) {
    juce::ignoreUnused(destData);
}

void MultiTrackEngine::setStateInformation(const void* data, int sizeInBytes) {
    juce::ignoreUnused(data, sizeInBytes);
}

juce::AudioProcessorEditor* MultiTrackEngine::createEditor() {
    return nullptr;
}