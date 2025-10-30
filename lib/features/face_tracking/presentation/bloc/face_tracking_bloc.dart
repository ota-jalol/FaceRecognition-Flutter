import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/use_cases/initialize_tracking_service.dart';
import '../../domain/models/face_tracking_config.dart';
import '../../../../core/resources/data_state.dart';
import 'face_tracking_event.dart';
import 'face_tracking_state.dart';

/// BLoC for managing face tracking functionality
class FaceTrackingBloc extends Bloc<FaceTrackingEvent, FaceTrackingState> {
  final InitializeTrackingService _initializeTrackingService;

  StreamSubscription? _faceDetectionSubscription;


  FaceTrackingBloc({
    required InitializeTrackingService initializeTrackingService,
  })  : _initializeTrackingService = initializeTrackingService,
        super(const FaceTrackingInitial()) {
    
    // Register event handlers
    on<InitializeFaceTracking>(_onInitializeFaceTracking);
 
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



  @override
  Future<void> close() {
    _faceDetectionSubscription?.cancel();
    return super.close();
  }
}