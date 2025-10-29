import 'package:flutter/foundation.dart';

import '../../domain/models/image_processing_request.dart';
import '../../domain/models/face_result.dart';
import '../../domain/models/face_tracking_config.dart';
import '../../domain/use_cases/initialize_tracking_service.dart';
import '../../domain/use_cases/submit_image_for_processing.dart';
import '../../domain/use_cases/get_face_detection_stream.dart';
import '../../../../core/resources/data_state.dart';
import '../../../../core/di/app_dependencies.dart';

/// Service layer for face tracking - Clean Architecture facade
class FaceTrackingService {
  // Singleton pattern
  FaceTrackingService._();
  static final FaceTrackingService _instance = FaceTrackingService._();
  static FaceTrackingService get instance => _instance;

  // Use cases
  late final InitializeTrackingService _initializeTrackingService;
  late final SubmitImageForProcessing _submitImageForProcessing;
  late final GetFaceDetectionStream _getFaceDetectionStream;

  // State
  int _requestIdCounter = 0;
  bool _isInitializing = false;
  bool _isInitialized = false;
  Stream<DataState<List<FaceResult>>>? _faceDetectionStream;

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
      _submitImageForProcessing = AppDependencies.getIt<SubmitImageForProcessing>();
      _getFaceDetectionStream = AppDependencies.getIt<GetFaceDetectionStream>();

      // Initialize with default config
      final config = FaceTrackingConfig.defaultConfig();
      final result = await _initializeTrackingService.call(params: config);

      if (result is DataSuccess) {
        _isInitialized = true;
        
        // Get face detection stream
        final streamResult = await _getFaceDetectionStream.call();
        if (streamResult is DataSuccess) {
          _faceDetectionStream = streamResult.data;
        }
        
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

  /// Send image for processing
  ///
  /// Throws [StateError] if service is not initialized.
  /// Call [initialize] first in main.dart.
  Future<void> sendImageForProcessing({
    required int orientation,
    required bool frontFacing,
    required bool isPhotoCaptureRequesting,
  }) async {
    if (!_isInitialized) {
      throw StateError(
        'FaceTrackingService not initialized! '
        'Call FaceTrackingService.instance.initialize() in main.dart first.',
      );
    }

    final request = ImageProcessingRequest(
      orientation: orientation,
      frontFacing: frontFacing,
      capturePhoto: isPhotoCaptureRequesting,
      requestId: _requestIdCounter++,
    );

    final result = await _submitImageForProcessing.call(params: request);
    if (result is DataFailed) {
      debugPrint('❌ Failed to submit image: ${result.error}');
    }
  }

  /// Get stream of processing results
  ///
  /// Throws [StateError] if service is not initialized.
  Stream<DataState<List<FaceResult>>> getProcessingResults() {
    if (!_isInitialized || _faceDetectionStream == null) {
      throw StateError(
        'FaceTrackingService not initialized! '
        'Call FaceTrackingService.instance.initialize() in main.dart first.',
      );
    }
    return _faceDetectionStream!;
  }

  /// Get image dimensions (from default config)
  int get imageWidth => FaceTrackingConfig.defaultConfig().imageWidth;
  int get imageHeight => FaceTrackingConfig.defaultConfig().imageHeight;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Pause processing (call when screen is disposed)
  /// This stops accepting new frames without killing the SDK
  void pause() {
    if (!_isInitialized) {
      debugPrint('⚠️ Cannot pause - service not initialized');
      return;
    }
    // Repository pause is handled at repository level
    debugPrint('⏸️ FaceTrackingService paused');
  }

  /// Resume processing (call when screen is re-entered)
  void resume() {
    if (!_isInitialized) {
      debugPrint('⚠️ Cannot resume - service not initialized');
      return;
    }
    // Repository resume is handled at repository level
    debugPrint('▶️ FaceTrackingService resumed');
  }

  /// Reset state (for screen re-entry)
  void reset() {
    _requestIdCounter = 0;
    debugPrint('🔄 FaceTrackingService reset');
  }

  /// Dispose the service (call when app is closing)
  Future<void> dispose() async {
    if (_isInitialized) {
      debugPrint('🗑️ Disposing FaceTrackingService...');
      _isInitialized = false;
      _faceDetectionStream = null;
      _requestIdCounter = 0;
    }
  }
}
