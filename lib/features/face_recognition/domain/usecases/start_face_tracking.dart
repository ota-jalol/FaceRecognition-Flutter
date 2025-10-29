import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/repository/face_tracking_repository.dart';

/// Use case for starting face tracking and receiving results
class StartFaceTrackingUseCase
    implements UseCase<Stream<FaceResult>, NoParams> {
  final FaceTrackingRepository _repository;

  StartFaceTrackingUseCase(this._repository);

  @override
  Future<Stream<FaceResult>> call({NoParams? params}) async {
    return _repository.startTracking();
  }
}
