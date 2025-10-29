import 'package:facerecognition_flutter/localization/my_localization.dart';
import 'package:flutter/material.dart';

/// Widget for displaying tips to the user
class TipsSection extends StatelessWidget {
  final Size screenSize;

  const TipsSection({required this.screenSize, super.key});

  @override
  Widget build(BuildContext context) {
    // Skip tips on very small screens
    if (screenSize.height < 500) return const SizedBox.shrink();

    final fontSize = screenSize.width < 600 ? 14.0 : 14.0;
    final titleFontSize = screenSize.width < 600 ? 18.0 : 16.0;
    final horizontalPadding = screenSize.width < 600 ? 16.0 : 24.0;
    final verticalPadding = screenSize.width < 600 ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width < 600 ? 20 : 30,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.7),
        border: Border.all(
          color: const Color(0xFFCBD5E1), // Light slate
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFFF59E0B), // Amber
                size: titleFontSize + 2,
              ),
              const SizedBox(width: 8),
              Text(
                tr('tips'),
                style: TextStyle(
                  color: const Color(0xFF1E293B), // Dark slate
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height < 600 ? 12 : 14),
          ...List.generate(3, (index) {
            final tips = [
              tr('tip_good_lighting'),
              tr('tip_face_camera_directly'),
              tr('tip_remove_accessories'),
            ];

            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenSize.height < 600 ? 1 : 2,
              ),
              child: Text(
                tips[index],
                style: TextStyle(
                  color: const Color(0xFF475569), // Slate
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}
