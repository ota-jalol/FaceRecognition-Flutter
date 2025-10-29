# Project Structure and Codebase Organization

## Main Application Structure (`/lib/`)

### Core Files
- **`main.dart`**
  - Application entry point with `MyApp` and `MyHomePage` classes
  - Face SDK initialization and license activation
  - Home screen UI with navigation to face detection and settings
  - Uses MaterialApp with dark theme
  - Symbols: `main()`, `MyApp`, `MyHomePageState`, `init()`

- **`facedetectionview.dart`**
  - Core face detection and recognition functionality
  - `FaceRecognitionView` - main detection screen widget
  - `FaceDetectionView` - platform-specific camera interface
  - `FacePainter` - custom painter for face detection overlays
  - Real-time face processing and results display
  - Key symbols: `onFaceDetected()`, `faceRecognitionStart()`, `FaceRecognitionViewState`

- **`settings.dart`**
  - Configuration screen using settings_ui package
  - Settings persistence via SharedPreferences
  - Threshold and parameter configuration
  - Key symbols: `SettingsPageState`, `loadSettings()`, `updateLivenessThreshold()`

## Face SDK Plugin (`/facesdk_plugin/`)

### Plugin Architecture
- **`lib/facesdk_plugin.dart`** - Main plugin interface
- **`lib/facesdk_plugin_platform_interface.dart`** - Platform abstraction
- **`lib/facesdk_plugin_method_channel.dart`** - Method channel implementation
- **`lib/facedetection_interface.dart`** - Camera interface and controller

### Native Integration
- **`android/libfacesdk/`** - KBY-AI Face SDK Android library
- **`android/libfotoapparat/`** - Camera management library
- **`ios/`** - iOS-specific Face SDK integration

## Configuration Files

### Build & Dependencies
- **`pubspec.yaml`** - Project dependencies and metadata
- **`analysis_options.yaml`** - Dart analysis rules (flutter_lints)
- **`android/app/build.gradle`** - Android build configuration
- **`android/settings.gradle`** - Android module settings

### Key Dependencies
- `facesdk_plugin` (local) - Face recognition functionality
- `flutter_exif_rotation` - Image rotation handling
- `settings_ui` - Settings screen UI components
- `shared_preferences` - Local data persistence
- `image_picker` - Image selection capabilities
- `sqflite` - SQLite database support
- `fluttertoast` - Toast notifications

## Data Flow Architecture
1. **UI Layer** (Flutter widgets) ↔ **Service Layer** (plugin interfaces) ↔ **Native Layer** (Face SDK)
2. **Settings** stored in SharedPreferences and applied to SDK parameters
3. **Camera frames** processed in real-time through method channels
4. **Face detection results** returned via callbacks to Flutter UI

## Important Design Patterns
- **Plugin Pattern**: Separation of Flutter app from native Face SDK
- **State Management**: StatefulWidget with setState() for local state
- **Platform Views**: AndroidView/UiKitView for native camera integration
- **Method Channels**: Bidirectional communication with native code
- **Observer Pattern**: Callback-based face detection events