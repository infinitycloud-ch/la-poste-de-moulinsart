#pragma once
#include <JuceHeader.h>

class ProjectManager {
public:
    void saveProject(const File& file);
    void loadProject(const File& file);
    ValueTree getProjectState();

private:
    ValueTree projectData;
};
