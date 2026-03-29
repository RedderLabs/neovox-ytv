import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/playlist.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Obtiene la lista de tracks de una playlist de YouTube
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final tracks = <Track>[];
    await for (final video in _yt.playlists.getVideos(playlistId)) {
      tracks.add(Track(
        videoId: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: video.thumbnails.mediumResUrl,
      ));
    }
    return tracks;
  }

  /// Obtiene la URL del stream de audio para un video
  Future<String> getAudioStreamUrl(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    // Preferir audio-only con mayor bitrate
    final audioStreams = manifest.audioOnly.sortByBitrate();
    if (audioStreams.isEmpty) {
      throw Exception('No se encontraron streams de audio');
    }
    return audioStreams.last.url.toString();
  }

  /// Obtiene info de un video individual
  Future<Track> getVideoInfo(String videoId) async {
    final video = await _yt.videos.get(videoId);
    return Track(
      videoId: video.id.value,
      title: video.title,
      author: video.author,
      duration: video.duration ?? Duration.zero,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }

  void dispose() {
    _yt.close();
  }
}
