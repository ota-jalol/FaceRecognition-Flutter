# Task Completion Checklist

## When a coding task is completed, perform these steps:

### 1. Code Quality Checks
```powershell
# Run analysis to check for issues
flutter analyze

# Fix any analysis issues that appear
# Pay attention to:
# - Unused imports
# - Deprecated API usage
# - Missing error handling
# - Type safety issues
```

### 2. Code Formatting
```powershell
# Format all Dart files
flutter format .

# Verify formatting is consistent
# Check that indentation, spacing, and line breaks follow Dart conventions
```

### 3. Dependency Management
```powershell
# Ensure all dependencies are properly declared in pubspec.yaml
flutter pub deps

# Update dependencies if needed
flutter pub get
```

### 4. Testing (when tests exist)
```powershell
# Run all tests
flutter test

# Verify test coverage
flutter test --coverage

# Check that new functionality has corresponding tests
```

### 5. Build Verification
```powershell
# Clean previous builds
flutter clean

# Verify debug build works
flutter build apk

# For production releases:
flutter build apk --release --split-per-abi
```

### 6. Platform-Specific Verification
- **Android**: Test on different API levels if possible
- **iOS**: Verify iOS-specific functionality (when applicable)
- **Camera permissions**: Ensure proper permission handling

### 7. Documentation Updates
- Update README.md if new features were added
- Add/update code comments for complex logic
- Update API documentation if plugin interfaces changed

### 8. Git Workflow (if using version control)
```powershell
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: description of changes"

# Push to repository
git push origin main
```

### Critical Areas to Verify
1. **Face SDK Integration**: Ensure license keys are properly configured
2. **Camera Permissions**: Test camera access on first app launch
3. **Settings Persistence**: Verify SharedPreferences save/load correctly
4. **Memory Management**: Check for memory leaks in camera operations
5. **Error Handling**: Ensure graceful handling of SDK failures
6. **UI Responsiveness**: Test on lower-end devices if possible