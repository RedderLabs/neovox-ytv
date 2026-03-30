import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/audio_service.dart';
import '../models/playlist.dart';

class MiniPlayerWidget extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayerWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            StreamBuilder<Duration>(
              stream: audioHandler.positionStream,
              builder: (_, posSnap) {
                return StreamBuilder<Duration?>(
                  stream: audioHandler.durationStream,
                  builder: (_, durSnap) {
                    final pos = posSnap.data?.inMilliseconds.toDouble() ?? 0;
                    final dur = durSnap.data?.inMilliseconds.toDouble() ?? 1;
                    final pct = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
                    return LinearProgressIndicator(
                      value: pct,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      color: cs.primary,
                    );
                  },
                );
              },
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: StreamBuilder<Track?>(
                stream: audioHandler.trackStream,
                builder: (_, snap) {
                  final track = snap.data ?? audioHandler.currentTrack;
                  return Row(
                    children: [
                      // Thumb
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44, height: 44,
                          child: track != null && track.thumbnailUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: track.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: cs.surface),
                                  errorWidget: (_, __, ___) => Container(color: cs.surface),
                                )
                              : Container(color: cs.surface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track?.title ?? 'Sin reproduccion',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              track?.artist ?? '--',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      StreamBuilder<bool>(
                        stream: audioHandler.playingStream,
                        builder: (_, snap) {
                          final playing = snap.data ?? false;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                iconSize: 24,
                                onPressed: audioHandler.skipToPrevious,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: IconButton(
                                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  iconSize: 20,
                                  color: Colors.white,
                                  onPressed: playing ? audioHandler.pause : audioHandler.play,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                iconSize: 24,
                                onPressed: audioHandler.skipToNext,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
