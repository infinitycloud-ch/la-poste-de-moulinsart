#include "PluginProcessor.h"
#include "PluginEditor.h"

LogicAudioDAWEditor::LogicAudioDAWEditor(LogicAudioDAWProcessor& p)
    : AudioProcessorEditor(&p), audioProcessor(p) {

    exportButton.setButtonText("Export WAV");
    exportButton.onClick = [this] { exportAudio(); };
    addAndMakeVisible(exportButton);

    statusLabel.setText("Ready", juce::dontSendNotification);
    statusLabel.setJustificationType(juce::Justification::centred);
    addAndMakeVisible(statusLabel);

    for (int i = 0; i < audioProcessor.getTracks().size(); ++i) {
        auto trackComp = std::make_unique<TrackComponent>(audioProcessor, i);
        addAndMakeVisible(trackComp.get());
        trackComponents.push_back(std::move(trackComp));
    }

    setSize(800, 600);
    startTimerHz(30);
}

LogicAudioDAWEditor::~LogicAudioDAWEditor() {
}

void LogicAudioDAWEditor::paint(juce::Graphics& g) {
    g.fillAll(getLookAndFeel().findColour(juce::ResizableWindow::backgroundColourId));

    g.setColour(juce::Colours::white);
    g.setFont(20.0f);
    g.drawText("Logic Audio DAW - Sprint 1", getLocalBounds().removeFromTop(40),
               juce::Justification::centred, true);
}

void LogicAudioDAWEditor::resized() {
    auto bounds = getLocalBounds();
    bounds.removeFromTop(40);

    auto masterSection = bounds.removeFromTop(60);
    exportButton.setBounds(masterSection.removeFromLeft(150).reduced(10));
    statusLabel.setBounds(masterSection.reduced(10));

    auto trackWidth = 200;
    auto trackBounds = bounds.reduced(10);

    for (auto& trackComp : trackComponents) {
        trackComp->setBounds(trackBounds.removeFromLeft(trackWidth));
        trackBounds.removeFromLeft(10);
    }
}

void LogicAudioDAWEditor::timerCallback() {
    for (auto& trackComp : trackComponents) {
        trackComp->updateMeters();
    }
}

void LogicAudioDAWEditor::exportAudio() {
    juce::File desktopDir = juce::File::getSpecialLocation(juce::File::userDesktopDirectory);
    juce::File outputFile = desktopDir.getChildFile("DAW_Test_Export.wav");

    if (audioProcessor.exportToWAV(outputFile)) {
        statusLabel.setText("Export successful: " + outputFile.getFileName(),
                          juce::dontSendNotification);
    } else {
        statusLabel.setText("Export failed!", juce::dontSendNotification);
    }
}