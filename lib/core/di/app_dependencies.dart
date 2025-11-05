import 'package:asbt/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';

/// Dependency injection configuration
GetIt getIt = GetIt.instance;
Future<void> initializeAppDependencies(GetIt _injector) async {
  getIt = _injector;

  getIt.registerLazySingleton<FacesdkPlugin>(() => FacesdkPlugin());


  getIt.registerFactory(() => FaceRecognitionBloc());
}
