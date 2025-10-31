import 'dart:async';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_event.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for managing face recognition state and business logic
class FaceRecognitionBloc
    extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
 

  FaceRecognitionBloc() : 
       super(const FaceRecognitionInitial()) {
  }
  @override
  Future<void> close() {
    return super.close();
  }
}
