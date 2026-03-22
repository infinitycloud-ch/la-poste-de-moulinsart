#include "FXSlotComponent.h"

FXSlotComponent::FXSlotComponent()
    : isEmpty(true), isBypassed(false), isHovered(false), isDragging(false)
{
    setWantsKeyboardFocus(true);
    setMouseCursor(juce::MouseCursor::PointingHandCursor);
}

FXSlotComponent::~FXSlotComponent() {}

void FXSlotComponent::paint(juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat().reduced(2);

    juce::Colour bgColour;
    if (isEmpty)
    {
        bgColour = juce::Colour(0xff2a2a2a);
    }
    else if (isBypassed)
    {
        bgColour = juce::Colour(0xff444444);
    }
    else
    {
        bgColour = juce::Colour(0xff4a90e2);
    }

    if (isHovered)
    {
        bgColour = bgColour.brighter(0.2f);
    }

    if (isDragging)
    {
        bgColour = bgColour.brighter(0.4f);
    }

    g.setColour(bgColour);
    g.fillRoundedRectangle(bounds, 4.0f);

    g.setColour(juce::Colour(0xff666666));
    g.drawRoundedRectangle(bounds, 4.0f, 1.0f);

    if (isEmpty)
    {
        g.setColour(juce::Colours::grey);
        g.setFont(10.0f);
        g.drawText("Empty Slot", bounds, juce::Justification::centred);

        g.setColour(juce::Colours::grey.withAlpha(0.5f));
        float dashLength[] = { 5.0f, 5.0f };
        g.drawDashedLine(juce::Line<float>(bounds.getCentreX() - 15, bounds.getCentreY(),
                                            bounds.getCentreX() + 15, bounds.getCentreY()),
                         dashLength, 2, 1.0f);
    }
    else
    {
        g.setColour(isBypassed ? juce::Colours::grey : juce::Colours::white);
        g.setFont(11.0f);
        g.drawText(effectName, bounds.reduced(5, 0), juce::Justification::centred);

        if (isBypassed)
        {
            g.setColour(juce::Colours::red.withAlpha(0.7f));
            g.setFont(8.0f);
            g.drawText("BYPASSED", bounds.removeFromBottom(15), juce::Justification::centred);
        }

        auto closeButton = bounds.removeFromTop(15).removeFromRight(15).reduced(2);
        g.setColour(juce::Colours::white.withAlpha(0.6f));
        g.drawLine(closeButton.getX(), closeButton.getY(),
                   closeButton.getRight(), closeButton.getBottom(), 1.0f);
        g.drawLine(closeButton.getRight(), closeButton.getY(),
                   closeButton.getX(), closeButton.getBottom(), 1.0f);
    }
}

void FXSlotComponent::resized() {}

void FXSlotComponent::mouseEnter(const juce::MouseEvent&)
{
    isHovered = true;
    repaint();
}

void FXSlotComponent::mouseExit(const juce::MouseEvent&)
{
    isHovered = false;
    repaint();
}

void FXSlotComponent::mouseDown(const juce::MouseEvent& e)
{
    if (!isEmpty && e.mods.isRightButtonDown())
    {
        juce::PopupMenu menu;
        menu.addItem(1, "Bypass", true, isBypassed);
        menu.addSeparator();
        menu.addItem(2, "Remove Effect");
        menu.addSeparator();
        menu.addItem(3, "Replace...");

        menu.showMenuAsync(juce::PopupMenu::Options(),
                           [this](int result)
                           {
                               if (result == 1)
                               {
                                   toggleBypass();
                               }
                               else if (result == 2)
                               {
                                   clearEffect();
                               }
                               else if (result == 3)
                               {
                                   showEffectSelector();
                               }
                           });
    }
    else if (isEmpty)
    {
        showEffectSelector();
    }
}

void FXSlotComponent::mouseDrag(const juce::MouseEvent& e)
{
    if (!isEmpty && !e.mods.isRightButtonDown())
    {
        if (!isDragging)
        {
            isDragging = true;

            auto dragContainer = new juce::DragAndDropContainer();
            dragContainer->startDragging(effectName, this, juce::Image(), true);
        }
    }
}

void FXSlotComponent::mouseUp(const juce::MouseEvent&)
{
    isDragging = false;
    repaint();
}

bool FXSlotComponent::isInterestedInDragSource(const SourceDetails& details)
{
    return details.description.toString().isNotEmpty();
}

void FXSlotComponent::itemDropped(const SourceDetails& details)
{
    auto droppedEffect = details.description.toString();
    if (droppedEffect.isNotEmpty())
    {
        setEffect(droppedEffect);
    }
}

void FXSlotComponent::setEffect(const juce::String& name)
{
    effectName = name;
    isEmpty = name.isEmpty();
    isBypassed = false;
    repaint();

    if (onEffectChanged)
        onEffectChanged(effectName);
}

void FXSlotComponent::clearEffect()
{
    effectName = "";
    isEmpty = true;
    isBypassed = false;
    repaint();

    if (onEffectRemoved)
        onEffectRemoved();
}

void FXSlotComponent::toggleBypass()
{
    if (!isEmpty)
    {
        isBypassed = !isBypassed;
        repaint();

        if (onBypassChanged)
            onBypassChanged(isBypassed);
    }
}

void FXSlotComponent::showEffectSelector()
{
    juce::PopupMenu menu;

    menu.addSectionHeader("Dynamics");
    menu.addItem(10, "Compressor");
    menu.addItem(11, "Limiter");
    menu.addItem(12, "Gate");

    menu.addSectionHeader("EQ");
    menu.addItem(20, "Parametric EQ");
    menu.addItem(21, "Graphic EQ");

    menu.addSectionHeader("Reverb");
    menu.addItem(30, "Hall Reverb");
    menu.addItem(31, "Room Reverb");
    menu.addItem(32, "Plate Reverb");

    menu.addSectionHeader("Delay");
    menu.addItem(40, "Delay");
    menu.addItem(41, "Ping Pong Delay");

    menu.addSectionHeader("Modulation");
    menu.addItem(50, "Chorus");
    menu.addItem(51, "Flanger");
    menu.addItem(52, "Phaser");

    menu.showMenuAsync(juce::PopupMenu::Options(),
                       [this](int result)
                       {
                           juce::String selectedEffect;
                           switch (result)
                           {
                               case 10: selectedEffect = "Compressor"; break;
                               case 11: selectedEffect = "Limiter"; break;
                               case 12: selectedEffect = "Gate"; break;
                               case 20: selectedEffect = "Parametric EQ"; break;
                               case 21: selectedEffect = "Graphic EQ"; break;
                               case 30: selectedEffect = "Hall Reverb"; break;
                               case 31: selectedEffect = "Room Reverb"; break;
                               case 32: selectedEffect = "Plate Reverb"; break;
                               case 40: selectedEffect = "Delay"; break;
                               case 41: selectedEffect = "Ping Pong Delay"; break;
                               case 50: selectedEffect = "Chorus"; break;
                               case 51: selectedEffect = "Flanger"; break;
                               case 52: selectedEffect = "Phaser"; break;
                           }

                           if (selectedEffect.isNotEmpty())
                               setEffect(selectedEffect);
                       });
}

juce::String FXSlotComponent::getEffectName() const
{
    return effectName;
}

bool FXSlotComponent::getIsBypassed() const
{
    return isBypassed;
}

void FXSlotComponent::setBypass(bool bypass)
{
    if (!isEmpty)
    {
        isBypassed = bypass;
        repaint();
    }
}