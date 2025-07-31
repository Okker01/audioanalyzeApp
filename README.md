# Audio Recorder & Preprocessor

A comprehensive Flutter application for professional audio recording with real-time visualization and preprocessing capabilities.

## Features

### 🎙️ Recording
- High-quality AAC audio recording
- Configurable sample rates (22.05kHz, 44.1kHz, 48kHz)
- Mono/Stereo recording modes
- Real-time audio visualization during recording
- Permission handling for microphone access

### 🎵 Audio Processing
- Audio normalization
- Low-pass filtering (0-20kHz)
- High-pass filtering (0-1000Hz)
- Real-time processing feedback
- A/B comparison between original and processed audio

### 📊 Visualization
- Real-time waveform visualization during recording
- Static waveform display for recorded audio
- Animated audio level indicators
- Side-by-side comparison of original vs processed audio

### 🎧 Playback & Management
- Built-in audio player
- Play original and processed versions
- Audio metadata display (duration, format, sample rate, etc.)
- File sharing capabilities
- Audio file management

## Screenshots

The app provides a comprehensive interface with multiple cards for different functionalities:
- Recording controls with real-time visualization
- Audio processing settings with filter controls
- Waveform analysis display
- Playback and comparison tools
- Detailed metadata information
- Share and export options

## Installation

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS development setup (for iOS deployment)

### Dependencies
```yaml
dependencies:
  flutter_sound: ^9.2.13      # Audio recording
  audioplayers: ^5.2.1        # Audio playback
  permission_handler: ^11.1.0  # Microphone permissions
  path_provider: ^2.1.1        # File system access
  share_plus: ^7.2.1          # File sharing
  fl_chart: ^0.65.0           # Charts and visualization
  provider: ^6.1.1            # State management
  intl: ^0.19.0               # Internationalization