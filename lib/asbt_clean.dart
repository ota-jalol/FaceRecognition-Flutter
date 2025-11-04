// Core exports
export 'core/constants/app_constants.dart';
export 'core/resources/data_state.dart';
export 'core/usecase/usecase.dart';


export 'features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
export 'features/face_recognition/presentation/bloc/face_recognition_event.dart';
export 'features/face_recognition/presentation/bloc/face_recognition_state.dart';
export 'features/face_recognition/presentation/pages/face_id_take_photo_v2.dart';
export 'features/face_recognition/presentation/widgets/face_detection_circle.dart';
export 'features/face_recognition/presentation/widgets/status_message.dart';
export 'features/face_recognition/presentation/widgets/tips_section.dart';

// Feature exports - Face Tracking (Optimized Background Worker)
export 'features/face_tracking/domain/models/face_tracking_config.dart';
export 'features/face_tracking/domain/models/image_processing_request.dart';
export 'features/face_tracking/domain/usecases/initialize_tracking_service.dart';
export 'features/face_tracking/presentation/services/face_tracking_service.dart';

// Localization exports
export 'localization/my_localization.dart';

// Models and utilities
export 'face_result_model.dart';

// ============================================================================
// Universal App Initialization Function
// ============================================================================
import 'package:asbt/core/di/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'localization/my_localization.dart';
import 'features/face_tracking/presentation/services/face_tracking_service.dart';

Future<void> initializeApp({
  List<String> supportedLocales = const ["uz", "ru", "en", "fr", "cuz"],
  String? defaultLang,
  String? actualLang,
  GetIt? injector,
}) async {
  try {
    await MyLocalization().initialize(
      supportedLocales: supportedLocales,
      actualLang: defaultLang ?? actualLang ?? "ru",
    );
    debugPrint('✅ Localization initialized!');

    // 2️⃣ Initialize Dependency Injection
    debugPrint('💉 Initializing Dependency Injection...');
    await initializeAppDependencies(injector!);
    debugPrint('✅ Dependency Injection initialized!');

    // 3️⃣ Initialize Face Tracking Service
    debugPrint('🚀 Initializing Face Tracking Service...');
    await FaceTrackingService.instance.initialize();
    debugPrint('✅ Face Tracking Service initialized successfully!');
  } catch (e) {
    debugPrint('❌ Failed to initialize app: $e');
    rethrow; // Error yuqoriga o'tkaziladi
  }
}
