#include <JuceHeader.h>
#include "PluginProcessor.h"
#include "PluginEditor.h"

class LogicAudioDAWApplication : public juce::JUCEApplication {
public:
    LogicAudioDAWApplication() {}

    const juce::String getApplicationName() override { return "Logic Audio DAW"; }
    const juce::String getApplicationVersion() override { return "1.0.0"; }
    bool moreThanOneInstanceAllowed() override { return true; }

    void initialise(const juce::String& commandLine) override {
        juce::ignoreUnused(commandLine);
        mainWindow.reset(new MainWindow(getApplicationName()));
    }

    void shutdown() override {
        mainWindow = nullptr;
    }

    void systemRequestedQuit() override {
        quit();
    }

    void anotherInstanceStarted(const juce::String& commandLine) override {
        juce::ignoreUnused(commandLine);
    }

    class MainWindow : public juce::DocumentWindow {
    public:
        MainWindow(juce::String name)
            : DocumentWindow(name,
                           juce::Desktop::getInstance().getDefaultLookAndFeel()
                                                       .findColour(ResizableWindow::backgroundColourId),
                           DocumentWindow::allButtons) {
            setUsingNativeTitleBar(true);
            setContentOwned(createMainContentComponent(), true);

            #if JUCE_IOS || JUCE_ANDROID
                setFullScreen(true);
            #else
                setResizable(true, true);
                centreWithSize(getWidth(), getHeight());
            #endif

            setVisible(true);
        }

        void closeButtonPressed() override {
            JUCEApplication::getInstance()->systemRequestedQuit();
        }

    private:
        juce::Component* createMainContentComponent() {
            auto processor = std::make_unique<LogicAudioDAWProcessor>();
            audioProcessor = std::move(processor);
            return audioProcessor->createEditor();
        }

        std::unique_ptr<juce::AudioProcessor> audioProcessor;
        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MainWindow)
    };

private:
    std::unique_ptr<MainWindow> mainWindow;
};

START_JUCE_APPLICATION(LogicAudioDAWApplication)