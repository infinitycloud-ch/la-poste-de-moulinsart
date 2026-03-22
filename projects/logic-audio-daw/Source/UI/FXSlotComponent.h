#pragma once

#include <JuceHeader.h>

class FXSlotComponent : public juce::Component,
                        public juce::DragAndDropTarget
{
public:
    FXSlotComponent();
    ~FXSlotComponent();

    void paint(juce::Graphics& g) override;
    void resized() override;

    void mouseEnter(const juce::MouseEvent& e) override;
    void mouseExit(const juce::MouseEvent& e) override;
    void mouseDown(const juce::MouseEvent& e) override;
    void mouseDrag(const juce::MouseEvent& e) override;
    void mouseUp(const juce::MouseEvent& e) override;

    bool isInterestedInDragSource(const SourceDetails& details) override;
    void itemDropped(const SourceDetails& details) override;

    void setEffect(const juce::String& name);
    void clearEffect();
    void toggleBypass();
    void setBypass(bool bypass);

    juce::String getEffectName() const;
    bool getIsBypassed() const;

    std::function<void(const juce::String&)> onEffectChanged;
    std::function<void()> onEffectRemoved;
    std::function<void(bool)> onBypassChanged;

private:
    void showEffectSelector();

    juce::String effectName;
    bool isEmpty;
    bool isBypassed;
    bool isHovered;
    bool isDragging;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(FXSlotComponent)
};