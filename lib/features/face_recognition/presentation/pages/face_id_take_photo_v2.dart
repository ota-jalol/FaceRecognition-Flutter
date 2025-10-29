import 'dart:async';

import 'package:facerecognition_flutter/core/constants/app_constants.dart';
import 'package:facerecognition_flutter/core/di/injection_container.dart';
import 'package:facerecognition_flutter/face_tracker.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_bloc.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_event.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/bloc/face_recognition_state.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/face_detection_circle.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/status_message.dart';
import 'package:facerecognition_flutter/features/face_recognition/presentation/widgets/tips_section.dart';
import 'package:facerecognition_flutter/localization/my_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<CameraDescription> _cameras = [];

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
    return BlocProvider(
      create: (_) =>
          injector<FaceRecognitionBloc>()..add(const InitializeFaceTracking()),
      child: FaceIDTakePhotoView(
        onTake: onTake,
        boxWidth: boxWidth,
        boxHeight: boxHeight,
        title: title,
      ),
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
  // Camera
  CameraController? _controller;
  CameraLensDirection _lens = CameraLensDirection.front;
  bool _cameraInitialized = false;
  bool _isInitializingCamera = false;
  bool _isDisposed = false; // Flag to prevent processing after disposal

  // BLoC reference (saved in didChangeDependencies to use in dispose)
  FaceRecognitionBloc? _bloc;

  // Image processing
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.initState()');
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save BLoC reference to use safely in dispose()
    _bloc = context.read<FaceRecognitionBloc>();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera ||
        _cameraInitialized ||
        !mounted ||
        _isDisposed) {
      debugPrint(
        '⚠️ [LIFECYCLE] Camera init skipped - already initializing or disposed',
      );
      return;
    }

    setState(() => _isInitializingCamera = true);

    try {
      debugPrint('📱 [LIFECYCLE] Initializing camera...');

      // Reset service state before camera init (clears queue)
      if (FaceTrackingService.instance.isInitialized) {
        FaceTrackingService.instance.reset();
        FaceTrackingService.instance.resume();
        debugPrint('📱 [LIFECYCLE] Service reset and resumed');
      }

      // Add delay to ensure previous camera resources fully released
      await Future.delayed(const Duration(milliseconds: 100));

      if (_isDisposed) {
        debugPrint(
          '⚠️ [LIFECYCLE] Disposed during delay - aborting camera init',
        );
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = _getCameraController();
        await _openCamera();

        if (mounted && !_isDisposed) {
          setState(() => _cameraInitialized = true);
          debugPrint('📱 [LIFECYCLE] Camera initialized successfully');
          // Start face tracking after camera is ready
          _bloc?.add(const StartFaceTracking());
        }
      }
    } catch (e) {
      debugPrint('❌ [LIFECYCLE] Camera init error: $e');
      if (mounted) {
        _showErrorDialog(tr('camera_error'), '${tr('camera_init_failed')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializingCamera = false);
      }
    }
  }

  CameraController _getCameraController() {
    return CameraController(
      _getCamera(),
      ResolutionPreset.high,
      enableAudio: false,
    );
  }

  CameraDescription _getCamera() {
    return _cameras.firstWhere(
      (element) => element.lensDirection == _lens,
      orElse: () => _cameras[0],
    );
  }

  void _processImage(CameraImage image) {
    // Immediately return if widget is disposed
    if (_isDisposed || _controller == null) return;

    // Skip frames for performance
    _frameCounter++;
    if (_frameCounter != AppConstants.imageProcessingFrameSkip) return;
    _frameCounter = 0;

    try {
      // Check if service is initialized
      if (!FaceTrackingService.instance.isInitialized) {
        return;
      }

      FaceTrackingService.instance.sendImageForProcessing(
        image: image,
        orientation: _controller!.description.sensorOrientation,
        frontFacing: _lens == CameraLensDirection.front,
        isPhotoCaptureRequesting: false,
      );
    } catch (e) {
      debugPrint('${tr('camera_image_processing_error')}: $e');
    }
  }

  Future<void> _openCamera() async {
    if (_isDisposed) {
      debugPrint('⚠️ [LIFECYCLE] Open camera aborted - widget disposed');
      return;
    }

    await _closeCamera();

    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted && !_isDisposed) {
          _showErrorDialog(
            tr('permission_required'),
            tr('camera_permission_required'),
          );
        }
        return;
      }
    }

    if (_isDisposed) {
      debugPrint(
        '⚠️ [LIFECYCLE] Open camera aborted - widget disposed after permission',
      );
      return;
    }

    try {
      _controller = _getCameraController();
      await _controller!.initialize();

      if (!_isDisposed) {
        await _controller!.startImageStream(_processImage);
        debugPrint('📱 [LIFECYCLE] Camera opened and streaming');
      }
    } catch (e) {
      debugPrint('❌ [LIFECYCLE] Camera open error: $e');
      if (mounted && !_isDisposed) {
        _showErrorDialog(tr('camera_error'), '${tr('camera_init_failed')}: $e');
      }
    }
  }

  Future<void> _closeCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
    } catch (e) {
      debugPrint('${tr('camera_stopping')}: $e');
    } finally {
      _controller = null;
    }
  }

  /// Synchronously stop image stream to prevent race conditions
  void _stopImageStreamSync() {
    if (_controller?.value.isStreamingImages == true) {
      try {
        // stopImageStream() is synchronous despite being in async context
        _controller!.stopImageStream();
        debugPrint('🛑 [LIFECYCLE] Image stream stopped');
      } catch (e) {
        debugPrint('⚠️ [LIFECYCLE] Error stopping image stream: $e');
      }
    }
  }

  /// Pause camera stream (for photo capture)
  void _pauseCameraStream() {
    if (_controller?.value.isStreamingImages == true && !_isDisposed) {
      try {
        _controller!.stopImageStream();
        debugPrint('⏸️ [CAMERA] Stream paused for photo capture');
      } catch (e) {
        debugPrint('⚠️ [CAMERA] Error pausing stream: $e');
      }
    }
  }

  /// Resume camera stream (after photo capture)
  void _resumeCameraStream() {
    if (_controller?.value.isInitialized == true &&
        _controller?.value.isStreamingImages == false &&
        !_isDisposed &&
        _cameraInitialized) {
      try {
        _controller!.startImageStream(_processImage);
        debugPrint('▶️ [CAMERA] Stream resumed after photo capture');
      } catch (e) {
        debugPrint('⚠️ [CAMERA] Error resuming stream: $e');
      }
    }
  }

  /// Synchronously dispose camera controller
  void _disposeCameraSync() {
    try {
      _controller?.dispose();
      _controller = null;
      debugPrint('🗑️ [LIFECYCLE] Camera controller disposed');
    } catch (e) {
      debugPrint('⚠️ [LIFECYCLE] Error disposing camera: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 252, 239, 239),
        title: Text(
          title,
          style: TextStyle(color: const Color.fromARGB(255, 39, 39, 39)),
        ),
        content: Text(
          message,
          style: TextStyle(color: const Color.fromARGB(255, 80, 79, 79)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('no')),
          ),
          TextButton(onPressed: () {Navigator.of(context).pop(); _openCamera();}, child: Text(tr('yes'))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.dispose() START');

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Set disposal flag FIRST to immediately stop processing
    _isDisposed = true;

    // Pause service instead of disposing (preserves isolate)
    debugPrint('📱 [LIFECYCLE] Pausing service...');
    FaceTrackingService.instance.pause();

    // Stop face tracking using saved BLoC reference (safe in dispose)
    debugPrint('📱 [LIFECYCLE] Stopping BLoC tracking...');
    _bloc?.add(const StopFaceTracking());

    // Stop image stream SYNCHRONOUSLY (critical!)
    debugPrint('📱 [LIFECYCLE] Stopping camera stream...');
    _stopImageStreamSync();

    // Dispose camera controller SYNCHRONOUSLY
    debugPrint('📱 [LIFECYCLE] Disposing camera controller...');
    _disposeCameraSync();

    debugPrint('📱 [LIFECYCLE] FaceIDTakePhoto.dispose() END');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isDisposed) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // App backgrounded - pause camera
      debugPrint('📱 [LIFECYCLE] App backgrounded - pausing camera');
      _stopImageStreamSync();
      FaceTrackingService.instance.pause();
    } else if (state == AppLifecycleState.resumed) {
      // App foregrounded - resume
      debugPrint('📱 [LIFECYCLE] App resumed - restarting camera');
      if (!_isDisposed &&
          _controller != null &&
          _controller!.value.isInitialized) {
        _controller!.startImageStream(_processImage);
        FaceTrackingService.instance.resume();
      }
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
            // Pause camera stream when preparing photo
            debugPrint('📸 [CAMERA] Pausing camera for photo capture');
            _pauseCameraStream();
          } else if (state is FaceRecognitionTracking) {
            // Resume camera stream when tracking
            debugPrint('📸 [CAMERA] Resuming camera stream');
            _resumeCameraStream();
          } else if (state is FaceRecognitionVerified) {
            // Photo captured - camera will be disposed when navigating away
            debugPrint(
              '📸 [CAMERA] Photo verified, camera will be disposed on navigation',
            );
          }

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
          if (_isInitializingCamera || !_cameraInitialized) {
            return _buildLoadingScreen();
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
                  Expanded(child: _buildMainContent(screenSize, state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF60A5FA), // Light blue
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              tr('camera_initializing'),
              style: const TextStyle(
                color: Color(0xFF334155), // Dark slate - for light background
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
              controller: _controller,
              lens: _lens,
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
