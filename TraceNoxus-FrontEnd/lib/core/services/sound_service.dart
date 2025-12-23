import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  /// Plays the notification sound.
  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.stop(); // Stop any currently playing sound
      await _audioPlayer.play(AssetSource('audio/notification.wav'));
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }
}
