#pragma once
#include <JuceHeader.h>

class PianoRoll : public Component {
public:
    void setZoom(float zoom);
    void addNote(int pitch, float start, float duration, int velocity);
    void quantize(int subdivision);

private:
    std::vector<MidiNote> notes;
    float zoomLevel{1.0f};
};
