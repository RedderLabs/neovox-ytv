import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist.dart';
import '../theme/cyber_theme.dart';

class TracklistWidget extends StatelessWidget {
  final List<Track> tracks;
  final int currentIndex;
  final ValueChanged<int> onTrackTap;

  const TracklistWidget({
    super.key,
    required this.tracks,
    required this.currentIndex,
    required this.onTrackTap,
  });

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                  'TRACKLIST',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: CyberTheme.textSecondary,
                  ),
                ),
                Text(
                  '${tracks.length} TRACKS',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: CyberTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tracks.length,
                itemBuilder: (ctx, i) {
                  final track = tracks[i];
                  final isActive = i == currentIndex;
                  return Material(
                    color: isActive
                        ? CyberTheme.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () => onTrackTap(i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive
                                ? CyberTheme.accent.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isActive
                                      ? CyberTheme.dotOn
                                      : CyberTheme.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: CachedNetworkImage(
                                imageUrl: track.thumbnailUrl,
                                width: 36,
                                height: 27,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 36,
                                  height: 27,
                                  color: CyberTheme.inputBg,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 36,
                                  height: 27,
                                  color: CyberTheme.inputBg,
                                  child: const Icon(Icons.music_note, size: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                track.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                  color: isActive
                                      ? CyberTheme.accent
                                      : CyberTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(track.duration),
                              style: const TextStyle(
                                fontSize: 10,
                                color: CyberTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
