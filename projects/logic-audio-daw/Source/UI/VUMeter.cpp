#include "VUMeter.h"

VUMeter::VUMeter() {
    setOpaque(false);
}

VUMeter::~VUMeter() {
}

void VUMeter::paint(juce::Graphics& g) {
    auto bounds = getLocalBounds().toFloat();

    g.setColour(juce::Colours::black);
    g.fillRoundedRectangle(bounds, 2.0f);

    g.setColour(juce::Colours::darkgreen.darker());
    g.drawRoundedRectangle(bounds, 2.0f, 1.0f);

    if (displayRMS > 0.001f) {
        auto meterHeight = bounds.getHeight() * displayRMS;
        auto meterRect = bounds.removeFromBottom(meterHeight);

        juce::ColourGradient gradient(juce::Colours::green, 0, bounds.getBottom(),
                                     juce::Colours::yellow, 0, bounds.getY() + bounds.getHeight() * 0.3f,
                                     false);
        gradient.addColour(0.9, juce::Colours::red);

        g.setGradientFill(gradient);
        g.fillRoundedRectangle(meterRect, 2.0f);
    }

    if (displayPeak > 0.001f) {
        auto peakY = bounds.getBottom() - (bounds.getHeight() * displayPeak);
        g.setColour(displayPeak > 0.9f ? juce::Colours::red : juce::Colours::yellow);
        g.drawHorizontalLine((int)peakY, bounds.getX(), bounds.getRight());
    }

    for (float level = 0.0f; level <= 1.0f; level += 0.25f) {
        auto y = bounds.getBottom() - (bounds.getHeight() * level);
        g.setColour(juce::Colours::grey);
        g.drawHorizontalLine((int)y, bounds.getX(), bounds.getX() + 5);
    }
}

void VUMeter::setLevel(float rms, float peak) {
    currentRMS = rms;
    currentPeak = peak;

    displayRMS = displayRMS * smoothingFactor + currentRMS * (1.0f - smoothingFactor);
    displayPeak = juce::jmax(displayPeak * 0.95f, currentPeak);

    repaint();
}