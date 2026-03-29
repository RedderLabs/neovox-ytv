import 'package:flutter/material.dart';
import '../services/audio_service.dart' as neo;
import '../services/api_service.dart';
import '../services/youtube_service.dart';
import '../models/playlist.dart';
import '../theme/cyber_theme.dart';
import '../widgets/vinyl_widget.dart';
import '../widgets/tracklist_widget.dart';

class PlayerScreen extends StatefulWidget {
  final neo.NeovoxAudioHandler audioHandler;
  final ApiService api;

  const PlayerScreen({
    super.key,
    required this.audioHandler,
    required this.api,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final YouTubeService _yt = YouTubeService();
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  bool _loading = false;
  String _statusMsg = 'SELECCIONA UNA PLAYLIST';

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final pls = await widget.api.getPlaylists();
      setState(() => _playlists = pls);
    } catch (e) {
      setState(() => _statusMsg = 'ERROR CARGANDO PLAYLISTS');
    }
  }

  Future<void> _selectPlaylist(Playlist pl) async {
    setState(() {
      _activePlaylist = pl;
      _loading = true;
      _statusMsg = 'CARGANDO: ${pl.name}...';
    });

    try {
      final tracks = await _yt.getPlaylistTracks(pl.ytId);
      if (tracks.isEmpty) {
        setState(() {
          _loading = false;
          _statusMsg = 'PLAYLIST VACIA O PRIVADA';
        });
        return;
      }
      await widget.audioHandler.loadPlaylist(tracks);
      setState(() {
        _loading = false;
        _statusMsg = '${tracks.length} TRACKS CARGADOS';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMsg = 'ERROR: ${e.toString().substring(0, 40)}';
      });
    }
  }

  Future<void> _addPlaylist() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _AddPlaylistDialog(),
    );
    if (result == null) return;

    try {
      final pl = await widget.api.addPlaylist(result['name']!, result['ytId']!);
      setState(() => _playlists.insert(0, pl));
      setState(() => _statusMsg = 'PLAYLIST GUARDADA');
    } catch (e) {
      setState(() => _statusMsg = 'ERROR AL GUARDAR');
    }
  }

  Future<void> _deletePlaylist(Playlist pl) async {
    try {
      await widget.api.deletePlaylist(pl.id);
      setState(() {
        _playlists.removeWhere((p) => p.id == pl.id);
        if (_activePlaylist?.id == pl.id) {
          _activePlaylist = null;
          widget.audioHandler.stop();
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEOVOX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 18),
            onPressed: () {
              // TODO: logout
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // ── Vinilo + controles ──
              _buildPlayerSection(),
              const SizedBox(height: 12),

              // ── Tracklist ──
              StreamBuilder<Track?>(
                stream: widget.audioHandler.currentTrackStream,
                builder: (ctx, snap) {
                  if (widget.audioHandler.tracks.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return TracklistWidget(
                    tracks: widget.audioHandler.tracks,
                    currentIndex: widget.audioHandler.currentIndex,
                    onTrackTap: (i) => widget.audioHandler.skipToQueueItem(i),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Playlist Vault ──
              _buildPlaylistVault(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vinilo con carátula
            StreamBuilder<Track?>(
              stream: widget.audioHandler.currentTrackStream,
              builder: (ctx, snap) {
                final track = snap.data;
                return VinylWidget(
                  imageUrl: track?.thumbnailUrl,
                  isPlaying: false, // se actualiza abajo
                );
              },
            ),
            const SizedBox(height: 12),

            // Título del track
            StreamBuilder<Track?>(
              stream: widget.audioHandler.currentTrackStream,
              builder: (ctx, snap) {
                final track = snap.data;
                return Column(
                  children: [
                    Text(
                      track?.title.toUpperCase() ?? 'NEOVOX YT-V',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        letterSpacing: 2,
                        color: CyberTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track?.author ?? 'SELECCIONA UNA PLAYLIST',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: CyberTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Barra de progreso
            _buildProgressBar(),
            const SizedBox(height: 8),

            // Controles
            _buildControls(),
            const SizedBox(height: 8),

            // Volumen
            _buildVolumeSlider(),

            // Status
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _statusMsg,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: CyberTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.audioHandler.positionStream,
      builder: (ctx, posSnap) {
        return StreamBuilder<Duration?>(
          stream: widget.audioHandler.durationStream,
          builder: (ctx, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final progress = dur.inMilliseconds > 0
                ? pos.inMilliseconds / dur.inMilliseconds
                : 0.0;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) {
                      final newPos = Duration(
                        milliseconds: (v * dur.inMilliseconds).round(),
                      );
                      widget.audioHandler.seek(newPos);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(pos),
                          style: const TextStyle(fontSize: 10, color: CyberTheme.textSecondary)),
                      Text(_formatDuration(dur),
                          style: const TextStyle(fontSize: 10, color: CyberTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<bool>(
      stream: widget.audioHandler.playingStream,
      builder: (ctx, snap) {
        final playing = snap.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 28),
              onPressed: widget.audioHandler.skipToPrevious,
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CyberTheme.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: CyberTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 36,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                onPressed: playing
                    ? widget.audioHandler.pause
                    : widget.audioHandler.play,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.stop_rounded, size: 28),
              onPressed: widget.audioHandler.stop,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 28),
              onPressed: widget.audioHandler.skipToNext,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 16, color: CyberTheme.textSecondary),
        Expanded(
          child: Slider(
            value: widget.audioHandler.volume,
            onChanged: (v) {
              widget.audioHandler.setVolume(v);
              setState(() {});
            },
          ),
        ),
        const Icon(Icons.volume_up, size: 16, color: CyberTheme.textSecondary),
      ],
    );
  }

  Widget _buildPlaylistVault() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PLAYLIST VAULT',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_playlists.length} LISTAS',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: CyberTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón añadir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addPlaylist,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('AÑADIR PLAYLIST',
                    style: TextStyle(fontSize: 11, letterSpacing: 2)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CyberTheme.accent,
                  side: const BorderSide(color: CyberTheme.inputBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lista
            if (_playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'VAULT VACIA\nAÑADE TU PRIMERA PLAYLIST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: CyberTheme.textSecondary,
                      height: 2,
                    ),
                  ),
                ),
              ),

            ...List.generate(_playlists.length, (i) {
              final pl = _playlists[i];
              final isActive = pl.id == _activePlaylist?.id;
              return _PlaylistTile(
                playlist: pl,
                isActive: isActive,
                isLoading: _loading && isActive,
                onTap: () => _selectPlaylist(pl),
                onDelete: () => _deletePlaylist(pl),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _yt.dispose();
    super.dispose();
  }
}

// ── Tile de playlist ──
class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistTile({
    required this.playlist,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive ? CyberTheme.accent.withValues(alpha: 0.1) : CyberTheme.inputBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? CyberTheme.accent : CyberTheme.inputBorder,
              ),
            ),
            child: Row(
              children: [
                // Icono vinilo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: CyberTheme.bgCard,
                    border: Border.all(color: CyberTheme.inputBorder),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.album, size: 20, color: CyberTheme.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: isActive ? CyberTheme.accent : CyberTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        playlist.ytId,
                        style: const TextStyle(fontSize: 9, color: CyberTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  onPressed: onTap,
                  color: CyberTheme.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: onDelete,
                  color: CyberTheme.danger,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialog para añadir playlist ──
class _AddPlaylistDialog extends StatefulWidget {
  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  String? _extractPlaylistId(String url) {
    final match = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CyberTheme.bgCard,
      title: const Text('AÑADIR PLAYLIST',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, letterSpacing: 2)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'NOMBRE',
              labelStyle: TextStyle(fontSize: 11, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL DE YOUTUBE',
              labelStyle: TextStyle(fontSize: 11, letterSpacing: 2),
              hintText: 'https://youtube.com/playlist?list=...',
              hintStyle: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final ytId = _extractPlaylistId(_urlCtrl.text.trim());
            if (name.isEmpty || ytId == null) return;
            Navigator.pop(context, {'name': name, 'ytId': ytId});
          },
          child: const Text('AÑADIR'),
        ),
      ],
    );
  }
}
