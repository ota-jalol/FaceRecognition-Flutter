import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_tracking/data/repository/face_tracking_repository_impl.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/image_processing_request.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';


class FaceTrackingService {
  // Singleton pattern
  FaceTrackingService._();
  static final FaceTrackingService _instance = FaceTrackingService._();
  static FaceTrackingService get instance => _instance;

  // Repository and state
  FaceTrackingRepository? _repository;
  int _requestIdCounter = 0;
  bool _isInitializing = false;
  Future<void> initialize() async {
    if (_isInitializing) {
      debugPrint('⚠️ FaceTrackingService is already initializing...');
      return;
    }

    if (_repository?.isInitialized == true) {
      debugPrint('✅ FaceTrackingService already initialized');
      return;
    }

    _isInitializing = true;
    try {
      debugPrint('🚀 Initializing FaceTrackingService...');
      _repository = FaceTrackingRepositoryImpl();
      await _repository!.initialize();
      debugPrint('✅ FaceTrackingService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize FaceTrackingService: $e');
      _repository = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Send image for processing
  ///
  /// Throws [StateError] if service is not initialized.
  /// Call [initialize] first in main.dart.
  void sendImageForProcessing({
    required CameraImage image,
    required int orientation,
    required bool frontFacing,
    required bool isPhotoCaptureRequesting,
  }) {
    if (_repository == null || !_repository!.isInitialized) {
      throw StateError(
        'FaceTrackingService not initialized! '
        'Call FaceTrackingService.instance.initialize() in main.dart first.',
      );
    }

    final request = ImageProcessingRequest(
      image: image,
      orientation: orientation,
      frontFacing: frontFacing,
      capturePhoto: isPhotoCaptureRequesting,
      requestId: _requestIdCounter++,
    );

    _repository!.submitImage(request);
  }

  /// Get stream of processing results
  ///
  /// Throws [StateError] if service is not initialized.
  Stream<FaceResult> getProcessingResults() {
    if (_repository == null) {
      throw StateError(
        'FaceTrackingService not initialized! '
        'Call FaceTrackingService.instance.initialize() in main.dart first.',
      );
    }
    return _repository!.processImageStream();
  }

  /// Get image dimensions
  int get imageWidth => _repository?.imageWidth ?? 0;
  int get imageHeight => _repository?.imageHeight ?? 0;

  /// Check if service is initialized
  bool get isInitialized => _repository?.isInitialized ?? false;

  /// Pause processing (call when screen is disposed)
  /// This stops accepting new frames without killing the isolate
  void pause() {
    if (_repository == null) {
      debugPrint('⚠️ Cannot pause - service not initialized');
      return;
    }
    _repository!.pause();
    debugPrint('⏸️ FaceTrackingService paused');
  }

  /// Resume processing (call when screen is re-entered)
  void resume() {
    if (_repository == null) {
      debugPrint('⚠️ Cannot resume - service not initialized');
      return;
    }
    _repository!.resume();
    debugPrint('▶️ FaceTrackingService resumed');
  }

  /// Reset state without killing isolate (for screen re-entry)
  void reset() {
    _requestIdCounter = 0;
    if (_repository != null) {
      _repository!.clearQueue();
      debugPrint('🔄 FaceTrackingService reset (queue cleared)');
    }
  }

  /// Dispose the service (call when app is closing)
  Future<void> dispose() async {
    if (_repository != null) {
      debugPrint('🗑️ Disposing FaceTrackingService...');
      await _repository!.dispose();
      _repository = null;
      _requestIdCounter = 0;
    }
  }

}
