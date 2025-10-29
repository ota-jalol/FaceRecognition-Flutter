import 'package:facerecognition_flutter/core/resources/data_state.dart';
import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/repository/face_tracking_repository.dart';

/// Use case for initializing face tracking
class InitializeFaceTrackingUseCase
    implements UseCase<DataState<bool>, NoParams> {
  final FaceTrackingRepository _repository;

  InitializeFaceTrackingUseCase(this._repository);

  @override
  Future<DataState<bool>> call({NoParams? params}) async {
    try {
      final result = await _repository.initialize();
      return DataSuccess(result);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }
}
