import 'package:facerecognition_flutter/face_result_model.dart';

/// Abstract repository for face tracking operations
/// Follows the Repository pattern to separate data source from business logic
abstract class FaceTrackingRepository {
  /// Initialize face tracking service
  Future<bool> initialize();

  /// Start tracking faces in the camera stream
  Stream<FaceResult> startTracking();

  /// Stop face tracking
  Future<void> stopTracking();

  /// Request photo capture from the face tracking service
  Future<void> requestPhotoCapture();

  /// Dispose of resources
  Future<void> dispose();
}
