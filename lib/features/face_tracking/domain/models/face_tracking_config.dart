import 'package:equatable/equatable.dart';

/// Configuration model for face tracking service
/// Contains all necessary parameters for KBY-AI Face SDK
class FaceTrackingConfig extends Equatable {
  final double livenessThreshold;
  final double identifyThreshold;
  final int livenessLevel;
  final int cameraLens;
  final int imageWidth;
  final int imageHeight;
  final bool enableLivenessDetection;
  final bool enableFaceRecognition;

  const FaceTrackingConfig({
    required this.livenessThreshold,
    required this.identifyThreshold,
    required this.livenessLevel,
    required this.cameraLens,
    required this.imageWidth,
    required this.imageHeight,
    this.enableLivenessDetection = true,
    this.enableFaceRecognition = true,
  });

  /// Default configuration for KBY-AI Face SDK
  factory FaceTrackingConfig.defaultConfig() {
    return const FaceTrackingConfig(
      livenessThreshold: 0.7,
      identifyThreshold: 0.8,
      livenessLevel: 0, // Best Accuracy
      cameraLens: 1, // Front camera
      imageWidth: 640,
      imageHeight: 480,
    );
  }

  /// Create a copy with updated values
  FaceTrackingConfig copyWith({
    double? livenessThreshold,
    double? identifyThreshold,
    int? livenessLevel,
    int? cameraLens,
    int? imageWidth,
    int? imageHeight,
    bool? enableLivenessDetection,
    bool? enableFaceRecognition,
  }) {
    return FaceTrackingConfig(
      livenessThreshold: livenessThreshold ?? this.livenessThreshold,
      identifyThreshold: identifyThreshold ?? this.identifyThreshold,
      livenessLevel: livenessLevel ?? this.livenessLevel,
      cameraLens: cameraLens ?? this.cameraLens,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      enableLivenessDetection: enableLivenessDetection ?? this.enableLivenessDetection,
      enableFaceRecognition: enableFaceRecognition ?? this.enableFaceRecognition,
    );
  }

  /// Convert to Map for SDK parameters
  Map<String, dynamic> toSDKParams() {
    return {
      'check_liveness_level': livenessLevel,
      'liveness_threshold': livenessThreshold,
      'identify_threshold': identifyThreshold,
      'camera_lens': cameraLens,
    };
  }

  @override
  List<Object?> get props => [
        livenessThreshold,
        identifyThreshold,
        livenessLevel,
        cameraLens,
        imageWidth,
        imageHeight,
        enableLivenessDetection,
        enableFaceRecognition,
      ];
}