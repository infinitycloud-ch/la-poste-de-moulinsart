#pragma once
#include <JuceHeader.h>

class MainLayout : public Component {
public:
    MainLayout();
    void resized() override;

private:
    std::unique_ptr<TrackArea> trackArea;
    std::unique_ptr<MasterSection> masterSection;
    std::unique_ptr<TransportBar> transport;
};
