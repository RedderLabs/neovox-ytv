import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playlist.dart';
import 'youtube_service.dart';

/// Handler que corre como Foreground Service en Android / AVAudioSession en iOS
class NeovoxAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _yt = YouTubeService();

  List<Track> _tracks = [];
  int _currentIndex = -1;

  final _currentTrackController = StreamController<Track?>.broadcast();
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Track? get currentTrack => _currentIndex >= 0 && _currentIndex < _tracks.length
      ? _tracks[_currentIndex]
      : null;
  int get currentIndex => _currentIndex;
  List<Track> get tracks => _tracks;

  NeovoxAudioHandler() {
    // Sincronizar estado del player con MediaSession del OS
    _player.playbackEventStream.listen(_broadcastState);

    // Auto-avanzar al siguiente track
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  /// Cargar una playlist completa
  Future<void> loadPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    _tracks = tracks;
    _currentIndex = -1;

    // Actualizar la queue del MediaSession
    queue.add(tracks
        .map((t) => MediaItem(
              id: t.videoId,
              title: t.title,
              artist: t.author,
              duration: t.duration,
              artUri: Uri.parse(t.thumbnailUrl),
            ))
        .toList());

    await skipToQueueItem(startIndex);
  }

  /// Reproducir un track específico por índice
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    _currentIndex = index;
    final track = _tracks[index];
    _currentTrackController.add(track);

    // Actualizar MediaItem activo (controles del OS)
    mediaItem.add(MediaItem(
      id: track.videoId,
      title: track.title,
      artist: track.author,
      duration: track.duration,
      artUri: Uri.parse(track.thumbnailUrl),
    ));

    try {
      // Obtener URL del stream (desde el dispositivo → IP residencial)
      final url = await _yt.getAudioStreamUrl(track.videoId);
      track.streamUrl = url;
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      // Si falla, saltar al siguiente
      if (_currentIndex < _tracks.length - 1) {
        await skipToNext();
      }
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentIndex = -1;
    _currentTrackController.add(null);
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_tracks.isEmpty) return;
    final next = (_currentIndex + 1) % _tracks.length;
    await skipToQueueItem(next);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_tracks.isEmpty) return;
    // Si estamos a más de 3s, reiniciar el track actual
    if ((_player.position.inSeconds) > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = (_currentIndex - 1 + _tracks.length) % _tracks.length;
    await skipToQueueItem(prev);
  }

  /// Broadcast del estado al OS (notificación, lock screen, etc.)
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  // Exponer streams del player
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  double get volume => _player.volume;
  double get speed => _player.speed;

  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  void dispose() {
    _player.dispose();
    _yt.dispose();
    _currentTrackController.close();
  }
}
