#pragma once
#include <JuceHeader.h>

class LoopComponent : public Component {
public:
    LoopComponent();
    void paint(Graphics& g) override;
    void mouseDown(const MouseEvent& e) override;

private:
    bool isActive{false};
    Colour loopColour;
};
