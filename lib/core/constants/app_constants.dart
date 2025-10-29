/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Face detection thresholds
  static const double faceConfidenceThreshold = 0.7;
  static const int maxVerificationAttempts = 3;
  static const int maxPhotoRequests = 3;

  static const int photoaptureTimeoutSeconds = 10;
  static const int faceTrackingRetryDelaySeconds = 2;
  static const int imageProcessingFrameSkip = 3; // Reduced for smoother detection

  // Animation durations
  static const int pulseAnimationMs = 1500;
  static const int scanAnimationMs = 2000;
  static const int progressAnimationMs = 3000;

  // UI constants
  static const double defaultBoxWidth = 300.0;
  static const double defaultBoxHeight = 400.0;
}
