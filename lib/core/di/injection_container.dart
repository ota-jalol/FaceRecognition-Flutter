import 'package:facerecognition_flutter/features/face_recognition/data/repository/face_tracking_repository_impl.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/repository/face_tracking_repository.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/usecases/initialize_face_tracking.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/usecases/start_face_tracking.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:facerecognition_flutter/features/face_tracking/data/repository/face_tracking_repository_impl.dart'
    as tracking;
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart'
    as tracking;
import 'package:facerecognition_flutter/features/face_tracking/domain/usecases/get_face_detection_stream.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/usecases/initialize_tracking_service.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/usecases/submit_image_for_processing.dart';
import 'package:get_it/get_it.dart';

GetIt injector = GetIt.instance;

/// Initialize dependency injection
Future<void> initializeDependencies(GetIt _injector) async {
  injector = _injector;
  // Face Recognition Repository
  injector.registerLazySingleton<FaceTrackingRepository>(
    () => FaceTrackingRepositoryImpl(),
  );

  // Face Recognition Use Cases
  injector.registerLazySingleton<InitializeFaceTrackingUseCase>(
    () => InitializeFaceTrackingUseCase(injector()),
  );

  injector.registerLazySingleton<StartFaceTrackingUseCase>(
    () => StartFaceTrackingUseCase(injector()),
  );

  // Face Recognition BLoC
  injector.registerFactory<FaceRecognitionBloc>(
    () => FaceRecognitionBloc(
      initializeFaceTracking: injector(),
      startFaceTracking: injector(),
    ),
  );

  // Face Tracking Repository (optimized background worker)
  injector.registerLazySingleton<tracking.FaceTrackingRepository>(
    () => tracking.FaceTrackingRepositoryImpl(),
  );

  // Face Tracking Use Cases
  injector.registerLazySingleton<InitializeFaceTrackingServiceUseCase>(
    () => InitializeFaceTrackingServiceUseCase(injector()),
  );

  injector.registerLazySingleton<GetFaceDetectionStreamUseCase>(
    () => GetFaceDetectionStreamUseCase(injector()),
  );

  injector.registerLazySingleton<SubmitImageForProcessingUseCase>(
    () => SubmitImageForProcessingUseCase(injector()),
  );
}
