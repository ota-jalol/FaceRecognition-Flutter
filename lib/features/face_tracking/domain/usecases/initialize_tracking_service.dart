import '../../../../core/resources/data_state.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/face_tracking_repository.dart';
import '../models/face_tracking_config.dart';

/// Use case for initializing KBY-AI Face SDK tracking service
class InitializeTrackingService implements UseCase<bool, FaceTrackingConfig> {
  final FaceTrackingRepository _repository;

  const InitializeTrackingService(this._repository);

  @override
  Future<DataState<bool>> call({FaceTrackingConfig? params}) async {
    final config = params ?? FaceTrackingConfig.defaultConfig();
    return await _repository.initialize(config);
  }
}
