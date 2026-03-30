import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist.dart';
import '../services/audio_service.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final int? index;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.index,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: audioHandler.trackStream,
      builder: (context, snap) {
        final current = audioHandler.currentTrack;
        final isPlaying = current?.videoId == track.videoId;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: isPlaying
                ? BoxDecoration(
                    color: cs.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48, height: 48,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        track.thumbnailUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: cs.surface),
                                errorWidget: (_, __, ___) => Container(
                                  color: cs.surface,
                                  child: Icon(Icons.music_note, size: 20, color: cs.outline),
                                ),
                              )
                            : Container(
                                color: cs.surface,
                                child: Icon(Icons.music_note, size: 20, color: cs.outline),
                              ),
                        if (isPlaying)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: StreamBuilder<bool>(
                                stream: audioHandler.playingStream,
                                builder: (_, snap) {
                                  final playing = snap.data ?? false;
                                  return Icon(
                                    playing ? Icons.equalizer_rounded : Icons.pause_rounded,
                                    color: cs.primary,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPlaying ? cs.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Duration
                if (track.duration.inSeconds > 0)
                  Text(
                    _formatDuration(track.duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
