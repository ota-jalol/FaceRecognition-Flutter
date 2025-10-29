# Code Style and Conventions

## Dart/Flutter Conventions
This project follows standard Flutter/Dart conventions:

### Naming Conventions
- **Classes**: PascalCase (e.g., `FaceRecognitionView`, `SettingsPage`)
- **Variables/Methods**: camelCase (e.g., `faceDetectionViewController`, `onFaceDetected`)
- **Private members**: Underscore prefix (e.g., `_faces`, `_livenessThreshold`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `_kItemExtent`)
- **Files**: snake_case (e.g., `facedetectionview.dart`, `settings.dart`)

### Code Organization
- **Widgets**: Stateful/Stateless widget pattern
- **State Management**: setState() for local component state
- **Constructors**: Use `super.key` for widget keys
- **Imports**: Organized with Flutter imports first, then package imports, then relative imports

### Flutter-Specific Patterns
- **Widget Lifecycle**: Proper initState(), dispose() implementation
- **Navigation**: MaterialPageRoute for screen transitions
- **Platform Views**: AndroidView/UiKitView for native camera integration
- **Method Channels**: For communication with native SDK

### Code Style Enforcement
- **Linting**: Uses `package:flutter_lints/flutter.yaml`
- **Analysis**: Configured in `analysis_options.yaml`
- **Formatting**: Standard Dart formatting rules

### Current Style Issues (to be addressed)
- Empty catch blocks should include error logging
- Deprecated APIs (WillPopScope) should be replaced with modern alternatives
- Missing const constructors for immutable widgets
- Missing error handling in async operations