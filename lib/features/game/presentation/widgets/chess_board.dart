import 'dart:ui' as ui;

import '../../domain/game_rules.dart';
import '../move_presentation.dart';

import 'package:flutter/material.dart';

import '../../../../app/app_services.dart';
import '../../../settings/domain/board_appearance.dart';
import '../board_view_state.dart';
import 'board_materials.dart';
import 'captured_pieces_strip.dart';
import 'chess_piece.dart';
import 'chess_table_3d.dart';
import 'carved_chess_mesh.dart';
import 'chess_mesh.dart';
import 'wizard_chess_3d_view.dart';

const pieceNames = {
  'p': 'piyon',
  'r': 'kale',
  'n': 'at',
  'b': 'fil',
  'q': 'vezir',
  'k': 'şah',
};
String squareLabel(
  BoardViewState state,
  String square, {
  bool showLegalMoves = false,
}) {
  final piece = state.rules.pieceAt(square);
  return '$square ${piece == null ? 'boş' : '${piece.isWhite ? 'Beyaz' : 'Siyah'} ${pieceNames[piece.type]}'}${showLegalMoves && state.targets.contains(square) ? ', yasal hamle' : ''}';
}

class ChessBoard extends StatelessWidget {
  const ChessBoard({
    super.key,
    required this.controller,
    this.onSquareTap,
    this.appearance,
    this.allowMoveHints = true,
  });
  final BoardViewState controller;
  final ValueChanged<String>? onSquareTap;
  final BoardAppearance? appearance;
  final bool allowMoveHints;
  @override
  Widget build(BuildContext context) {
    if (appearance != null) return _board(appearance!);
    final preferences = AppScope.of(context).boardAppearance;
    return ListenableBuilder(
      listenable: Listenable.merge([preferences, AppScope.of(context).comfort]),
      builder: (context, _) => _board(
        AppScope.of(context).comfort?.lightBoard == true
            ? preferences.value.copyWith(view: BoardViewMode.flat)
            : preferences.value,
      ),
    );
  }

  Widget _board(BoardAppearance value) {
    if (!allowMoveHints) value = value.copyWith(showLegalMoves: false);
    final material = BoardMaterial.of(value.board);
    return RepaintBoundary(
      child: FutureBuilder<ui.Image?>(
        initialData: value.view == BoardViewMode.flat
            ? null
            : BoardTextures.cached(material.texture),
        key: ValueKey(
          '${value.view == BoardViewMode.flat ? 'flat' : material.texture}',
        ),
        future: value.view == BoardViewMode.flat || material.texture == null
            ? null
            : BoardTextures.load(material.texture!),
        builder: (context, snapshot) {
          if (value.view == BoardViewMode.wizard3d) {
            return WizardChess3DView(
              controller: controller,
              appearance: value,
              onSquareTap: onSquareTap,
            );
          }
          return value.view == BoardViewMode.table3d
              ? FutureBuilder<Map<String, List<MeshFace>>>(
                  initialData: switch (value.shape) {
                    PieceShape.carved => CarvedChessMeshes.cached,
                    PieceShape.classic => null,
                  },
                  key: ValueKey(value.shape),
                  future: value.shape == PieceShape.carved
                      ? CarvedChessMeshes.load()
                      : null,
                  builder: (context, mesh) => ChessTable3D(
                    controller: controller,
                    appearance: value,
                    texture: snapshot.data,
                    detailedMeshes: mesh.data,
                    onSquareTap: onSquareTap,
                  ),
                )
              : _PlanBoard(
                  controller: controller,
                  appearance: value,
                  texture: snapshot.data,
                  onSquareTap: onSquareTap,
                );
        },
      ),
    );
  }
}

class _PlanBoard extends StatefulWidget {
  const _PlanBoard({
    required this.controller,
    required this.appearance,
    required this.texture,
    this.onSquareTap,
  });
  final BoardViewState controller;
  final BoardAppearance appearance;
  final ui.Image? texture;
  final ValueChanged<String>? onSquareTap;
  @override
  State<_PlanBoard> createState() => _PlanBoardState();
}

class _PlanBoardState extends State<_PlanBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: MovePresentation.slide,
  );
  late String _fen;
  Map<String, BoardPiece> _previous = {};
  late bool _flipped;
  String? _movingFrom, _movingTo;
  BoardPiece? _movingPiece;
  String? _dragFrom;
  BoardPiece? _dragPiece;
  Offset? _dragPosition;

  @override
  void initState() {
    super.initState();
    _fen = widget.controller.rules.fen;
    _flipped = widget.controller.flipped;
    _previous = _pieces();
    _motion.value = 1;
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(_PlanBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = widget.controller;
    if (state.flipped != _flipped) {
      _motion.value = 1;
      _flipped = state.flipped;
    }
    if (state.rules.fen != _fen) {
      final from = state.lastFrom, to = state.lastTo;
      final piece = to == null ? null : state.rules.pieceAt(to);
      final before = _previous[from];
      _movingFrom = from;
      _movingTo = to;
      _movingPiece = before;
      if (before != null &&
          from != null &&
          to != null &&
          piece != null &&
          before.isWhite == piece.isWhite &&
          state.rules.pieceAt(from) == null &&
          !MediaQuery.disableAnimationsOf(context)) {
        _motion.forward(from: 0);
      } else {
        _motion.value = 1;
      }
      _fen = state.rules.fen;
      _previous = _pieces();
    }
  }

  Map<String, BoardPiece> _pieces() => {
    for (var row = 0; row < 8; row++)
      for (var col = 0; col < 8; col++)
        if (widget.controller.rules.pieceAt(
              '${String.fromCharCode(97 + col)}${8 - row}',
            )
            case final BoardPiece piece)
          '${String.fromCharCode(97 + col)}${8 - row}': piece,
  };

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Offset _center(String square, double cell) {
    var column = square.codeUnitAt(0) - 97;
    var row = 8 - int.parse(square[1]);
    if (widget.controller.flipped) {
      column = 7 - column;
      row = 7 - row;
    }
    return Offset((column + .5) * cell, (row + .5) * cell);
  }

  Widget _movingOverlay(double width) {
    final cell = width / 8;
    final position = Offset.lerp(
      _center(_movingFrom!, cell),
      _center(_movingTo!, cell),
      Curves.easeInOutCubic.transform(_motion.value),
    )!;
    return Positioned(
      key: const ValueKey('moving-piece'),
      left: position.dx - cell / 2,
      top: position.dy - cell / 2,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ChessPieceView(
              piece: _movingPiece!,
              style: widget.appearance.pieces,
              flat: widget.appearance.view == BoardViewMode.flat,
            ),
          ),
        ),
      ),
    );
  }

  String? _squareAt(Offset local, double width) {
    if (local.dx < 0 || local.dy < 0 || local.dx >= width || local.dy >= width) {
      return null;
    }
    final cell = width / 8;
    var col = (local.dx ~/ cell).clamp(0, 7);
    var row = (local.dy ~/ cell).clamp(0, 7);
    if (widget.controller.flipped) {
      col = 7 - col;
      row = 7 - row;
    }
    return '${String.fromCharCode(97 + col)}${8 - row}';
  }

  Offset? _dragStartPos;

  Widget _draggingOverlay(double width) {
    final cell = width / 8 * 1.12;
    return Positioned(
      key: const ValueKey('dragging-piece'),
      left: _dragPosition!.dx - cell / 2,
      top: _dragPosition!.dy - cell / 2,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: ChessPieceView(
            piece: _dragPiece!,
            style: widget.appearance.pieces,
            flat: widget.appearance.view == BoardViewMode.flat,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targets = widget.controller.targets;
    final checkedSquare = checkedKingSquare(widget.controller.rules);
    final material = BoardMaterial.of(widget.appearance.board);
    final flat = widget.appearance.view == BoardViewMode.flat;
    return Container(
      padding: EdgeInsets.all(flat ? 5 : 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(material.frame, Colors.white, .22)!,
            material.frame,
            Color.lerp(material.frame, Colors.black, .26)!,
          ],
        ),
        boxShadow: [
          if (!flat)
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardWidth = constraints.maxWidth;
              final grid = GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 64,
                itemBuilder: (context, index) {
                  final actual = widget.controller.flipped ? 63 - index : index;
                  final row = actual ~/ 8, col = actual % 8;
                  final square = '${String.fromCharCode(97 + col)}${8 - row}';
                  final piece = widget.controller.rules.pieceAt(square);
                  final light = (row + col).isEven;
                  final selected = widget.controller.selected == square;
                  final checked = checkedSquare == square;
                  final recent =
                      widget.controller.lastFrom == square ||
                      widget.controller.lastTo == square;
                  final color = light ? material.light : material.dark;
                  final ink = color.computeLuminance() > .45
                      ? const Color(0xFF304842)
                      : Colors.white;
                  return Semantics(
                    button: widget.onSquareTap != null,
                    selected: selected,
                    label: squareLabel(
                      widget.controller,
                      square,
                      showLegalMoves: widget.appearance.showLegalMoves,
                    ),
                    child: GestureDetector(
                      key: ValueKey('square-$square'),
                      onTap: widget.onSquareTap == null
                          ? null
                          : () => widget.onSquareTap!(square),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        color: checked
                            ? Color.lerp(color, const Color(0xFFD94A4A), .60)
                            : selected
                            ? Color.lerp(color, const Color(0xFF82AC69), .65)
                            : recent
                            ? Color.lerp(color, const Color(0xFFC9AE5E), .34)
                            : color,
                        child: Stack(
                          children: [
                            if (!flat && widget.texture != null)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SurfacePainter(
                                    widget.texture!,
                                    row,
                                    col,
                                    material,
                                  ),
                                ),
                              ),
                            if (checked)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    key: ValueKey('checked-square-$square'),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFB3261E),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (piece != null &&
                                !(square == _movingTo && _motion.isAnimating))
                              Positioned.fill(
                                child: Opacity(
                                  opacity: _dragFrom == square &&
                                          _dragPiece != null
                                      ? .35
                                      : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: ChessPieceView(
                                      piece: piece,
                                      style: widget.appearance.pieces,
                                      flat: flat,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.appearance.showLegalMoves &&
                                targets.contains(square))
                              Center(
                                child: Container(
                                  key: ValueKey('legal-target-$square'),
                                  width: piece == null ? 13 : 40,
                                  height: piece == null ? 13 : 40,
                                  decoration: BoxDecoration(
                                    color: piece == null
                                        ? ink.withValues(alpha: .45)
                                        : null,
                                    shape: BoxShape.circle,
                                    border: piece == null
                                        ? null
                                        : Border.all(
                                            color: ink.withValues(alpha: .8),
                                            width: 3,
                                          ),
                                  ),
                                ),
                              ),
                            if (index ~/ 8 == 7)
                              Positioned(
                                right: 3,
                                bottom: 1,
                                child: Text(
                                  String.fromCharCode(97 + col),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                  ),
                                ),
                              ),
                            if (index % 8 == 0)
                              Positioned(
                                left: 3,
                                top: 1,
                                child: Text(
                                  '${8 - row}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
              final boardStack = AnimatedBuilder(
                animation: _motion,
                child: grid,
                builder: (context, child) => Stack(
                  children: [
                    child!,
                    if (_motion.isAnimating && _movingPiece != null)
                      _movingOverlay(boardWidth),
                    if (_dragPiece != null && _dragPosition != null)
                      _draggingOverlay(boardWidth),
                  ],
                ),
              );
              if (widget.onSquareTap == null) return boardStack;
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final from = _squareAt(event.localPosition, boardWidth);
                  if (from == null) return;
                  final piece = widget.controller.rules.pieceAt(from);
                  if (piece == null ||
                      piece.isWhite != widget.controller.rules.whiteToMove) {
                    return;
                  }
                  _dragStartPos = event.localPosition;
                  setState(() {
                    _dragFrom = from;
                    _dragPiece = piece;
                    _dragPosition = event.localPosition;
                  });
                },
                onPointerMove: (event) {
                  if (_dragPiece == null) return;
                  setState(() => _dragPosition = event.localPosition);
                },
                onPointerUp: (event) {
                  final from = _dragFrom;
                  final startPos = _dragStartPos;
                  final piece = _dragPiece;
                  setState(() {
                    _dragFrom = null;
                    _dragPiece = null;
                    _dragPosition = null;
                    _dragStartPos = null;
                  });
                  if (from == null || piece == null || startPos == null) return;
                  final distance = (event.localPosition - startPos).distance;
                  if (distance > 10 && widget.onSquareTap != null) {
                    final to = _squareAt(event.localPosition, boardWidth);
                    if (to != null && to != from) {
                      if (widget.controller.selected != from) {
                        widget.onSquareTap?.call(from);
                      }
                      if (widget.controller.targets.contains(to)) {
                        widget.onSquareTap?.call(to);
                      }
                    }
                  }
                },
                onPointerCancel: (_) {
                  if (_dragPiece == null) return;
                  setState(() {
                    _dragFrom = null;
                    _dragPiece = null;
                    _dragPosition = null;
                    _dragStartPos = null;
                  });
                },
                child: boardStack,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SurfacePainter extends CustomPainter {
  const _SurfacePainter(this.image, this.row, this.col, this.material);
  final ui.Image image;
  final int row, col;
  final BoardMaterial material;
  @override
  void paint(Canvas canvas, Size size) {
    final tile = image.width / 4;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH((col % 4) * tile, (row % 4) * tile, tile, tile),
      Offset.zero & size,
      Paint()
        ..color = Colors.white.withValues(
          alpha: material.texture!.contains('marble') ? .22 : .17,
        )
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.image != image ||
      old.row != row ||
      old.col != col ||
      old.material != material;
}
