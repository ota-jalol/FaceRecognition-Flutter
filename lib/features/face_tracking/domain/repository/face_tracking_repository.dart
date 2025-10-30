import '../models/face_tracking_config.dart';
import '../../../../core/resources/data_state.dart';

/// Repository interface for face tracking operations with KBY-AI SDK
abstract class FaceTrackingRepository {
  /// Initialize the KBY-AI Face SDK with configuration
  Future<DataState<bool>> initialize(FaceTrackingConfig config);

  bool get isInitialized;

  /// Get image dimensions
  int get imageWidth;
  int get imageHeight;

  Future<DataState<void>> dispose();
}
