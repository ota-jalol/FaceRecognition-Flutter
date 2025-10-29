import '../../../../core/usecase/usecase.dart';
import '../../../../core/resources/data_state.dart';
import '../models/image_processing_request.dart';
import '../repository/face_tracking_repository.dart';

/// Use case for submitting image for processing to KBY-AI SDK
class SubmitImageForProcessing implements UseCase<void, ImageProcessingRequest> {
  final FaceTrackingRepository _repository;

  const SubmitImageForProcessing(this._repository);

  @override
  Future<DataState<void>> call({ImageProcessingRequest? params}) async {
    if (params == null) {
      return const DataFailed('ImageProcessingRequest cannot be null');
    }

    return await _repository.submitImage(params);
  }
}
