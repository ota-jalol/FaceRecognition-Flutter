# Flutter Face Recognition Project Overview

## Project Purpose
This is a Flutter mobile application that implements real-time face recognition and liveness detection capabilities using KBY-AI's Face SDK. The application provides:

- **Real-time face detection** through device camera
- **Liveness detection** to prevent spoofing attacks 
- **Face recognition and identification** with similarity scoring
- **User settings** for configuring detection parameters and thresholds
- **Cross-platform support** for Android and iOS

## Tech Stack
- **Framework**: Flutter (Dart)
- **Face Recognition**: KBY-AI Face SDK (native Android/iOS libraries)
- **Camera Integration**: Platform-specific camera implementations via method channels
- **State Management**: Flutter's built-in setState() pattern
- **Local Storage**: SharedPreferences for settings persistence
- **UI Components**: Material Design with settings_ui package

## Core Architecture
The project follows a standard Flutter plugin architecture:

1. **Flutter App Layer** (`/lib/`):
   - `main.dart` - Application entry point and home screen
   - `facedetectionview.dart` - Camera interface and face detection UI
   - `settings.dart` - Configuration screen for detection parameters

2. **Face SDK Plugin** (`/facesdk_plugin/`):
   - Custom Flutter plugin providing Dart interface to native Face SDK
   - Method channel communication between Flutter and native code
   - Platform-specific implementations for Android/iOS

3. **Native Libraries** (`/android/libfacesdk/`, `/android/libfotoapparat/`):
   - KBY-AI Face SDK for advanced face recognition
   - Camera management and image processing libraries

## Key Features
- Real-time face detection with bounding box overlay
- Liveness score calculation (0.0-1.0) to detect spoofing
- Face similarity comparison with configurable thresholds
- Camera lens selection (front/back)
- Detection level adjustment (Best Accuracy vs Light Weight)
- Settings persistence across app sessions