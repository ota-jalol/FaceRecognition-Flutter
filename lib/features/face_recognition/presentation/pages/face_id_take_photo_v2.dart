import 'package:facerecognition_flutter/core/constants/app_constants.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/face_detection_circle.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/status_message.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/tips_section.dart';
import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/localization/my_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modern Face ID screen with clean architecture and BLoC pattern
class FaceIDTakePhoto extends StatelessWidget {
  final Function onTake;
  final double boxWidth;
  final double boxHeight;
  final String title;

  const FaceIDTakePhoto({
    this.boxWidth = AppConstants.defaultBoxWidth,
    this.boxHeight = AppConstants.defaultBoxHeight,
    required this.onTake,
    this.title = "",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FaceIDTakePhotoView(
      onTake: onTake,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      title: title,
    );
  }
}

class FaceIDTakePhotoView extends StatefulWidget {
  final Function onTake;
  final double boxWidth;
  final double boxHeight;
  final String title;

  const FaceIDTakePhotoView({
    required this.onTake,
    required this.boxWidth,
    required this.boxHeight,
    required this.title,
    super.key,
  });

  @override
  State<FaceIDTakePhotoView> createState() => _FaceIDTakePhotoViewState();
}

class _FaceIDTakePhotoViewState extends State<FaceIDTakePhotoView>
    with WidgetsBindingObserver {
  // Face detection data
  List<dynamic>? _currentFaces;
  String _currentMessage = "";
  bool _faceDetected = false;
  bool _isCentered = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.initState()');
    WidgetsBinding.instance.addObserver(this);
    _currentMessage = tr('position_face_center');
  }

  // Face detection callback method
  void _onFaceDetected(List<dynamic> faces) {
    if (!mounted) return;

    setState(() {
      _currentFaces = faces;

      if (faces.isEmpty) {
        _faceDetected = false;
        _isCentered = false;
        _currentMessage = tr('no_face_detected');
      } else {
        _faceDetected = true;

        // Check if face is centered (you can adjust these thresholds)
        var face = faces.first;

        // Safely get face data with null checks
        double frameWidth = (face['frameWidth'] as num?)?.toDouble() ?? 1.0;
        double frameHeight = (face['frameHeight'] as num?)?.toDouble() ?? 1.0;
        double x1 = (face['x1'] as num?)?.toDouble() ?? 0.0;
        double y1 = (face['y1'] as num?)?.toDouble() ?? 0.0;
        double x2 = (face['x2'] as num?)?.toDouble() ?? 0.0;
        double y2 = (face['y2'] as num?)?.toDouble() ?? 0.0;

        if (frameWidth <= 0 || frameHeight <= 0) {
          _currentMessage = tr('face_not_detected');
          return;
        }

        double faceX = (x1 + x2) / 2;
        double faceY = (y1 + y2) / 2;
        double centerX = frameWidth / 2;
        double centerY = frameHeight / 2;

        double distanceFromCenter =
            ((faceX - centerX).abs() + (faceY - centerY).abs()) / frameWidth;
        _isCentered = distanceFromCenter < 0.15; // Adjust threshold as needed

        double liveness = (face['liveness'] as num?)?.toDouble() ?? 0.0;
        if (liveness > 0.7) {
          // Liveness threshold
          if (_isCentered) {
            _currentMessage = tr('face_detected_good');
          } else {
            _currentMessage = tr('center_face_please');
          }
        } else {
          _currentMessage = tr('face_too_close_or_spoof');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save BLoC reference to use safely in dispose()
  }

  @override
  void dispose() {
    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.dispose() START');

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.dispose() END');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // App backgrounded - pause camera
      debugPrint('📱 [LIFECYCLE] App backgrounded - pausing camera');
    } else if (state == AppLifecycleState.resumed) {
      // App foregrounded - resume
      debugPrint('📱 [LIFECYCLE] App resumed - restarting camera');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: BlocConsumer<FaceRecognitionBloc, FaceRecognitionState>(
        listener: (context, state) {
          // Handle camera pause/resume based on state
          if (state is FaceRecognitionCapturing) {
          } else if (state is FaceRecognitionTracking) {
          } else if (state is FaceRecognitionVerified) {}

          // Handle state changes
          if (state is FaceRecognitionVerified) {
            // Photo was captured successfully
            // Call onTake callback with photo bytes
            if (state.photoBytes.isNotEmpty) {
              widget.onTake(state.photoBytes);
            }
          }
        },
        builder: (context, state) {
          // Create a custom state based on our face detection data
          FaceRecognitionState currentState;
          if (_faceDetected &&
              _currentFaces != null &&
              _currentFaces!.isNotEmpty) {
            var face = _currentFaces!.first;
            currentState = FaceRecognitionTracking(
              faceResult: FaceResult(
                faceDetected: true,
                isCentered: _isCentered,
                confidence: (face['liveness'] as num?)?.toDouble() ?? 0.0,
                message: _currentMessage,
                timestamp: DateTime.now(),
                imageWidth: (face['frameWidth'] as num?)?.toDouble() ?? 0.0,
                imageHeight: (face['frameHeight'] as num?)?.toDouble() ?? 0.0,
              ),
            );
          } else {
            currentState = const FaceRecognitionInitial();
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF0F4F8), // Light blue-grey
                  Color(0xFFF8FAFC), // Very light grey
                  Color(0xFFFFFFFF), // White
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildMainContent(screenSize, currentState)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(Size screenSize, FaceRecognitionState state) {
    final verticalSpacing = _calculateVerticalSpacing(screenSize);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Face detection area
            FaceDetectionCircle(
              screenSize: screenSize,
              state: state,
              onFaceDetected: _onFaceDetected,
            ),

            SizedBox(height: verticalSpacing),

            // Status message
            StatusMessage(state: state, screenSize: screenSize),

            SizedBox(height: verticalSpacing * 0.6),

            // Tips section (only on larger screens)
            AnimatedOpacity(
              opacity: _shouldShowTips(state, screenSize) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: TipsSection(screenSize: screenSize),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateVerticalSpacing(Size screenSize) {
    if (screenSize.height < 500) return 15.0;
    if (screenSize.height < 600) return 20.0;
    if (screenSize.height < 800) return 25.0;
    return 30.0;
  }

  bool _shouldShowTips(FaceRecognitionState state, Size screenSize) {
    if (screenSize.height <= 550) return false;

    if (state is FaceRecognitionVerifying ||
        state is FaceRecognitionVerified ||
        state is FaceRecognitionCapturing) {
      return false;
    }

    if (state is FaceRecognitionTracking) {
      return false;
    }

    return true;
  }
}
