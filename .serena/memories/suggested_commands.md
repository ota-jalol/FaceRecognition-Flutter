# Development Commands and Workflow

## Essential Flutter Commands

### Development Workflow
```powershell
# Get dependencies
flutter pub get

# Run in debug mode (Android)
flutter run

# Run in debug mode (iOS)
flutter run -d ios

# Hot reload during development
# (Press 'r' in terminal while running)

# Hot restart
# (Press 'R' in terminal while running)
```

### Code Quality Commands
```powershell
# Analyze code for issues
flutter analyze

# Format code according to Dart style
flutter format .
flutter format lib/

# Run tests (when available)
flutter test

# Run tests with coverage
flutter test --coverage
```

### Build Commands
```powershell
# Build APK for Android (debug)
flutter build apk

# Build APK for Android (release)
flutter build apk --release

# Build APK with ABI splitting (reduces size)
flutter build apk --release --split-per-abi

# Build iOS (requires Xcode)
flutter build ios

# Build for specific target
flutter build apk --target-platform android-arm64
```

### Plugin Development
```powershell
# Navigate to plugin directory
cd facesdk_plugin

# Get plugin dependencies
flutter pub get

# Run plugin example
cd example
flutter run
```

### Debugging Commands
```powershell
# Run with debug information
flutter run --debug

# Profile app performance
flutter run --profile

# Attach debugger to running app
flutter attach

# Clean build artifacts
flutter clean

# Rebuild everything
flutter clean && flutter pub get && flutter run
```

### Platform-Specific Commands
```powershell
# Windows system commands
dir /s /b *.dart          # Find all Dart files
findstr /r "TODO" *.dart  # Search for TODOs
```