import 'package:asbt/face_result_model.dart';
import 'package:asbt/features/face_recognition/presentation/widgets/camera_preview_widget.dart';
import 'package:asbt/features/face_recognition/presentation/widgets/facedetectionview.dart';
import 'package:flutter/material.dart';

/// Widget for displaying the face detection circle with camera preview
class FaceDetectionCircle extends StatelessWidget {
  final Size screenSize;
  final FaceResult? state;
  final Function(List<dynamic>)? onFaceDetected;
  const FaceDetectionCircle({
    required this.screenSize,
    required this.state,
    this.onFaceDetected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double baseSize = _calculateBaseSize();
    final size = baseSize.clamp(150.0, 240.0);
    FaceRecognitionViewState ? faceRecognitionViewState;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size + (screenSize.width < 600 ? 130 : 200),
            height: size + (screenSize.width < 600 ? 130 : 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getDetectionColor().withOpacity(0.2),
                  blurRadius: screenSize.width < 600 ? 15 : 20,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),

          // Main face detection circle
          Container(
            width: size + (screenSize.width < 600 ? 120 : 190),
            height: size + (screenSize.width < 600 ? 120 : 190),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getDetectionColor().withOpacity(0.15),
                  _getDetectionColor().withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: _getDetectionColor(),
                width: screenSize.width < 600 ? 2.0 : 2.5,
              ),
            ),
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                  ),
                ),
                child: Stack(
                  children: [
                    _buildCameraPreview(),
                  ],
                ),
              ),
            ),
          ),

         
          // if (state is FaceRecognitionTracking)
        ],
      ),
    );
  }

  double _calculateBaseSize() {
    if (screenSize.width < 480) return screenSize.width * 0.38;
    if (screenSize.width < 600) return screenSize.width * 0.35;
    if (screenSize.width < 800) return screenSize.width * 0.28;
    if (screenSize.width < 1200) return screenSize.width * 0.22;
    return screenSize.width * 0.18;
  }

  Color _getDetectionColor() {
    if (state != null && state!.faceDetected) {
      return state!.isCentered
          ? const Color(0xFF10B981) // Emerald green - centered
          : const Color(0xFF3B82F6); // Blue - not centered yet
    }

    // Default - searching for face
    return const Color(0xFF94A3B8); // Slate grey - neutral
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: 1, // kvadrat
      child: ClipOval(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FaceRecognitionView(
            onFaceDetected: (faces) {
              // Handle face detection events and forward to parent
              if (onFaceDetected != null) {
                onFaceDetected!(faces);
              }
            },
          ),
        ),
      ),
    );
  }
}
