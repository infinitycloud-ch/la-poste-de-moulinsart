#include "MasterSectionComponent.h"

MasterSectionComponent::MasterSectionComponent(AudioEngine* engine)
    : audioEngine(engine), masterVolume(0.75f), isMuted(false)
{
    addAndMakeVisible(volumeFader);
    volumeFader.setSliderStyle(juce::Slider::LinearVertical);
    volumeFader.setRange(0.0, 1.0, 0.01);
    volumeFader.setValue(masterVolume);
    volumeFader.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 60, 20);
    volumeFader.setColour(juce::Slider::trackColourId, juce::Colour(0xff4FC3F7));
    volumeFader.setColour(juce::Slider::backgroundColourId, juce::Colour(0xff333333));
    volumeFader.onValueChange = [this] {
        masterVolume = volumeFader.getValue();
        if (audioEngine)
            audioEngine->setMasterVolume(masterVolume);
    };

    addAndMakeVisible(muteButton);
    muteButton.setButtonText("MUTE");
    muteButton.setColour(juce::TextButton::buttonColourId, juce::Colour(0xff444444));
    muteButton.onClick = [this] {
        isMuted = !isMuted;
        muteButton.setColour(juce::TextButton::buttonColourId,
                              isMuted ? juce::Colours::red : juce::Colour(0xff444444));
        if (audioEngine)
            audioEngine->setMasterMute(isMuted);
    };

    addAndMakeVisible(exportButton);
    exportButton.setButtonText("EXPORT");
    exportButton.setColour(juce::TextButton::buttonColourId, juce::Colour(0xff4FC3F7));
    exportButton.onClick = [this] {
        showExportDialog();
    };

    vuMeterLeft = std::make_unique<VUMeter>();
    vuMeterRight = std::make_unique<VUMeter>();
    addAndMakeVisible(vuMeterLeft.get());
    addAndMakeVisible(vuMeterRight.get());

    startTimerHz(30);
}

MasterSectionComponent::~MasterSectionComponent()
{
    stopTimer();
}

void MasterSectionComponent::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colour(0xff2a2a2a));

    g.setColour(juce::Colour(0xff444444));
    g.drawRect(getLocalBounds(), 2);

    g.setColour(juce::Colours::white);
    g.setFont(14.0f);
    g.drawText("MASTER", 10, 10, getWidth() - 20, 20, juce::Justification::centred);

    auto labelBounds = getLocalBounds().removeFromBottom(40);
    g.setFont(11.0f);
    g.setColour(juce::Colours::grey);
    g.drawText("L", labelBounds.removeFromLeft(getWidth() / 4), juce::Justification::centred);
    g.drawText("R", labelBounds.removeFromLeft(getWidth() / 4), juce::Justification::centred);

    auto volumeLabel = getLocalBounds().removeFromBottom(60).removeFromTop(20);
    g.drawText(juce::String(masterVolume * 100, 1) + "%",
               volumeLabel, juce::Justification::centred);
}

void MasterSectionComponent::resized()
{
    auto bounds = getLocalBounds().reduced(10);

    bounds.removeFromTop(30);

    auto buttonArea = bounds.removeFromTop(80);
    muteButton.setBounds(buttonArea.removeFromTop(35).reduced(5, 0));
    exportButton.setBounds(buttonArea.reduced(5, 0));

    auto meterArea = bounds.removeFromTop(200);
    auto meterWidth = meterArea.getWidth() / 4;

    vuMeterLeft->setBounds(meterArea.removeFromLeft(meterWidth).reduced(5));
    vuMeterRight->setBounds(meterArea.removeFromLeft(meterWidth).reduced(5));

    volumeFader.setBounds(meterArea.reduced(10, 0));
}

void MasterSectionComponent::timerCallback()
{
    if (!audioEngine) return;

    float leftLevel, rightLevel;
    audioEngine->getMasterLevels(leftLevel, rightLevel);

    vuMeterLeft->setLevel(leftLevel);
    vuMeterRight->setLevel(rightLevel);
}

void MasterSectionComponent::showExportDialog()
{
    auto chooser = std::make_shared<juce::FileChooser>(
        "Export Audio File",
        juce::File::getSpecialLocation(juce::File::userDocumentsDirectory),
        "*.wav"
    );

    chooser->launchAsync(juce::FileBrowserComponent::saveMode,
                         [this, chooser](const juce::FileChooser& fc) {
                             auto file = fc.getResult();
                             if (file != juce::File{})
                             {
                                 exportToFile(file);
                             }
                         });
}

void MasterSectionComponent::exportToFile(const juce::File& file)
{
    if (!audioEngine) return;

    juce::AlertWindow exportProgress("Exporting...",
                                      "Exporting audio to: " + file.getFileName(),
                                      juce::MessageBoxIconType::NoIcon);

    exportProgress.addProgressBarComponent(0.0);
    exportProgress.enterModalState();

    bool success = audioEngine->exportToWav(file.getFullPathName().toStdString(),
                                             [&exportProgress](float progress) {
                                                 if (auto* bar = exportProgress.getProgressBar())
                                                     bar->setProgress(progress);
                                             });

    exportProgress.exitModalState(0);

    if (success)
    {
        juce::AlertWindow::showMessageBoxAsync(
            juce::MessageBoxIconType::InfoIcon,
            "Export Complete",
            "Audio exported successfully to:\n" + file.getFullPathName()
        );
    }
    else
    {
        juce::AlertWindow::showMessageBoxAsync(
            juce::MessageBoxIconType::WarningIcon,
            "Export Failed",
            "Failed to export audio file."
        );
    }
}