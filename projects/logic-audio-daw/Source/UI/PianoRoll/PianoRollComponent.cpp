#include "PianoRollComponent.h"

PianoRollComponent::PianoRollComponent()
    : zoomLevel(1.0f), quantizeValue(16), currentVelocity(100)
{
    setSize(800, 400);
    viewport = std::make_unique<juce::Viewport>();
    pianoRollContent = std::make_unique<PianoRollContent>();

    viewport->setViewedComponent(pianoRollContent.get(), false);
    addAndMakeVisible(viewport.get());

    addAndMakeVisible(zoomSlider);
    zoomSlider.setRange(0.5, 4.0, 0.1);
    zoomSlider.setValue(1.0);
    zoomSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    zoomSlider.setTextBoxStyle(juce::Slider::TextBoxLeft, false, 50, 20);
    zoomSlider.onValueChange = [this] {
        setZoomLevel(zoomSlider.getValue());
    };

    addAndMakeVisible(quantizeButton);
    quantizeButton.setButtonText("Quantize: 1/16");
    quantizeButton.onClick = [this] {
        showQuantizeMenu();
    };

    addAndMakeVisible(velocitySlider);
    velocitySlider.setRange(0, 127, 1);
    velocitySlider.setValue(100);
    velocitySlider.setSliderStyle(juce::Slider::LinearHorizontal);
    velocitySlider.setTextBoxStyle(juce::Slider::TextBoxLeft, false, 50, 20);
    velocitySlider.onValueChange = [this] {
        currentVelocity = static_cast<int>(velocitySlider.getValue());
    };
}

PianoRollComponent::~PianoRollComponent() {}

void PianoRollComponent::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colour(0xff2a2a2a));

    g.setColour(juce::Colours::white);
    g.setFont(14.0f);
    g.drawText("Piano Roll Editor", 10, 10, 200, 20, juce::Justification::left);
}

void PianoRollComponent::resized()
{
    auto bounds = getLocalBounds();

    auto topBar = bounds.removeFromTop(40);

    zoomSlider.setBounds(topBar.removeFromLeft(150).reduced(5));
    quantizeButton.setBounds(topBar.removeFromLeft(120).reduced(5));
    velocitySlider.setBounds(topBar.removeFromLeft(150).reduced(5));

    viewport->setBounds(bounds);

    pianoRollContent->setSize(getWidth() * zoomLevel, 88 * 20);
}

void PianoRollComponent::setZoomLevel(float zoom)
{
    zoomLevel = juce::jlimit(0.5f, 4.0f, zoom);
    pianoRollContent->setSize(getWidth() * zoomLevel, pianoRollContent->getHeight());
    pianoRollContent->repaint();
}

void PianoRollComponent::showQuantizeMenu()
{
    juce::PopupMenu menu;
    menu.addItem(1, "1/4", true, quantizeValue == 4);
    menu.addItem(2, "1/8", true, quantizeValue == 8);
    menu.addItem(3, "1/16", true, quantizeValue == 16);
    menu.addItem(4, "1/32", true, quantizeValue == 32);
    menu.addSeparator();
    menu.addItem(5, "Triplets", true, false);

    menu.showMenuAsync(juce::PopupMenu::Options(),
                       [this](int result) {
                           switch(result) {
                               case 1: quantizeValue = 4; quantizeButton.setButtonText("Quantize: 1/4"); break;
                               case 2: quantizeValue = 8; quantizeButton.setButtonText("Quantize: 1/8"); break;
                               case 3: quantizeValue = 16; quantizeButton.setButtonText("Quantize: 1/16"); break;
                               case 4: quantizeValue = 32; quantizeButton.setButtonText("Quantize: 1/32"); break;
                           }
                           applyQuantize();
                       });
}

void PianoRollComponent::applyQuantize()
{
    for (auto& note : notes)
    {
        float gridSize = (getWidth() * zoomLevel) / (float)(quantizeValue * 4);
        note.startTime = std::round(note.startTime / gridSize) * gridSize;
    }
    pianoRollContent->repaint();
}

PianoRollComponent::PianoRollContent::PianoRollContent()
{
    setSize(800, 88 * 20);
}

void PianoRollComponent::PianoRollContent::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colour(0xff1a1a1a));

    for (int note = 0; note < 88; ++note)
    {
        int y = note * 20;

        bool isBlackKey = isBlackNote(87 - note);
        g.setColour(isBlackKey ? juce::Colour(0xff2a2a2a) : juce::Colour(0xff333333));
        g.fillRect(0, y, getWidth(), 20);

        g.setColour(juce::Colour(0xff555555));
        g.drawHorizontalLine(y, 0, getWidth());

        if (note % 12 == 0)
        {
            g.setColour(juce::Colours::white.withAlpha(0.5f));
            g.setFont(10.0f);
            g.drawText("C" + juce::String(8 - note / 12), 5, y, 30, 20, juce::Justification::centredLeft);
        }
    }

    for (int beat = 0; beat < getWidth() / 50; ++beat)
    {
        int x = beat * 50;
        g.setColour(beat % 4 == 0 ? juce::Colour(0xff666666) : juce::Colour(0xff444444));
        g.drawVerticalLine(x, 0, getHeight());
    }

    auto parent = findParentComponentOfClass<PianoRollComponent>();
    if (parent != nullptr)
    {
        g.setColour(juce::Colour(0xff4FC3F7));
        for (const auto& note : parent->notes)
        {
            auto noteBounds = juce::Rectangle<float>(note.startTime, note.pitch * 20, note.length, 18);
            g.fillRoundedRectangle(noteBounds, 2.0f);

            g.setColour(juce::Colours::white);
            g.drawRoundedRectangle(noteBounds, 2.0f, 1.0f);
        }
    }
}

void PianoRollComponent::PianoRollContent::mouseDown(const juce::MouseEvent& e)
{
    auto parent = findParentComponentOfClass<PianoRollComponent>();
    if (parent != nullptr)
    {
        int pitch = (getHeight() - e.y) / 20;
        float startTime = e.x;
        float length = 50;

        Note newNote { pitch, startTime, length, parent->currentVelocity };
        parent->notes.push_back(newNote);
        repaint();
    }
}

bool PianoRollComponent::PianoRollContent::isBlackNote(int noteNumber)
{
    int noteInOctave = noteNumber % 12;
    return noteInOctave == 1 || noteInOctave == 3 || noteInOctave == 6 ||
           noteInOctave == 8 || noteInOctave == 10;
}