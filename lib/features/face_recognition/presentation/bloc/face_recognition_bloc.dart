import 'dart:async';
import 'package:facerecognition_flutter/core/constants/app_constants.dart';
import 'package:facerecognition_flutter/core/usecase/usecase.dart';
import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/usecases/initialize_face_tracking.dart';
import 'package:facerecognition_flutter/features/face_recognition/domain/usecases/start_face_tracking.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_event.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for managing face recognition state and business logic
class FaceRecognitionBloc
    extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
  final InitializeFaceTrackingUseCase _initializeFaceTracking;
  final StartFaceTrackingUseCase _startFaceTracking;

  StreamSubscription<FaceResult>? _faceTrackingSubscription;

  int _verificationAttempts = 0;

  FaceRecognitionBloc({
    required InitializeFaceTrackingUseCase initializeFaceTracking,
    required StartFaceTrackingUseCase startFaceTracking,
  }) : _initializeFaceTracking = initializeFaceTracking,
       _startFaceTracking = startFaceTracking,
       super(const FaceRecognitionInitial()) {
    on<InitializeFaceTracking>(_onInitialize);
    on<StartFaceTracking>(_onStartTracking);
    on<StopFaceTracking>(_onStopTracking);
    on<FaceDetected>(_onFaceDetected);
    on<PhotoCaptured>(_onPhotoCaptured);
    on<VerificationSuccess>(_onVerificationSuccess);
    on<VerificationFailed>(_onVerificationFailed);
    on<ResetFaceRecognition>(_onReset);
  }

  Future<void> _onInitialize(
    InitializeFaceTracking event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(const FaceRecognitionInitializing());

    final result = await _initializeFaceTracking(params: NoParams());

    result.data != null && result.data == true
        ? emit(const FaceRecognitionReady())
        : emit(
            FaceRecognitionError(
              message: result.error ?? 'Failed to initialize',
              canRetry: true,
            ),
          );
  }

  Future<void> _onStartTracking(
    StartFaceTracking event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    try {
      final stream = await _startFaceTracking(params: NoParams());

      emit(const FaceRecognitionTracking());

      await _faceTrackingSubscription?.cancel();
      _faceTrackingSubscription = stream.listen((faceResult) {
        // Check if photo was captured
        if (faceResult.isPhotoCaptured && faceResult.base64Photo != null) {
          add(PhotoCaptured(faceResult.base64Photo!));
        } else {
          // Normal face detection
          add(
            FaceDetected(
              confidence: faceResult.confidence,
              isCentered: faceResult.isCentered,
              isPreparingPhoto: faceResult.isPreparingPhoto,
              message: faceResult.message,
            ),
          );
        }
      }, onError: (error) => add(VerificationFailed(error.toString())));
    } catch (e) {
      emit(FaceRecognitionError(message: e.toString(), canRetry: true));
    }
  }

  Future<void> _onStopTracking(
    StopFaceTracking event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    await _faceTrackingSubscription?.cancel();
    _faceTrackingSubscription = null;
  
    emit(const FaceRecognitionReady());
  }

  void _onFaceDetected(FaceDetected event, Emitter<FaceRecognitionState> emit) {
    if (state is FaceRecognitionTracking) {
      final currentState = state as FaceRecognitionTracking;

      // Check if preparing photo - emit capturing state
      if (event.isPreparingPhoto) {
        emit(const FaceRecognitionCapturing());
        return;
      }

      // Always update tracking state with latest face result (detected or not)
      emit(
        currentState.copyWith(
          faceResult: FaceResult(
            faceDetected: event.confidence > 0.0, // Face detected if confidence > 0
            confidence: event.confidence,
            isCentered: event.isCentered,
            isPreparingPhoto: event.isPreparingPhoto,
            message: event.message,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }
  }

  void _onPhotoCaptured(
    PhotoCaptured event,
    Emitter<FaceRecognitionState> emit,
  ) {
    // Photo captured successfully - emit verified state with photo bytes
    emit(FaceRecognitionVerified(event.photoBytes));
  }

  void _onVerificationSuccess(
    VerificationSuccess event,
    Emitter<FaceRecognitionState> emit,
  ) {
    // This can be used for additional verification logic if needed
    emit(FaceRecognitionVerified(const []));
  }

  void _onVerificationFailed(
    VerificationFailed event,
    Emitter<FaceRecognitionState> emit,
  ) {
    _verificationAttempts++;

    if (_verificationAttempts >= AppConstants.maxVerificationAttempts) {
      emit(FaceRecognitionMaxAttemptsReached(event.error));
    } else {
      emit(
        FaceRecognitionWaiting(
          attemptCount: _verificationAttempts,
        ),
      );

     
    }
  }

  void _onReset(
    ResetFaceRecognition event,
    Emitter<FaceRecognitionState> emit,
  ) {
    _verificationAttempts = 0;
    emit(const FaceRecognitionInitial());
  }

  @override
  Future<void> close() {
    _faceTrackingSubscription?.cancel();
    return super.close();
  }
}
