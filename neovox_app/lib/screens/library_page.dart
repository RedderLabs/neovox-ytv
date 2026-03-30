import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with AutomaticKeepAliveClientMixin {
  List<Playlist> _playlists = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = data.map((j) => Playlist.fromJson(j)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPlaylist() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _AddPlaylistDialog(),
    );
    if (result == null) return;

    try {
      await ApiService.addPlaylist(result['name']!, result['ytId']!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist agregada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al agregar playlist')));
      }
    }
  }

  Future<void> _deletePlaylist(Playlist pl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar playlist'),
        content: Text('Eliminar "${pl.name}"?'),
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
      await ApiService.deletePlaylist(pl.id);
      _load();
    } catch (_) {}
  }

  Future<void> _quickPlay(Playlist pl) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cargando ${pl.name}...')));
    try {
      final data = await ApiService.getPlaylistItems(pl.ytId);
      final items = (data['items'] as List).map((j) => Track.fromJson(j)).toList();
      if (items.isNotEmpty) {
        audioHandler.playQueue(items, 0);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text('Biblioteca', style: Theme.of(context).appBarTheme.titleTextStyle)),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _addPlaylist,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _playlists.isEmpty
                    ? _emptyState(cs)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _playlists.length,
                          itemBuilder: (context, i) => _PlaylistTile(
                            playlist: _playlists[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailPage(playlist: _playlists[i]),
                              ),
                            ).then((_) => _load()),
                            onPlay: () => _quickPlay(_playlists[i]),
                            onDelete: () => _deletePlaylist(_playlists[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.queue_music_rounded, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(height: 12),
          Text('Aun no tienes playlists', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addPlaylist,
            child: const Text('Agregar playlist'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(colors: [cs.primary, const Color(0xFFFC5C7C)]),
        ),
        child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 24),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('YouTube Playlist', style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: onPlay,
            tooltip: 'Reproducir',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: cs.error.withAlpha(150)),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AddPlaylistDialog extends StatefulWidget {
  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar playlist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pega la URL de una playlist de YouTube',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'Nombre'),
            maxLength: 40,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(hintText: 'https://youtube.com/playlist?list=...'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final url = _urlCtrl.text.trim();
            if (name.isEmpty || url.isEmpty) return;
            final match = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(url);
            if (match == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL de playlist invalida')));
              return;
            }
            Navigator.pop(context, {'name': name, 'ytId': match.group(1)!});
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
