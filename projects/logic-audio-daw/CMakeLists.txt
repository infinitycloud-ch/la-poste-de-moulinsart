cmake_minimum_required(VERSION 3.15)
project(LogicAudioDAW VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(JUCE CONFIG REQUIRED)

juce_add_plugin(LogicAudioDAW
    PRODUCT_NAME "Logic Audio DAW"
    COMPANY_NAME "Moulinsart"
    IS_SYNTH TRUE
    NEEDS_MIDI_INPUT TRUE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    PLUGIN_MANUFACTURER_CODE Mlns
    PLUGIN_CODE Ldaw
    FORMATS AU VST3 Standalone
    COPY_PLUGIN_AFTER_BUILD TRUE)

juce_generate_juce_header(LogicAudioDAW)

target_sources(LogicAudioDAW
    PRIVATE
        Source/Main.cpp
        Source/PluginProcessor.cpp
        Source/PluginEditor.cpp
        Source/Core/AudioEngine.cpp
        Source/Core/Track.cpp
        Source/UI/TrackComponent.cpp
        Source/UI/VUMeter.cpp)

target_compile_definitions(LogicAudioDAW
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
        JUCE_USE_CUSTOM_PLUGIN_STANDALONE_APP=1)

target_link_libraries(LogicAudioDAW
    PRIVATE
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_formats
        juce::juce_audio_plugin_client
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_core
        juce::juce_data_structures
        juce::juce_events
        juce::juce_graphics
        juce::juce_gui_basics
        juce::juce_gui_extra
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)