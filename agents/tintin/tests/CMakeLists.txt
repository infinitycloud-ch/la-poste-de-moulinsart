cmake_minimum_required(VERSION 3.14)
project(DAWAudioTests)

# Standard C++17
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

# Test executable
add_executable(test_runner
    test_runner.cpp
)

# Link Catch2
target_link_libraries(test_runner PRIVATE Catch2::Catch2WithMain)

# Enable testing
enable_testing()

# Register tests with CTest
include(CTest)
include(Catch)
catch_discover_tests(test_runner)