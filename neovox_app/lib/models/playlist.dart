class Playlist {
  final String id;
  final String name;
  final String ytId;
  final int added;

  Playlist({
    required this.id,
    required this.name,
    required this.ytId,
    required this.added,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        ytId: json['ytId'] as String,
        added: json['added'] is int
            ? json['added'] as int
            : int.parse(json['added'].toString()),
      );
}

class Track {
  final String videoId;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;
  String? streamUrl;

  Track({
    required this.videoId,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    this.streamUrl,
  });
}
