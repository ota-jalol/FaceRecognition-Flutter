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
  } catch (e) {
    debugPrint('❌ Failed to initialize app: $e');
    rethrow; // Error yuqoriga o'tkaziladi
  }
}
