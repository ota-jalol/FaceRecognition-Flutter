import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/core/resources/data_state.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/image_processing_request.dart';

/// Use case for submitting image for processing
class SubmitImageForProcessing implements UseCase<void, ImageProcessingRequest> {
  final FaceTrackingRepository _repository;

  const SubmitImageForProcessing(this._repository);

  @override
  Future<DataState<void>> call({ImageProcessingRequest? params}) async {
    if (params == null) {
      return const DataFailed('Image processing request is required');
    }

    return await _repository.submitImage(params);
  }
}