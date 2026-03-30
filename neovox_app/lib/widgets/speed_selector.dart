import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class SpeedSelector extends StatefulWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const SpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<SpeedSelector> createState() => _SpeedSelectorState();
}

class _SpeedSelectorState extends State<SpeedSelector> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('SPD',
            style: CyberTheme.mono.copyWith(
                fontSize: 10, letterSpacing: 2, color: CT.textVol)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: _speeds.map((s) {
              final active = (s - widget.currentSpeed).abs() < 0.01;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => widget.onSpeedChanged(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? null : CT.inputBg,
                        gradient: active
                            ? const LinearGradient(
                                colors: [Color(0xFF0c1428), Color(0xFF080e1c)])
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: active
                              ? CT.btnActiveBorder
                              : CT.inputBorder,
                        ),
                        boxShadow: active
                            ? [BoxShadow(
                                color: CT.accent.withValues(alpha: 0.15),
                                blurRadius: 8)]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${s}x',
                        style: CyberTheme.mono.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: active
                              ? CT.accentGlow
                              : CT.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
