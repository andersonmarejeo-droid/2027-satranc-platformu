import 'package:flutter/material.dart';

import '../../domain/game_rules.dart';
import '../../../settings/domain/board_appearance.dart';
import 'board_materials.dart';

class ChessPieceView extends StatelessWidget {
  const ChessPieceView({
    super.key,
    required this.piece,
    this.style = PieceStyle.classic,
    this.flat = false,
  });
  final BoardPiece piece;
  final PieceStyle style;
  final bool flat;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PiecePainter(piece, style, flat));
}

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.piece, this.material, this.flat);
  final BoardPiece piece;
  final PieceStyle material;
  final bool flat;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final white = piece.isWhite;
    final baseColor = PieceMaterial.of(material).team(white);
    final colors = material == PieceStyle.classic
        ? white
              ? [
                  const Color(0xFFBAA78A),
                  const Color(0xFFFFF6DA),
                  const Color(0xFFE5D4B2),
                  const Color(0xFF8D785A),
                ]
              : [
                  const Color(0xFF151A17),
                  const Color(0xFF647168),
                  const Color(0xFF354139),
                  const Color(0xFF111812),
                ]
        : [
            Color.lerp(baseColor, Colors.black, .3)!,
            Color.lerp(baseColor, Colors.white, .4)!,
            baseColor,
            Color.lerp(baseColor, Colors.black, .45)!,
          ];
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        stops: const [0, .3, .58, 1],
      ).createShader(const Rect.fromLTWH(15, 0, 70, 100));
    if (flat) {
      bodyPaint.shader = null;
      bodyPaint.color = baseColor;
    }
    final edge = Paint()
      ..color =
          (baseColor.computeLuminance() > .45
                  ? (material == PieceStyle.blackWhite
                        ? const Color(0xFF67717D)
                        : const Color(0xFF69553D))
                  : Colors.white)
              .withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = flat ? 2.2 : 1.2;
    void draw(Path p) {
      canvas.drawPath(p, bodyPaint);
      canvas.drawPath(p, edge);
    }

    void ellipse(Rect r) {
      final p = Path()..addOval(r);
      draw(p);
    }

    void band(double y, double w) {
      draw(
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(50 - w / 2, y, w, 7),
            const Radius.circular(3.5),
          ),
        ),
      );
    }

    if (!flat) {
      canvas.drawOval(
        const Rect.fromLTWH(15, 84, 76, 11),
        Paint()
          ..color = Colors.black.withValues(alpha: .23)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    final base = Path()
      ..moveTo(20, 85)
      ..quadraticBezierTo(20, 78, 29, 76)
      ..lineTo(71, 76)
      ..quadraticBezierTo(80, 78, 80, 85)
      ..lineTo(82, 90)
      ..quadraticBezierTo(50, 98, 18, 90)
      ..close();
    draw(base);
    switch (piece.type) {
      case 'p':
        draw(
          Path()
            ..moveTo(32, 76)
            ..quadraticBezierTo(42, 57, 41, 46)
            ..lineTo(59, 46)
            ..quadraticBezierTo(58, 57, 68, 76)
            ..close(),
        );
        band(46, 31);
        ellipse(const Rect.fromLTWH(34, 20, 32, 31));
        break;
      case 'r':
        draw(
          Path()
            ..moveTo(30, 77)
            ..lineTo(35, 39)
            ..lineTo(29, 35)
            ..lineTo(29, 18)
            ..lineTo(40, 18)
            ..lineTo(40, 26)
            ..lineTo(46, 26)
            ..lineTo(46, 18)
            ..lineTo(55, 18)
            ..lineTo(55, 26)
            ..lineTo(61, 26)
            ..lineTo(61, 18)
            ..lineTo(72, 18)
            ..lineTo(72, 35)
            ..lineTo(65, 39)
            ..lineTo(70, 77)
            ..close(),
        );
        band(37, 39);
        band(69, 44);
        break;
      case 'n':
        draw(
          Path()
            ..moveTo(29, 77)
            ..quadraticBezierTo(37, 59, 40, 49)
            ..lineTo(24, 53)
            ..lineTo(18, 46)
            ..lineTo(34, 29)
            ..lineTo(38, 13)
            ..lineTo(49, 21)
            ..quadraticBezierTo(73, 26, 72, 57)
            ..lineTo(70, 76)
            ..close(),
        );
        canvas.drawCircle(
          const Offset(39, 34),
          2.4,
          Paint()
            ..color = white ? const Color(0xFF6A553E) : const Color(0xFFABB7A9),
        );
        canvas.drawPath(
          Path()
            ..moveTo(54, 28)
            ..quadraticBezierTo(64, 48, 57, 67),
          Paint()
            ..color = colors[0]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        band(72, 48);
        break;
      case 'b':
        draw(
          Path()
            ..moveTo(29, 77)
            ..quadraticBezierTo(43, 58, 41, 48)
            ..lineTo(59, 48)
            ..quadraticBezierTo(57, 58, 71, 77)
            ..close(),
        );
        draw(
          Path()
            ..moveTo(50, 14)
            ..cubicTo(31, 28, 26, 39, 42, 46)
            ..quadraticBezierTo(50, 49, 59, 46)
            ..cubicTo(74, 39, 68, 28, 50, 14)
            ..close(),
        );
        canvas.drawLine(
          const Offset(53, 22),
          const Offset(43, 37),
          Paint()
            ..color = colors[0]
            ..strokeWidth = 3,
        );
        ellipse(const Rect.fromLTWH(46, 9, 8, 8));
        band(47, 34);
        band(70, 43);
        break;
      case 'q':
        draw(
          Path()
            ..moveTo(29, 77)
            ..quadraticBezierTo(42, 61, 39, 45)
            ..lineTo(29, 23)
            ..lineTo(40, 30)
            ..lineTo(44, 15)
            ..lineTo(50, 27)
            ..lineTo(57, 15)
            ..lineTo(61, 30)
            ..lineTo(72, 23)
            ..lineTo(61, 45)
            ..quadraticBezierTo(58, 60, 71, 77)
            ..close(),
        );
        for (final point in const [
          Offset(29, 22),
          Offset(44, 14),
          Offset(57, 14),
          Offset(72, 22),
        ]) {
          ellipse(Rect.fromCircle(center: point, radius: 3.8));
        }
        band(43, 39);
        band(69, 45);
        break;
      default:
        draw(
          Path()
            ..moveTo(29, 77)
            ..quadraticBezierTo(43, 57, 39, 45)
            ..lineTo(32, 29)
            ..quadraticBezierTo(50, 22, 68, 29)
            ..lineTo(60, 45)
            ..quadraticBezierTo(57, 57, 71, 77)
            ..close(),
        );
        draw(
          Path()
            ..moveTo(46, 27)
            ..lineTo(46, 17)
            ..lineTo(38, 17)
            ..lineTo(38, 10)
            ..lineTo(46, 10)
            ..lineTo(46, 3)
            ..lineTo(54, 3)
            ..lineTo(54, 10)
            ..lineTo(62, 10)
            ..lineTo(62, 17)
            ..lineTo(54, 17)
            ..lineTo(54, 27)
            ..close(),
        );
        band(43, 37);
        band(69, 44);
    }
    band(79, 58);
    if (!flat) {
      canvas.drawArc(
        const Rect.fromLTWH(22, 83, 56, 8),
        .1,
        2.9,
        false,
        Paint()
          ..color = colors[1].withValues(alpha: .5)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) =>
      oldDelegate.piece.type != piece.type ||
      oldDelegate.piece.isWhite != piece.isWhite ||
      oldDelegate.material != material ||
      oldDelegate.flat != flat;
}
