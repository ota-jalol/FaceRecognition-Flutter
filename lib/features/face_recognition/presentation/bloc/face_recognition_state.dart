import 'package:asbt/face_result_model.dart';
import 'package:equatable/equatable.dart';

/// Base class for Face Recognition states
abstract class FaceRecognitionState extends Equatable {
  const FaceRecognitionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FaceRecognitionInitial extends FaceRecognitionState {
  const FaceRecognitionInitial();
}

/// Loading/initializing camera
class FaceRecognitionInitializing extends FaceRecognitionState {
  const FaceRecognitionInitializing();
}

/// Camera initialized successfully
class FaceRecognitionReady extends FaceRecognitionState {
  const FaceRecognitionReady();
}

/// Actively tracking face
class FaceRecognitionTracking extends FaceRecognitionState {
  final FaceResult? faceResult;

  const FaceRecognitionTracking({this.faceResult});

  @override
  List<Object?> get props => [faceResult];

  FaceRecognitionTracking copyWith({FaceResult? faceResult}) {
    return FaceRecognitionTracking(faceResult: faceResult ?? this.faceResult);
  }
}

/// Capturing photo
class FaceRecognitionCapturing extends FaceRecognitionState {
  const FaceRecognitionCapturing();
}

/// Verifying captured photo
class FaceRecognitionVerifying extends FaceRecognitionState {
  const FaceRecognitionVerifying();
}

/// Verification successful
class FaceRecognitionVerified extends FaceRecognitionState {
  final List<int> photoBytes;

  const FaceRecognitionVerified(this.photoBytes);

  @override
  List<Object?> get props => [photoBytes];
}

/// Waiting between photo attempts
class FaceRecognitionWaiting extends FaceRecognitionState {
  final int attemptCount;

  const FaceRecognitionWaiting({required this.attemptCount});

  @override
  List<Object?> get props => [attemptCount];
}

/// Error state
class FaceRecognitionError extends FaceRecognitionState {
  final String message;
  final bool canRetry;

  const FaceRecognitionError({required this.message, this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

/// Max attempts reached
class FaceRecognitionMaxAttemptsReached extends FaceRecognitionState {
  final String message;

  const FaceRecognitionMaxAttemptsReached(this.message);

  @override
  List<Object?> get props => [message];
}
