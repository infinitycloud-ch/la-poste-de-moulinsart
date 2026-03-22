#include "TrackComponent.h"

TrackComponent::TrackComponent(LogicAudioDAWProcessor& processor, int trackIndex)
    : audioProcessor(processor), trackIdx(trackIndex) {

    instrumentLabel.setText("Instrument: SimpleSynth", juce::dontSendNotification);
    instrumentLabel.setJustificationType(juce::Justification::centred);
    addAndMakeVisible(instrumentLabel);

    fxLabel.setText("FX: Compressor", juce::dontSendNotification);
    fxLabel.setJustificationType(juce::Justification::centred);
    addAndMakeVisible(fxLabel);

    volumeSlider.setRange(0.0, 1.0, 0.01);
    volumeSlider.setValue(1.0);
    volumeSlider.setSliderStyle(juce::Slider::LinearVertical);
    volumeSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    volumeSlider.onValueChange = [this] {
        audioProcessor.setTrackVolume(trackIdx, (float)volumeSlider.getValue());
    };
    addAndMakeVisible(volumeSlider);

    volumeLabel.setText("Volume", juce::dontSendNotification);
    volumeLabel.setJustificationType(juce::Justification::centred);
    addAndMakeVisible(volumeLabel);

    muteButton.setButtonText("Mute");
    muteButton.onStateChange = [this] {
        audioProcessor.setTrackMute(trackIdx, muteButton.getToggleState());
    };
    addAndMakeVisible(muteButton);

    armButton.setButtonText("Arm");
    armButton.setToggleState(true, juce::dontSendNotification);
    armButton.onStateChange = [this] {
        auto& tracks = audioProcessor.getTracks();
        if (trackIdx < tracks.size()) {
            tracks[trackIdx].armed = armButton.getToggleState();
        }
    };
    addAndMakeVisible(armButton);

    vuMeter = std::make_unique<VUMeter>();
    addAndMakeVisible(vuMeter.get());
}

TrackComponent::~TrackComponent() {
}

void TrackComponent::paint(juce::Graphics& g) {
    g.fillAll(juce::Colours::darkgrey);
    g.setColour(juce::Colours::lightgrey);
    g.drawRect(getLocalBounds(), 1);

    g.setColour(juce::Colours::white);
    g.setFont(16.0f);
    g.drawText("Track " + juce::String(trackIdx + 1),
               getLocalBounds().removeFromTop(30),
               juce::Justification::centred, true);
}

void TrackComponent::resized() {
    auto bounds = getLocalBounds();
    bounds.removeFromTop(30);

    instrumentLabel.setBounds(bounds.removeFromTop(30).reduced(5));
    fxLabel.setBounds(bounds.removeFromTop(30).reduced(5));

    auto controlsArea = bounds.removeFromTop(250);
    auto sliderArea = controlsArea.removeFromLeft(60);
    volumeSlider.setBounds(sliderArea.removeFromTop(200));
    volumeLabel.setBounds(sliderArea);

    vuMeter->setBounds(controlsArea.removeFromLeft(40).reduced(5));

    auto buttonArea = bounds.removeFromTop(80);
    muteButton.setBounds(buttonArea.removeFromTop(35).reduced(10, 5));
    armButton.setBounds(buttonArea.removeFromTop(35).reduced(10, 5));
}

void TrackComponent::updateMeters() {
    float rms = audioProcessor.getTrackRMS(trackIdx);
    float peak = audioProcessor.getTrackPeak(trackIdx);
    vuMeter->setLevel(rms, peak);
}