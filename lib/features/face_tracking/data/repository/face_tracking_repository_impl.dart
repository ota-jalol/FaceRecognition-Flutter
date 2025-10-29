import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:facerecognition_flutter/face_result_model.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/models/image_processing_request.dart';
import 'package:facerecognition_flutter/features/face_tracking/domain/repository/face_tracking_repository.dart';
import 'package:facerecognition_flutter/localization/my_localization.dart';
// ignore: library_prefixes
import 'package:facerecognition_flutter/flutter_face_sdk.dart' as FSDK;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:facerecognition_flutter/converter.dart' as converter;

/// Optimized implementation of face tracking repository
class FaceTrackingRepositoryImpl implements FaceTrackingRepository {
  // Isolate communication
  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();

  // Stream controllers
  final _resultController = StreamController<FaceResult>.broadcast();
  final _requestQueue = <ImageProcessingRequest>[];
  static const int _maxQueueSize = 3; // Limit queue size to prevent memory issues

  // State
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturingPhoto = false; // Flag to block queue during photo capture
  bool _isPaused = false; // Flag to pause processing without killing isolate
  int _frameCounter = 0;
  int _frameSkipCount = 3;
  int _imageWidth = 0;
  int _imageHeight = 0;

  @override
  bool get isInitialized => _isInitialized;

  @override
  int get imageWidth => _imageWidth;

  @override
  int get imageHeight => _imageHeight;

  @override
  Stream<FaceResult> processImageStream() => _resultController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ FaceTrackingService already initialized');
      return;
    }

    try {
      debugPrint('🚀 Starting background worker with FSDK initialization...');
      debugPrint('⏱️ Timeout set to 30 seconds for slower devices...');

      // Setup isolate communication with completion tracking
      final initCompleter = Completer<void>();

      _receivePort.listen((message) {
        if (message is SendPort) {
          debugPrint('📨 Received SendPort from isolate');
          _sendPort = message;
          if (!initCompleter.isCompleted) {
            debugPrint('✅ Initialization completer completed');
            initCompleter.complete();
          }
        } else {
          _handleIsolateMessage(message);
        }
      });

      // Spawn background worker (FSDK init happens inside isolate)
      debugPrint('🔄 Spawning isolate...');
      _isolate = await Isolate.spawn(
        _backgroundWorker,
        _IsolateConfig(sendPort: _receivePort.sendPort),
        debugName: 'FaceTrackingWorker',
      );
      debugPrint('✅ Isolate spawned successfully');

      // Wait for isolate to send SendPort (increased timeout for slow devices)
      debugPrint('⏳ Waiting for SendPort from isolate...');
      await initCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('FSDK initialization timeout (30s)');
        },
      );

      _isInitialized = true;
      debugPrint(
        '✅ Face tracking service initialized (FSDK ready in background)',
      );
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout waiting for isolate: $e');
      debugPrint('💡 Possible causes:');
      debugPrint('   1. FSDK license invalid or expired');
      debugPrint('   2. Native library not loaded properly');
      debugPrint('   3. Device too slow for initialization');
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      rethrow;
    } catch (e) {
      debugPrint('❌ Failed to initialize face tracking: $e');
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      rethrow;
    }
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      return;
    }

    if (message is Map<String, dynamic>) {
      _isProcessing = false;

      // Check if this is a photo capture preparation message
      if (message['isPreparingPhoto'] == true) {
        _isCapturingPhoto = true; // Block queue
      }

      // Check if photo capture is complete
      if (message['isPhotoCaptured'] == true) {
        _isCapturingPhoto = false; // Unblock queue
      }

      final result = FaceResult(
        faceDetected: message['faceDetected'] ?? false,
        confidence: message['confidence'] ?? 0.0,
        faceRectangle: message['faceRectangle'] != null
            ? FaceRectangle.fromMap(message['faceRectangle'])
            : null,
        isCentered: message['isCentered'] ?? false,
        imageWidth: imageWidth.toDouble(),
        imageHeight: imageHeight.toDouble(),
        base64Photo: message['base64Photo'],
        isPhotoCaptured: message['isPhotoCaptured'] ?? false,
        isPreparingPhoto: message['isPreparingPhoto'] ?? false,
        message: _getStatusMessage(message),
        timestamp: DateTime.now(),
      );

      _resultController.add(result);

      // Process next request in queue
      _processNextRequest();
    }
  }

  String _getStatusMessage(Map<String, dynamic> data) {
    // Check if preparing photo
    if (data['isPreparingPhoto'] == true) {
      return tr('preparing_photo');
    }

    // Use message from background service if available
    if (data['message'] != null && data['message'].toString().isNotEmpty) {
      final message = data['message'].toString();

      // Handle percentage messages with threshold
      if (message.startsWith('liveness_percentage_detected:')) {
        final parts = message.split(':');
        final percentage = parts[1];
        final threshold = parts.length > 2 ? parts[2] : '1';
        return 'Liveness: $percentage% (${threshold}/5) - ${tr('liveness_detected')}';
      } else if (message.startsWith('liveness_percentage_checking:')) {
        final parts = message.split(':');
        final percentage = parts[1];
        final threshold = parts.length > 2 ? parts[2] : '1';
        return 'Liveness: $percentage% (${threshold}/5) - ${tr('liveness_checking')}';
      }

      // Handle regular i18n keys
      return tr(message);
    }

    // Fallback messages
    if (data['faceDetected'] == true) {
      return tr('face_found_processing');
    }
    return tr('face_not_detected');
  }

  @override
  void submitImage(ImageProcessingRequest request) {
    if (!_isInitialized || _sendPort == null) {
      debugPrint('⚠️ Service not initialized, skipping frame');
      return;
    }

    // Block queue additions during pause or photo capture
    if (_isPaused) {
      return; // Silent skip when paused
    }

    if (_isCapturingPhoto) {
      debugPrint('⏸️ Photo capture in progress, skipping frame');
      return;
    }

    // Frame skip logic - only process every Nth frame
    _frameCounter++;
    if (_frameCounter < _frameSkipCount && !request.capturePhoto) {
      return;
    }
    _frameCounter = 0;

    // If already processing and not a photo capture request, skip
    if (_isProcessing && !request.capturePhoto) {
      return;
    }

    // Limit queue size to prevent unbounded growth
    if (_requestQueue.length >= _maxQueueSize) {
      debugPrint('⚠️ Queue full, dropping oldest frame');
      _requestQueue.removeAt(0);
    }

    // Add to queue
    _requestQueue.add(request);

    // Process if not busy
    if (!_isProcessing) {
      _processNextRequest();
    }
  }

  void _processNextRequest() {
    if (_requestQueue.isEmpty || _isProcessing || _sendPort == null) {
      return;
    }

    _isProcessing = true;
    final request = _requestQueue.removeAt(0);

    try {
      // Store dimensions
      _imageWidth = request.image.width;
      _imageHeight = request.image.height;

      // Send to isolate for background processing
      _sendPort!.send({
        'imageData': request.image,
        'orientation': request.orientation,
        'frontFacing': request.frontFacing,
        'capturePhoto': request.capturePhoto,
        'requestId': request.requestId,
      });
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      _isProcessing = false;
      _processNextRequest();
    }
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    _requestQueue.clear();

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    await _resultController.close();
    _receivePort.close();

    debugPrint('🗑️ Face tracking service disposed');
  }

  @override
  void pause() {
    _isPaused = true;
    _requestQueue.clear();
    _isProcessing = false;
    _isCapturingPhoto = false;
    _frameCounter = 0;
    debugPrint('⏸️ Repository paused, queue cleared');
  }

  @override
  void resume() {
    _isPaused = false;
    _frameCounter = 0;
    debugPrint('▶️ Repository resumed');
  }

  @override
  void clearQueue() {
    _requestQueue.clear();
    _isProcessing = false;
    debugPrint('🧹 Queue cleared');
  }

  // Background worker - runs in separate isolate
  static void _backgroundWorker(_IsolateConfig config) {
    // CRITICAL: Create ReceivePort and send SendPort IMMEDIATELY
    // This allows main thread to proceed without waiting for FSDK initialization
    final receivePort = ReceivePort();

    // Send SendPort to main thread FIRST (before any heavy initialization)
    config.sendPort.send(receivePort.sendPort);
    debugPrint('📤 [Isolate] SendPort sent to main thread');

    // NOW do heavy FSDK initialization (can take 5-15 seconds)
    try {
      debugPrint('🔑 [Isolate] Activating FaceSDK library...');
      FSDK.ActivateLibrary(
        'iagRoeEeIzuCnF4NfDkXTDs1/gknkmB7zAvqpBDDTO4Y3EluMEMj/5i7hG7xVJefGD02vAmhD29NIYdZQT8y4+G0wmD86OVihc8Z43QPgeVaHcdgdRNQGgfCorxwuSm7vKEkrosqeJhDLXOEkV1GiZu4grjujzR/VKp0IglI0A4=',
      );
      debugPrint('⚡ [Isolate] Initializing FaceSDK...');
      FSDK.Initialize();
      debugPrint('✅ [Isolate] FaceSDK initialized successfully');
    } on FSDK.NotActivatedError {
      debugPrint(
        '❌ [Isolate] FaceSDK activation failed - license key required',
      );
      return; // Exit isolate on failure
    } on FSDK.Error catch (e) {
      debugPrint('❌ [Isolate] FaceSDK error: ${e.callee} -> ${e.code}');
      return; // Exit isolate on failure
    }

    final ids = FSDK.Int64Buffer.allocate(5);
    late FSDK.Tracker tracker;

    // Consecutive liveness tracking for auto photo capture
    int consecutiveLivenessCount = 0;
    const int requiredConsecutiveDetections = 5;
    const double livenessThreshold = 0.9; // Minimum liveness score (90%)
    int currentDetectionThreshold = 1; // Start with threshold 1

    // Photo capture state
    bool isCapturingPhoto = false;

    try {
      tracker = FSDK.Tracker();
      tracker.setMultipleParameters({
      'HandleArbitraryRotations': false,
      'DetermineFaceRotationAngle': false,
      'InternalResizeWidth':256,
      'FaceDetectionThreshold': 1,
      'LivenessFramesCount': 15,
      'DetectLiveness': true,
      'SmoothAttributeLiveness': true,
      'AttributeLivenessSmoothingAlpha':0.7,
      'DetectFacialFeatures': false,
      'TrimOutOfScreenFaces': false, // Don't trim faces near edges
      'TrimFacesWithUncertainFacialFeatures': false, // Allow uncertain features
      'FaceDetection2Threshold':1,
      'FaceDetection2ComputationDelegate':'gpu',
      'DetectionVersion':2,
      

    });
    } catch (e) {
      debugPrint('❌ Failed to create tracker: $e');
      return;
    }

    receivePort.listen((data) async {
      if (data is! Map<String, dynamic>) return;

      try {
        final result = await _processImageInIsolate(
          data,
          tracker,
          ids,
          consecutiveLivenessCount,
          requiredConsecutiveDetections,
          livenessThreshold,
          currentDetectionThreshold,
        );

        final bool isFaceGood =
            result['faceDetected'] == true &&
            result['isCentered'] == true &&
            (result['confidence'] as double) >= livenessThreshold &&
            result['isFake'] != true; // Fake face ni reject qilish

        if (isFaceGood) {
          consecutiveLivenessCount++;
          debugPrint('✅ [Isolate] Good face detected! Count: $consecutiveLivenessCount/$requiredConsecutiveDetections');

          // Trigger photo capture on 5th consecutive detection
          if (consecutiveLivenessCount >= requiredConsecutiveDetections &&
              !isCapturingPhoto) {
            isCapturingPhoto = true;

            // Send status: preparing photo
            config.sendPort.send({...result, 'isPreparingPhoto': true});

            // Capture photo asynchronously without blocking
            _capturePhotoAsync(
                  data: data,
                  tracker: tracker,
                  ids: ids,
                  config: config,
                )
                .then((photoResult) {
                  // Reset all state after successful capture
                  consecutiveLivenessCount = 0;
                  currentDetectionThreshold = 1;
                  isCapturingPhoto = false;

                  config.sendPort.send(photoResult);
                })
                .catchError((error) {
                  debugPrint('❌ Photo capture failed: $error');

                  // Reset state on error
                  consecutiveLivenessCount = 0;
                  currentDetectionThreshold = 1;
                  isCapturingPhoto = false;

                  config.sendPort.send({
                    'faceDetected': false,
                    'confidence': 0.0,
                    'isPhotoCaptured': false,
                    'error': 'Photo capture failed',
                  });
                });

            return; // Don't send regular result, async capture will send
          }
        } else {
          // Reset state on poor detection
          _resetDetectionState(
            tracker: tracker,
            onReset: () {
          consecutiveLivenessCount = 0;
            },
          );
        }

        result['isPreparingPhoto'] = isCapturingPhoto;

        config.sendPort.send(result);
      } catch (e) {
        debugPrint('❌ Error in background worker: $e');

        // Reset all state on error
        consecutiveLivenessCount = 0;
        isCapturingPhoto = false;

        config.sendPort.send({
          'faceDetected': false,
          'confidence': 0.0,
          'isPhotoCaptured': false,
          'error': e.toString(),
        });
      }
    });

    // NOTE: SendPort already sent at the beginning of _backgroundWorker()
    // No need to send it again here
  }

  /// Helper: Reset detection state atomically
  static void _resetDetectionState({
    required FSDK.Tracker tracker,
    required VoidCallback onReset,
  }) {
    onReset();
  }

  /// Async photo capture task - runs independently
  static Future<Map<String, dynamic>> _capturePhotoAsync({
    required Map<String, dynamic> data,
    required FSDK.Tracker tracker,
    required FSDK.Int64Buffer ids,
    required _IsolateConfig config,
  }) async {
    FSDK.Image? fsdkImage;

    try {
      // Re-process image for photo capture
      final imageData = data['imageData'] as CameraImage;
      fsdkImage = await converter.ImageConverter().convert(imageData);

      // Apply same transformations
      final rotation = Platform.isAndroid
          ? data['orientation'] ~/ 90
          : -(data['orientation'] ~/ 90) + 1;

      if (rotation != 0) {
        final rotatedImage = fsdkImage.rotate90(rotation);
        fsdkImage.free();
        fsdkImage = rotatedImage;
      }

      if (data['frontFacing'] && !Platform.isIOS) {
        fsdkImage.mirror(true);
      }

      // Detect face again for photo
      ids.length = 0;
      tracker.feedFrame(0, fsdkImage, ids: ids);

      if (ids.isEmpty) {
        fsdkImage.free();
        throw Exception('Face lost during photo capture');
      }

      // Get face position
      final facePos = tracker.getFacePosition(0, ids[0]);
      final xc = facePos.xc;
      final yc = facePos.yc;
      final w = facePos.w;

      // Capture and crop photo
      final photoBytes = await _capturePhoto(fsdkImage, xc, yc, w);

      facePos.free();
      fsdkImage.free();

      return {
        'faceDetected': true,
        'confidence': 1.0,
        'isPhotoCaptured': true,
        'base64Photo': photoBytes,
        'isCentered': true,
        'consecutiveCount': 5,
        'message': 'photo_captured_success',
        'currentThreshold': 5,
        'isPreparingPhoto': false,
      };
    } catch (e) {
      fsdkImage?.free();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _processImageInIsolate(
    Map<String, dynamic> data,
    FSDK.Tracker tracker,
    FSDK.Int64Buffer ids,
    int consecutiveLivenessCount,
    int requiredConsecutiveDetections,
    double livenessThreshold,
    int currentDetectionThreshold,
  ) async {
    FSDK.Image? fsdkImage;

    try {
      final imageData = data['imageData'] as CameraImage;
      fsdkImage = await converter.ImageConverter().convert(imageData);

      // Rotate if needed
      final rotation = Platform.isAndroid
          ? data['orientation'] ~/ 90
          : -(data['orientation'] ~/ 90) + 1;

      if (rotation != 0) {
        final rotatedImage = fsdkImage.rotate90(rotation);
        fsdkImage.free();
        fsdkImage = rotatedImage;
      }

      // Mirror for front camera
      if (data['frontFacing'] && !Platform.isIOS) {
        fsdkImage.mirror(true);
      }

      // Detect faces
      ids.length = 0;
      try {
        tracker.feedFrame(0, fsdkImage, ids: ids);
      } on FSDK.FaceNotFoundError {
        // No faces found
      }

      if (ids.isEmpty) {
        fsdkImage.free();
        return {
          'faceDetected': false,
          'confidence': 0.0,
          'isPhotoCaptured': false,
          'isCentered': false,
          'consecutiveCount': 0,
          'message': 'face_not_detected',
        };
      }

      // Process first face
      late FSDK.FacePosition facePos;
      double confidence = 0.0;
      bool livenessDetected = false;

      for (var i = 0; i < ids.length; i++) {
        try {
          facePos = tracker.getFacePosition(0, ids[i]);
          
          // Get liveness attribute
          try {
            final attr = tracker.getFacialAttribute(0, ids[i], "Liveness");

            if (attr.isNotEmpty) {
              confidence = FSDK.GetValueConfidence(attr, "Liveness");
              livenessDetected = true;
              debugPrint('🔍 [Isolate] Liveness detected: ${(confidence * 100).toStringAsFixed(1)}%');
            }
          } on FSDK.AttributeNotDetectedError {
            debugPrint('⚠️ [Isolate] Liveness attribute not detected for face ${ids[i]}');
          }

          if (confidence > 0.0) break;
        } on FSDK.FaceNotFoundError {
          continue;
        }
      }

      final xc = facePos.xc;
      final yc = facePos.yc;
      final w = facePos.w;

      final isCentered = _checkIfCentered(
        xc,
        yc,
        fsdkImage.width,
        fsdkImage.height,
      );

      // Check if face is fake (photo/video)
      if (livenessDetected && confidence < 0.4) {
        debugPrint('🚫 [Isolate] FAKE DETECTED! Liveness: ${(confidence * 100).toStringAsFixed(1)}%');
        facePos.free();
        fsdkImage.free();
        return {
          'faceDetected': true,
          'confidence': confidence,
          'isPhotoCaptured': false,
          'isCentered': isCentered,
          'consecutiveCount': 0,
          'message': 'fake_face_detected', // Yangi xabar
          'isFake': true,
        };
      }

      // Determine message based on face detection and liveness
      String message;
      if (confidence > 0.9 && isCentered) {
        final percentage = (confidence * 100).toStringAsFixed(0);
        message = 'liveness_percentage_detected:$percentage:5';
      } else if (confidence > 0.0) {
        final percentage = (confidence * 100).toStringAsFixed(0);
        message = 'liveness_percentage_checking:$percentage:5';
      } else {
        message = 'face_found_processing';
      }

      final result = {
        'faceDetected': true,
        'confidence': confidence,
        'isPhotoCaptured': false,
        'faceRectangle': {
          'left': xc.toDouble(),
          'top': yc.toDouble(),
          'width': w.toDouble(),
          'height': w.toDouble(),
        },
        'isCentered': isCentered,
        'consecutiveCount': consecutiveLivenessCount,
        'message': message,
      };

      facePos.free();
      fsdkImage.free();

      return result;
    } catch (e) {
      fsdkImage?.free();
      rethrow;
    }
  }

  /// Convert YUV image data to FSDK Image (runs in isolate)
  static bool _checkIfCentered(int xc, int yc, int width, int height) {
    return (xc - width / 2).abs() < (width / 4) &&
        (yc - height / 2).abs() < (height / 4);
  }

  static Future<Uint8List> _capturePhoto(
    FSDK.Image image,
    int xc,
    int yc,
    int w,
  ) async {
    final buf = image.saveToBuffer(FSDK.ImageMode.Color32bit);
    final imageBytes = buf.asUint8List;

    final im = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: imageBytes.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    final cropX = (xc - w ~/ 2).clamp(0, im.width - 1);
    final cropY = (yc - w ~/ 2).clamp(0, im.height - 1);
    var cropWidth = w;
    var cropHeight = (w * 1.25).toInt();

    if (cropX + cropWidth > im.width) {
      cropWidth = im.width - cropX;
    }
    if (cropY + cropHeight > im.height) {
      cropHeight = im.height - cropY;
    }

    final command = img.Command()
      ..image(im)
      ..copyCrop(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
      ..encodeJpg();

    final croppedBytes = await command.getBytesThread();

    buf.free();
    im.clear();

    return croppedBytes!;
  }
}

class _IsolateConfig {
  final SendPort sendPort;

  _IsolateConfig({required this.sendPort});
}
