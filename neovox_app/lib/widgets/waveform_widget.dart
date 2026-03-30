import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class WaveformWidget extends StatefulWidget {
  final bool isPlaying;
  final int barCount;

  const WaveformWidget({
    super.key,
    required this.isPlaying,
    this.barCount = 40,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  late List<double> _heights;
  late List<double> _baseHeights;
  Timer? _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _baseHeights = List.generate(
      widget.barCount,
      (_) => 4 + _random.nextDouble() * 10,
    );
    _heights = List.from(_baseHeights);
    if (widget.isPlaying) _startAnimation();
  }

  @override
  void didUpdateWidget(WaveformWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _startAnimation();
    } else if (!widget.isPlaying && old.isPlaying) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _heights.length; i++) {
          final base = 6 + sin(DateTime.now().millisecondsSinceEpoch / 300 + i * 0.4) * 10 +
              _random.nextDouble() * 8;
          _heights[i] = max(3, min(base, 28));
        }
      });
    });
  }

  void _stopAnimation() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _heights = List.from(_baseHeights));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: _heights[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: widget.isPlaying
                      ? [CyberTheme.wfActiveBottom, CyberTheme.wfActiveTop]
                      : [CyberTheme.wfGradientBottom, CyberTheme.wfGradientTop],
                ),
                boxShadow: widget.isPlaying
                    ? [BoxShadow(color: CT.accentGlow.withValues(alpha: 0.4), blurRadius: 4)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
