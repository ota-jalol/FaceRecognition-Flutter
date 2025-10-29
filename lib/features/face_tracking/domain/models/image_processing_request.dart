import 'package:camera/camera.dart';

/// Request to process a camera image
class ImageProcessingRequest {
  final CameraImage image;
  final int orientation;
  final bool frontFacing;
  final bool capturePhoto;
  final int requestId;

  const ImageProcessingRequest({
    required this.image,
    required this.orientation,
    required this.frontFacing,
    this.capturePhoto = false,
    required this.requestId,
  });

  Map<String, dynamic> toMap() {
    return {
      'orientation': orientation,
      'frontFacing': frontFacing,
      'capturePhoto': capturePhoto,
      'requestId': requestId,
    };
  }
}
