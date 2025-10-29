import '../models/face_result.dart';
import '../models/image_processing_request.dart';
import '../models/face_tracking_config.dart';
import '../../../../core/resources/data_state.dart';

/// Repository interface for face tracking operations with KBY-AI SDK
abstract class FaceTrackingRepository {
  /// Initialize the KBY-AI Face SDK with configuration
  Future<DataState<bool>> initialize(FaceTrackingConfig config);

  /// Process a camera image and return face detection results
  Stream<DataState<List<FaceResult>>> processImageStream();

  /// Submit an image for processing
  Future<DataState<void>> submitImage(ImageProcessingRequest request);

  /// Check if SDK is initialized
  bool get isInitialized;

  /// Get image dimensions
  int get imageWidth;
  int get imageHeight;

  /// Update SDK parameters
  Future<DataState<void>> updateConfig(FaceTrackingConfig config);

  /// Extract faces from image path
  Future<DataState<List<FaceResult>>> extractFaces(String imagePath);

  /// Calculate similarity between face templates
  Future<DataState<double>> calculateSimilarity(
    List<int> template1,
    List<int> template2,
  );

  /// Pause processing (screen-level lifecycle)
  void pause();

  /// Resume processing (screen-level lifecycle)
  void resume();

  /// Clear processing queue
  void clearQueue();

  /// Dispose resources
  Future<DataState<void>> dispose();
}
