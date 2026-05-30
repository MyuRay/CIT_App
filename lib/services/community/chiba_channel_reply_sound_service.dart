import 'package:audioplayers/audioplayers.dart';

/// ちばちゃんねる 新着レス通知音
class ChibaChannelReplySoundService {
  ChibaChannelReplySoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static const _assetPath = 'sounds/chiba_channel_reply_pop.wav';
  static bool _configured = false;

  static Future<void> ensureLoaded() async {
    if (_configured) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(0.55);
    _configured = true;
  }

  static Future<void> playNewReplyPop() async {
    try {
      await ensureLoaded();
      await _player.stop();
      await _player.play(AssetSource(_assetPath));
    } catch (_) {
      // 効果音失敗は投稿・閲覧に影響させない
    }
  }
}
