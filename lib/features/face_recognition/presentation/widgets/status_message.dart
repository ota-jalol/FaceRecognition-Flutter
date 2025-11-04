import 'package:asbt/face_result_model.dart';
import 'package:asbt/localization/my_localization.dart';
import 'package:flutter/material.dart';

/// Widget for displaying status messages based on face recognition state
class StatusMessage extends StatelessWidget {
  final FaceResult? state;
  final Size screenSize;

  const StatusMessage({
    required this.state,
    required this.screenSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final messageData = _getMessageData();
    final horizontalMargin = screenSize.width < 480 ? 16.0 : 20.0;
    final horizontalPadding = screenSize.width < 480 ? 16.0 : 20.0;
    final verticalPadding = screenSize.width < 480 ? 10.0 : 12.0;
    final iconSize = screenSize.width < 480 ? 18.0 : 20.0;
    final fontSize = screenSize.width < 480 ? 14.0 : 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            messageData.color.withOpacity(0.1),
            messageData.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: messageData.color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: messageData.color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              messageData.icon,
              key: ValueKey(DateTime.now()),
              color: messageData.color,
              size: iconSize,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                messageData.message,
                key: ValueKey(DateTime.now()),
                style: TextStyle(
                  color: messageData.textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _MessageData _getMessageData() {
    if (state != null) {
      final faceResult = state!;

      // Check for fake face detection
      if (faceResult.message.contains('fake_face_detected') ||
          faceResult.message.contains('face_too_close_or_spoof')) {
        return _MessageData(
          message: tr('fake_face_detected'),
          color: const Color(0xFFEF4444), // Red - fake detected
          icon: Icons.warning_amber_rounded,
          textColor: const Color(0xFF7F1D1D), // Dark red
        );
      }

      // Yuz topilgan
      if (faceResult.faceDetected) {
        return _MessageData(
          message: faceResult.message,
          color: faceResult.isCentered && faceResult.confidence > 0.7
              ? const Color(0xFF10B981) // Emerald green
              : const Color(0xFF3B82F6), // Blue
          icon: Icons.face_retouching_natural,
          textColor: faceResult.isCentered && faceResult.confidence > 0.7
              ? const Color(0xFF065F46) // Dark green
              : const Color(0xFF1E3A8A), // Dark blue
        );
      }
    }

    // Default - yuz topilmadi
    return _MessageData(
      message: tr('no_face_detected'),
      color: const Color(0xFF94A3B8), // Slate grey
      icon: Icons.camera_alt,
      textColor: const Color(0xFF334155), // Dark slate
    );
  }
}

class _MessageData {
  final String message;
  final Color color;
  final IconData icon;
  final Color textColor;

  _MessageData({
    required this.message,
    required this.color,
    required this.icon,
    required this.textColor,
  });
}
