import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class EqualizerWidget extends StatefulWidget {
  const EqualizerWidget({super.key});

  @override
  State<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends State<EqualizerWidget> {
  final _labels = ['60', '150', '400', '1K', '2.5K', '6K', '12K', '16K'];
  List<double> _values = [0, 0, 0, 0, 0, 0, 0, 0];
  String _activePreset = 'FLAT';

  static const _presets = {
    'FLAT': [0.0, 0, 0, 0, 0, 0, 0, 0],
    'BASS': [10.0, 8, 5, 1, 0, 0, -1, -2],
    'VOCAL': [-2.0, -1, 2, 6, 6, 3, 0, -2],
    'TREBLE': [-3.0, -2, 0, 1, 3, 6, 9, 10],
  };

  void _applyPreset(String name) {
    final vals = _presets[name];
    if (vals == null) return;
    setState(() {
      _values = vals.map((v) => v.toDouble()).toList();
      _activePreset = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CT.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CT.inputBorder),
      ),
      child: Column(
        children: [
          // Header + presets
          Row(
            children: [
              Text('EQUALIZER',
                  style: CyberTheme.mono.copyWith(
                      fontSize: 10, letterSpacing: 2, color: CT.textVol)),
              const Spacer(),
              ..._presets.keys.map((name) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _presetBtn(name),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          // Sliders
          SizedBox(
            height: 65,
            child: Row(
              children: List.generate(8, (i) {
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: CT.accentGlow,
                              inactiveTrackColor: CT.inputBorder,
                              thumbColor: CT.accentGlow,
                              overlayColor: CT.accentGlow.withValues(alpha: 0.1),
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                            ),
                            child: Slider(
                              value: _values[i],
                              min: -12,
                              max: 12,
                              onChanged: (v) => setState(() {
                                _values[i] = v;
                                _activePreset = '';
                              }),
                            ),
                          ),
                        ),
                      ),
                      Text(_labels[i],
                          style: CyberTheme.mono.copyWith(
                              fontSize: 8, color: CT.textSecondary)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetBtn(String name) {
    final active = _activePreset == name;
    return GestureDetector(
      onTap: () => _applyPreset(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: active ? CT.btnActiveBorder : CT.inputBorder,
          ),
          boxShadow: active
              ? [BoxShadow(color: CT.accent.withValues(alpha: 0.15), blurRadius: 6)]
              : null,
        ),
        child: Text(
          name,
          style: CyberTheme.orbitron.copyWith(
            fontSize: 8,
            letterSpacing: 1,
            color: active ? CT.accentGlow : CT.textSecondary,
          ),
        ),
      ),
    );
  }
}
