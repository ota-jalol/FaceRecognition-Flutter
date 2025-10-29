import 'package:equatable/equatable.dart';

/// Base class for all Face Recognition events
abstract class FaceRecognitionEvent extends Equatable {
  const FaceRecognitionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize face tracking
class InitializeFaceTracking extends FaceRecognitionEvent {
  const InitializeFaceTracking();
}

/// Event to start face tracking
class StartFaceTracking extends FaceRecognitionEvent {
  const StartFaceTracking();
}

/// Event to stop face tracking
class StopFaceTracking extends FaceRecognitionEvent {
  const StopFaceTracking();
}

/// Event fired when face is detected
class FaceDetected extends FaceRecognitionEvent {
  final double confidence;
  final bool isCentered;
  final bool isPreparingPhoto;
  final String message;

  const FaceDetected({
    required this.confidence,
    required this.isCentered,
    this.isPreparingPhoto = false,
    required this.message,
  });

  @override
  List<Object?> get props => [confidence, isCentered, isPreparingPhoto, message];
}

/// Event when photo is captured
class PhotoCaptured extends FaceRecognitionEvent {
  final List<int> photoBytes;

  const PhotoCaptured(this.photoBytes);

  @override
  List<Object?> get props => [photoBytes];
}

/// Event for verification success
class VerificationSuccess extends FaceRecognitionEvent {
  const VerificationSuccess();
}

/// Event for verification failure
class VerificationFailed extends FaceRecognitionEvent {
  final String error;

  const VerificationFailed(this.error);

  @override
  List<Object?> get props => [error];
}

/// Event to reset state
class ResetFaceRecognition extends FaceRecognitionEvent {
  const ResetFaceRecognition();
}
