import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../settings/domain/board_appearance.dart';
import '../../domain/game_rules.dart';
import '../board_view_state.dart';
import 'board_materials.dart';
import 'captured_pieces_strip.dart';
import 'chess_mesh.dart';
import 'chess_board.dart' show squareLabel;

/// Perspective projection shared by paint, touch and accessibility positions.
class BoardProjection {
  BoardProjection(
    this.size,
    this.camera, {
    this.zoom = 1.0,
    this.yaw = 0.0,
    this.pitchOffset = 0.0,
  }) {
    final baseDeg = switch (camera) {
      BoardCamera.low => 38.0,
      BoardCamera.balanced => 52.0,
      BoardCamera.high => 68.0,
    };
    angle = (baseDeg + pitchOffset).clamp(24.0, 82.0) * math.pi / 180;
    final bounds = <Offset>[];
    for (final x in [-4.4, 4.4]) {
      for (final z in [-4.4, 4.4]) {
        bounds.add(_raw(Vec3(x, -.35, z)));
        bounds.add(_raw(Vec3(x, 1.3, z)));
      }
    }
    final minX = bounds.map((p) => p.dx).reduce(math.min),
        maxX = bounds.map((p) => p.dx).reduce(math.max);
    final minY = bounds.map((p) => p.dy).reduce(math.min),
        maxY = bounds.map((p) => p.dy).reduce(math.max);
    scale =
        math.min(
          size.width * .96 / (maxX - minX),
          size.height * .96 / (maxY - minY),
        ) *
        zoom;
    origin = Offset(
      size.width / 2 - (minX + maxX) * scale / 2,
      size.height / 2 - (minY + maxY) * scale / 2,
    );
  }
  final Size size;
  final BoardCamera camera;
  final double zoom;
  final double yaw;
  final double pitchOffset;
  late final double angle, scale;
  late final Offset origin;

  Vec3 get eye {
    final dist = 26.0 / zoom.clamp(0.5, 2.5);
    final elevated = Vec3(0, dist * math.sin(angle), dist * math.cos(angle));
    if (yaw == 0) return elevated;
    final cosY = math.cos(yaw), sinY = math.sin(yaw);
    return Vec3(
      elevated.x * cosY + elevated.z * sinY,
      elevated.y,
      -elevated.x * sinY + elevated.z * cosY,
    );
  }

  double depth(Vec3 p) {
    var pt = p;
    if (yaw != 0) {
      final cosY = math.cos(-yaw), sinY = math.sin(-yaw);
      pt = Vec3(pt.x * cosY + pt.z * sinY, pt.y, -pt.x * sinY + pt.z * cosY);
    }
    return 26 - pt.y * math.sin(angle) - pt.z * math.cos(angle);
  }

  Offset _raw(Vec3 p) {
    var pt = p;
    if (yaw != 0) {
      final cosY = math.cos(-yaw), sinY = math.sin(-yaw);
      pt = Vec3(pt.x * cosY + pt.z * sinY, pt.y, -pt.x * sinY + pt.z * cosY);
    }
    final d = 26 - pt.y * math.sin(angle) - pt.z * math.cos(angle);
    return Offset(
      pt.x / d,
      (pt.z * math.sin(angle) - pt.y * math.cos(angle)) / d,
    );
  }

  Offset project(Vec3 p) => origin + _raw(p) * scale;

  Vec3 center(String square, {bool flipped = false, double height = .03}) {
    var x = square.codeUnitAt(0) - 97 - 3.5, z = 8 - int.parse(square[1]) - 3.5;
    if (flipped) {
      x = -x;
      z = -z;
    }
    return Vec3(x, height, z);
  }

  List<Offset> cell(String square, bool flipped) {
    final p = center(square, flipped: flipped);
    return [
      project(p + const Vec3(-.5, 0, -.5)),
      project(p + const Vec3(.5, 0, -.5)),
      project(p + const Vec3(.5, 0, .5)),
      project(p + const Vec3(-.5, 0, .5)),
    ];
  }

  static Path polygon(List<Offset> points) => Path()..addPolygon(points, true);

  String? squareAt(Offset point, bool flipped) {
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final square = '${String.fromCharCode(97 + col)}${8 - row}';
        if (polygon(cell(square, flipped)).contains(point)) return square;
      }
    }
    return null;
  }
}

class ChessTable3D extends StatefulWidget {
  const ChessTable3D({
    super.key,
    required this.controller,
    required this.appearance,
    this.texture,
    this.detailedMeshes,
    this.onSquareTap,
  });
  final BoardViewState controller;
  final BoardAppearance appearance;
  final ui.Image? texture;
  final Map<String, List<MeshFace>>? detailedMeshes;
  final ValueChanged<String>? onSquareTap;

  @override
  State<ChessTable3D> createState() => _ChessTable3DState();
}

class _ChessTable3DState extends State<ChessTable3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late String _fen;
  Map<String, BoardPiece> _previous = {};
  String? _movingFrom, _movingTo;

  @override
  void initState() {
    super.initState();
    _fen = widget.controller.rules.fen;
    _previous = _pieces();
    _motion.value = 1;
  }

  Map<String, BoardPiece> _pieces() => {
    for (var r = 0; r < 8; r++)
      for (var c = 0; c < 8; c++)
        if (widget.controller.rules.pieceAt(
              '${String.fromCharCode(97 + c)}${8 - r}',
            )
            case final BoardPiece p)
          '${String.fromCharCode(97 + c)}${8 - r}': p,
  };

  @override
  void didUpdateWidget(ChessTable3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextFen = widget.controller.rules.fen;
    if (nextFen != _fen) {
      final from = widget.controller.lastFrom, to = widget.controller.lastTo;
      final before = _previous[from];
      final after = to == null ? null : widget.controller.rules.pieceAt(to);
      _movingFrom = null;
      _movingTo = null;

      if (before != null &&
          after != null &&
          before.type == after.type &&
          before.isWhite == after.isWhite &&
          widget.controller.rules.pieceAt(from!) == null) {
        _movingFrom = from;
        _movingTo = to;
        if (!MediaQuery.disableAnimationsOf(context)) _motion.forward(from: 0);
      }
      _fen = nextFen;
      _previous = _pieces();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final projection = BoardProjection(
              Size(constraints.maxWidth, constraints.maxHeight),
              widget.appearance.camera,
            );

            final painter = _TablePainter(
              widget.controller,
              widget.appearance,
              projection,
              widget.texture,
              detailedMeshes: widget.detailedMeshes,
              dark: Theme.of(context).brightness == Brightness.dark,
              progress: Curves.easeInOutCubic.transform(_motion.value),
              from: _movingFrom,
              to: _movingTo,
            );

            return Stack(
              children: [
                GestureDetector(
                  key: const ValueKey('board-3d'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: widget.onSquareTap == null
                      ? null
                      : (event) {
                          final square = painter.hitTestSquare(event.localPosition);
                          if (square != null) widget.onSquareTap!(square);
                        },
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: painter)),
                      for (var row = 0; row < 8; row++)
                        for (var col = 0; col < 8; col++)
                          _semanticCell(
                            projection,
                            '${String.fromCharCode(97 + col)}${8 - row}',
                          ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _semanticCell(BoardProjection projection, String square) {
    final center = projection.project(
      projection.center(square, flipped: widget.controller.flipped),
    );
    final bounds = Rect.fromPoints(
      projection.cell(square, widget.controller.flipped)[0],
      projection.cell(square, widget.controller.flipped)[2],
    );
    return Positioned(
      left: center.dx - bounds.width * .4,
      top: center.dy - bounds.height * .4,
      width: bounds.width * .8,
      height: bounds.height * .8,
      child: IgnorePointer(
        child: Semantics(
          key: ValueKey('square-$square'),
          label: squareLabel(
            widget.controller,
            square,
            showLegalMoves: widget.appearance.showLegalMoves,
          ),
          selected: widget.controller.selected == square,
          button: widget.onSquareTap != null,
          onTap: widget.onSquareTap == null
              ? null
              : () => widget.onSquareTap!(square),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ProjectedFace {
  _ProjectedFace(this.points, this.colors, this.depth, this.square);
  late final Path path = BoardProjection.polygon(points);
  final List<Offset> points;
  final List<Color> colors;
  final double depth;
  final String square;
}

class _TablePainter extends CustomPainter {
  _TablePainter(
    BoardViewState state,
    this.appearance,
    this.projection,
    this.texture, {
    this.detailedMeshes,
    required this.dark,
    required this.progress,
    this.from,
    this.to,
  }) : fen = state.rules.fen,
       flipped = state.flipped,
       selected = state.selected,
       checkedKing = checkedKingSquare(state.rules),
       lastFrom = state.lastFrom,
       lastTo = state.lastTo,
       targets = List.of(state.targets),
       pieces = {
         for (var r = 0; r < 8; r++)
           for (var c = 0; c < 8; c++)
             if (state.rules.pieceAt('${String.fromCharCode(97 + c)}${8 - r}')
                 case final BoardPiece p)
               '${String.fromCharCode(97 + c)}${8 - r}': p,
       };
  final BoardAppearance appearance;
  final bool dark;
  final BoardProjection projection;
  final ui.Image? texture;
  final Map<String, List<MeshFace>>? detailedMeshes;
  final String fen;
  final bool flipped;
  final String? selected, checkedKing, lastFrom, lastTo, from, to;
  final List<String> targets;
  final Map<String, BoardPiece> pieces;
  final double progress;
  List<_ProjectedFace>? _faces;

  Vec3 _origin(String square) {
    final end = projection.center(square, flipped: flipped, height: .045);
    if (square != to || from == null || progress >= 1) return end;
    final start = projection.center(from!, flipped: flipped, height: .045);
    return start * (1 - progress) + end * progress;
  }

  static final _light = const Vec3(-.6, 1, .4).unit;

  Color _lit(Color color, Vec3 normal, Vec3 point, bool metal) {
    final n = normal.unit;
    final diffuse = math.max(0.0, n.dot(_light));
    final half = (_light + (projection.eye - point).unit).unit;
    final spec =
        math.pow(math.max(0.0, n.dot(half)), metal ? 24.0 : 38.0) *
        (metal ? .33 : .16);
    final shade = .45 + .54 * diffuse;
    final r = ((color.r * shade + spec) * 255).round().clamp(0, 255);
    final g = ((color.g * shade + spec) * 255).round().clamp(0, 255);
    final b = ((color.b * shade + spec) * 255).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  List<_ProjectedFace> _projectFaces() {
    if (_faces != null) return _faces!;
    final result = <_ProjectedFace>[];
    final material = PieceMaterial.of(appearance.pieces);

    for (final entry in pieces.entries) {
      final piece = entry.value;
      final origin = _origin(entry.key);
      final reverse = flipped ^ !piece.isWhite;
      Vec3 rotate(Vec3 p) => reverse ? Vec3(-p.x, p.y, -p.z) : p;

      for (final face in detailedMeshes?[piece.type] ?? ChessMeshes.of(piece.type)) {
        final world = face.points.map((p) => rotate(p) + origin).toList();
        final center = world.reduce((a, b) => a + b) * (1 / world.length);
        final normal = rotate(face.surfaceNormal);
        if (normal.dot(projection.eye - center) <= 0) continue;
        final points = world.map(projection.project).toList();

        result.add(
          _ProjectedFace(
            points,
            [
              for (var i = 0; i < world.length; i++)
                _lit(
                  material.team(piece.isWhite),
                  rotate(face.normals[i]),
                  world[i],
                  material.metallic,
                ),
            ],
            projection.depth(center),
            entry.key,
          ),
        );
      }
    }

    result.sort((a, b) => b.depth.compareTo(a.depth));
    return _faces = result;
  }

  String? _visiblePieceAt(Offset position) {
    for (final face in _projectFaces().reversed) {
      if (face.path.contains(position)) return face.square;
    }
    return null;
  }

  String? hitTestSquare(Offset position) {
    final piece = _visiblePieceAt(position),
        plane = projection.squareAt(position, flipped);
    if (piece != null && targets.contains(piece)) return piece;
    if (plane != null && targets.contains(plane)) return plane;
    return piece ?? plane;
  }

  void _polygon(Canvas canvas, List<Vec3> world, Color color) =>
      canvas.drawPath(
        BoardProjection.polygon(world.map(projection.project).toList()),
        Paint()..color = color,
      );

  void _texture(Canvas canvas, List<Offset> points, int row, int col) {
    if (texture == null) return;
    final t = texture!,
        step = t.width / 4,
        x = col % 4 * step,
        y = row % 4 * step;
    final vertices = ui.Vertices(
      ui.VertexMode.triangleFan,
      points,
      textureCoordinates: [
        Offset(x, y),
        Offset(x + step, y),
        Offset(x + step, y + step),
        Offset(x, y + step),
      ],
      colors: List.filled(4, Colors.white.withValues(alpha: .20)),
    );
    canvas.drawVertices(
      vertices,
      BlendMode.modulate,
      Paint()
        ..shader = ImageShader(
          t,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        )
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final board = BoardMaterial.of(appearance.board);
    final matRect = Rect.fromLTWH(
      0,
      size.height * .06,
      size.width,
      size.height * .9,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(matRect, const Radius.circular(24)),
      Paint()
        ..shader = RadialGradient(
          colors: dark
              ? [
                  Color.lerp(board.frame, Colors.black, .68)!,
                  Color.lerp(board.frame, Colors.black, .84)!,
                ]
              : [
                  Color.lerp(board.frame, Colors.white, .87)!,
                  Color.lerp(board.frame, Colors.white, .93)!,
                ],
        ).createShader(matRect),
    );

    final shadow = BoardProjection.polygon([
      for (final p in const [
        Vec3(-4.4, -.5, -4.4),
        Vec3(4.4, -.5, -4.4),
        Vec3(4.4, -.5, 4.4),
        Vec3(-4.4, -.5, 4.4),
      ])
        projection.project(p),
    ]);
    canvas.drawPath(
      shadow.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: .24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    for (final face in ChessMeshes.box(
      const Vec3(0, -.16, 0),
      const Vec3(4.3, .19, 4.3),
    )) {
      final center =
          face.points.reduce((a, b) => a + b) * (1 / face.points.length);
      if (face.normals.first.dot(projection.eye - center) > 0) {
        _polygon(
          canvas,
          face.points,
          _lit(board.frame, face.normals.first, center, false),
        );
      }
    }

    // Kareler ve Zemin
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final square = '${String.fromCharCode(97 + col)}${8 - row}';
        final points = projection.cell(square, flipped);
        final path = BoardProjection.polygon(points);
        final color = (row + col).isEven ? board.light : board.dark;
        canvas.drawPath(path, Paint()..color = color);
        _texture(canvas, points, row, col);

        if (square == checkedKing) {
          canvas.drawPath(
            path,
            Paint()..color = const Color(0xFFE53E3E).withValues(alpha: .65),
          );
        } else if (square == selected || square == lastFrom || square == lastTo) {
          canvas.drawPath(
            path,
            Paint()
              ..color =
                  (square == selected
                          ? const Color(0xFF82AC69)
                          : const Color(0xFFDBBF6D))
                      .withValues(alpha: square == selected ? .65 : .35),
          );
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withValues(alpha: .045)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .5,
        );

        if (appearance.showLegalMoves && targets.contains(square)) {
          final capture = pieces.containsKey(square);
          final radius = capture ? .43 : .14;
          final center = projection.center(
            square,
            flipped: flipped,
            height: .04,
          );
          final ring = [
            for (var i = 0; i < 32; i++)
              projection.project(
                center +
                    Vec3(
                      radius * math.cos(i * math.pi / 16),
                      0,
                      radius * math.sin(i * math.pi / 16),
                    ),
              ),
          ];
          canvas.drawPath(
            BoardProjection.polygon(ring),
            Paint()
              ..color = capture ? const Color(0xFFB3261E) : const Color(0xFF5A7B4C)
              ..style = capture ? PaintingStyle.stroke : PaintingStyle.fill
              ..strokeWidth = 2.5,
          );
        }
      }
    }

    // Taş gölgeleri
    for (final entry in pieces.entries) {
      final origin = _origin(entry.key);
      final center = Vec3(origin.x, .04, origin.z);
      final points = [
        for (var i = 0; i < 32; i++)
          projection.project(
            center +
                Vec3(
                  .36 * math.cos(i * math.pi / 16) + .05,
                  0,
                  .30 * math.sin(i * math.pi / 16) + .04,
                ),
          ),
      ];
      canvas.drawPath(
        BoardProjection.polygon(points),
        Paint()
          ..color = Colors.black.withValues(alpha: .23)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }

    // 3B Taşların tek seferde çizimi
    final positions = <Offset>[], colors = <Color>[];
    for (final face in _projectFaces()) {
      for (var i = 1; i < face.points.length - 1; i++) {
        for (final index in [0, i, i + 1]) {
          positions.add(face.points[index]);
          colors.add(face.colors[index]);
        }
      }
    }
    if (positions.isNotEmpty) {
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
      );
      canvas.drawVertices(vertices, BlendMode.dst, Paint());
      vertices.dispose();
    }

    // Kare koordinat etiketleri
    final labelColor = board.frame.computeLuminance() > .45
        ? const Color(0xFF394D49)
        : const Color(0xFFF4E4C7);
    for (var i = 0; i < 8; i++) {
      final file = flipped ? 7 - i : i, rank = flipped ? i + 1 : 8 - i;
      _text(
        canvas,
        String.fromCharCode(97 + file),
        projection.project(Vec3(i - 3.5, .045, 4.15)),
        labelColor,
      );
      _text(
        canvas,
        '$rank',
        projection.project(Vec3(-4.15, .045, i - 3.5)),
        labelColor,
      );
    }
  }

  void _text(Canvas canvas, String text, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(_TablePainter old) =>
      old.fen != fen ||
      old.dark != dark ||
      old.flipped != flipped ||
      old.selected != selected ||
      old.checkedKing != checkedKing ||
      old.lastFrom != lastFrom ||
      old.lastTo != lastTo ||
      old.appearance != appearance ||
      old.texture != texture ||
      old.detailedMeshes != detailedMeshes ||
      old.progress != progress ||
      old.projection.size != projection.size ||
      old.projection.camera != projection.camera ||
      old.targets.join() != targets.join();
}
