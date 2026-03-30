import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class ScanlinesOverlay extends StatelessWidget {
  const ScanlinesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _ScanlinesPainter()),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CT.scanlineColor;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CornerAccents extends StatelessWidget {
  const CornerAccents({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
        _corner(top: 12, left: 12, borderTop: true, borderLeft: true),
        _corner(top: 12, right: 12, borderTop: true, borderRight: true),
        _corner(bottom: 12, left: 12, borderBottom: true, borderLeft: true),
        _corner(bottom: 12, right: 12, borderBottom: true, borderRight: true),
        ],
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool borderTop = false,
    bool borderBottom = false,
    bool borderLeft = false,
    bool borderRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: borderTop
                ? const BorderSide(color: CyberTheme.borderCorner, width: 2)
                : BorderSide.none,
            bottom: borderBottom
                ? const BorderSide(color: CyberTheme.borderCorner, width: 2)
                : BorderSide.none,
            left: borderLeft
                ? const BorderSide(color: CyberTheme.borderCorner, width: 2)
                : BorderSide.none,
            right: borderRight
                ? const BorderSide(color: CyberTheme.borderCorner, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
