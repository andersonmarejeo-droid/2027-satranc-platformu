import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_config.dart';
import '../features/game/domain/game_rules.dart';
import '../features/game/presentation/widgets/chess_piece.dart';
import '../features/settings/domain/board_appearance.dart';

class BrandIntroGate extends StatefulWidget {
  const BrandIntroGate({super.key, required this.child});
  final Widget child;
  @override
  State<BrandIntroGate> createState() => _BrandIntroGateState();
}

class _BrandIntroGateState extends State<BrandIntroGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _visible = true, _started = false, _reduceMotion = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
    _fallbackTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _visible) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _motion.duration = const Duration(milliseconds: 650);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _motion.forward();
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        excluding: _visible,
        child: IgnorePointer(ignoring: _visible, child: widget.child),
      ),
      if (_visible)
        Positioned.fill(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Semantics(
              label: '${AppConfig.name}. ZP Games.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (mounted) setState(() => _visible = false);
                },
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) => BrandIntroScene(
                    progress: _motion.value,
                    reduceMotion: _reduceMotion,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// Deterministic positions keep the opening scene stable across frames.
class BrandIntroScene extends StatelessWidget {
  const BrandIntroScene({
    super.key,
    required this.progress,
    this.reduceMotion = false,
  });
  final double progress;
  final bool reduceMotion;
  static const _particles = [
    (.07, .00, 'n', true, 42.0, -.12),
    (.24, .11, 'p', true, 28.0, .12),
    (.76, .02, 'q', true, 46.0, -.10),
    (.91, .16, 'b', false, 36.0, .15),
    (.42, .04, 'r', true, 34.0, .07),
    (.57, .23, 'k', false, 48.0, -.11),
    (.13, .25, 'b', true, 38.0, .13),
    (.83, .30, 'p', true, 30.0, -.08),
    (.33, .33, 'q', false, 42.0, .09),
    (.65, .12, 'n', true, 44.0, -.14),
    (.04, .36, 'r', true, 32.0, .10),
    (.95, .00, 'k', true, 50.0, -.09),
  ];
  @override
  Widget build(BuildContext context) {
    final fade = reduceMotion || progress <= .86
        ? 1.0
        : (1 - (progress - .86) / .14).clamp(0.0, 1.0);
    final publisher = reduceMotion
        ? 1.0
        : ((progress - .18) / .25).clamp(0.0, 1.0);
    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: fade,
        child: DecoratedBox(
          key: const ValueKey('brand-intro'),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF203A2C), Color(0xFF101C15)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (!reduceMotion) ...[
                  for (var i = 0; i < _particles.length; i++)
                    _fallingPiece(_particles[i], constraints.biggest),
                ],
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A4433),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFB3905C)
                                  .withValues(alpha: .45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const ChessPieceView(
                            piece: BoardPiece('n', true),
                            style: PieceStyle.porcelain,
                            flat: false,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          AppConfig.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 31,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.7,
                            color: Color(0xFFF5F0E3),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hamle sırası sende.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB5C5B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.paddingOf(context).bottom + 36,
                  child: Opacity(
                    opacity: publisher,
                    child: const Column(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Divider(
                            color: Color(0xFFB3905C),
                            thickness: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ZP GAMES',
                          key: ValueKey('intro-publisher'),
                          style: TextStyle(
                            color: Color(0xFFC9BA96),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallingPiece(
    (double, double, String, bool, double, double) particle,
    Size size,
  ) {
    final (x, delay, type, white, extent, angle) = particle;
    final phase = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    return Positioned(
      left: x * (size.width - extent),
      top: -extent - 24 + phase * (size.height + extent * 2),
      width: extent,
      height: extent,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: progress < delay ? 0 : (white ? .27 : .35),
          child: Transform.rotate(
            angle: angle * (1 + phase),
            child: ChessPieceView(
              piece: BoardPiece(type, white),
              style: white ? PieceStyle.porcelain : PieceStyle.bronze,
              flat: false,
            ),
          ),
        ),
      ),
    );
  }
}
