import 'package:equatable/equatable.dart';
import '../../domain/models/face_result.dart';

/// Base class for all face tracking states
abstract class FaceTrackingState extends Equatable {
  const FaceTrackingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FaceTrackingInitial extends FaceTrackingState {
  const FaceTrackingInitial();
}

/// Loading state during initialization
class FaceTrackingLoading extends FaceTrackingState {
  const FaceTrackingLoading();
}

/// State when face tracking is ready
class FaceTrackingReady extends FaceTrackingState {
  const FaceTrackingReady();
}

/// State when actively detecting faces
class FaceTrackingActive extends FaceTrackingState {
  final List<FaceResult> faces;
  final String? message;
  final bool isProcessing;

  const FaceTrackingActive({
    required this.faces,
    this.message,
    this.isProcessing = false,
  });

  @override
  List<Object?> get props => [faces, message, isProcessing];

  FaceTrackingActive copyWith({
    List<FaceResult>? faces,
    String? message,
    bool? isProcessing,
  }) {
    return FaceTrackingActive(
      faces: faces ?? this.faces,
      message: message ?? this.message,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// State when face tracking is paused
class FaceTrackingPaused extends FaceTrackingState {
  const FaceTrackingPaused();
}

/// State when photo is being captured
class FaceTrackingCapturingPhoto extends FaceTrackingState {
  final List<FaceResult> faces;
  final String? message;

  const FaceTrackingCapturingPhoto({
    required this.faces,
    this.message,
  });

  @override
  List<Object?> get props => [faces, message];
}

/// State when photo is successfully captured
class FaceTrackingPhotoCaptured extends FaceTrackingState {
  final String base64Photo;
  final FaceResult faceResult;
  final String? message;

  const FaceTrackingPhotoCaptured({
    required this.base64Photo,
    required this.faceResult,
    this.message,
  });

  @override
  List<Object?> get props => [base64Photo, faceResult, message];
}

/// Error state
class FaceTrackingError extends FaceTrackingState {
  final String error;
  final String? details;

  const FaceTrackingError({
    required this.error,
    this.details,
  });

  @override
  List<Object?> get props => [error, details];
}