import 'package:flutter/foundation.dart';

import '../../domain/models/image_processing_request.dart';
import '../../domain/models/face_result.dart';
import '../../domain/models/face_tracking_config.dart';
import '../../domain/use_cases/initialize_tracking_service.dart';
import '../../../../core/resources/data_state.dart';
import '../../../../core/di/app_dependencies.dart';

/// Service layer for face tracking - Clean Architecture facade
class FaceTrackingService {
  // Singleton pattern
  FaceTrackingService._();
  static final FaceTrackingService _instance = FaceTrackingService._();
  static FaceTrackingService get instance => _instance;

  late final InitializeTrackingService _initializeTrackingService;

  bool _isInitializing = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitializing) {
      debugPrint('⚠️ FaceTrackingService is already initializing...');
      return;
    }

    if (_isInitialized) {
      debugPrint('✅ FaceTrackingService already initialized');
      return;
    }

    _isInitializing = true;
    try {
      debugPrint('🚀 Initializing FaceTrackingService...');
      
      // Get use cases from DI
      _initializeTrackingService = AppDependencies.getIt<InitializeTrackingService>();

      // Initialize with default config
      final config = FaceTrackingConfig.defaultConfig();
      final result = await _initializeTrackingService.call(params: config);

      if (result is DataSuccess) {
        _isInitialized = true;
        
       
        
        debugPrint('✅ FaceTrackingService initialized successfully');
      } else if (result is DataFailed) {
        throw Exception(result.error);
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize FaceTrackingService: $e');
      _isInitialized = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose the service (call when app is closing)
  Future<void> dispose() async {
    if (_isInitialized) {
      debugPrint('🗑️ Disposing FaceTrackingService...');
      _isInitialized = false;
    }
  }
}
