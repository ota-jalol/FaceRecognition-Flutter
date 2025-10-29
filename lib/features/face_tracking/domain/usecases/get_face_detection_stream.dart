import '../../../../core/usecase/usecase.dart';
import '../../../../core/resources/data_state.dart';
import '../models/face_result.dart';
import '../repository/face_tracking_repository.dart';

/// Use case for getting face detection results stream from KBY-AI SDK
class GetFaceDetectionStream implements UseCaseNoParams<Stream<DataState<List<FaceResult>>>> {
  final FaceTrackingRepository _repository;

  const GetFaceDetectionStream(this._repository);

  @override
  Future<DataState<Stream<DataState<List<FaceResult>>>>> call() async {
    try {
      final stream = _repository.processImageStream();
      return DataSuccess(stream);
    } catch (e) {
      return DataFailed('Failed to get detection stream: $e');
    }
  }
}
