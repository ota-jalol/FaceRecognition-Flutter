import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/use_cases/initialize_tracking_service.dart';
import '../../domain/use_cases/submit_image_for_processing.dart';
import '../../domain/use_cases/get_face_detection_stream.dart';
import '../../domain/models/face_tracking_config.dart';
import '../../domain/models/image_processing_request.dart';
import '../../../../core/resources/data_state.dart';
import 'face_tracking_event.dart';
import 'face_tracking_state.dart';

/// BLoC for managing face tracking functionality
class FaceTrackingBloc extends Bloc<FaceTrackingEvent, FaceTrackingState> {
  final InitializeTrackingService _initializeTrackingService;
  final SubmitImageForProcessing _submitImageForProcessing;
  final GetFaceDetectionStream _getFaceDetectionStream;

  StreamSubscription? _faceDetectionSubscription;
  int _requestIdCounter = 0;

  FaceTrackingBloc({
    required InitializeTrackingService initializeTrackingService,
    required SubmitImageForProcessing submitImageForProcessing,
    required GetFaceDetectionStream getFaceDetectionStream,
  })  : _initializeTrackingService = initializeTrackingService,
        _submitImageForProcessing = submitImageForProcessing,
        _getFaceDetectionStream = getFaceDetectionStream,
        super(const FaceTrackingInitial()) {
    
    // Register event handlers
    on<InitializeFaceTracking>(_onInitializeFaceTracking);
    on<StartFaceDetection>(_onStartFaceDetection);
    on<SubmitCameraImage>(_onSubmitCameraImage);
    on<PauseFaceTracking>(_onPauseFaceTracking);
    on<ResumeFaceTracking>(_onResumeFaceTracking);
    on<StopFaceTracking>(_onStopFaceTracking);
    on<CapturePhoto>(_onCapturePhoto);
    on<ResetFaceTracking>(_onResetFaceTracking);
  }

  /// Initialize face tracking
  Future<void> _onInitializeFaceTracking(
    InitializeFaceTracking event,
    Emitter<FaceTrackingState> emit,
  ) async {
    if (state is FaceTrackingLoading) return;

    emit(const FaceTrackingLoading());

    try {
      // Initialize with default configuration
      final config = FaceTrackingConfig.defaultConfig();
      final result = await _initializeTrackingService.call(params: config);

      if (result is DataSuccess) {
        debugPrint('✅ Face tracking initialized successfully');
        emit(const FaceTrackingReady());
      } else if (result is DataFailed) {
        debugPrint('❌ Face tracking initialization failed: ${result.error}');
        emit(FaceTrackingError(error: result.error ?? 'Unknown error'));
      }
    } catch (e) {
      debugPrint('❌ Exception during face tracking initialization: $e');
      emit(FaceTrackingError(error: 'Initialization failed: $e'));
    }
  }

  /// Start face detection stream
  Future<void> _onStartFaceDetection(
    StartFaceDetection event,
    Emitter<FaceTrackingState> emit,
  ) async {
    if (state is! FaceTrackingReady) {
      emit(const FaceTrackingError(error: 'Face tracking not initialized'));
      return;
    }

    try {
      // Get face detection stream
      final streamResult = await _getFaceDetectionStream.call();
      
      if (streamResult is DataSuccess) {
        // Subscribe to face detection stream
        _faceDetectionSubscription = streamResult.data!.listen(
          (dataState) {
            if (dataState is DataSuccess) {
              final faces = dataState.data ?? [];
              
              // Check if this is a photo capture result
              final hasPhotoCapture = faces.any((face) => face.faceImage != null);
              
              if (hasPhotoCapture) {
                final capturedFace = faces.firstWhere((face) => face.faceImage != null);
                // Convert face image to base64 for compatibility
                final base64Photo = _convertFaceImageToBase64(capturedFace);
                add(const StopFaceTracking()); // Stop after photo capture
                emit(FaceTrackingPhotoCaptured(
                  base64Photo: base64Photo,
                  faceResult: capturedFace,
                  message: 'Photo captured successfully',
                ));
              } else {
                // Regular face detection
                emit(FaceTrackingActive(
                  faces: faces,
                  message: _generateStatusMessage(faces),
                  isProcessing: faces.isNotEmpty,
                ));
              }
            } else if (dataState is DataFailed) {
              emit(FaceTrackingError(error: dataState.error ?? 'Detection failed'));
            }
          },
          onError: (error) {
            debugPrint('❌ Face detection stream error: $error');
            emit(FaceTrackingError(error: 'Stream error: $error'));
          },
        );

        emit(const FaceTrackingActive(faces: []));
        debugPrint('✅ Face detection started');
      } else if (streamResult is DataFailed) {
        emit(FaceTrackingError(error: streamResult.error ?? 'Failed to start detection'));
      }
    } catch (e) {
      debugPrint('❌ Exception starting face detection: $e');
      emit(FaceTrackingError(error: 'Failed to start detection: $e'));
    }
  }

  /// Submit camera image for processing
  Future<void> _onSubmitCameraImage(
    SubmitCameraImage event,
    Emitter<FaceTrackingState> emit,
  ) async {
    if (state is! FaceTrackingActive && state is! FaceTrackingCapturingPhoto) {
      return; // Only process images when actively tracking
    }

    try {
      final request = ImageProcessingRequest(
        orientation: event.orientation,
        frontFacing: event.frontFacing,
        capturePhoto: event.capturePhoto,
        requestId: _requestIdCounter++,
      );

      if (event.capturePhoto) {
        emit(FaceTrackingCapturingPhoto(
          faces: state is FaceTrackingActive ? (state as FaceTrackingActive).faces : [],
          message: 'Preparing photo capture...',
        ));
      }

      final result = await _submitImageForProcessing.call(params: request);

      if (result is DataFailed) {
        debugPrint('⚠️ Failed to submit image: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Exception submitting camera image: $e');
    }
  }

  /// Pause face tracking
  void _onPauseFaceTracking(
    PauseFaceTracking event,
    Emitter<FaceTrackingState> emit,
  ) {
    _faceDetectionSubscription?.pause();
    emit(const FaceTrackingPaused());
    debugPrint('⏸️ Face tracking paused');
  }

  /// Resume face tracking
  void _onResumeFaceTracking(
    ResumeFaceTracking event,
    Emitter<FaceTrackingState> emit,
  ) {
    _faceDetectionSubscription?.resume();
    emit(const FaceTrackingActive(faces: []));
    debugPrint('▶️ Face tracking resumed');
  }

  /// Stop face tracking
  void _onStopFaceTracking(
    StopFaceTracking event,
    Emitter<FaceTrackingState> emit,
  ) {
    _faceDetectionSubscription?.cancel();
    _faceDetectionSubscription = null;
    emit(const FaceTrackingReady());
    debugPrint('⏹️ Face tracking stopped');
  }

  /// Capture photo
  void _onCapturePhoto(
    CapturePhoto event,
    Emitter<FaceTrackingState> emit,
  ) {
    if (state is FaceTrackingActive) {
      emit(FaceTrackingCapturingPhoto(
        faces: (state as FaceTrackingActive).faces,
        message: 'Capturing photo...',
      ));
      debugPrint('📸 Photo capture initiated');
    }
  }

  /// Reset face tracking
  void _onResetFaceTracking(
    ResetFaceTracking event,
    Emitter<FaceTrackingState> emit,
  ) {
    _faceDetectionSubscription?.cancel();
    _faceDetectionSubscription = null;
    _requestIdCounter = 0;
    emit(const FaceTrackingInitial());
    debugPrint('🔄 Face tracking reset');
  }

  /// Generate status message based on face detection results
  String _generateStatusMessage(List<dynamic> faces) {
    if (faces.isEmpty) {
      return 'No face detected';
    }

    final face = faces.first;
    if (face.liveness > 0.9) {
      return 'High quality face detected';
    } else if (face.liveness > 0.7) {
      return 'Good face detected';
    } else {
      return 'Face detected - improve position';
    }
  }

  /// Convert face image to base64 string for compatibility
  String _convertFaceImageToBase64(dynamic face) {
    // TODO: Implement actual base64 conversion from face.faceImage
    // This is a placeholder for compatibility with existing UI
    return 'data:image/jpeg;base64,placeholder_image_data';
  }

  @override
  Future<void> close() {
    _faceDetectionSubscription?.cancel();
    return super.close();
  }
}