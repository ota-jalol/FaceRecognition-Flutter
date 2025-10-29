import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/image_processing_request.dart';

/// Repository interface for face tracking operations
abstract class FaceTrackingRepository {
  /// Initialize the face tracking service
  Future<void> initialize();

  /// Process a camera image and return face detection results
  Stream<FaceResult> processImageStream();

  /// Submit an image for processing
  void submitImage(ImageProcessingRequest request);

  /// Check if service is initialized
  bool get isInitialized;

  /// Get image dimensions
  int get imageWidth;
  int get imageHeight;

  /// Pause processing (screen-level lifecycle)
  void pause();

  /// Resume processing (screen-level lifecycle)
  void resume();

  /// Clear processing queue
  void clearQueue();

  /// Dispose resources
  Future<void> dispose();
}
