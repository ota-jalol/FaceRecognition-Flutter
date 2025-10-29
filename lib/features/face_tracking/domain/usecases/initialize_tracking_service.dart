import 'package:facerecognition_flutter/core/resources/data_state.dart';
import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';

/// Use case for initializing face tracking service
class InitializeFaceTrackingServiceUseCase
    implements UseCase<DataState<bool>,NoParams> {
  final FaceTrackingRepository _repository;

  InitializeFaceTrackingServiceUseCase(this._repository);

  @override
  Future<DataState<bool>> call({NoParams? params}) async {
    try {
      await _repository.initialize();
      return const DataSuccess(true);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }
}
