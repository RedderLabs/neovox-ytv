import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';

class FullPlayerWidget extends StatefulWidget {
  final VoidCallback onClose;
  const FullPlayerWidget({super.key, required this.onClose});

  @override
  State<FullPlayerWidget> createState() => _FullPlayerWidgetState();
}

class _FullPlayerWidgetState extends State<FullPlayerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    widget.onClose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final artSize = (size.width - 48).clamp(200.0, 380.0).toDouble();

    return SlideTransition(
      position: _slideAnim,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: StreamBuilder<Track?>(
          stream: audioHandler.trackStream,
          builder: (_, snap) {
            final track = snap.data ?? audioHandler.currentTrack;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Blurred bg
                if (track != null && track.thumbnailUrl.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.3,
                      child: CachedNetworkImage(
                        imageUrl: track.thumbnailUrl,
                        fit: BoxFit.cover,
                        color: Colors.black54,
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  ),
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                                onPressed: _close,
                              ),
                              Text('Reproduciendo',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                      color: Theme.of(context).textTheme.bodyMedium?.color)),
                              IconButton(
                                icon: const Icon(Icons.queue_music_rounded),
                                onPressed: () => _showQueue(context),
                              ),
                            ],
                          ),
                        ),

                        // Art
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: artSize, height: artSize,
                                child: track != null && track.thumbnailUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: track.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => _artPlaceholder(cs),
                                        errorWidget: (_, __, ___) => _artPlaceholder(cs),
                                      )
                                    : _artPlaceholder(cs),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Track info
                        Text(
                          track?.title ?? 'Sin reproduccion',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track?.artist ?? '--',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Progress
                        StreamBuilder<Duration>(
                          stream: audioHandler.positionStream,
                          builder: (_, posSnap) {
                            return StreamBuilder<Duration?>(
                              stream: audioHandler.durationStream,
                              builder: (_, durSnap) {
                                final pos = posSnap.data ?? Duration.zero;
                                final dur = durSnap.data ?? Duration.zero;
                                final maxVal = dur.inMilliseconds.toDouble();
                                final curVal = pos.inMilliseconds.toDouble().clamp(0.0, maxVal > 0 ? maxVal : 1.0);
                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: Theme.of(context).sliderTheme.copyWith(
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                      ),
                                      child: Slider(
                                        value: curVal,
                                        max: maxVal > 0 ? maxVal : 1,
                                        onChanged: (v) {
                                          audioHandler.seek(Duration(milliseconds: v.toInt()));
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fmt(pos), style: Theme.of(context).textTheme.bodySmall),
                                          Text(_fmt(dur), style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Controls
                        StreamBuilder<bool>(
                          stream: audioHandler.playingStream,
                          builder: (_, snap) {
                            final playing = snap.data ?? false;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shuffle_rounded,
                                      color: audioHandler.shuffleEnabled ? cs.primary : null),
                                  onPressed: () {
                                    audioHandler.toggleShuffle();
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, size: 32),
                                  onPressed: audioHandler.skipToPrevious,
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 20, spreadRadius: 2),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36),
                                    color: Colors.white,
                                    onPressed: playing ? audioHandler.pause : audioHandler.play,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, size: 32),
                                  onPressed: audioHandler.skipToNext,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    audioHandler.repeatMode_ == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                    color: audioHandler.repeatMode_ > 0 ? cs.primary : null,
                                  ),
                                  onPressed: () {
                                    audioHandler.toggleRepeat();
                                    setState(() {});
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Volume
                        Row(
                          children: [
                            Icon(Icons.volume_up_rounded, size: 20,
                                color: Theme.of(context).textTheme.bodySmall?.color),
                            Expanded(
                              child: Slider(
                                value: _volume,
                                onChanged: (v) {
                                  setState(() => _volume = v);
                                  audioHandler.setVolume(v);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _artPlaceholder(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.music_note_rounded, size: 48, color: cs.outline),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final queue = audioHandler.queue_;
        final idx = audioHandler.currentIndex;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('Cola de reproduccion (${queue.length})',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: queue.length,
                    itemBuilder: (_, i) {
                      final t = queue[i];
                      final isCurrent = i == idx;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40, height: 40,
                            child: t.thumbnailUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: t.thumbnailUrl, fit: BoxFit.cover)
                                : Container(color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                        title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                color: isCurrent ? Theme.of(context).colorScheme.primary : null)),
                        subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                        onTap: () {
                          audioHandler.currentIndex = i;
                          audioHandler.playQueue(queue, i);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
