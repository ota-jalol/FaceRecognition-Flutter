import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';

/// Use case for getting face detection results stream
class GetFaceDetectionStreamUseCase
    implements UseCase<Stream<FaceResult>, NoParams> {
  final FaceTrackingRepository _repository;

  GetFaceDetectionStreamUseCase(this._repository);

  @override
  Future<Stream<FaceResult>> call({NoParams? params}) async {
    return _repository.processImageStream();
  }
}
