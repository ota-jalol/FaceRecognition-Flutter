import 'package:asbt/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';

import '../../features/face_tracking/data/repository/face_tracking_repository_impl.dart';
import '../../features/face_tracking/domain/repository/face_tracking_repository.dart';
import '../../features/face_tracking/domain/use_cases/initialize_tracking_service.dart';
import '../../features/face_tracking/presentation/bloc/face_tracking_bloc.dart';

/// Dependency injection configuration
GetIt getIt = GetIt.instance;
Future<void> initializeAppDependencies(GetIt _injector) async {
  getIt = _injector;

  getIt.registerLazySingleton<FacesdkPlugin>(() => FacesdkPlugin());

  // Repositories
  getIt.registerLazySingleton<FaceTrackingRepository>(
    () => FaceTrackingRepositoryImpl(getIt<FacesdkPlugin>()),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => InitializeTrackingService(getIt<FaceTrackingRepository>()),
  );

  // BLoC
  getIt.registerFactory(
    () => FaceTrackingBloc(
      initializeTrackingService: getIt<InitializeTrackingService>(),
    ),
  );
  getIt.registerFactory(() => FaceRecognitionBloc());
}
