import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:facesdk_plugin/facedetection_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';

/// A camera preview widget that can be safely used inside constraints
/// without the full scaffold overhead
class CameraPreviewWidget extends StatefulWidget {
  final Function(List<dynamic> faces)? onFaceDetected;

  const CameraPreviewWidget({
    this.onFaceDetected,
    super.key,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  FaceDetectionViewController? faceDetectionViewController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    faceDetectionViewController?.stopCamera();
    super.dispose();
  }

  Future<void> _loadSettings() async {
   
  }

  Future<void> _onFaceDetected(dynamic faces) async {
    if (!mounted) return;

    List<dynamic> facesList = [];
    
    // Safely convert faces to list
    if (faces != null) {
      if (faces is List) {
        facesList = faces;
      } else {
        facesList = [faces];
      }
    }

    // Call the callback if provided
    if (widget.onFaceDetected != null) {
      widget.onFaceDetected!(facesList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera view
        _CameraView(
          onFaceDetected: _onFaceDetected,
          onViewControllerCreated: (controller) {
            faceDetectionViewController = controller;
          },
        ),
        
      ],
    );
  }
}

class _CameraView extends StatefulWidget {
  final Function(dynamic faces) onFaceDetected;
  final Function(FaceDetectionViewController controller) onViewControllerCreated;

  const _CameraView({
    required this.onFaceDetected,
    required this.onViewControllerCreated,
  });

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> implements FaceDetectionInterface {
  @override
  Future<void> onFaceDetected(faces) async {
    widget.onFaceDetected(faces);
    
    // Debug print with null safety (only in debug mode)
    if (kDebugMode) {
      if (faces != null && faces is List && faces.isNotEmpty) {
        print('Face detected: ${jsonEncode(faces[0])}');
      } else {
        print('No faces detected or faces is null/empty');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return UiKitView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
  }

  void _onPlatformViewCreated(int id) async {
    final prefs = await SharedPreferences.getInstance();
    var cameraLens = prefs.getInt("camera_lens");

    final controller = FaceDetectionViewController(id, this);
    widget.onViewControllerCreated(controller);

    await controller.initHandler();

    int? livenessLevel = prefs.getInt("liveness_level");
    await FacesdkPlugin().setParam({'check_liveness_level': livenessLevel ?? 0});

    await controller.startCamera(cameraLens ?? 1);
  }
}

/// Custom painter for drawing face detection rectangles
class FacePainter extends CustomPainter {
  final dynamic faces;
  final double livenessThreshold;

  FacePainter({
    required this.faces,
    required this.livenessThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces != null && faces is List && faces.isNotEmpty) {
      var paint = Paint();
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;

      for (var face in faces) {
        if (face == null || 
            face['frameWidth'] == null || 
            face['frameHeight'] == null ||
            face['x1'] == null ||
            face['y1'] == null ||
            face['x2'] == null ||
            face['y2'] == null ||
            face['liveness'] == null) {
          continue;
        }
        
        double xScale = face['frameWidth'] / size.width;
        double yScale = face['frameHeight'] / size.height;

        Color color;
        String title;
        
        if (face['liveness'] < livenessThreshold) {
          color = const Color(0xFFEF4444); // Red
          title = "Spoof ${face['liveness'].toStringAsFixed(2)}";
        } else {
          color = const Color(0xFF10B981); // Green
          title = "Real ${face['liveness'].toStringAsFixed(2)}";
        }

        // Draw text
        TextSpan span = TextSpan(
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500),
          text: title,
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(face['x1'] / xScale, face['y1'] / yScale - 25));

        // Draw rectangle
        paint.color = color;
        canvas.drawRect(
          Offset(face['x1'] / xScale, face['y1'] / yScale) &
              Size(
                (face['x2'] - face['x1']) / xScale,
                (face['y2'] - face['y1']) / yScale,
              ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}