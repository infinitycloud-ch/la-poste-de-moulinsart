#!/bin/bash

echo "🎵 Building Logic Audio DAW - Sprint 1"
echo "=================================="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

if [ ! -d "$BUILD_DIR" ]; then
    echo "📁 Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"

echo "🔧 Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DJUCE_DIR="/usr/local/share/juce" \
         -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    echo "Trying alternative JUCE paths..."

    cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DJUCE_DIR="$HOME/JUCE" \
             -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" 2>&1

    if [ $? -ne 0 ]; then
        echo "❌ CMake configuration failed. Please check JUCE installation."
        exit 1
    fi
fi

echo "🏗️ Building project..."
cmake --build . --config Release -j$(sysctl -n hw.ncpu) 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📍 Standalone app location:"
    find . -name "*.app" -type d | head -1
    echo ""
    echo "🚀 To run: open $(find . -name '*.app' -type d | head -1)"
else
    echo "❌ Build failed"
    exit 1
fi