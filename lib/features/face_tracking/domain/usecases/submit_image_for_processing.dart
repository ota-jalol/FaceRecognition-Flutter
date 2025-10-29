import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/image_processing_request.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';

/// Use case for submitting image for processing
class SubmitImageForProcessingUseCase
    implements UseCase<void, ImageProcessingRequest> {
  final FaceTrackingRepository _repository;

  SubmitImageForProcessingUseCase(this._repository);

  @override
  Future<void> call({ImageProcessingRequest? params}) async {
    if (params == null) {
      throw ArgumentError('ImageProcessingRequest cannot be null');
    }

    _repository.submitImage(params);
  }
}
