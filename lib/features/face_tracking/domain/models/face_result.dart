import 'package:equatable/equatable.dart';
import 'dart:typed_data';

/// Represents a detected face from KBY-AI Face SDK
class FaceResult extends Equatable {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double liveness;
  final double yaw;
  final double roll;
  final double pitch;
  final Uint8List? templates;
  final Uint8List? faceImage;

  const FaceResult({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.liveness,
    required this.yaw,
    required this.roll,
    required this.pitch,
    this.templates,
    this.faceImage,
  });

  /// Create FaceResult from KBY-AI SDK response
  factory FaceResult.fromMap(Map<String, dynamic> map) {
    return FaceResult(
      x1: (map['x1'] ?? 0.0).toDouble(),
      y1: (map['y1'] ?? 0.0).toDouble(),
      x2: (map['x2'] ?? 0.0).toDouble(),
      y2: (map['y2'] ?? 0.0).toDouble(),
      liveness: (map['liveness'] ?? 0.0).toDouble(),
      yaw: (map['yaw'] ?? 0.0).toDouble(),
      roll: (map['roll'] ?? 0.0).toDouble(),
      pitch: (map['pitch'] ?? 0.0).toDouble(),
      templates: map['templates'] as Uint8List?,
      faceImage: map['faceImage'] as Uint8List?,
    );
  }

  /// Check if this face passes liveness threshold
  bool isLive(double threshold) => liveness >= threshold;

  /// Get face bounding box width
  double get width => x2 - x1;

  /// Get face bounding box height
  double get height => y2 - y1;

  /// Get face center point
  Map<String, double> get center => {
        'x': (x1 + x2) / 2,
        'y': (y1 + y2) / 2,
      };

  /// Check if face is within acceptable pose angles
  bool isGoodPose({
    double maxYaw = 15.0,
    double maxRoll = 15.0,
    double maxPitch = 15.0,
  }) {
    return yaw.abs() <= maxYaw &&
           roll.abs() <= maxRoll &&
           pitch.abs() <= maxPitch;
  }

  @override
  List<Object?> get props => [
        x1, y1, x2, y2,
        liveness, yaw, roll, pitch,
        templates, faceImage,
      ];
}

/// Represents face recognition result
class FaceRecognitionResult extends Equatable {
  final bool isRecognized;
  final String identifiedName;
  final double similarity;
  final FaceResult faceResult;
  final Uint8List? enrolledFace;

  const FaceRecognitionResult({
    required this.isRecognized,
    required this.identifiedName,
    required this.similarity,
    required this.faceResult,
    this.enrolledFace,
  });

  @override
  List<Object?> get props => [
        isRecognized,
        identifiedName,
        similarity,
        faceResult,
        enrolledFace,
      ];
}