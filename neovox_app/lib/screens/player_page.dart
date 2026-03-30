import 'package:flutter/material.dart';
import '../services/audio_service.dart' as neo;
import '../services/api_service.dart';
import '../services/youtube_service.dart';
import '../models/playlist.dart';
import '../theme/cyber_theme.dart';
import '../widgets/vinyl_widget.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/equalizer_widget.dart';
import '../widgets/speed_selector.dart';
import '../widgets/scanlines_widget.dart';
import '../widgets/tracklist_widget.dart';

class PlayerPage extends StatefulWidget {
  final neo.NeovoxAudioHandler audioHandler;
  final ApiService api;

  const PlayerPage({
    super.key,
    required this.audioHandler,
    required this.api,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final YouTubeService _yt = YouTubeService();
  List<Playlist> _playlists = [];
  Playlist? _activePlaylist;
  bool _loading = false;
  String _statusMsg = 'CARGANDO...';
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final pls = await widget.api.getPlaylists();
      debugPrint('PlayerPage: ${pls.length} playlists cargadas');
      if (mounted) {
        setState(() {
          _playlists = pls;
          if (pls.isEmpty) {
            _statusMsg = 'ANADE UNA PLAYLIST EN VAULT';
          } else {
            _statusMsg = '${pls.length} PLAYLIST${pls.length > 1 ? 'S' : ''} · SELECCIONA UNA';
          }
        });
      }
    } catch (e) {
      debugPrint('PlayerPage._loadPlaylists error: $e');
      if (mounted) setState(() => _statusMsg = 'ERROR CARGANDO PLAYLISTS');
    }
  }

  Future<void> _selectPlaylist(Playlist pl) async {
    setState(() {
      _activePlaylist = pl;
      _loading = true;
      _statusMsg = 'CARGANDO PLAYLIST...';
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
        _statusMsg = 'ERROR: ${e.toString().length > 40 ? e.toString().substring(0, 40) : e}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          _buildPlayerPanel(),
          const SizedBox(height: 12),
          // Tracklist
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
          // Quick playlist selector
          if (_playlists.isNotEmpty) _buildQuickPlaylistSelector(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel() {
    return Container(
      decoration: CyberTheme.panelDecoration,
      child: Stack(
        children: [
          const ScanlinesOverlay(),
          const CornerAccents(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusDots(),
                const SizedBox(height: 8),
                // Turntable
                StreamBuilder<Track?>(
                  stream: widget.audioHandler.currentTrackStream,
                  builder: (ctx, trackSnap) {
                    return StreamBuilder<bool>(
                      stream: widget.audioHandler.playingStream,
                      builder: (ctx, playSnap) {
                        return StreamBuilder<Duration>(
                          stream: widget.audioHandler.positionStream,
                          builder: (ctx, posSnap) {
                            return StreamBuilder<Duration?>(
                              stream: widget.audioHandler.durationStream,
                              builder: (ctx, durSnap) {
                                final playing = playSnap.data ?? false;
                                final pos = posSnap.data ?? Duration.zero;
                                final track = trackSnap.data;
                                final dur = durSnap.data ?? track?.duration ?? Duration.zero;
                                double progress = 0;
                                if (dur.inMilliseconds > 0) {
                                  progress = pos.inMilliseconds / dur.inMilliseconds;
                                }
                                return TurntableWidget(
                                  imageUrl: track?.thumbnailUrl,
                                  isPlaying: playing,
                                  progress: progress.clamp(0.0, 1.0),
                                  onSeek: dur.inMilliseconds > 0
                                      ? (p) {
                                          final newPos = Duration(
                                              milliseconds:
                                                  (p * dur.inMilliseconds).round());
                                          widget.audioHandler.seek(newPos);
                                        }
                                      : null,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Waveform
                StreamBuilder<bool>(
                  stream: widget.audioHandler.playingStream,
                  builder: (ctx, snap) {
                    return WaveformWidget(isPlaying: snap.data ?? false);
                  },
                ),
                const SizedBox(height: 12),
                _buildTrackInfo(),
                const SizedBox(height: 12),
                _buildProgressBar(),
                const SizedBox(height: 8),
                _buildControls(),
                const SizedBox(height: 12),
                const EqualizerWidget(),
                const SizedBox(height: 12),
                _buildVolumeRow(),
                const SizedBox(height: 8),
                SpeedSelector(
                  currentSpeed: _speed,
                  onSpeedChanged: (s) {
                    widget.audioHandler.setSpeed(s);
                    setState(() {
                      _speed = s;
                      _statusMsg = 'VELOCIDAD: ${s}x';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _statusMsg,
                  style: CyberTheme.mono.copyWith(
                    fontSize: 10, letterSpacing: 1, color: CT.textSys),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDots() {
    return StreamBuilder<bool>(
      stream: widget.audioHandler.playingStream,
      builder: (ctx, snap) {
        final playing = snap.data ?? false;
        final state = playing
            ? 'playing'
            : (_activePlaylist != null ? 'paused' : 'stopped');
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _dot(active: state == 'stopped'),
            const SizedBox(width: 6),
            _dot(active: state == 'paused'),
            const SizedBox(width: 6),
            _dot(active: state == 'playing'),
          ],
        );
      },
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? CT.dotOn : CT.dotOff,
        boxShadow: active
            ? [BoxShadow(color: CT.dotOn.withValues(alpha: 0.7), blurRadius: 7)]
            : null,
      ),
    );
  }

  Widget _buildTrackInfo() {
    return StreamBuilder<Track?>(
      stream: widget.audioHandler.currentTrackStream,
      builder: (ctx, snap) {
        final track = snap.data;
        return Column(
          children: [
            Text(
              track?.title.toUpperCase() ?? 'NEOVOX YT-V',
              style: CyberTheme.orbitron.copyWith(
                fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.textTitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              track != null
                  ? 'TRACK ${(widget.audioHandler.currentIndex + 1).toString().padLeft(2, '0')}'
                  : 'SELECCIONA UNA PLAYLIST',
              style: CyberTheme.mono.copyWith(
                fontSize: 11, letterSpacing: 2, color: CT.textSecondary),
            ),
          ],
        );
      },
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
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            return Column(
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final ratio = details.localPosition.dx / box.size.width;
                    final newPos = Duration(
                        milliseconds: (ratio.clamp(0.0, 1.0) * dur.inMilliseconds).round());
                    widget.audioHandler.seek(newPos);
                  },
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: CT.progBg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0040bb), Color(0xFF0088ff), Color(0xFF00ccff)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0096FF).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Transform.translate(
                            offset: const Offset(4, 0),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CT.progDot,
                                boxShadow: [
                                  BoxShadow(
                                    color: CT.accentGlow.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(pos), style: CyberTheme.mono.copyWith(
                          fontSize: 11, color: CT.textVol)),
                      Text(_fmt(dur), style: CyberTheme.mono.copyWith(
                          fontSize: 11, color: CT.textVol)),
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
            _ctrlButton(
              size: 40,
              icon: Icons.skip_previous_rounded,
              iconSize: 16,
              onTap: widget.audioHandler.skipToPrevious,
            ),
            const SizedBox(width: 8),
            _ctrlButton(
              size: 48,
              icon: Icons.stop_rounded,
              iconSize: 18,
              onTap: () {
                widget.audioHandler.stop();
                setState(() => _statusMsg = 'DETENIDO');
              },
            ),
            const SizedBox(width: 8),
            _ctrlButton(
              size: 64,
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              iconSize: 26,
              active: playing,
              onTap: () {
                if (_activePlaylist == null && widget.audioHandler.tracks.isEmpty) {
                  setState(() => _statusMsg = 'SELECCIONA UNA PLAYLIST PRIMERO');
                  return;
                }
                if (playing) {
                  widget.audioHandler.pause();
                } else {
                  widget.audioHandler.play();
                }
              },
            ),
            const SizedBox(width: 8),
            _ctrlButton(
              size: 48,
              icon: Icons.pause_rounded,
              iconSize: 18,
              active: !playing && _activePlaylist != null,
              onTap: () {
                if (playing) widget.audioHandler.pause();
              },
            ),
            const SizedBox(width: 8),
            _ctrlButton(
              size: 40,
              icon: Icons.skip_next_rounded,
              iconSize: 16,
              onTap: widget.audioHandler.skipToNext,
            ),
          ],
        );
      },
    );
  }

  Widget _ctrlButton({
    required double size,
    required IconData icon,
    required double iconSize,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: CT.isDark
                ? [const Color(0xFF0c1428), const Color(0xFF080e1c)]
                : [const Color(0xFFe8ecf4), const Color(0xFFdce0ec)],
          ),
          border: Border.all(
            color: active ? CT.btnActiveBorder : CT.borderPanel,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? const Color(0xFF0064FF).withValues(alpha: 0.35)
                  : const Color(0xFF003CB4).withValues(alpha: 0.1),
              blurRadius: active ? 20 : 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: active ? CT.btnHoverFill : CT.btnFill,
        ),
      ),
    );
  }

  Widget _buildVolumeRow() {
    return Row(
      children: [
        Text('VOL', style: CyberTheme.mono.copyWith(
            fontSize: 10, letterSpacing: 2, color: CT.textVol)),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: CT.volFill,
              inactiveTrackColor: CT.volTrack,
              thumbColor: CT.accentGlow,
              overlayColor: CT.accentGlow.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: widget.audioHandler.volume,
              onChanged: (v) {
                widget.audioHandler.setVolume(v);
                setState(() {});
              },
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${(widget.audioHandler.volume * 100).round()}',
            style: CyberTheme.mono.copyWith(fontSize: 11, color: CT.accent),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPlaylistSelector() {
    return Container(
      decoration: CyberTheme.panelAltDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLAYLISTS', style: CyberTheme.orbitron.copyWith(
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.textHeader)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _playlists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final pl = _playlists[i];
                final active = pl.id == _activePlaylist?.id;
                return GestureDetector(
                  onTap: () => _selectPlaylist(pl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? CT.plActiveBg : CT.plBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? CT.plActiveBorder : CT.plBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading && active)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: CT.accentGlow),
                            ),
                          ),
                        Text(
                          pl.name.toUpperCase(),
                          style: CyberTheme.orbitron.copyWith(
                            fontSize: 9, letterSpacing: 1,
                            color: active ? CT.plNameActive : CT.plName),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
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
