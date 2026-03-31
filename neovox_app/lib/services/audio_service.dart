import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;
import '../models/playlist.dart';
// Conditional import for web player
import 'yt_web_player_stub.dart'
    if (dart.library.js_interop) 'yt_web_player.dart';

late NeovoxAudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => NeovoxAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.neovox.music.channel',
      androidNotificationChannelName: 'NEOVOX Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  if (kIsWeb) {
    await audioHandler._initWebPlayerAsync();
  }
}

class NeovoxAudioHandler extends BaseAudioHandler with SeekHandler {
  // Native player (mobile/desktop)
  final AudioPlayer _player = AudioPlayer();

  // Web player
  Timer? _webPositionTimer;
  bool _webPlaying = false;
  Duration _webPosition = Duration.zero;
  Duration _webDuration = Duration.zero;

  List<Track> queue_ = [];
  int currentIndex = -1;
  bool shuffleEnabled = false;
  int repeatMode_ = 0; // 0=off, 1=all, 2=one

  Track? get currentTrack =>
      currentIndex >= 0 && currentIndex < queue_.length ? queue_[currentIndex] : null;

  final _trackController = StreamController<Track?>.broadcast();
  Stream<Track?> get trackStream => _trackController.stream;

  // Unified streams for UI
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();

  NeovoxAudioHandler() {
    if (!kIsWeb) {
      _initNativePlayer();
    }
  }

  Future<void> _initWebPlayerAsync() async {
    final webPlayer = YtWebPlayer();
    await webPlayer.init();

    webPlayer.playingStream.listen((playing) {
      _webPlaying = playing;
      _playingController.add(playing);
    });

    webPlayer.endedStream.listen((_) {
      _onTrackEnd();
    });

    // Poll position
    _webPositionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _webPosition = Duration(milliseconds: (webPlayer.getCurrentTime() * 1000).toInt());
      _webDuration = Duration(milliseconds: (webPlayer.getDuration() * 1000).toInt());
      _positionController.add(_webPosition);
      if (_webDuration.inSeconds > 0) {
        _durationController.add(_webDuration);
      }
    });
  }

  void _initNativePlayer() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapState(event.processingState),
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
      ));
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackEnd();
      }
    });
  }

  AudioProcessingState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _onTrackEnd() {
    if (repeatMode_ == 2) {
      if (kIsWeb) {
        YtWebPlayer().seekTo(0);
        YtWebPlayer().play();
      } else {
        _player.seek(Duration.zero);
        _player.play();
      }
      return;
    }
    if (currentIndex < queue_.length - 1) {
      skipToNext();
    } else if (repeatMode_ == 1) {
      currentIndex = 0;
      _playCurrentTrack();
    }
  }

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    queue_ = tracks;
    currentIndex = startIndex;
    await _playCurrentTrack();
  }

  int _consecutiveErrors = 0;
  static const _maxConsecutiveErrors = 3;
  final yte.YoutubeExplode _yt = yte.YoutubeExplode();

  Future<void> _playCurrentTrack() async {
    final track = currentTrack;
    if (track == null) return;
    _trackController.add(track);

    mediaItem.add(MediaItem(
      id: track.videoId,
      title: track.title,
      artist: track.artist,
      artUri: track.thumbnailUrl.isNotEmpty ? Uri.parse(track.thumbnailUrl) : null,
      duration: track.duration,
    ));

    try {
      if (kIsWeb) {
        // Web: use YouTube IFrame Player — no CORS, no scraping
        YtWebPlayer().loadAndPlay(track.videoId);
        _webPlaying = true;
        _playingController.add(true);
      } else {
        // Mobile/desktop: resolve directly via youtube_explode_dart
        final manifest = await _yt.videos.streamsClient.getManifest(track.videoId);
        final audioStreams = manifest.audioOnly.sortByBitrate();
        if (audioStreams.isEmpty) throw Exception('No audio streams');
        final streamUrl = audioStreams.last.url.toString();
        await _player.setUrl(streamUrl);
        _player.play();
      }
      _consecutiveErrors = 0;
    } catch (e) {
      debugPrint('AudioService: failed to play ${track.videoId}: $e');
      _consecutiveErrors++;
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _consecutiveErrors = 0;
        return;
      }
      if (currentIndex < queue_.length - 1) {
        Future.delayed(const Duration(seconds: 1), () => skipToNext());
      }
    }
  }

  @override
  Future<void> play() async {
    if (kIsWeb) {
      YtWebPlayer().play();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (kIsWeb) {
      YtWebPlayer().pause();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> stop() async {
    if (kIsWeb) {
      YtWebPlayer().stop();
    } else {
      await _player.stop();
    }
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (kIsWeb) {
      YtWebPlayer().seekTo(position.inMilliseconds / 1000.0);
    } else {
      await _player.seek(position);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (currentIndex < queue_.length - 1) {
      currentIndex++;
      await _playCurrentTrack();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (kIsWeb) {
      if (_webPosition.inSeconds > 3) {
        YtWebPlayer().seekTo(0);
        return;
      }
    } else {
      if (_player.position.inSeconds > 3) {
        await _player.seek(Duration.zero);
        return;
      }
    }
    if (currentIndex > 0) {
      currentIndex--;
      await _playCurrentTrack();
    }
  }

  Future<void> setVolume(double volume) async {
    if (kIsWeb) {
      YtWebPlayer().setVolume((volume * 100).toInt());
    } else {
      await _player.setVolume(volume);
    }
  }

  Future<void> setSpeed(double speed) async {
    if (!kIsWeb) {
      await _player.setSpeed(speed);
    }
  }

  // Unified streams — UI uses these
  Stream<Duration> get positionStream =>
      kIsWeb ? _positionController.stream : _player.positionStream;
  Stream<Duration?> get durationStream =>
      kIsWeb ? _durationController.stream : _player.durationStream;
  Stream<bool> get playingStream =>
      kIsWeb ? _playingController.stream : _player.playingStream;

  Duration get position => kIsWeb ? _webPosition : _player.position;
  Duration? get duration => kIsWeb ? _webDuration : _player.duration;
  bool get isPlaying => kIsWeb ? _webPlaying : _player.playing;

  void toggleShuffle() {
    shuffleEnabled = !shuffleEnabled;
    if (shuffleEnabled && queue_.length > 1) {
      final current = queue_[currentIndex];
      final rest = [...queue_]..removeAt(currentIndex);
      rest.shuffle();
      queue_ = [current, ...rest];
      currentIndex = 0;
    }
  }

  void toggleRepeat() {
    repeatMode_ = (repeatMode_ + 1) % 3;
  }
}
