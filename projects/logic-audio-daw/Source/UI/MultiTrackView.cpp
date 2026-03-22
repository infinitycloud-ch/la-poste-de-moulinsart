#include "MultiTrackView.h"

MultiTrackView::MultiTrackView(AudioEngine* engine) : audioEngine(engine)
{
    for (int i = 0; i < 4; ++i)
    {
        auto track = std::make_unique<TrackComponent>();
        track->setTrackNumber(i + 1);
        track->setTrackName("Track " + juce::String(i + 1));

        track->onMuteChanged = [this, i](bool muted) {
            if (audioEngine) {
                audioEngine->setTrackMute(i, muted);
            }
        };

        track->onSoloChanged = [this, i](bool soloed) {
            if (audioEngine) {
                audioEngine->setTrackSolo(i, soloed);
                updateSoloStates();
            }
        };

        track->onArmChanged = [this, i](bool armed) {
            if (audioEngine) {
                audioEngine->setTrackRecordArm(i, armed);
            }
        };

        track->onVolumeChanged = [this, i](float volume) {
            if (audioEngine) {
                audioEngine->setTrackVolume(i, volume);
            }
        };

        track->onTrackSelected = [this, i]() {
            selectTrack(i);
        };

        addAndMakeVisible(track.get());
        tracks.add(track.release());
    }

    selectedTrack = 0;
    tracks[0]->setSelected(true);

    startTimerHz(30);
}

MultiTrackView::~MultiTrackView()
{
    stopTimer();
}

void MultiTrackView::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colour(0xff1e1e1e));

    g.setColour(juce::Colour(0xff333333));
    for (int i = 1; i < 4; ++i)
    {
        int x = i * getWidth() / 4;
        g.drawLine(x, 0, x, getHeight(), 1.0f);
    }
}

void MultiTrackView::resized()
{
    int trackWidth = getWidth() / 4;

    for (int i = 0; i < tracks.size(); ++i)
    {
        tracks[i]->setBounds(i * trackWidth, 0, trackWidth - 2, getHeight());
    }
}

void MultiTrackView::timerCallback()
{
    if (!audioEngine) return;

    for (int i = 0; i < tracks.size(); ++i)
    {
        float rms, peak;
        audioEngine->getTrackLevels(i, rms, peak);
        tracks[i]->updateLevels(rms, peak);
    }
}

void MultiTrackView::selectTrack(int index)
{
    if (index >= 0 && index < tracks.size())
    {
        for (int i = 0; i < tracks.size(); ++i)
        {
            tracks[i]->setSelected(i == index);
        }
        selectedTrack = index;

        if (onTrackSelectionChanged)
            onTrackSelectionChanged(index);
    }
}

void MultiTrackView::updateSoloStates()
{
    bool anySoloed = false;
    for (auto* track : tracks)
    {
        if (track->isSoloed())
        {
            anySoloed = true;
            break;
        }
    }

    for (int i = 0; i < tracks.size(); ++i)
    {
        tracks[i]->setImplicitMute(anySoloed && !tracks[i]->isSoloed());
    }
}

void MultiTrackView::loadInstrumentIntoTrack(int trackIndex, const juce::String& instrumentName)
{
    if (trackIndex >= 0 && trackIndex < tracks.size())
    {
        tracks[trackIndex]->setInstrumentName(instrumentName);
        if (audioEngine)
        {
            audioEngine->loadInstrument(trackIndex, instrumentName);
        }
    }
}

void MultiTrackView::addEffectToTrack(int trackIndex, int slotIndex, const juce::String& effectName)
{
    if (trackIndex >= 0 && trackIndex < tracks.size())
    {
        tracks[trackIndex]->setEffectName(slotIndex, effectName);
        if (audioEngine)
        {
            audioEngine->loadEffect(trackIndex, slotIndex, effectName);
        }
    }
}

TrackComponent* MultiTrackView::getTrack(int index)
{
    if (index >= 0 && index < tracks.size())
        return tracks[index];
    return nullptr;
}

int MultiTrackView::getSelectedTrackIndex() const
{
    return selectedTrack;
}