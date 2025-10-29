import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';

import '../../features/face_tracking/data/repository/face_tracking_repository_impl.dart';
import '../../features/face_tracking/domain/repository/face_tracking_repository.dart';
import '../../features/face_tracking/domain/use_cases/initialize_tracking_service.dart';
import '../../features/face_tracking/domain/use_cases/submit_image_for_processing.dart';
import '../../features/face_tracking/domain/use_cases/get_face_detection_stream.dart';
import '../../features/face_tracking/presentation/bloc/face_tracking_bloc.dart';

/// Dependency injection configuration
class AppDependencies {
  static final GetIt _getIt = GetIt.instance;

  /// Get service locator instance
  static GetIt get getIt => _getIt;

  /// Initialize all dependencies
  static Future<void> initialize() async {
    // External dependencies
    _getIt.registerLazySingleton<FacesdkPlugin>(() => FacesdkPlugin());

    // Repositories
    _getIt.registerLazySingleton<FaceTrackingRepository>(
      () => FaceTrackingRepositoryImpl(_getIt<FacesdkPlugin>()),
    );

    // Use cases
    _getIt.registerLazySingleton(
      () => InitializeTrackingService(_getIt<FaceTrackingRepository>()),
    );
    
    _getIt.registerLazySingleton(
      () => SubmitImageForProcessing(_getIt<FaceTrackingRepository>()),
    );
    
    _getIt.registerLazySingleton(
      () => GetFaceDetectionStream(_getIt<FaceTrackingRepository>()),
    );

    // BLoC
    _getIt.registerFactory(
      () => FaceTrackingBloc(
        initializeTrackingService: _getIt<InitializeTrackingService>(),
        submitImageForProcessing: _getIt<SubmitImageForProcessing>(),
        getFaceDetectionStream: _getIt<GetFaceDetectionStream>(),
      ),
    );
    _getIt.registerFactory(()=>FaceRecognitionBloc());
  }

  /// Dispose all dependencies
  static Future<void> dispose() async {
    await _getIt.reset();
  }
}