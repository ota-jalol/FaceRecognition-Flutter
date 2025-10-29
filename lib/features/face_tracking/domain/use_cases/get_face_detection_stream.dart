import 'dart:async';
import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/core/resources/data_state.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/face_result.dart';

/// Use case for getting face detection stream
class GetFaceDetectionStream implements UseCaseNoParams<Stream<DataState<List<FaceResult>>>> {
  final FaceTrackingRepository _repository;

  const GetFaceDetectionStream(this._repository);

  @override
  Future<DataState<Stream<DataState<List<FaceResult>>>>> call() async {
    try {
      final stream = _repository.processImageStream();
      return DataSuccess(stream);
    } catch (e) {
      return DataFailed('Failed to get face detection stream: $e');
    }
  }
}