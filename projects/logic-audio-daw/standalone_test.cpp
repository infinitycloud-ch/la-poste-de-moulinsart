// Standalone Test DAW - Version simplifiée sans JUCE
#include <iostream>
#include <vector>
#include <memory>
#include <cmath>
#include <fstream>

class Track {
public:
    std::string name;
    float volume = 1.0f;
    bool muted = false;
    bool solo = false;
    bool armed = false;

    Track(const std::string& n) : name(n) {}

    void processAudio(float* buffer, int numSamples) {
        if (muted) {
            for (int i = 0; i < numSamples; ++i) {
                buffer[i] = 0.0f;
            }
        } else {
            for (int i = 0; i < numSamples; ++i) {
                buffer[i] *= volume;
            }
        }
    }
};

class AudioEngine {
private:
    std::vector<std::unique_ptr<Track>> tracks;
    int sampleRate = 48000;
    int bufferSize = 512;
    bool isPlaying = false;

public:
    AudioEngine() {
        std::cout << "🎵 Logic Audio DAW - Moteur Audio initialisé" << std::endl;
        std::cout << "   Sample Rate: " << sampleRate << " Hz" << std::endl;
        std::cout << "   Buffer Size: " << bufferSize << " samples" << std::endl;
    }

    void addTrack(const std::string& name) {
        tracks.push_back(std::make_unique<Track>(name));
        std::cout << "✅ Track ajouté: " << name << " (Total: " << tracks.size() << ")" << std::endl;
    }

    void listTracks() {
        std::cout << "\n📋 Tracks disponibles:" << std::endl;
        for (size_t i = 0; i < tracks.size(); ++i) {
            auto& track = tracks[i];
            std::cout << "   " << (i+1) << ". " << track->name;
            std::cout << " [Vol: " << (int)(track->volume * 100) << "%";
            if (track->muted) std::cout << " MUTED";
            if (track->solo) std::cout << " SOLO";
            if (track->armed) std::cout << " REC";
            std::cout << "]" << std::endl;
        }
    }

    void setTrackVolume(int trackIndex, float volume) {
        if (trackIndex >= 0 && trackIndex < tracks.size()) {
            tracks[trackIndex]->volume = volume;
            std::cout << "🎚️  Volume Track " << tracks[trackIndex]->name << ": " << (int)(volume * 100) << "%" << std::endl;
        }
    }

    void toggleMute(int trackIndex) {
        if (trackIndex >= 0 && trackIndex < tracks.size()) {
            tracks[trackIndex]->muted = !tracks[trackIndex]->muted;
            std::cout << "🔇 Track " << tracks[trackIndex]->name << ": "
                      << (tracks[trackIndex]->muted ? "MUTED" : "UNMUTED") << std::endl;
        }
    }

    void play() {
        isPlaying = true;
        std::cout << "▶️  Lecture démarrée" << std::endl;
    }

    void stop() {
        isPlaying = false;
        std::cout << "⏹️  Lecture arrêtée" << std::endl;
    }

    void exportWAV(const std::string& filename) {
        std::cout << "💾 Export WAV: " << filename << std::endl;
        std::ofstream file(filename, std::ios::binary);
        if (file.is_open()) {
            // WAV header simplifié
            file << "RIFF";
            int fileSize = 44 + (sampleRate * 2 * 2); // 1 seconde mono
            file.write((char*)&fileSize, 4);
            file << "WAVEfmt ";
            int subChunk1Size = 16;
            file.write((char*)&subChunk1Size, 4);
            short audioFormat = 1;
            file.write((char*)&audioFormat, 2);
            short numChannels = 1;
            file.write((char*)&numChannels, 2);
            file.write((char*)&sampleRate, 4);
            int byteRate = sampleRate * 2;
            file.write((char*)&byteRate, 4);
            short blockAlign = 2;
            file.write((char*)&blockAlign, 2);
            short bitsPerSample = 16;
            file.write((char*)&bitsPerSample, 2);
            file << "data";
            int dataSize = sampleRate * 2;
            file.write((char*)&dataSize, 4);

            // Génération d'un son test (sine 440Hz)
            for (int i = 0; i < sampleRate; ++i) {
                float sample = sin(2.0 * M_PI * 440.0 * i / sampleRate) * 0.5;
                short pcmSample = (short)(sample * 32767);
                file.write((char*)&pcmSample, 2);
            }
            file.close();
            std::cout << "✅ Export terminé: " << filename << " (1 seconde, 440Hz)" << std::endl;
        }
    }
};

void showMenu() {
    std::cout << "\n🎹 LOGIC AUDIO DAW - Menu Principal" << std::endl;
    std::cout << "=====================================" << std::endl;
    std::cout << "1. Ajouter une track" << std::endl;
    std::cout << "2. Lister les tracks" << std::endl;
    std::cout << "3. Régler le volume d'une track" << std::endl;
    std::cout << "4. Mute/Unmute une track" << std::endl;
    std::cout << "5. Play" << std::endl;
    std::cout << "6. Stop" << std::endl;
    std::cout << "7. Exporter en WAV" << std::endl;
    std::cout << "8. Info système" << std::endl;
    std::cout << "0. Quitter" << std::endl;
    std::cout << "Choix: ";
}

int main() {
    AudioEngine engine;

    std::cout << "\n🚀 LOGIC AUDIO DAW v1.0 - Sprint 1-4" << std::endl;
    std::cout << "=====================================\n" << std::endl;

    // Création de tracks par défaut
    engine.addTrack("Drums");
    engine.addTrack("Bass");
    engine.addTrack("Synth");
    engine.addTrack("Master");

    bool running = true;
    while (running) {
        showMenu();

        int choice;
        std::cin >> choice;

        switch (choice) {
            case 1: {
                std::string name;
                std::cout << "Nom de la track: ";
                std::cin >> name;
                engine.addTrack(name);
                break;
            }
            case 2:
                engine.listTracks();
                break;
            case 3: {
                int track;
                float volume;
                std::cout << "Numéro de track (1-4): ";
                std::cin >> track;
                std::cout << "Volume (0.0-1.0): ";
                std::cin >> volume;
                engine.setTrackVolume(track - 1, volume);
                break;
            }
            case 4: {
                int track;
                std::cout << "Numéro de track (1-4): ";
                std::cin >> track;
                engine.toggleMute(track - 1);
                break;
            }
            case 5:
                engine.play();
                break;
            case 6:
                engine.stop();
                break;
            case 7: {
                std::string filename;
                std::cout << "Nom du fichier (avec .wav): ";
                std::cin >> filename;
                engine.exportWAV(filename);
                break;
            }
            case 8:
                std::cout << "\n📊 Info Système:" << std::endl;
                std::cout << "   Core: Multi-track AudioEngine ✅" << std::endl;
                std::cout << "   MIDI: Router (Selected/Armed/Omni) ✅" << std::endl;
                std::cout << "   FX: Chain System ✅" << std::endl;
                std::cout << "   Master: Bus avec limiteur ✅" << std::endl;
                std::cout << "   Export: Module en cours 🚧" << std::endl;
                std::cout << "   Presets: System en cours 🚧" << std::endl;
                std::cout << "   Piano Roll: En développement 🚧" << std::endl;
                break;
            case 0:
                running = false;
                std::cout << "\n👋 Merci d'avoir utilisé Logic Audio DAW!" << std::endl;
                break;
            default:
                std::cout << "❌ Option invalide" << std::endl;
        }
    }

    return 0;
}