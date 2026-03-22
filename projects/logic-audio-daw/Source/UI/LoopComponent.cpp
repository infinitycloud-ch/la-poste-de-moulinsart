#include "LoopComponent.h"

LoopComponent::LoopComponent()
{
    loopColour = juce::Colour(0xff4FC3F7);
    setSize(100, 50);
}

void LoopComponent::paint(juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat();

    juce::Colour bgColour = isActive ? loopColour : loopColour.withAlpha(0.3f);
    g.setColour(bgColour);
    g.fillRoundedRectangle(bounds.reduced(2), 6.0f);

    g.setColour(isActive ? loopColour.brighter(0.3f) : juce::Colour(0xff666666));
    g.drawRoundedRectangle(bounds.reduced(2), 6.0f, 2.0f);

    g.setColour(juce::Colours::white.withAlpha(0.9f));
    g.setFont(12.0f);
    g.drawText(isActive ? "LOOP ON" : "LOOP OFF", bounds, juce::Justification::centred);

    if (isActive)
    {
        auto iconBounds = bounds.reduced(10);
        auto leftArrow = iconBounds.removeFromLeft(20);
        auto rightArrow = iconBounds.removeFromRight(20);

        g.setColour(juce::Colours::white);
        juce::Path arrow;
        arrow.addArrow(juce::Line<float>(leftArrow.getCentreX() + 10, leftArrow.getCentreY(),
                                          leftArrow.getCentreX(), leftArrow.getCentreY()),
                       4.0f, 8.0f, 6.0f);
        g.fillPath(arrow);

        arrow.clear();
        arrow.addArrow(juce::Line<float>(rightArrow.getCentreX() - 10, rightArrow.getCentreY(),
                                          rightArrow.getCentreX(), rightArrow.getCentreY()),
                       4.0f, 8.0f, 6.0f);
        g.fillPath(arrow);
    }
}

void LoopComponent::mouseDown(const juce::MouseEvent&)
{
    isActive = !isActive;
    repaint();
}