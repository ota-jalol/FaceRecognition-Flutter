import 'dart:async';
import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/face_tracker.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/repository/face_tracking_repository.dart';

/// Implementation of FaceTrackingRepository
/// Handles actual communication with the native face tracking service
class FaceTrackingRepositoryImpl implements FaceTrackingRepository {
  StreamSubscription<FaceResult>? _faceStreamSubscription;
  bool _isInitialized = false;
  bool _isTracking = false;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize face tracking service if needed
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Stream<FaceResult> startTracking() {
    if (!_isInitialized) {
      throw Exception(
        'Face tracking not initialized. Call initialize() first.',
      );
    }

    _isTracking = true;
    return FaceTrackingService.instance.getProcessingResults();
  }

  @override
  Future<void> stopTracking() async {
    _isTracking = false;
    await _faceStreamSubscription?.cancel();
    _faceStreamSubscription = null;
  }

  @override
  Future<void> requestPhotoCapture() async {
    if (!_isTracking) {
      throw Exception('Face tracking is not active');
    }
    // Photo capture is handled in camera processing
  }

  @override
  Future<void> dispose() async {
    await stopTracking();
    _isInitialized = false;
  }
}
