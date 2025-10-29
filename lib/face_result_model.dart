import 'package:flutter/services.dart';

class FaceResult {
  final bool faceDetected;
  final double confidence;
  final FaceRectangle? faceRectangle;
  final bool isCentered;
  final double imageWidth;
  final double imageHeight;
  final Uint8List? base64Photo;
  final bool isPhotoCaptured;
  final bool isPreparingPhoto;
  final String message;
  final DateTime timestamp;
  final bool hasError;

  FaceResult({
    required this.faceDetected,
    required this.confidence,
    this.faceRectangle,
    this.isCentered = false,
    this.imageWidth = 0.0,
    this.imageHeight = 0.0,
    this.base64Photo,
    this.isPhotoCaptured = false,
    this.isPreparingPhoto = false,
    required this.message,
    required this.timestamp,
    this.hasError = false,
  });

  factory FaceResult.noFace() {
    return FaceResult(
      faceDetected: false,
      confidence: 0.0,
      message: 'Yuz aniqlanmadi',
      timestamp: DateTime.now(),
    );
  }

  factory FaceResult.error(String error) {
    return FaceResult(
      faceDetected: false,
      confidence: 0.0,
      message: error,
      timestamp: DateTime.now(),
      hasError: true,
    );
  }
}

class FaceRectangle {
  final double left;
  final double top;
  final double width;
  final double height;

  FaceRectangle({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory FaceRectangle.fromMap(Map map) {
    return FaceRectangle(
      left: (map['left'] ?? 0.0).toDouble(),
      top: (map['top'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}
