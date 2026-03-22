#include "Track.h"

Track::Track() {
}

Track::~Track() {
}

void Track::setInstrument(std::unique_ptr<juce::AudioProcessor> newInstrument) {
    instrument = std::move(newInstrument);
}

void Track::addEffect(std::unique_ptr<juce::AudioProcessor> effect) {
    effects.push_back(std::move(effect));
}

void Track::removeEffect(int index) {
    if (index >= 0 && index < effects.size()) {
        effects.erase(effects.begin() + index);
    }
}

void Track::clearEffects() {
    effects.clear();
}

void Track::setVolume(float newVolume) {
    volume = juce::jlimit(0.0f, 2.0f, newVolume);
}

void Track::setMuted(bool shouldBeMuted) {
    muted = shouldBeMuted;
}

void Track::setArmed(bool shouldBeArmed) {
    armed = shouldBeArmed;
}

void Track::updateMeters(float rms, float peak) {
    currentRMS = rms;
    currentPeak = peak;
}

juce::AudioProcessor* Track::getEffect(int index) const {
    if (index >= 0 && index < effects.size()) {
        return effects[index].get();
    }
    return nullptr;
}

void Track::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midi) {
    if (muted) {
        buffer.clear();
        currentRMS = 0.0f;
        currentPeak = 0.0f;
        return;
    }

    if (instrument != nullptr) {
        instrument->processBlock(buffer, midi);
    }

    for (auto& effect : effects) {
        if (effect != nullptr) {
            juce::MidiBuffer emptyMidi;
            effect->processBlock(buffer, emptyMidi);
        }
    }

    buffer.applyGain(volume);

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

    updateMeters(rms, peak);
}