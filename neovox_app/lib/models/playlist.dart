class Playlist {
  final String id;
  final String name;
  final String ytId;
  final int added;
  String? thumbnailUrl;
  int? trackCount;

  Playlist({
    required this.id,
    required this.name,
    required this.ytId,
    required this.added,
    this.thumbnailUrl,
    this.trackCount,
  });

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        ytId: j['ytId'] ?? '',
        added: j['added'] is int ? j['added'] : int.tryParse('${j['added']}') ?? 0,
      );
}

class Track {
  final String videoId;
  final String title;
  final String artist;
  final Duration duration;
  final String thumbnailUrl;
  String? streamUrl;

  Track({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnailUrl,
    this.streamUrl,
  });

  factory Track.fromJson(Map<String, dynamic> j) {
    final dur = j['duration'] as String? ?? '0:00';
    final parts = dur.split(':').map(int.tryParse).toList();
    Duration d;
    if (parts.length == 3) {
      d = Duration(hours: parts[0] ?? 0, minutes: parts[1] ?? 0, seconds: parts[2] ?? 0);
    } else if (parts.length == 2) {
      d = Duration(minutes: parts[0] ?? 0, seconds: parts[1] ?? 0);
    } else {
      d = Duration.zero;
    }
    return Track(
      videoId: j['videoId'] ?? j['id'] ?? '',
      title: j['title'] ?? '',
      artist: j['artist'] ?? j['author'] ?? 'Unknown',
      duration: d,
      thumbnailUrl: j['thumbnail'] ?? j['thumbnailUrl'] ?? '',
    );
  }
}
