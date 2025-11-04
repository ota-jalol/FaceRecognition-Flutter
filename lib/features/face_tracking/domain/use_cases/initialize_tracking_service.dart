import 'package:asbt/core/usecase/usecase.dart';
import 'package:asbt/core/resources/data_state.dart';
import 'package:asbt/features/face_tracking/domain/repository/face_tracking_repository.dart';
import 'package:asbt/features/face_tracking/domain/models/face_tracking_config.dart';

/// Use case for initializing face tracking service
class InitializeTrackingService implements UseCase<bool, FaceTrackingConfig> {
  final FaceTrackingRepository _repository;

  const InitializeTrackingService(this._repository);

  @override
  Future<DataState<bool>> call({FaceTrackingConfig? params}) async {
    if (params == null) {
      return const DataFailed('Configuration is required');
    }

    return await _repository.initialize(params);
  }
}