import 'dart:async';

/// Stub for non-web platforms. Never actually called.
class YtWebPlayer {
  static final YtWebPlayer _instance = YtWebPlayer._();
  factory YtWebPlayer() => _instance;
  YtWebPlayer._();

  Stream<bool> get playingStream => const Stream.empty();
  Stream<void> get endedStream => const Stream.empty();
  bool get isPlaying => false;

  Future<void> init() async {}
  void loadAndPlay(String videoId) {}
  void play() {}
  void pause() {}
  void stop() {}
  void seekTo(double seconds) {}
  void setVolume(int volume) {}
  double getCurrentTime() => 0;
  double getDuration() => 0;
}
