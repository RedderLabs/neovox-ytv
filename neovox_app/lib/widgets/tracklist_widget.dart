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
    return Container(
      decoration: BoxDecoration(
        color: CT.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CT.inputBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRACKLIST',
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 2, color: CT.textVol)),
              Text('${tracks.length} TRACKS',
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 1, color: CT.counterColor)),
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
                return GestureDetector(
                  onTap: () => onTrackTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isActive ? CT.plActiveBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? CT.plActiveBorder
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            '${i + 1}'.padLeft(2, '0'),
                            style: CyberTheme.mono.copyWith(
                              fontSize: 10,
                              color: isActive
                                  ? CT.dotOn
                                  : CT.counterColor,
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
                              color: CT.inputBg,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 36,
                              height: 27,
                              color: CT.inputBg,
                              child: Icon(Icons.music_note,
                                  size: 14, color: CT.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            track.title,
                            style: CyberTheme.mono.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: isActive
                                  ? CT.plNameActive
                                  : CT.plName,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(track.duration),
                          style: CyberTheme.mono.copyWith(
                              fontSize: 10, color: CT.counterColor),
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
}
