import 'package:equatable/equatable.dart';

/// Base class for all face tracking events
abstract class FaceTrackingEvent extends Equatable {
  const FaceTrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize face tracking
class InitializeFaceTracking extends FaceTrackingEvent {
  const InitializeFaceTracking();
}

/// Event to start face detection process
class StartFaceDetection extends FaceTrackingEvent {
  const StartFaceDetection();
}

/// Event to submit camera image for processing
class SubmitCameraImage extends FaceTrackingEvent {
  final int orientation;
  final bool frontFacing;
  final bool capturePhoto;

  const SubmitCameraImage({
    required this.orientation,
    required this.frontFacing,
    this.capturePhoto = false,
  });

  @override
  List<Object?> get props => [ orientation, frontFacing, capturePhoto];
}

/// Event to pause face tracking
class PauseFaceTracking extends FaceTrackingEvent {
  const PauseFaceTracking();
}

/// Event to resume face tracking
class ResumeFaceTracking extends FaceTrackingEvent {
  const ResumeFaceTracking();
}

/// Event to stop face tracking
class StopFaceTracking extends FaceTrackingEvent {
  const StopFaceTracking();
}

/// Event to capture photo
class CapturePhoto extends FaceTrackingEvent {
  const CapturePhoto();
}

/// Event to reset tracking state
class ResetFaceTracking extends FaceTrackingEvent {
  const ResetFaceTracking();
}