import 'package:asbt/core/constants/app_constants.dart';
import 'package:asbt/features/face_recognition/presentation/widgets/face_detection_circle.dart';
import 'package:asbt/features/face_recognition/presentation/widgets/status_message.dart';
import 'package:asbt/features/face_recognition/presentation/widgets/tips_section.dart';
import 'package:asbt/face_result_model.dart';
import 'package:asbt/localization/my_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  
  // Photo capture logic
  int _consecutiveFaceDetections = 0;
  bool _isCapturingPhoto = false;
  bool _photoTaken = false;
  Timer? _captureTimer;

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
        
        // Yuz topilmadi, hisoblagichni qayta boshlash
        _consecutiveFaceDetections = 0;
        _captureTimer?.cancel();
        _captureTimer = null;
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
          _consecutiveFaceDetections = 0;
          _captureTimer?.cancel();
          _captureTimer = null;
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
        
        // Yuz sifatli va markazda bo'lsa
        if (liveness > 0.7 && _isCentered && !_photoTaken) {
          // Ketma-ket topilgan yuzlar hisoblagichini oshirish
          _consecutiveFaceDetections++;
          
          if (_consecutiveFaceDetections >= 5 && !_isCapturingPhoto) {
            // 5 marta ketma-ket yuz topildi, rasm olish jarayonini boshlash
            _isCapturingPhoto = true;
            _currentMessage = tr('taking_photo');
            
            // 1 sekund kutib rasm olish
            _captureTimer = Timer(Duration(seconds: 1), () {
              _capturePhoto(face['faceJpg']);
            });
          } else if (_consecutiveFaceDetections < 5) {
            _currentMessage = '${tr('face_detected_good')} ($_consecutiveFaceDetections/5)';
          }
        } else {
          // Yuz sifatsiz yoki markazda emas
          _consecutiveFaceDetections = 0;
          _captureTimer?.cancel();
          _captureTimer = null;
          
          if (liveness > 0.7) {
            if (_isCentered) {
              _currentMessage = tr('face_detected_good');
            } else {
              _currentMessage = tr('center_face_please');
            }
          } else {
            _currentMessage = tr('face_too_close_or_spoof');
          }
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

    // Timer'ni bekor qilish
    _captureTimer?.cancel();

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

    // Create a FaceResult based on current face detection data
    FaceResult? currentFaceResult;
    if (_faceDetected && _currentFaces != null && _currentFaces!.isNotEmpty) {
      var face = _currentFaces!.first;
      currentFaceResult = FaceResult(
        faceDetected: true,
        isCentered: _isCentered,
        confidence: (face['liveness'] as num?)?.toDouble() ?? 0.0,
        message: _currentMessage,
        timestamp: DateTime.now(),
        imageWidth: (face['frameWidth'] as num?)?.toDouble() ?? 0.0,
        imageHeight: (face['frameHeight'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Container(
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
              Expanded(
                child: _buildMainContent(screenSize, currentFaceResult),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(Size screenSize, FaceResult? faceResult) {
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
              state: faceResult,
              onFaceDetected: _onFaceDetected,
            ),

            SizedBox(height: verticalSpacing),

            // Status message
            StatusMessage(state: faceResult, screenSize: screenSize),

            SizedBox(height: verticalSpacing * 0.6),

            // Tips section (only on larger screens)
            AnimatedOpacity(
              opacity: _shouldShowTips(faceResult, screenSize) ? 1.0 : 0.0,
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

  bool _shouldShowTips(FaceResult? faceResult, Size screenSize) {
    if (screenSize.height <= 550) return false;

    // Don't show tips during photo capture
    if (_isCapturingPhoto || _photoTaken) {
      return false;
    }

    // Don't show tips when face is detected and centered
    if (faceResult != null && 
        faceResult.faceDetected && 
        faceResult.isCentered && 
        faceResult.confidence > 0.7) {
      return false;
    }

    return true;
  }

  void _capturePhoto(dynamic img) {
    if (!mounted || _photoTaken) return;
    widget.onTake(img);
    setState(() {
      _photoTaken = true;
      _isCapturingPhoto = false;
      _currentMessage = tr('photo_captured');
    });
    
    // Bu yerda rasm olish logikasi qo'shiladi
    // Masalan: BlocProvider.of<FaceRecognitionBloc>(context).add(CapturePhotoEvent());
  }
}
