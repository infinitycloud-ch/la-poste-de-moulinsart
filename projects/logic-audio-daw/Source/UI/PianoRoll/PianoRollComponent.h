#pragma once

#include <JuceHeader.h>

class PianoRollComponent : public juce::Component
{
public:
    PianoRollComponent();
    ~PianoRollComponent();

    void paint(juce::Graphics& g) override;
    void resized() override;

    void setZoomLevel(float zoom);
    void applyQuantize();

private:
    struct Note
    {
        int pitch;
        float startTime;
        float length;
        int velocity;
    };

    class PianoRollContent : public juce::Component
    {
    public:
        PianoRollContent();
        void paint(juce::Graphics& g) override;
        void mouseDown(const juce::MouseEvent& e) override;

    private:
        bool isBlackNote(int noteNumber);
    };

    void showQuantizeMenu();

    std::unique_ptr<juce::Viewport> viewport;
    std::unique_ptr<PianoRollContent> pianoRollContent;

    juce::Slider zoomSlider;
    juce::TextButton quantizeButton;
    juce::Slider velocitySlider;

    std::vector<Note> notes;
    float zoomLevel;
    int quantizeValue;
    int currentVelocity;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PianoRollComponent)
};