import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import '../widgets/track_list_tile.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  List<Track> _tracks = [];
  bool _loading = true;
  String? _thumbnail;
  String? _author;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final data = await ApiService.getPlaylistItems(widget.playlist.ytId);
      if (mounted) {
        setState(() {
          _tracks = (data['items'] as List).map((j) => Track.fromJson(j)).toList();
          _thumbnail = data['thumbnail'] as String?;
          _author = data['author'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playAll() {
    if (_tracks.isEmpty) return;
    audioHandler.playQueue(_tracks, 0);
  }

  void _shufflePlay() {
    if (_tracks.isEmpty) return;
    final shuffled = [..._tracks]..shuffle();
    audioHandler.playQueue(shuffled, 0);
  }

  void _playTrack(Track track) {
    final idx = _tracks.indexOf(track);
    audioHandler.playQueue(_tracks, idx >= 0 ? idx : 0);
  }

  Future<void> _deletePlaylist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar playlist'),
        content: Text('Eliminar "${widget.playlist.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deletePlaylist(widget.playlist.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            title: Text(widget.playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _deletePlaylist),
            ],
          ),

          // Hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: _thumbnail!,
                            width: 140, height: 140,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _artPlaceholder(cs),
                            errorWidget: (_, __, ___) => _artPlaceholder(cs),
                          )
                        : _artPlaceholder(cs),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.playlist.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (_author != null) ...[
                          const SizedBox(height: 4),
                          Text(_author!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 4),
                        Text(_loading ? 'Cargando...' : '${_tracks.length} canciones',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _playAll,
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text('Reproducir'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _shufflePlay,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(10),
                                minimumSize: const Size(44, 44),
                              ),
                              child: const Icon(Icons.shuffle_rounded, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tracks
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
            )
          else if (_tracks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.music_off_rounded, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text('No se encontraron canciones', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => TrackListTile(
                  track: _tracks[i],
                  index: i + 1,
                  onTap: () => _playTrack(_tracks[i]),
                ),
                childCount: _tracks.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _artPlaceholder(ColorScheme cs) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [cs.primary, const Color(0xFFFC5C7C)],
        ),
      ),
      child: const Icon(Icons.queue_music_rounded, size: 40, color: Colors.white),
    );
  }
}
