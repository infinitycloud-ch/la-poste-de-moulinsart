cmake_minimum_required(VERSION 3.14)
project(LogicAudioDAWTests)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch Catch2
Include(FetchContent)
FetchContent_Declare(
  Catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG        v3.4.0
)
FetchContent_MakeAvailable(Catch2)

# Find JUCE
find_package(JUCE REQUIRED)

# Test executables
add_executable(AudioEngineTest AudioEngineTest.cpp)
add_executable(MultiTrackTests MultiTrackTests.cpp)
add_executable(MidiRoutingTests MidiRoutingTests.cpp)
add_executable(FXChainTests FXChainTests.cpp)
add_executable(ExportTests ExportTests.cpp)

# Link libraries
target_link_libraries(AudioEngineTest PRIVATE juce::juce_audio_basics juce::juce_audio_processors)
target_link_libraries(MultiTrackTests PRIVATE juce::juce_audio_basics juce::juce_audio_processors)
target_link_libraries(MidiRoutingTests PRIVATE juce::juce_audio_basics juce::juce_audio_processors)
target_link_libraries(FXChainTests PRIVATE juce::juce_audio_basics juce::juce_audio_processors)
target_link_libraries(ExportTests PRIVATE juce::juce_audio_basics juce::juce_audio_processors)

# Enable testing
enable_testing()

# Register tests
add_test(NAME AudioEngine COMMAND AudioEngineTest)
add_test(NAME MultiTrack COMMAND MultiTrackTests)
add_test(NAME MidiRouting COMMAND MidiRoutingTests)
add_test(NAME FXChain COMMAND FXChainTests)
add_test(NAME Export COMMAND ExportTests)