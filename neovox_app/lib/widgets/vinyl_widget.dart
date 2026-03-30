import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/cyber_theme.dart';

class TurntableWidget extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;
  final double progress;
  final ValueChanged<double>? onSeek;

  const TurntableWidget({
    super.key,
    this.imageUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.onSeek,
  });

  @override
  State<TurntableWidget> createState() => _TurntableWidgetState();
}

class _TurntableWidgetState extends State<TurntableWidget>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _armController;

  // Ángulos del brazo (en grados, rotación desde el pivote)
  // Positivo = horario = brazo va a la derecha (fuera del disco)
  // Negativo = antihorario = brazo va a la izquierda (sobre el disco)
  //
  // Reposo: brazo fuera del disco, retirado a la derecha
  static const double _restAngle = 28.0;
  // Inicio del disco (borde exterior, 0% de la canción)
  static const double _discStartAngle = -8.0;
  // Final del disco (cerca de la etiqueta, 100% de la canción)
  static const double _discEndAngle = -28.0;

  bool _onDisc = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _armController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Rebuild en cada frame de la animación del brazo
    _armController.addListener(() => setState(() {}));

    if (widget.isPlaying) {
      _spinController.repeat();
      _armController.value = 1.0;
      _onDisc = true;
    }
  }

  @override
  void didUpdateWidget(TurntableWidget old) {
    super.didUpdateWidget(old);

    // Vinilo gira/para
    if (widget.isPlaying && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isPlaying && _spinController.isAnimating) {
      _spinController.stop();
    }

    // Brazo: detectar transición play/stop
    final shouldBeOnDisc = widget.isPlaying || widget.progress > 0;
    if (shouldBeOnDisc && !_onDisc) {
      // Mover brazo al disco
      _onDisc = true;
      _armController.forward();
    } else if (!shouldBeOnDisc && _onDisc) {
      // Retirar brazo del disco al reposo
      _onDisc = false;
      _armController.reverse();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _armController.dispose();
    super.dispose();
  }

  double get _armAngleDeg {
    // armController.value: 0 = reposo, 1 = sobre el disco
    final t = Curves.easeInOutCubic.transform(_armController.value);

    // Posición objetivo sobre el disco según progreso de la canción
    final discAngle = _discStartAngle +
        (_discEndAngle - _discStartAngle) * widget.progress.clamp(0.0, 1.0);

    // Lerp entre reposo y posición en disco
    return _restAngle + (discAngle - _restAngle) * t;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final ttSize = (screenW * 0.72).clamp(220.0, 360.0);
    final vinylSize = ttSize * 0.90;
    final labelSize = vinylSize * 0.33;
    final axleSize = vinylSize * 0.04;

    return SizedBox(
      width: ttSize,
      height: ttSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Platter (fondo circular) ──
          Center(
            child: Container(
              width: ttSize,
              height: ttSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF0a1020), Color(0xFF080e1c), Color(0xFF060a14)],
                ),
                border: Border.all(color: CyberTheme.borderPanel),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0050C8).withValues(alpha: 0.12),
                    blurRadius: 30,
                  ),
                  const BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 20,
                    spreadRadius: -8,
                  ),
                ],
              ),
            ),
          ),

          // ── Vinilo (gira) ──
          Center(
            child: RotationTransition(
              turns: _spinController,
              child: SizedBox(
                width: vinylSize,
                height: vinylSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Disco base con SweepGradient
                    Container(
                      width: vinylSize,
                      height: vinylSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18), Color(0xFF131322),
                            Color(0xFF0c0c18),
                          ],
                        ),
                      ),
                    ),

                    // Surcos del vinilo
                    CustomPaint(
                      size: Size(vinylSize, vinylSize),
                      painter: _GroovePainter(),
                    ),

                    // Etiqueta central con caratula
                    Container(
                      width: labelSize,
                      height: labelSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.2, -0.3),
                          colors: [Color(0xFF1a3a8f), Color(0xFF0d1f5c), Color(0xFF071540)],
                        ),
                        border: Border.all(color: CyberTheme.labelBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3264FF).withValues(alpha: 0.2),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Caratula
                            if (widget.imageUrl != null)
                              CachedNetworkImage(
                                imageUrl: widget.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const SizedBox.shrink(),
                                errorWidget: (_, _, _) => const SizedBox.shrink(),
                              ),
                            if (widget.imageUrl != null)
                              Container(color: Colors.black.withValues(alpha: 0.35)),
                            // Texto
                            if (widget.imageUrl == null)
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('CYBER',
                                        style: CyberTheme.orbitron.copyWith(
                                            fontSize: 8, fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5, color: CyberTheme.textLabel)),
                                    const SizedBox(height: 2),
                                    Text('33\u2153',
                                        style: CyberTheme.mono.copyWith(
                                            fontSize: 7, color: CyberTheme.textLabelSub)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Eje central
                    Container(
                      width: axleSize,
                      height: axleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.3, -0.3),
                          colors: [Color(0xFF8ab0ff), Color(0xFF2a4aaf), Color(0xFF0a1a50)],
                        ),
                        border: Border.all(color: CyberTheme.axleBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5082FF).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Brazo (tonearm) — draggable para seek ──
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onPanUpdate: widget.onSeek == null
                  ? null
                  : (details) {
                      // Convertir movimiento horizontal en progreso:
                      // Arrastrar a la derecha = avanzar, izquierda = retroceder
                      final delta = details.delta.dx / (ttSize * 0.45);
                      final newProgress =
                          (widget.progress + delta).clamp(0.0, 1.0);
                      widget.onSeek!(newProgress);
                    },
              onPanEnd: widget.onSeek == null
                  ? null
                  : (_) {
                      // El seek ya se fue haciendo en cada update
                    },
              child: SizedBox(
                width: ttSize * 0.45,
                height: ttSize * 0.50,
                child: _Tonearm(angleDeg: _armAngleDeg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Surcos del vinilo ──
class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = const Color(0x10649BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final pct in [0.95, 0.86, 0.77, 0.68, 0.59, 0.50]) {
      canvas.drawCircle(center, radius * pct, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Brazo del tocadiscos ──
class _Tonearm extends StatelessWidget {
  final double angleDeg;
  const _Tonearm({required this.angleDeg});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      // El pivote esta arriba a la derecha
      final pivotX = w * 0.78;
      final pivotY = h * 0.12;

      return Stack(
        children: [
          // Todo el brazo rota desde el pivote
          Positioned.fill(
            child: Transform.rotate(
              angle: angleDeg * pi / 180,
              origin: Offset(pivotX - w / 2, pivotY - h / 2),
              child: CustomPaint(
                painter: _TonearmPainter(
                  pivotX: pivotX,
                  pivotY: pivotY,
                ),
              ),
            ),
          ),
          // Pivote (no rota, siempre visible)
          Positioned(
            right: w * 0.13,
            top: h * 0.06,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  colors: [Color(0xFF60a0ff), Color(0xFF1a3a8f), Color(0xFF0a1a40)],
                ),
                border: Border.all(color: CyberTheme.pivotBorder),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3C78FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _TonearmPainter extends CustomPainter {
  final double pivotX;
  final double pivotY;

  _TonearmPainter({required this.pivotX, required this.pivotY});

  @override
  void paint(Canvas canvas, Size size) {
    // Brazo: linea desde el pivote hacia abajo-izquierda
    final armLength = size.height * 0.72;
    final armAngle = -15 * pi / 180; // ligera inclinacion

    final startX = pivotX;
    final startY = pivotY;
    final endX = startX + sin(armAngle) * armLength;
    final endY = startY + cos(armAngle) * armLength;

    // Barra del brazo
    final armPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3060af), Color(0xFF1a3060), Color(0xFF3060af)],
      ).createShader(Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), armPaint);

    // Cabezal
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4080ff), Color(0xFF1a4aaf)],
      ).createShader(Rect.fromCenter(center: Offset(endX, endY), width: 16, height: 10));

    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(endX - 2, endY + 2), width: 14, height: 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(headRect, headPaint);

    // Sombra del cabezal
    final glowPaint = Paint()
      ..color = const Color(0xFF3C82FF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(headRect, glowPaint);

    // Aguja
    final needleStart = Offset(endX - 2, endY + 6);
    final needleEnd = Offset(endX - 2, endY + 16);
    final needlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF88aaff), Color(0xFFcc44ff)],
      ).createShader(Rect.fromPoints(needleStart, needleEnd))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(needleStart, needleEnd, needlePaint);

    // Glow de la aguja
    final needleGlow = Paint()
      ..color = const Color(0xFFC864FF).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(needleStart, needleEnd, needleGlow);
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter oldDelegate) {
    return oldDelegate.pivotX != pivotX || oldDelegate.pivotY != pivotY;
  }
}
