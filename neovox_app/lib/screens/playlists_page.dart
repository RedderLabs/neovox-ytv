import 'package:flutter/material.dart';
import '../services/audio_service.dart' as neo;
import '../services/api_service.dart';
import '../services/youtube_service.dart';
import '../models/playlist.dart';
import '../theme/cyber_theme.dart';
import '../widgets/scanlines_widget.dart';

class PlaylistsPage extends StatefulWidget {
  final neo.NeovoxAudioHandler audioHandler;
  final ApiService api;
  final VoidCallback? onPlaylistLoaded;

  const PlaylistsPage({
    super.key,
    required this.audioHandler,
    required this.api,
    this.onPlaylistLoaded,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final YouTubeService _yt = YouTubeService();
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final pls = await widget.api.getPlaylists();
      if (mounted) setState(() => _playlists = pls);
    } catch (e) {
      debugPrint('PlaylistsPage._loadPlaylists error: $e');
    }
  }

  Future<void> _selectPlaylist(Playlist pl) async {
    setState(() {
      _activePlaylist = pl;
      _loading = true;
    });

    try {
      final tracks = await _yt.getPlaylistTracks(pl.ytId);
      if (tracks.isNotEmpty) {
        await widget.audioHandler.loadPlaylist(tracks);
        // Ir al HOME para ver tracks y seleccionar pista
        widget.onPlaylistLoaded?.call();
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
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
    } catch (_) {}
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: CyberTheme.panelDecoration,
        child: Stack(
          children: [
            const ScanlinesOverlay(),
            const CornerAccents(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PLAYLIST VAULT', style: CyberTheme.orbitron.copyWith(
                        fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textHeader)),
                      Text(
                        '${_playlists.length}/20',
                        style: CyberTheme.mono.copyWith(
                          fontSize: 11, letterSpacing: 1, color: CT.counterColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  GestureDetector(
                    onTap: _playlists.length < 20 ? _addPlaylist : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: CT.isDark
                              ? [const Color(0xFF0c1e4a), const Color(0xFF081430)]
                              : [const Color(0xFFd0daf0), const Color(0xFFc0cce4)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CT.addBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ ANADIR PLAYLIST',
                        style: CyberTheme.orbitron.copyWith(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          letterSpacing: 2, color: CT.addText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.library_music_outlined, size: 40, color: CT.counterColor),
                            const SizedBox(height: 12),
                            Text(
                              'VAULT VACIA\nANADE TU PRIMERA PLAYLIST',
                              textAlign: TextAlign.center,
                              style: CyberTheme.mono.copyWith(
                                fontSize: 12, letterSpacing: 2, color: CT.plIdColor, height: 2.2),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ...List.generate(_playlists.length, (i) {
                    final pl = _playlists[i];
                    final isActive = pl.id == _activePlaylist?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PlaylistItem(
                        playlist: pl,
                        isActive: isActive,
                        isLoading: _loading && isActive,
                        onTap: () => _selectPlaylist(pl),
                        onDelete: () => _deletePlaylist(pl),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _yt.dispose();
    super.dispose();
  }
}

// ── PLAYLIST ITEM ──
class _PlaylistItem extends StatelessWidget {
  final Playlist playlist;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistItem({
    required this.playlist,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? CT.plActiveBg : CT.plBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? CT.plActiveBorder : CT.plBorder,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF0050DC).withValues(alpha: 0.2), blurRadius: 18)]
              : null,
        ),
        child: Row(
          children: [
            // Vinyl icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0d1f5c), Color(0xFF071540)],
                ),
                border: Border.all(color: const Color(0xFF1a3080)),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: CT.accentGlow),
                    )
                  : Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [Color(0xFF0c0c18), Color(0xFF151530), Color(0xFF0c0c18), Color(0xFF151530)],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1a3a8f),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: CyberTheme.orbitron.copyWith(
                      fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700,
                      color: isActive ? CT.plNameActive : CT.plName),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playlist.ytId,
                    style: CyberTheme.mono.copyWith(
                        fontSize: 10, letterSpacing: 1, color: CT.plIdColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CT.plBadgeBg,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: CT.plBadgeBorder),
                    ),
                    child: Text(
                      'YT PLAYLIST',
                      style: CyberTheme.orbitron.copyWith(
                          fontSize: 9, letterSpacing: 1, color: CT.plBadgeColor),
                    ),
                  ),
                ],
              ),
            ),
            _itemBtn(Icons.play_arrow, 10, onTap),
            const SizedBox(width: 5),
            _itemBtn(Icons.close, 10, onDelete, iconColor: CT.danger),
          ],
        ),
      ),
    );
  }

  Widget _itemBtn(IconData icon, double size, VoidCallback onTap,
      {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: CT.inputBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CT.plBorder),
        ),
        child: Icon(icon, size: size, color: iconColor ?? CT.btnFill),
      ),
    );
  }
}

// ── ADD PLAYLIST DIALOG ──
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: CyberTheme.panelDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ANADIR PLAYLIST', style: CyberTheme.orbitron.copyWith(
              fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3, color: CT.textTitle)),
            const SizedBox(height: 20),
            Text('NOMBRE', style: CyberTheme.mono.copyWith(
                fontSize: 10, letterSpacing: 2, color: CT.labelColor)),
            const SizedBox(height: 6),
            _cyberInput(_nameCtrl, 'Mi playlist favorita'),
            const SizedBox(height: 12),
            Text('URL DE YOUTUBE', style: CyberTheme.mono.copyWith(
                fontSize: 10, letterSpacing: 2, color: CT.labelColor)),
            const SizedBox(height: 6),
            _cyberInput(_urlCtrl, 'https://youtube.com/playlist?list=...'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CT.inputBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text('CANCELAR', style: CyberTheme.mono.copyWith(
                          fontSize: 11, letterSpacing: 2, color: CT.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final name = _nameCtrl.text.trim();
                      final ytId = _extractPlaylistId(_urlCtrl.text.trim());
                      if (name.isEmpty || ytId == null) return;
                      Navigator.pop(context, {'name': name, 'ytId': ytId});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0c1e4a), Color(0xFF081430)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CT.addBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text('ANADIR', style: CyberTheme.orbitron.copyWith(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          letterSpacing: 2, color: CT.addText)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cyberInput(TextEditingController ctrl, String hint) {
    return Container(
      decoration: CyberTheme.inputDecoration,
      child: TextField(
        controller: ctrl,
        style: CyberTheme.mono.copyWith(fontSize: 13, letterSpacing: 1, color: CT.inputColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: CyberTheme.mono.copyWith(fontSize: 12, color: CT.inputPlaceholder),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
