import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';

import '../../domain/repository/face_tracking_repository.dart';
import '../../domain/models/face_tracking_config.dart';

import '../../../../core/resources/data_state.dart';

/// KBY-AI Face SDK implementation of face tracking repository
class FaceTrackingRepositoryImpl implements FaceTrackingRepository {
  final FacesdkPlugin _faceSDK;

  // State
  bool _isInitialized = false;

  FaceTrackingRepositoryImpl(this._faceSDK);

  @override
  Future<DataState<bool>> initialize(FaceTrackingConfig config) async {
    if (_isInitialized) {
      debugPrint('⚠️ KBY-AI Face SDK already initialized');
      return const DataSuccess(true);
    }

    try {
      debugPrint('🚀 Initializing KBY-AI Face SDK...');

      // Set activation (license key should be set from environment or config)
      final activationResult = await _faceSDK.setActivation(_getLicenseKey());
      if (activationResult != 0) {
        return DataFailed('License activation failed: $activationResult');
      }

      // Initialize SDK
      final initResult = await _faceSDK.init();
      if (initResult != 0) {
        return DataFailed('SDK initialization failed: $initResult');
      }

      // Apply configuration
      await _faceSDK.setParam(Map<String, Object>.from(config.toSDKParams()));
      _isInitialized = true;

      debugPrint('✅ KBY-AI Face SDK initialized successfully');
      return const DataSuccess(true);
    } catch (e) {
      debugPrint('❌ Failed to initialize KBY-AI Face SDK: $e');
      return DataFailed('Initialization failed: $e');
    }
  }

  /// Get license key from configuration or environment
  String _getLicenseKey() {
    // KBY-AI license keys for different platforms
    // These are the actual keys from main.dart - should be moved to secure config
    if (Platform.isAndroid) {
      return "uxEwZEiyufiqON8jz9VoPp5ClWquRmrBHd3uaaWWldr3Wuo2MKbmgvG3ETMKVNoK7l4xAqMAwYTx"
          "f+QYv+Z9zltxH7TF6ehkt96t5pJdmj81TH/0TVGTGsh5Mx6TQLOieV7OU6Sqk0AVP7kGBgaADkxt"
          "QXqupz+PmzXeW64v1ipEHGMVDbm/RjEX+dl0vRnrnCrMXrt9jYXqbUN3MwQClQfyP4GgXW7ZLOsX"
          "s+AXBevZRRMVfNIGzGmNm0FVLADm1AaGywLwgjV09TXgJumvh/gw/7rRhl3OwqkxEL2n0KCQBykM"
          "YLQ5CQzWSHKxkN8aux3OhcSnOzEuJwf96LJ6/A==";
      // return "j63rQnZifPT82LEDGFa+wzorKx+M55JQlNr+S0bFfvMULrNYt+UEWIsa11V/Wk1bU9Srti0/FQqp"
      //     "UczeCxFtiEcABmZGuTzNd27XnwXHUSIMaFOkrpNyNE4MHb7HBm5kU/0J/SAMfybICCWyFajuZ4fL"
      //     "agozJV5DPKj22oFVaueWMjO/9fMvcps4u1AIiHH2rjP4mEYfiAE8nhHBa1Ou3u/WkXj6jdDafyJo"
      //     "AFtQHYJYKDU+hcbtCZ3P1f8y1JB5JxOf92ItK4euAt6/OFG9jGfKpo/Fs2mAgwxH3HoWMLJQ16Iy"
      //     "u2K6boMyDxRQtBJFTiktuJ+ltlay+dVqIi3Jpg==";
    } else {
      return "qtUa0F+8kUQ3IKx0KnH7INdhZobNEry1toTG1IqYBCeFFj66uMc2Znp3Tlj+fPdO212bCJrRCK27"
          "xKyn0qNtbRene869aUDxMf9nZyPDVDuWoz6TZKdKhgAGlQ65RoLAunUrbLfIwR/OqqZU8zwxwAYU"
          "BPn6f7X0zkoAFDwMUgBMR87RQdLDkGssfCDOmyOYW3qq1hX9k9FZvFMuC6nzJQhQgAy1edFJ4YuW"
          "g5BKXKsulTTzq2cPwz0qPUNp1qR75OitXjo9KoojhJEM6Hj7n8l6ydcPpZpdpUURrn5/7RLEVteX"
          "l84vhHGm6jXjOftcNdR1ikC7wM2hhfVQuhK0gA==";
    }
  }
}
