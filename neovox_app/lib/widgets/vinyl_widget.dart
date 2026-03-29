import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/cyber_theme.dart';

class VinylWidget extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;

  const VinylWidget({super.key, this.imageUrl, this.isPlaying = false});

  @override
  State<VinylWidget> createState() => _VinylWidgetState();
}

class _VinylWidgetState extends State<VinylWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(VinylWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: RotationTransition(
        turns: _controller,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFF0a0a12),
                Color(0xFF151520),
                Color(0xFF0a0a12),
                Color(0xFF1a1a28),
                Color(0xFF0a0a12),
              ],
            ),
            border: Border.all(color: CyberTheme.inputBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: CyberTheme.accent.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CyberTheme.bgCard,
                border: Border.all(color: CyberTheme.inputBorder),
              ),
              child: ClipOval(
                child: widget.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(
                          Icons.music_note,
                          color: CyberTheme.textSecondary,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.music_note,
                          color: CyberTheme.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: CyberTheme.textSecondary,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
